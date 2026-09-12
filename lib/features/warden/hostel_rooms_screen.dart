import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Warden-facing screen for a single hostel: shows every room with its
/// seat/vacancy status and lets the warden update seats, mark rooms
/// vacant/filled, schedule upcoming vacancies (e.g. "2 of 3 seats free
/// from 20 Sep"), add brand-new rooms, or remove rooms entirely.
///
/// The hostel's "total rooms" is simply the length of this list, so
/// adding/removing a room here already IS updating the total room count —
/// there's no separate counter to keep in sync.
///
/// Pass the hostel's current room list in, and use the value this screen
/// pops with (via the back button) to write the edits back to the caller:
///
///   final updated = await Navigator.push<List<Map<String, dynamic>>>(
///     context,
///     MaterialPageRoute(
///       builder: (_) => HostelRoomsScreen(hostelName: name, rooms: rooms),
///     ),
///   );
///   if (updated != null) setState(() => hostel['rooms'] = updated);
class HostelRoomsScreen extends StatefulWidget {
  final String hostelName;
  final List<Map<String, dynamic>> rooms;

  const HostelRoomsScreen({
    super.key,
    required this.hostelName,
    required this.rooms,
  });

  @override
  State<HostelRoomsScreen> createState() => _HostelRoomsScreenState();
}

class _HostelRoomsScreenState extends State<HostelRoomsScreen> {
  static const maroon = Color(0xFF800020);
  static const List<int> _roomTypeOptions = [1, 2, 3, 4, 5, 6];

  late List<Map<String, dynamic>> _rooms;

