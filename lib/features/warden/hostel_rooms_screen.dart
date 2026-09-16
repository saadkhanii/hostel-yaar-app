import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/hostel_service.dart';

/// Warden-facing screen for a single hostel: shows every room with its
/// seat/vacancy status and lets the warden add, edit, or remove rooms.
///
/// All mutations hit the backend immediately — an add/edit/delete here is
/// persisted before the sheet closes. On pop, the parent should reload
/// its hostel list so the card's stats reflect the new state.
class HostelRoomsScreen extends StatefulWidget {
  final String hostelId;
  final String hostelName;
  final List<Map<String, dynamic>> rooms;

  const HostelRoomsScreen({
    super.key,
    required this.hostelId,
    required this.hostelName,
    required this.rooms,
  });

  @override
  State<HostelRoomsScreen> createState() => _HostelRoomsScreenState();
}

class _HostelRoomsScreenState extends State<HostelRoomsScreen> {
  static const maroon = Color(0xFF800020);
  static const List<int> _roomTypeOptions = [1, 2, 3, 4, 5, 6];

  final _hostelService = HostelService();
  late List<Map<String, dynamic>> _rooms;

  @override
  void initState() {
    super.initState();
    // Work on a copy so nothing mutates the caller's list.
    _rooms = widget.rooms.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  int get _totalSeats =>
      _rooms.fold<int>(0, (s, r) => s + ((r['roomType'] as int?) ?? 0));

  int get _vacantSeats => _rooms.fold<int>(0, (s, r) {
    if (r['bookingType'] == 'Seat') {
      return s + ((r['availableSeats'] as int?) ?? 0);
    }
    return s + (r['vacant'] == true ? ((r['roomType'] as int?) ?? 0) : 0);
  });

  // ── Delete ────────────────────────────────────────────────────────────
  Future<void> _confirmDeleteRoom(int index) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final room = _rooms[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
        isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove Room',
          style: TextStyle(color: maroon, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Remove Room ${room['number']}? This cannot be undone.',
          style: TextStyle(color: maroon.withValues(alpha: 0.75)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: maroon.withValues(alpha: 0.6)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final roomId = room['id'] as String?;
    if (roomId == null) {
      // Shouldn't happen — every room from the backend has an id.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room id missing — cannot delete')),
      );
      return;
    }

    try {
      await _hostelService.deleteRoom(widget.hostelId, roomId);
      if (!mounted) return;
      setState(() => _rooms.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not remove: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  // ── Add / Edit Room sheet ─────────────────────────────────────────────
  void _showRoomSheet({int? existingIndex}) {
    final existing = existingIndex != null ? _rooms[existingIndex] : null;
    final roomId = existing?['id'] as String?;

    final roomNumCtrl = TextEditingController(text: existing?['number'] ?? '');
    final priceCtrl = TextEditingController(
      text: (existing?['price'] as int?)?.toString() ?? '',
    );
    final advanceCtrl = TextEditingController(
      text: (existing?['advance'] as int?)?.toString() ?? '',
    );

    String bookingType = existing?['bookingType'] ?? 'Room';
    int roomType = existing?['roomType'] ?? 1;
    bool attachedWashroom = existing?['attachedWashroom'] ?? false;
    bool roomVacant = existing?['vacant'] ?? true;
    final availableSeatsCtrl = TextEditingController(
      text: existing != null
          ? (existing['availableSeats'] ?? 0).toString()
          : (bookingType == 'Room' ? roomType.toString() : '0'),
    );
    String? errorText;
    bool isSaving = false;

    // Upcoming vacancies (unchanged from original — local-only for now).
    List<Map<String, dynamic>> upcomingVacancies = existing != null &&
        existing['upcomingVacancies'] != null
        ? (existing['upcomingVacancies'] as List)
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList()
        : <Map<String, dynamic>>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1D2128)
          : const Color(0xFFF3E6D5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> submit() async {
            final roomNum = roomNumCtrl.text.trim();
            if (roomNum.isEmpty) {
              setSheetState(() => errorText = 'Room number/name is required');
              return;
            }

            final isDuplicate = _rooms.asMap().entries.any((entry) =>
            entry.key != existingIndex &&
                (entry.value['number'] as String).toLowerCase() ==
                    roomNum.toLowerCase());
            if (isDuplicate) {
              setSheetState(() => errorText = 'Room "$roomNum" already exists');
              return;
            }

            final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
            final advance = int.tryParse(advanceCtrl.text.trim()) ?? 0;
            if (price <= 0) {
              setSheetState(() => errorText = 'Rent must be greater than 0');
              return;
            }
            if (advance < 0) {
              setSheetState(() => errorText = 'Advance cannot be negative');
              return;
            }

            final seatsText = availableSeatsCtrl.text.trim();
            final parsedSeats = int.tryParse(seatsText);
            final available = bookingType == 'Room'
                ? (roomVacant ? roomType : 0)
                : (parsedSeats ?? -1);
            if (bookingType == 'Seat' &&
                (seatsText.isEmpty || available < 0 || available > roomType)) {
              setSheetState(() => errorText =
              'Vacant seats must be between 0 and $roomType');
              return;
            }

            setSheetState(() {
              isSaving = true;
              errorText = null;
            });

            // Build the payload in Flutter camelCase — HostelService
            // translates to backend snake_case.
            final payload = <String, dynamic>{
              'number': roomNum,
              'bookingType': bookingType,
              'roomType': roomType,
              'availableSeats': available,
              'attachedWashroom': attachedWashroom,
              'price': price,
              'advance': advance,
              'vacant': bookingType == 'Room' ? roomVacant : (available > 0),
              'availabilityDates': existing?['availabilityDates'] ?? <String>[],
            };

            try {
              Map<String, dynamic> saved;
              if (roomId == null) {
                saved = await _hostelService.addRoom(
                  widget.hostelId,
                  payload,
                );
              } else {
                saved = await _hostelService.updateRoom(
                  widget.hostelId,
                  roomId,
                  payload,
                );
              }

              // Carry over fields the service doesn't return but the UI
              // still reads (availabilitySameDate, upcomingVacancies).
              saved['availabilitySameDate'] =
                  existing?['availabilitySameDate'] ?? true;
              saved['upcomingVacancies'] = upcomingVacancies;

              if (!mounted) return;

              setState(() {
                if (existingIndex != null) {
                  _rooms[existingIndex] = saved;
                } else {
                  _rooms.add(saved);
                }
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    existingIndex != null
                        ? 'Room $roomNum updated'
                        : 'Room $roomNum added',
                  ),
                ),
              );
            } catch (e) {
              if (!mounted) return;
              setSheetState(() {
                isSaving = false;
                errorText = e.toString().replaceFirst('Exception: ', '');
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existingIndex != null ? 'Edit Room' : 'Add Room',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: maroon,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _field(
                    controller: roomNumCtrl,
                    label: 'Room Number',
                    hint: 'e.g. 101',
                    icon: Icons.door_front_door_outlined,
                    onChanged: (_) =>
                        setSheetState(() => errorText = null),
                  ),
                  const SizedBox(height: 14),

                  // ── Listing type ────────────────────────────────
                  const Text(
                    'Listing Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: maroon,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ('Room', 'Complete Room'),
                      ('Seat', 'Per Seat'),
                    ].map((entry) {
                      final (value, label) = entry;
                      final selected = bookingType == value;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() {
                            bookingType = value;
                            if (bookingType == 'Room') {
                              availableSeatsCtrl.text =
                              roomVacant ? roomType.toString() : '0';
                            }
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? maroon
                                  : maroon.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected
                                    ? maroon
                                    : maroon.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : maroon,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // ── Room type ───────────────────────────────────
                  const Text(
                    'Room Type (Seater)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: maroon,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _roomTypeOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final type = _roomTypeOptions[i];
                        final selected = roomType == type;
                        return GestureDetector(
                          onTap: () => setSheetState(() {
                            roomType = type;
                            final currentAvailable =
                                int.tryParse(availableSeatsCtrl.text) ?? 0;
                            if (bookingType == 'Room' ||
                                currentAvailable > roomType) {
                              availableSeatsCtrl.text = roomType.toString();
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? maroon
                                  : maroon.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected
                                    ? maroon
                                    : maroon.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              '$type Seater',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : maroon,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Room status / available seats ───────────────
                  if (bookingType == 'Room') ...[
                    const Text(
                      'Room Status',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: maroon,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        (true, 'Vacant'),
                        (false, 'Filled'),
                      ].map((entry) {
                        final (value, label) = entry;
                        final selected = roomVacant == value;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() {
                              roomVacant = value;
                              availableSeatsCtrl.text =
                              value ? roomType.toString() : '0';
                            }),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding:
                              const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? (value ? Colors.green : maroon)
                                    : maroon.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selected
                                      ? (value ? Colors.green : maroon)
                                      : maroon.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : maroon,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    _field(
                      controller: availableSeatsCtrl,
                      label: 'Seats Currently Vacant (0 – $roomType)',
                      hint: '0 if fully occupied',
                      icon: Icons.event_seat_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      onChanged: (_) =>
                          setSheetState(() => errorText = null),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // ── Price & advance ─────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: priceCtrl,
                          label: 'Monthly Rent (Rs.)',
                          hint: 'e.g. 12000',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (_) =>
                              setSheetState(() => errorText = null),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: advanceCtrl,
                          label: 'Advance (Rs.)',
                          hint: 'e.g. 12000',
                          icon: Icons.lock_outline,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (_) =>
                              setSheetState(() => errorText = null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Attached washroom ───────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: maroon.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: maroon.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wc_outlined, color: maroon, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Attached Washroom',
                            style: TextStyle(fontSize: 14, color: maroon),
                          ),
                        ),
                        Switch(
                          value: attachedWashroom,
                          onChanged: (v) =>
                              setSheetState(() => attachedWashroom = v),
                          activeThumbColor: maroon,
                        ),
                      ],
                    ),
                  ),

                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style:
                      const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: maroon,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSaving ? null : submit,
                      child: isSaving
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(
                              Color(0xFFF3E6D5)),
                        ),
                      )
                          : Text(
                        existingIndex != null
                            ? 'Save Changes'
                            : 'Add Room',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : const Color(0xFF800020);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, _rooms);
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: fg, size: 18),
            onPressed: () => Navigator.pop(context, _rooms),
          ),
          title: Text(
            widget.hostelName,
            style: TextStyle(
                color: fg, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: Row(
                  children: [
                    Expanded(
                        child: _summaryStat('Rooms', '${_rooms.length}', fg)),
                    Expanded(
                        child: _summaryStat('Total Seats', '$_totalSeats', fg)),
                    Expanded(
                        child:
                        _summaryStat('Vacant Seats', '$_vacantSeats', fg)),
                  ],
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: _rooms.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'No rooms yet. Tap "Add Room" below to create the first one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: fg.withValues(alpha: 0.5)),
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _rooms.length,
                  itemBuilder: (context, i) => _ManagedRoomCard(
                    room: _rooms[i],
                    onEdit: () => _showRoomSheet(existingIndex: i),
                    onDelete: () => _confirmDeleteRoom(i),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: maroon,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Room',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          onPressed: () => _showRoomSheet(),
        ),
      ),
    );
  }

  Widget _summaryStat(String label, String value, Color fg) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: fg),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}

String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

// ── Reusable text field ────────────────────────────────────────────────
Widget _field({
  TextEditingController? controller,
  required String label,
  required String hint,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  List<TextInputFormatter>? inputFormatters,
  void Function(String)? onChanged,
}) {
  const maroon = Color(0xFF800020);
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    onChanged: onChanged,
    style: const TextStyle(color: maroon, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon:
      Icon(icon, color: maroon.withValues(alpha: 0.6), size: 20),
      labelStyle:
      TextStyle(color: maroon.withValues(alpha: 0.7), fontSize: 13),
      hintStyle:
      TextStyle(color: maroon.withValues(alpha: 0.35), fontSize: 13),
      filled: true,
      fillColor: maroon.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: maroon.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: maroon.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: maroon),
      ),
    ),
  );
}

// ── Room card shown in the list ─────────────────────────────────────────
class _ManagedRoomCard extends StatelessWidget {
  final Map<String, dynamic> room;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ManagedRoomCard({
    required this.room,
    required this.onEdit,
    required this.onDelete,
  });

  static const maroon = Color(0xFF800020);

  @override
  Widget build(BuildContext context) {
    final bookingType = room['bookingType'] as String? ?? 'Room';
    final roomType = (room['roomType'] as int?) ?? 0;
    final availableSeats = (room['availableSeats'] as int?) ?? 0;
    final vacant = room['vacant'] == true;
    final price = (room['price'] as int?) ?? 0;
    final bool currentlyFree =
    bookingType == 'Room' ? vacant : availableSeats > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: maroon.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: maroon.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.door_front_door_outlined,
                  color: maroon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Room ${room['number']}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: maroon,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: currentlyFree
                      ? Colors.green.withValues(alpha: 0.15)
                      : maroon.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bookingType == 'Room'
                      ? (vacant ? 'Vacant' : 'Filled')
                      : '$availableSeats/$roomType vacant',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: currentlyFree ? Colors.green[800] : maroon,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    color: maroon.withValues(alpha: 0.6), size: 18),
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: maroon.withValues(alpha: 0.6), size: 18),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$roomType Seater • ${bookingType == 'Room' ? 'Complete Room' : 'Per Seat'} • '
                '${room['attachedWashroom'] == true ? 'Attached WR' : 'Shared WR'}',
            style: TextStyle(
                fontSize: 12, color: maroon.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 4),
          Text(
            'Rs. $price/mo  •  Advance: Rs. ${room['advance'] ?? 0}',
            style: TextStyle(
                fontSize: 12, color: maroon.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}