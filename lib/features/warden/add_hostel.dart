import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddHostelScreen extends StatefulWidget {
  const AddHostelScreen({super.key});

  @override
  State<AddHostelScreen> createState() => _AddHostelScreenState();
}

class _AddHostelScreenState extends State<AddHostelScreen> {
  static const maroon = Color(0xFF800020);

  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // ── Basic Info ─────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _totalRoomsCtrl = TextEditingController();
  String _selectedType = 'Boys';

  // ── Rooms ──────────────────────────────────────────────────
  final List<Map<String, dynamic>> _rooms = [];

  // Parses the "Total rooms in hostel" field from Step 1. Used to gate
  // Step 2 so a warden can't move on with fewer rooms entered than the
  // hostel actually has.
  int? get _declaredTotalRooms => int.tryParse(_totalRoomsCtrl.text.trim());

  // ── Pricing (rent & advance security are both set per-room) ──────────

  // ── Facilities ─────────────────────────────────────────────
  final Map<String, bool> _facilities = {
    'WiFi': false,
    'Meals': false,
    'Laundry': false,
    'Generator': false,
    'Parking': false,
    'CCTV': false,
    'Kitchen': false,
    'Refrigerator': false,
    'Water Cooler': false,
  };

  // ── Contact ────────────────────────────────────────────────
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  bool _inAppChat = true;