  @override
  void initState() {
    super.initState();
    // Work on a copy so nothing mutates the caller's list until we
    // explicitly hand the edited version back on pop.
    _rooms = widget.rooms.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  int get _totalSeats => _rooms.fold<int>(0, (s, r) => s + (r['roomType'] as int));

  int get _vacantSeats => _rooms.fold<int>(0, (s, r) {
    if (r['bookingType'] == 'Seat') return s + (r['availableSeats'] as int);
    return s + (r['vacant'] == true ? (r['roomType'] as int) : 0);
  });

  void _confirmDeleteRoom(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Room', style: TextStyle(color: maroon, fontWeight: FontWeight.bold)),
        content: Text(
          'Remove Room ${_rooms[index]['number']}? This cannot be undone.',
          style: TextStyle(color: maroon.withValues(alpha: 0.75)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: maroon.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () {
              setState(() => _rooms.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Add / Edit Room sheet ──────────────────────────────────────────
  void _showRoomSheet({int? existingIndex}) {
    final existing = existingIndex != null ? _rooms[existingIndex] : null;

    final roomNumCtrl = TextEditingController(text: existing?['number'] ?? '');
    String bookingType = existing?['bookingType'] ?? 'Room';
    int roomType = existing?['roomType'] ?? 1;
    bool attachedWashroom = existing?['attachedWashroom'] ?? false;
    bool roomVacant = existing?['vacant'] ?? true;
    final availableSeatsCtrl = TextEditingController(
      text: existing != null
          ? existing['availableSeats'].toString()
          : (bookingType == 'Room' ? roomType.toString() : '0'),
    );
    String? errorText;

    // Seats/rooms that are occupied right now but scheduled to become
    // free on a known future date.
    List<Map<String, dynamic>> upcomingVacancies = existing != null && existing['upcomingVacancies'] != null
        ? (existing['upcomingVacancies'] as List).map((v) => Map<String, dynamic>.from(v as Map)).toList()
        : <Map<String, dynamic>>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1D2128)
          : const Color(0xFFF3E6D5),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> addVacancy() async {
            int seats = 1;
            DateTime date = DateTime.now().add(const Duration(days: 1));
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1D2128)
                  : const Color(0xFFF3E6D5),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (context) => StatefulBuilder(
                builder: (context, setVacancySheetState) => Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Schedule Upcoming Vacancy',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: maroon),
                      ),
                      const SizedBox(height: 16),
                      if (bookingType == 'Seat') ...[
                        Text('Seats becoming vacant', style: TextStyle(fontSize: 13, color: maroon.withValues(alpha: 0.8))),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              onPressed: seats > 1 ? () => setVacancySheetState(() => seats--) : null,
                              icon: const Icon(Icons.remove_circle_outline, color: maroon),
                            ),
                            Text('$seats', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: maroon)),
                            IconButton(
                              onPressed: seats < roomType ? () => setVacancySheetState(() => seats++) : null,
                              icon: const Icon(Icons.add_circle_outline, color: maroon),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'The whole room will be marked vacant from this date.',
                            style: TextStyle(fontSize: 12, color: maroon.withValues(alpha: 0.6)),
                          ),
                        ),
                      _datePickerField(
                        context: context,
                        label: 'Vacant From',
                        date: date,
                        onPick: (picked) => setVacancySheetState(() => date = picked),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: maroon,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            final seatsForEntry = bookingType == 'Seat' ? seats : roomType;
                            Navigator.pop(context);
                            setSheetState(() {
                              upcomingVacancies.add({'seats': seatsForEntry, 'date': date.toIso8601String()});
                            });
                          },
                          child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: maroon),
                  ),
                  const SizedBox(height: 20),
                  _field(
                    controller: roomNumCtrl,
                    label: 'Room Number',
                    hint: 'e.g. 101',
                    icon: Icons.door_front_door_outlined,
                  ),
                  const SizedBox(height: 14),
                  const Text('Listing Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: maroon)),
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
                              availableSeatsCtrl.text = roomVacant ? roomType.toString() : '0';
                            } else if (int.tryParse(availableSeatsCtrl.text) == null) {
                              availableSeatsCtrl.text = '0';
                            }
                            errorText = null;
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? maroon : maroon.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: selected ? maroon : maroon.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : maroon),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text('Room Type (Seater)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: maroon)),
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
                            final currentAvailable = int.tryParse(availableSeatsCtrl.text) ?? 0;
                            if (bookingType == 'Room' || currentAvailable > roomType) {
                              availableSeatsCtrl.text = roomType.toString();
                            }
                            errorText = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? maroon : maroon.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: selected ? maroon : maroon.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              '$type Seater',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : maroon),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (bookingType == 'Room') ...[
                    const SizedBox(height: 14),
                    const Text('Room Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: maroon)),
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
                              availableSeatsCtrl.text = value ? roomType.toString() : '0';
                            }),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected ? (value ? Colors.green : maroon) : maroon.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: selected ? (value ? Colors.green : maroon) : maroon.withValues(alpha: 0.25)),
                              ),
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : maroon),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    const SizedBox(height: 14),
                    _field(
                      controller: availableSeatsCtrl,
                      label: 'Seats Currently Vacant (0 – $roomType)',
                      hint: '0 if fully occupied',
                      icon: Icons.event_seat_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setSheetState(() => errorText = null),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: maroon.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: maroon.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wc_outlined, color: maroon, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('Attached Washroom', style: TextStyle(fontSize: 14, color: maroon))),
                        Switch(
                          value: attachedWashroom,
                          onChanged: (v) => setSheetState(() => attachedWashroom = v),
                          activeThumbColor: maroon,
                        ),
                      ],
                    ),
                  ),

                  // Upcoming vacancies — occupied seats/rooms scheduled to
                  // free up on a known future date (e.g. "2 seats vacant
                  // from 20 Sep" because a tenant gave notice).
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Upcoming Vacancies', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: maroon)),
                      TextButton.icon(
                        onPressed: addVacancy,
                        icon: const Icon(Icons.add, size: 16, color: maroon),
                        label: const Text('Add', style: TextStyle(color: maroon, fontSize: 12)),
                      ),
                    ],
                  ),
                  if (upcomingVacancies.isEmpty)
                    Text(
                      'None scheduled. Add one when a seat or room will free up on a future date.',
                      style: TextStyle(fontSize: 11, color: maroon.withValues(alpha: 0.5)),
                    )
                  else
                    ...upcomingVacancies.asMap().entries.map((e) {
                      final vi = e.key;
                      final v = e.value;
                      final date = DateTime.parse(v['date'] as String);
                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: maroon.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Icon(Icons.event_available_outlined, color: maroon, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${v['seats']} seat${(v['seats'] as int) == 1 ? '' : 's'} vacant from ${_formatDate(date)}',
                                style: const TextStyle(fontSize: 12, color: maroon),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: maroon),
                              onPressed: () => setSheetState(() => upcomingVacancies.removeAt(vi)),
                            ),
                          ],
                        ),
                      );
                    }),

                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(errorText!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: maroon,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final roomNum = roomNumCtrl.text.trim();
                        if (roomNum.isEmpty) {
                          setSheetState(() => errorText = 'Room number/name is required');
                          return;
                        }
                        final isDuplicate = _rooms.asMap().entries.any((entry) =>
                        entry.key != existingIndex &&
                            (entry.value['number'] as String).toLowerCase() == roomNum.toLowerCase());
                        if (isDuplicate) {
                          setSheetState(() => errorText = 'Room "$roomNum" already exists');
                          return;
                        }
                        final seatsText = availableSeatsCtrl.text.trim();
                        final parsedSeats = int.tryParse(seatsText);
                        final available = bookingType == 'Room' ? (roomVacant ? roomType : 0) : (parsedSeats ?? -1);
                        if (bookingType == 'Seat' && (seatsText.isEmpty || available < 0 || available > roomType)) {
                          setSheetState(() => errorText = 'Vacant seats must be between 0 and $roomType');
                          return;
                        }

                        final room = {
                          'number': roomNum,
                          'bookingType': bookingType,
                          'roomType': roomType,
                          'availableSeats': available,
                          'attachedWashroom': attachedWashroom,
                          'vacant': bookingType == 'Room' ? roomVacant : (available > 0),
                          'price': existing?['price'] ?? 0,
                          'advance': existing?['advance'] ?? 0,
                          // Carried over as-is; set from the Add Hostel flow.
                          'availabilityDates': existing?['availabilityDates'] ?? <String>[],
                          'availabilitySameDate': existing?['availabilitySameDate'] ?? true,
                          'upcomingVacancies': upcomingVacancies,
                        };
                        setState(() {
                          if (existingIndex != null) {
                            _rooms[existingIndex] = room;
                          } else {
                            _rooms.add(room);
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        existingIndex != null ? 'Save Changes' : 'Add Room',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
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
          title: Text(widget.hostelName, style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: Row(
                  children: [
                    Expanded(child: _summaryStat('Rooms', '${_rooms.length}', fg)),
                    Expanded(child: _summaryStat('Total Seats', '$_totalSeats', fg)),
                    Expanded(child: _summaryStat('Vacant Seats', '$_vacantSeats', fg)),
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
          label: const Text('Add Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          onPressed: () => _showRoomSheet(),
        ),
      ),
    );
  }

  Widget _summaryStat(String label, String value, Color fg) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: fg)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.6))),
      ],
    );
  }
}

String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

// ── Reusable date-picker row ──────────────────────────────────────────
Widget _datePickerField({
  required BuildContext context,
  required String label,
  required DateTime date,
  required ValueChanged<DateTime> onPick,
}) {
  const maroon = Color(0xFF800020);
  return GestureDetector(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (picked != null) onPick(picked);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: maroon.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: maroon.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, color: maroon, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: maroon))),
          Text(_formatDate(date), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: maroon)),
        ],
      ),
    ),
  );
}

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
      prefixIcon: Icon(icon, color: maroon.withValues(alpha: 0.6), size: 20),
      labelStyle: TextStyle(color: maroon.withValues(alpha: 0.7), fontSize: 13),
      hintStyle: TextStyle(color: maroon.withValues(alpha: 0.35), fontSize: 13),
      filled: true,
      fillColor: maroon.withValues(alpha: 0.06),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: maroon.withValues(alpha: 0.2))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: maroon.withValues(alpha: 0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: maroon)),
    ),
  );
}

// ── Room card shown in the list ─────────────────────────────────────────
class _ManagedRoomCard extends StatelessWidget {
  final Map<String, dynamic> room;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ManagedRoomCard({required this.room, required this.onEdit, required this.onDelete});

  static const maroon = Color(0xFF800020);

  @override
  Widget build(BuildContext context) {
    final bookingType = room['bookingType'] as String;
    final roomType = room['roomType'] as int;
    final availableSeats = room['availableSeats'] as int;
    final vacant = room['vacant'] == true;
    final upcoming = (room['upcomingVacancies'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final bool currentlyFree = bookingType == 'Room' ? vacant : availableSeats > 0;

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
              const Icon(Icons.door_front_door_outlined, color: maroon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Room ${room['number']}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: maroon),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: currentlyFree ? Colors.green.withValues(alpha: 0.15) : maroon.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bookingType == 'Room' ? (vacant ? 'Vacant' : 'Filled') : '$availableSeats/$roomType vacant',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: currentlyFree ? Colors.green[800] : maroon,
                  ),
                ),
              ),
              IconButton(icon: Icon(Icons.edit_outlined, color: maroon.withValues(alpha: 0.6), size: 18), onPressed: onEdit),
              IconButton(icon: Icon(Icons.delete_outline, color: maroon.withValues(alpha: 0.6), size: 18), onPressed: onDelete),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$roomType Seater • ${bookingType == 'Room' ? 'Complete Room' : 'Per Seat'} • '
                '${room['attachedWashroom'] == true ? 'Attached WR' : 'Shared WR'}',
            style: TextStyle(fontSize: 12, color: maroon.withValues(alpha: 0.6)),
          ),
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...upcoming.map((v) {
              final date = DateTime.parse(v['date'] as String);
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_outlined, size: 14, color: Colors.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${v['seats']} seat${(v['seats'] as int) == 1 ? '' : 's'} becoming vacant on ${_formatDate(date)}',
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}