  // ── Photos ─────────────────────────────────────────────────
  final List<String> _photos = []; // will hold file paths

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _totalRoomsCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : const Color(0xFF800020);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: fg, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add New Hostel',
          style: TextStyle(
            color: fg,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Step Indicator ───────────────────────────────────
          _StepIndicator(currentStep: _currentStep),

          // ── Form ─────────────────────────────────────────────
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _buildCurrentStep(isDark, fg),
              ),
            ),
          ),

          // ── Bottom Buttons ────────────────────────────────────
          _BottomButtons(
            currentStep: _currentStep,
            totalSteps: 5,
            onBack: () => setState(() => _currentStep--),
            onNext: _handleNext,
            onSubmit: _handleSubmit,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(bool isDark, Color fg) {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfo(fg);
      case 1:
        return _buildRooms(fg);
      case 2:
        return _buildPricing(fg);
      case 3:
        return _buildFacilities(fg);
      case 4:
        return _buildContactAndPhotos(fg);
      default:
        return const SizedBox();
    }
  }

  // ── Step 1: Basic Info ────────────────────────────────────────────────────
  Widget _buildBasicInfo(Color fg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Basic Information', fg),
        const SizedBox(height: 16),
        _inputField(
          controller: _nameCtrl,
          label: 'Hostel Name',
          hint: 'e.g. Green View Boys Hostel',
          icon: Icons.home_work_outlined,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        _sectionLabel('Hostel Type', fg),
        const SizedBox(height: 8),
        Row(
          children: ['Boys', 'Girls', 'Mixed'].map((type) {
            final selected = _selectedType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? maroon : maroon.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? maroon : maroon.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    type,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
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
        _inputField(
          controller: _cityCtrl,
          label: 'City',
          hint: 'e.g. Lahore',
          icon: Icons.location_city_outlined,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        _inputField(
          controller: _addressCtrl,
          label: 'Full Address',
          hint: 'Street, area, city...',
          icon: Icons.location_on_outlined,
          maxLines: 2,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        _inputField(
          controller: _totalRoomsCtrl,
          label: 'Total Rooms in Hostel',
          hint: 'e.g. 6',
          icon: Icons.grid_view_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            final n = int.tryParse(v.trim());
            if (n == null || n <= 0) return 'Enter a valid number';
            return null;
          },
        ),
      ],
    );
  }

  // ── Step 2: Rooms ─────────────────────────────────────────────────────────
  Widget _buildRooms(Color fg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Rooms & Seats', fg),
        const SizedBox(height: 6),
        Text(
          'Add each room individually with its details',
          style: TextStyle(fontSize: 12, color: fg.withOpacity(0.5)),
        ),
        const SizedBox(height: 16),

        // Availability summary — lets the warden see at a glance how many
        // Complete Rooms are vacant vs. filled, and how many individual
        // seats are open across Per Seat rooms.
        if (_rooms.isNotEmpty) _buildAvailabilitySummary(fg),

        // Existing rooms
        ..._rooms.asMap().entries.map((entry) {
          final i = entry.key;
          final room = entry.value;
          return _RoomCard(
            index: i,
            room: room,
            onDelete: () => setState(() => _rooms.removeAt(i)),
            onEdit: () => _showAddRoomSheet(existingIndex: i),
          );
        }),

        // Add room button
        GestureDetector(
          onTap: () => _showAddRoomSheet(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: maroon.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: maroon.withOpacity(0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.add_circle_outline, color: maroon.withOpacity(0.6), size: 28),
                const SizedBox(height: 6),
                Text(
                  'Add a Room',
                  style: TextStyle(
                    fontSize: 14,
                    color: maroon.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_declaredTotalRooms != null && _rooms.length != _declaredTotalRooms)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _rooms.length < _declaredTotalRooms!
                  ? 'Add ${_declaredTotalRooms! - _rooms.length} more room${_declaredTotalRooms! - _rooms.length == 1 ? '' : 's'} to match the total entered in Step 1'
                  : 'You have ${_rooms.length - _declaredTotalRooms!} more room${_rooms.length - _declaredTotalRooms! == 1 ? '' : 's'} than declared in Step 1',
              style: TextStyle(fontSize: 12, color: maroon.withOpacity(0.5)),
            ),
          ),
      ],
    );
  }

  // Summarizes booking availability across all added rooms: how many
  // Complete Rooms are vacant/filled, and how many total seats are open
  // across Per Seat rooms — so the warden can see booking capacity at a
  // glance while adding rooms.
  Widget _buildAvailabilitySummary(Color fg) {
    final completeRooms = _rooms.where((r) => r['bookingType'] == 'Room').toList();
    final vacantRooms = completeRooms.where((r) => r['vacant'] == true).length;
    final filledRooms = completeRooms.length - vacantRooms;

    final seatRooms = _rooms.where((r) => r['bookingType'] == 'Seat').toList();
    final availableSeats = seatRooms.fold<int>(
      0,
          (sum, r) => sum + (r['availableSeats'] as int? ?? 0),
    );
    final totalSeats = seatRooms.fold<int>(
      0,
          (sum, r) => sum + (r['roomType'] as int? ?? 0),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: maroon.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: maroon.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          if (completeRooms.isNotEmpty)
            Expanded(
              child: _summaryStat(
                icon: Icons.meeting_room_outlined,
                label: 'Rooms Available',
                value: '$vacantRooms / ${completeRooms.length}',
                sublabel: '$filledRooms filled',
              ),
            ),
          if (completeRooms.isNotEmpty && seatRooms.isNotEmpty)
            Container(width: 1, height: 34, color: maroon.withOpacity(0.15)),
          if (seatRooms.isNotEmpty)
            Expanded(
              child: _summaryStat(
                icon: Icons.event_seat_outlined,
                label: 'Seats Available',
                value: '$availableSeats / $totalSeats',
                sublabel: '${seatRooms.length} room${seatRooms.length == 1 ? '' : 's'}',
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryStat({
    required IconData icon,
    required String label,
    required String value,
    required String sublabel,
  }) {
    return Row(
      children: [
        Icon(icon, color: maroon, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: maroon,
              ),
            ),
            Text(
              '$label • $sublabel',
              style: TextStyle(fontSize: 10, color: maroon.withOpacity(0.6)),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 3: Pricing ───────────────────────────────────────────────────────
  Widget _buildPricing(Color fg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Pricing', fg),
        const SizedBox(height: 6),
        Text(
          'Set the monthly rent and advance security for each room individually.',
          style: TextStyle(fontSize: 12, color: fg.withOpacity(0.5)),
        ),
        const SizedBox(height: 16),
        if (_rooms.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: maroon.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: maroon.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: maroon, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Add your rooms first — you\'ll set the rent and advance for each one here.',
                    style: TextStyle(fontSize: 12, color: maroon.withOpacity(0.7)),
                  ),
                ),
              ],
            ),
          )
        else
          ..._rooms.asMap().entries.map((entry) {
            final i = entry.key;
            final room = entry.value;
            final isWholeRoom = room['bookingType'] == 'Room';
            final price = room['price'] as int;
            final advance = room['advance'] as int;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: maroon.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: maroon.withOpacity(0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.door_front_door_outlined, color: maroon, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Room ${room['number']}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: maroon,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${room['roomType']} Seater',
                        style: TextStyle(fontSize: 12, color: maroon.withOpacity(0.6)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    key: ValueKey('room_price_${room['number']}_$i'),
                    initialValue: price == 0 ? '' : price.toString(),
                    label: isWholeRoom ? 'Rent per Month (per room)' : 'Rent per Month (per seat)',
                    hint: 'e.g. 12000',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    onChanged: (v) => _rooms[i]['price'] = int.tryParse(v) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    key: ValueKey('room_advance_${room['number']}_$i'),
                    initialValue: advance == 0 ? '' : advance.toString(),
                    label: isWholeRoom ? 'Advance Security (per room)' : 'Advance Security (per seat)',
                    hint: 'e.g. 16000',
                    icon: Icons.lock_outline,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    onChanged: (v) => _rooms[i]['advance'] = int.tryParse(v) ?? 0,
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ── Step 4: Facilities ────────────────────────────────────────────────────
  Widget _buildFacilities(Color fg) {
    final icons = {
      'WiFi': Icons.wifi,
      'Meals': Icons.restaurant_outlined,
      'Laundry': Icons.local_laundry_service_outlined,
      'Generator': Icons.bolt_outlined,
      'Parking': Icons.local_parking_outlined,
      'CCTV': Icons.videocam_outlined,
      'Kitchen': Icons.kitchen_outlined,
      'Refrigerator': Icons.kitchen,
      'Water Cooler': Icons.water_drop_outlined,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Facilities', fg),
        const SizedBox(height: 6),
        Text(
          'Select all that apply',
          style: TextStyle(fontSize: 12, color: fg.withOpacity(0.5)),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: _facilities.keys.map((facility) {
            final selected = _facilities[facility]!;
            return GestureDetector(
              onTap: () => setState(() => _facilities[facility] = !selected),
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? maroon : maroon.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? maroon : maroon.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[facility] ?? Icons.check_circle_outline,
                      color: selected ? Colors.white : maroon.withOpacity(0.6),
                      size: 26,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      facility,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : maroon.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Step 5: Contact & Photos ──────────────────────────────────────────────
  Widget _buildContactAndPhotos(Color fg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Contact', fg),
        const SizedBox(height: 16),
        _inputField(
          controller: _phoneCtrl,
          label: 'Phone Number',
          hint: '03XX-XXXXXXX',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        _inputField(
          controller: _whatsappCtrl,
          label: 'WhatsApp Number',
          hint: '03XX-XXXXXXX',
          icon: Icons.chat_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),

        // In-app chat toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: maroon.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: maroon.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.forum_outlined, color: maroon, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enable In-App Chat',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: maroon,
                      ),
                    ),
                    Text(
                      'Allow seekers to message you directly',
                      style: TextStyle(fontSize: 12, color: maroon.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _inAppChat,
                onChanged: (v) => setState(() => _inAppChat = v),
                activeColor: maroon,
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),
        _sectionTitle('Photos', fg),
        const SizedBox(height: 6),
        Text(
          'Add as many photos as you like',
          style: TextStyle(fontSize: 12, color: fg.withOpacity(0.5)),
        ),
        const SizedBox(height: 14),

        // Photo grid
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            // Uploaded photos (dummy placeholders)
            ..._photos.map((_) => Container(
              decoration: BoxDecoration(
                color: maroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.image, color: maroon),
            )),

            // Add photo button
            GestureDetector(
              onTap: () {
                // TODO: integrate image_picker
                setState(() => _photos.add('placeholder'));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: maroon.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: maroon.withOpacity(0.25)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: maroon.withOpacity(0.6), size: 28),
                    const SizedBox(height: 4),
                    Text(
                      'Add',
                      style: TextStyle(fontSize: 11, color: maroon.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Add Room Bottom Sheet ─────────────────────────────────────────────────
  // Room types available: 1 (Single) through 6 seater.
  static const List<int> _roomTypeOptions = [1, 2, 3, 4, 5, 6];

  void _showAddRoomSheet({int? existingIndex}) {
    final existing = existingIndex != null ? _rooms[existingIndex] : null;

    final roomNumCtrl = TextEditingController(text: existing?['number'] ?? '');

    // 'Room' = whole room booked together, occupancy flexible.
    // 'Seat' = individual seats/beds booked and priced separately.
    String bookingType = existing?['bookingType'] ?? 'Room';
    int roomType = existing?['roomType'] ?? 1;
    bool attachedWashroom = existing?['attachedWashroom'] ?? false;
    // For Complete Room listings, tracks whether this room is currently
    // free to book (Vacant) or already occupied (Filled).
    // NOTE: `?? true` defaults missing 'vacant' to Vacant. Harmless now
    // since all rooms are created fresh in this session, but once rooms
    // are loaded back from Firestore, older documents saved before this
    // field existed will silently read as Vacant — revisit if that
    // matters (e.g. migrate on read, or default to Filled instead).
    bool roomVacant = existing?['vacant'] ?? true;
    String? errorText;

    // For a Complete Room booking, available seats always equals the room
    // type (the whole room is the unit), so there's nothing to ask for.
    final availableSeatsCtrl = TextEditingController(
      text: existing != null
          ? existing['availableSeats'].toString()
          : (bookingType == 'Room' ? roomType.toString() : ''),
    );

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
        builder: (context, setSheetState) => Padding(
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
                const Text(
                  'Room Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: maroon,
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Complete Room / Per Seat
                const Text(
                  'Listing Type',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: maroon),
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
                          // Whole-room bookings default to full occupancy;
                          // per-seat listings start with none marked available yet.
                          if (bookingType == 'Room') {
                            availableSeatsCtrl.text = roomType.toString();
                          }
                          errorText = null;
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? maroon : maroon.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected ? maroon : maroon.withOpacity(0.25),
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
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    bookingType == 'Room'
                        ? 'Tenant books the whole room and can adjust occupancy freely.'
                        : 'Tenant books a single seat/bed; only the seats you mark available can be booked.',
                    style: TextStyle(fontSize: 11, color: maroon.withOpacity(0.55)),
                  ),
                ),

                // 1b. Room Status (Vacant / Filled) — only relevant for
                // Complete Room listings, since Per Seat availability is
                // already tracked via Available Seats.
                if (bookingType == 'Room') ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Room Status',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: maroon),
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
                            errorText = null;
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? (value ? Colors.green : maroon)
                                  : maroon.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected
                                    ? (value ? Colors.green : maroon)
                                    : maroon.withOpacity(0.25),
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
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      roomVacant
                          ? 'This room is free and will count toward available bookings.'
                          : 'This room is currently occupied and won\'t be offered for booking.',
                      style: TextStyle(fontSize: 11, color: maroon.withOpacity(0.55)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // 2. Room Details
                _inputField(
                  controller: roomNumCtrl,
                  label: 'Room Number / Name',
                  hint: 'e.g. 101 or Ground Floor Room',
                  icon: Icons.door_front_door_outlined,
                ),
                const SizedBox(height: 14),

                // 3. Room Type (Seater)
                const Text(
                  'Room Type',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: maroon),
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
                          // Available seats can never exceed the room's capacity.
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
                            color: selected ? maroon : maroon.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected ? maroon : maroon.withOpacity(0.25),
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
                // 4. Available Seats — only relevant for Per Seat listings.
                // A Complete Room booking is priced/booked as one unit, so
                // the room type (seater) alone is enough. 0 is a valid
                // value here — it means every seat in the room is currently
                // occupied, which the warden still needs to record.
                if (bookingType == 'Seat') ...[
                  const SizedBox(height: 14),
                  _inputField(
                    controller: availableSeatsCtrl,
                    label: 'Available Seats (0 – $roomType)',
                    hint: '0 if fully occupied, up to $roomType',
                    icon: Icons.people_outline,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null) return 'Required';
                      if (n < 0) return 'Cannot be negative';
                      if (n > roomType) return 'Cannot exceed $roomType';
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 14),

                // 5. Attached Washroom
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: maroon.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: maroon.withOpacity(0.2)),
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
                        onChanged: (v) => setSheetState(() => attachedWashroom = v),
                        activeColor: maroon,
                      ),
                    ],
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorText!,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
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
                    onPressed: () {
                      // Complete Room bookings always use the full room type
                      // as the "available seats" — there's nothing to ask.
                      // For Per Seat rooms, an empty field is treated as not
                      // entered (still required) — 0 is a distinct, valid
                      // value meaning "fully occupied".
                      final seatsText = availableSeatsCtrl.text.trim();
                      final parsedSeats = int.tryParse(seatsText);
                      final available =
                      bookingType == 'Room' ? roomType : (parsedSeats ?? -1);

                      final roomNum = roomNumCtrl.text.trim();
                      if (roomNum.isEmpty) {
                        setSheetState(() => errorText = 'Room number/name is required');
                        return;
                      }
                      // Block duplicate room numbers — compared
                      // case-insensitively, and skipping the room currently
                      // being edited so re-saving it doesn't flag itself.
                      final isDuplicate = _rooms.asMap().entries.any((entry) =>
                      entry.key != existingIndex &&
                          (entry.value['number'] as String).toLowerCase() ==
                              roomNum.toLowerCase());
                      if (isDuplicate) {
                        setSheetState(
                              () => errorText = 'Room "$roomNum" already exists',
                        );
                        return;
                      }
                      if (bookingType == 'Seat' &&
                          (seatsText.isEmpty || available < 0 || available > roomType)) {
                        setSheetState(
                              () => errorText = 'Available seats must be between 0 and $roomType',
                        );
                        return;
                      }

                      final room = {
                        'number': roomNumCtrl.text.trim(),
                        'bookingType': bookingType,
                        'roomType': roomType,
                        'availableSeats': available,
                        'attachedWashroom': attachedWashroom,
                        // Only meaningful for Complete Room listings; a Per
                        // Seat room's availability is derived from
                        // availableSeats instead.
                        'vacant': bookingType == 'Room' ? roomVacant : (available > 0),
                        // Rent & advance are set later, in the Pricing step.
                        'price': existing?['price'] ?? 0,
                        'advance': existing?['advance'] ?? 0,
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
                      existingIndex != null ? 'Update Room' : 'Add Room',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNext() {
    if (_currentStep == 1) {
      if (_rooms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one room')),
        );
        return;
      }
      final declared = _declaredTotalRooms;
      // declared should always be set by this point since Step 1's
      // validator requires it, but fall back to just requiring >=1 room
      // if it's somehow missing.
      if (declared != null && _rooms.length != declared) {
        final remaining = declared - _rooms.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              remaining > 0
                  ? 'Add $remaining more room${remaining == 1 ? '' : 's'} to match the total ($declared) entered in Step 1'
                  : 'You\'ve added ${_rooms.length} rooms but Step 1 says $declared — remove ${-remaining} or update the total',
            ),
          ),
        );
        return;
      }
    }
    if (_formKey.currentState!.validate()) {
      setState(() => _currentStep++);
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // TODO: save to Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hostel listed successfully!')),
      );
      Navigator.pop(context);
    }
  }
}

// ── Room Card ─────────────────────────────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> room;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _RoomCard({
    required this.index,
    required this.room,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: maroon.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: maroon.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.door_front_door_outlined, color: maroon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Room ${room['number']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: maroon,
                      ),
                    ),
                    if (room['bookingType'] == 'Room') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: room['vacant'] == true
                              ? Colors.green.withOpacity(0.15)
                              : maroon.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          room['vacant'] == true ? 'Vacant' : 'Filled',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: room['vacant'] == true ? Colors.green[800] : maroon,
                          ),
                        ),
                      ),
                    ],
                    // Per Seat rooms don't get a Vacant/Filled toggle like
                    // Complete Rooms do, but a fully-booked seat room is
                    // just as worth flagging at a glance.
                    if (room['bookingType'] == 'Seat' && room['availableSeats'] == 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: maroon.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Full',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: maroon,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${room['roomType']} Seater • '
                      '${room['bookingType'] == 'Room' ? 'Complete Room' : 'Per Seat • ${room['availableSeats']}/${room['roomType']} available'} • '
                      '${room['attachedWashroom'] ? 'Attached WR' : 'Shared WR'}',
                  style: TextStyle(fontSize: 12, color: maroon.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: maroon.withOpacity(0.6), size: 18),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: maroon.withOpacity(0.6), size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── Step Indicator ────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  static const maroon = Color(0xFF800020);
  final List<String> labels = const ['Info', 'Rooms', 'Pricing', 'Facilities', 'Contact'];

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(labels.length, (i) {
          final done = i < currentStep;
          final active = i == currentStep;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: done || active ? maroon : maroon.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: done
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
                            : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: active ? Colors.white : maroon.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 9,
                        color: active ? maroon : maroon.withOpacity(0.4),
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (i < labels.length - 1)
                  Expanded(
                    child: Container(
                      height: 1.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: i < currentStep ? maroon : maroon.withOpacity(0.2),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Bottom Buttons ────────────────────────────────────────────────────────────
class _BottomButtons extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  static const maroon = Color(0xFF800020);

  const _BottomButtons({
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5),
        border: Border(top: BorderSide(color: maroon.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: maroon),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onBack,
                child: const Text('Back', style: TextStyle(color: maroon)),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: maroon,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: currentStep == totalSteps - 1 ? onSubmit : onNext,
              child: Text(
                currentStep == totalSteps - 1 ? 'Submit Hostel' : 'Next',
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
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────
Widget _sectionTitle(String title, Color fg) => Text(
  title,
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: fg,
  ),
);

Widget _sectionLabel(String label, Color fg) => Text(
  label,
  style: TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: fg.withOpacity(0.8),
  ),
);

Widget _inputField({
  Key? key,
  TextEditingController? controller,
  String? initialValue,
  required String label,
  required String hint,
  required IconData icon,
  int maxLines = 1,
  TextInputType keyboardType = TextInputType.text,
  List<TextInputFormatter>? inputFormatters,
  String? Function(String?)? validator,
  void Function(String)? onChanged,
}) =>
    TextFormField(
      key: key,
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(color: Color(0xFF800020), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF800020).withOpacity(0.6), size: 20),
        labelStyle: TextStyle(color: const Color(0xFF800020).withOpacity(0.7), fontSize: 13),
        hintStyle: TextStyle(color: const Color(0xFF800020).withOpacity(0.35), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF800020).withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF800020).withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF800020).withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF800020)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );