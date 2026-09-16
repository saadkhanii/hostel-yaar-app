import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/services/hostel_service.dart';

class AddHostelScreen extends StatefulWidget {
  const AddHostelScreen({super.key});

  @override
  State<AddHostelScreen> createState() => _AddHostelScreenState();
}

class _AddHostelScreenState extends State<AddHostelScreen> {
  static const maroon = Color(0xFF800020);

  final _formKey = GlobalKey<FormState>();
  final _hostelService = HostelService();
  final _cloudinaryService = CloudinaryService();
  final _imagePicker = ImagePicker();
  final Set<String> _uploadingPhotos = {}; // tracks in-flight uploads
  int _currentStep = 0;

  // ── Basic Info ─────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _totalRoomsCtrl = TextEditingController();
  String _selectedType = 'Boys';

  // ── Rooms ──────────────────────────────────────────────────
  final List<Map<String, dynamic>> _rooms = [];

  int? get _declaredTotalRooms => int.tryParse(_totalRoomsCtrl.text.trim());

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
  final List<String> _photos = [];

  // ── Submission state ───────────────────────────────────────
  bool _isSubmitting = false;

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
          _StepIndicator(currentStep: _currentStep),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: _buildCurrentStep(isDark, fg),
              ),
            ),
          ),
          _BottomButtons(
            currentStep: _currentStep,
            totalSteps: 5,
            isSubmitting: _isSubmitting,
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
  Future<void> _pickAndUploadPhoto() async {
    final source = await _pickSource();
    if (source == null) return;

    final XFile? picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80, // shrink before upload to save bandwidth
      maxWidth: 1600,
    );
    if (picked == null) return;

    final file = File(picked.path);

    // Show a placeholder entry so the grid reflects "uploading".
    final placeholder = 'uploading-${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _photos.add(placeholder);
      _uploadingPhotos.add(placeholder);
    });

    try {
      final url = await _cloudinaryService.uploadImage(file);
      if (!mounted) return;
      setState(() {
        final idx = _photos.indexOf(placeholder);
        if (idx != -1) _photos[idx] = url;
        _uploadingPhotos.remove(placeholder);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _photos.remove(placeholder);
        _uploadingPhotos.remove(placeholder);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<ImageSource?> _pickSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFFF3E6D5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: maroon),
              title: const Text('Choose from Gallery',
                  style: TextStyle(color: maroon)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading:
              const Icon(Icons.camera_alt_outlined, color: maroon),
              title: const Text('Take Photo',
                  style: TextStyle(color: maroon)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.close, color: maroon),
              title: const Text('Cancel', style: TextStyle(color: maroon)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
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
                    color: selected ? maroon : maroon.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? maroon : maroon.withValues(alpha: 0.25),
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
          style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 16),
        if (_rooms.isNotEmpty) _buildAvailabilitySummary(fg),
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
        GestureDetector(
          onTap: () => _showAddRoomSheet(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: maroon.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: maroon.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: maroon.withValues(alpha: 0.6),
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  'Add a Room',
                  style: TextStyle(
                    fontSize: 14,
                    color: maroon.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_declaredTotalRooms != null &&
            _rooms.length != _declaredTotalRooms) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _rooms.length < _declaredTotalRooms!
                  ? 'Add ${_declaredTotalRooms! - _rooms.length} more room${_declaredTotalRooms! - _rooms.length == 1 ? '' : 's'} to match the total entered in Step 1'
                  : 'You have ${_rooms.length - _declaredTotalRooms!} more room${_rooms.length - _declaredTotalRooms! == 1 ? '' : 's'} than declared in Step 1',
              style: TextStyle(
                fontSize: 12,
                color: maroon.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvailabilitySummary(Color fg) {
    final completeRooms = _rooms
        .where((r) => r['bookingType'] == 'Room')
        .toList();
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
        color: maroon.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: maroon.withValues(alpha: 0.18)),
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
            Container(
              width: 1,
              height: 34,
              color: maroon.withValues(alpha: 0.15),
            ),
          if (seatRooms.isNotEmpty)
            Expanded(
              child: _summaryStat(
                icon: Icons.event_seat_outlined,
                label: 'Seats Available',
                value: '$availableSeats / $totalSeats',
                sublabel:
                    '${seatRooms.length} room${seatRooms.length == 1 ? '' : 's'}',
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
              style: TextStyle(
                fontSize: 10,
                color: maroon.withValues(alpha: 0.6),
              ),
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
          style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 16),
        if (_rooms.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: maroon.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: maroon.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: maroon, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Add your rooms first — you'll set the rent and advance for each one here.",
                    style: TextStyle(
                      fontSize: 12,
                      color: maroon.withValues(alpha: 0.7),
                    ),
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
                color: maroon.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: maroon.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.door_front_door_outlined,
                        color: maroon,
                        size: 18,
                      ),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: maroon.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    key: ValueKey('room_price_${room['number']}_$i'),
                    initialValue: price == 0 ? '' : price.toString(),
                    label: isWholeRoom
                        ? 'Rent per Month (per room)'
                        : 'Rent per Month (per seat)',
                    hint: 'e.g. 12000',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                    onChanged: (v) => _rooms[i]['price'] = int.tryParse(v) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    key: ValueKey('room_advance_${room['number']}_$i'),
                    initialValue: advance == 0 ? '' : advance.toString(),
                    label: isWholeRoom
                        ? 'Advance Security (per room)'
                        : 'Advance Security (per seat)',
                    hint: 'e.g. 16000',
                    icon: Icons.lock_outline,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                    onChanged: (v) =>
                        _rooms[i]['advance'] = int.tryParse(v) ?? 0,
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
          style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.5)),
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
                  color: selected ? maroon : maroon.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? maroon : maroon.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[facility] ?? Icons.check_circle_outline,
                      color: selected
                          ? Colors.white
                          : maroon.withValues(alpha: 0.6),
                      size: 26,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      facility,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : maroon.withValues(alpha: 0.7),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: maroon.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: maroon.withValues(alpha: 0.2)),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: maroon.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _inAppChat,
                onChanged: (v) => setState(() => _inAppChat = v),
                activeThumbColor: maroon,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _sectionTitle('Photos', fg),
        const SizedBox(height: 6),
        Text(
          'Add as many photos as you like',
          style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            ..._photos.asMap().entries.map((entry) {
              final i = entry.key;
              final url = entry.value;
              final isUploading = _uploadingPhotos.contains(url);
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: isUploading
                        ? Container(
                      color: maroon.withValues(alpha: 0.1),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(maroon),
                        ),
                      ),
                    )
                        : Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: maroon.withValues(alpha: 0.05),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                AlwaysStoppedAnimation(maroon),
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stack) => Container(
                        color: maroon.withValues(alpha: 0.1),
                        child: Icon(Icons.broken_image_outlined,
                            color: maroon.withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _photos.removeAt(i)),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: maroon,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            }),
            GestureDetector(
              onTap: _pickAndUploadPhoto,
              child: Container(
                decoration: BoxDecoration(
                  color: maroon.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: maroon.withValues(alpha: 0.25)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: maroon.withValues(alpha: 0.6), size: 28),
                    const SizedBox(height: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                          fontSize: 11, color: maroon.withValues(alpha: 0.6)),
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
  static const List<int> _roomTypeOptions = [1, 2, 3, 4, 5, 6];

  void _showAddRoomSheet({int? existingIndex}) {
    final existing = existingIndex != null ? _rooms[existingIndex] : null;

    final roomNumCtrl = TextEditingController(text: existing?['number'] ?? '');
    String bookingType = existing?['bookingType'] ?? 'Room';
    int roomType = existing?['roomType'] ?? 1;
    bool attachedWashroom = existing?['attachedWashroom'] ?? false;
    bool roomVacant = existing?['vacant'] ?? true;
    String? errorText;

    bool sameDateForAll = existing?['availabilitySameDate'] ?? true;
    List<DateTime> availabilityDates =
        existing != null && existing['availabilityDates'] != null
        ? (existing['availabilityDates'] as List)
              .map((s) => DateTime.parse(s as String))
              .toList()
        : <DateTime>[];

    void syncAvailabilityDates(int count) {
      if (count > availabilityDates.length) {
        availabilityDates.addAll(
          List.generate(
            count - availabilityDates.length,
            (_) => DateTime.now(),
          ),
        );
      } else if (count < availabilityDates.length) {
        availabilityDates.removeRange(count, availabilityDates.length);
      }
    }

    final availableSeatsCtrl = TextEditingController(
      text: existing != null
          ? existing['availableSeats'].toString()
          : (bookingType == 'Room' ? roomType.toString() : ''),
    );

    if (bookingType == 'Seat') {
      syncAvailabilityDates(int.tryParse(availableSeatsCtrl.text) ?? 0);
    } else if (bookingType == 'Room' && roomVacant) {
      syncAvailabilityDates(1);
    }

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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: maroon,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [('Room', 'Complete Room'), ('Seat', 'Per Seat')]
                      .map((entry) {
                        final (value, label) = entry;
                        final selected = bookingType == value;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() {
                              bookingType = value;
                              if (bookingType == 'Room') {
                                availableSeatsCtrl.text = roomType.toString();
                                if (roomVacant) {
                                  syncAvailabilityDates(1);
                                } else {
                                  availabilityDates.clear();
                                }
                              } else {
                                syncAvailabilityDates(
                                  int.tryParse(availableSeatsCtrl.text) ?? 0,
                                );
                              }
                              errorText = null;
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
                      })
                      .toList(),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    bookingType == 'Room'
                        ? 'Tenant books the whole room and can adjust occupancy freely.'
                        : 'Tenant books a single seat/bed; only the seats you mark available can be booked.',
                    style: TextStyle(
                      fontSize: 11,
                      color: maroon.withValues(alpha: 0.55),
                    ),
                  ),
                ),

                // 1b. Room Status
                if (bookingType == 'Room') ...[
                  const SizedBox(height: 14),
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
                    children: [(true, 'Vacant'), (false, 'Filled')].map((
                      entry,
                    ) {
                      final (value, label) = entry;
                      final selected = roomVacant == value;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() {
                            roomVacant = value;
                            if (roomVacant) {
                              syncAvailabilityDates(1);
                            } else {
                              availabilityDates.clear();
                            }
                            errorText = null;
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      roomVacant
                          ? 'This room is free and will count toward available bookings.'
                          : "This room is currently occupied and won't be offered for booking.",
                      style: TextStyle(
                        fontSize: 11,
                        color: maroon.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  if (roomVacant) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Available From',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: maroon,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'When will this room be free for a new tenant to move in?',
                      style: TextStyle(
                        fontSize: 11,
                        color: maroon.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _datePickerField(
                      context: context,
                      label: 'Available From',
                      date: availabilityDates.isNotEmpty
                          ? availabilityDates.first
                          : DateTime.now(),
                      onPick: (picked) => setSheetState(() {
                        if (availabilityDates.isEmpty) {
                          availabilityDates.add(picked);
                        } else {
                          availabilityDates[0] = picked;
                        }
                      }),
                    ),
                  ],
                ],
                const SizedBox(height: 16),

                // 2. Room Number
                _inputField(
                  controller: roomNumCtrl,
                  label: 'Room Number / Name',
                  hint: 'e.g. 101 or Ground Floor Room',
                  icon: Icons.door_front_door_outlined,
                ),
                const SizedBox(height: 14),

                // 3. Room Type
                const Text(
                  'Room Type',
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
                          if (bookingType == 'Seat') {
                            syncAvailabilityDates(
                              int.tryParse(availableSeatsCtrl.text) ?? 0,
                            );
                          }
                          errorText = null;
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

                // 4. Available Seats (Per Seat only)
                if (bookingType == 'Seat') ...[
                  const SizedBox(height: 14),
                  _inputField(
                    controller: availableSeatsCtrl,
                    label: 'Available Seats (0 – $roomType)',
                    hint: '0 if fully occupied, up to $roomType',
                    icon: Icons.people_outline,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) => setSheetState(() {
                      errorText = null;
                      final n = (int.tryParse(v) ?? 0).clamp(0, roomType);
                      syncAvailabilityDates(n);
                    }),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null) return 'Required';
                      if (n < 0) return 'Cannot be negative';
                      if (n > roomType) return 'Cannot exceed $roomType';
                      return null;
                    },
                  ),
                  if ((int.tryParse(availableSeatsCtrl.text) ?? 0) > 0) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Availability Date(s)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: maroon,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'When will these seats be free for a new tenant to move in?',
                      style: TextStyle(
                        fontSize: 11,
                        color: maroon.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (availabilityDates.length > 1) ...[
                      Row(
                        children:
                            [
                              (true, 'Same date for all'),
                              (false, 'Set individually'),
                            ].map((entry) {
                              final (value, label) = entry;
                              final selected = sameDateForAll == value;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setSheetState(
                                    () => sameDateForAll = value,
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
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
                      const SizedBox(height: 10),
                    ],
                    if (sameDateForAll || availabilityDates.length <= 1)
                      _datePickerField(
                        context: context,
                        label: 'Available From',
                        date: availabilityDates.first,
                        onPick: (picked) => setSheetState(() {
                          for (var i = 0; i < availabilityDates.length; i++) {
                            availabilityDates[i] = picked;
                          }
                        }),
                      )
                    else
                      ...List.generate(availabilityDates.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _datePickerField(
                            context: context,
                            label: 'Seat ${i + 1} — Available From',
                            date: availabilityDates[i],
                            onPick: (picked) => setSheetState(
                              () => availabilityDates[i] = picked,
                            ),
                          ),
                        );
                      }),
                  ],
                ],
                const SizedBox(height: 14),

                // 5. Attached Washroom
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
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
                      final seatsText = availableSeatsCtrl.text.trim();
                      final parsedSeats = int.tryParse(seatsText);
                      final available = bookingType == 'Room'
                          ? roomType
                          : (parsedSeats ?? -1);

                      final roomNum = roomNumCtrl.text.trim();
                      if (roomNum.isEmpty) {
                        setSheetState(
                          () => errorText = 'Room number/name is required',
                        );
                        return;
                      }
                      final isDuplicate = _rooms.asMap().entries.any(
                        (entry) =>
                            entry.key != existingIndex &&
                            (entry.value['number'] as String).toLowerCase() ==
                                roomNum.toLowerCase(),
                      );
                      if (isDuplicate) {
                        setSheetState(
                          () => errorText = 'Room "$roomNum" already exists',
                        );
                        return;
                      }
                      if (bookingType == 'Seat' &&
                          (seatsText.isEmpty ||
                              available < 0 ||
                              available > roomType)) {
                        setSheetState(
                          () => errorText =
                              'Available seats must be between 0 and $roomType',
                        );
                        return;
                      }

                      final room = {
                        'number': roomNum,
                        'bookingType': bookingType,
                        'roomType': roomType,
                        'availableSeats': available,
                        'attachedWashroom': attachedWashroom,
                        'vacant': bookingType == 'Room'
                            ? roomVacant
                            : (available > 0),
                        'price': existing?['price'] ?? 0,
                        'advance': existing?['advance'] ?? 0,
                        'availabilityDates':
                            (bookingType == 'Seat' && available > 0) ||
                                (bookingType == 'Room' && roomVacant)
                            ? availabilityDates
                                  .map((d) => d.toIso8601String())
                                  .toList()
                            : <String>[],
                        'availabilitySameDate': sameDateForAll,
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
      if (declared != null && _rooms.length != declared) {
        final remaining = declared - _rooms.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              remaining > 0
                  ? 'Add $remaining more room${remaining == 1 ? '' : 's'} to match the total ($declared) entered in Step 1'
                  : "You've added ${_rooms.length} rooms but Step 1 says $declared — remove ${-remaining} or update the total",
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one room before submitting'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final selectedFacilities = _facilities.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final roomPayloads = _rooms.map((r) {
        return {
          'number': r['number'],
          'bookingType': r['bookingType'],
          'roomType': r['roomType'],
          'availableSeats': r['availableSeats'],
          'attachedWashroom': r['attachedWashroom'],
          'price': r['price'],
          'advance': r['advance'],
          'vacant': r['vacant'],
          'availabilityDates': r['availabilityDates'] ?? <String>[],
        };
      }).toList();

      final created = await _hostelService.createHostel(
        name: _nameCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        type: _selectedType,
        facilities: selectedFacilities,
        photos: _photos,
        phone: _phoneCtrl.text.trim(),
        whatsapp: _whatsappCtrl.text.trim().isEmpty
            ? null
            : _whatsappCtrl.text.trim(),
        inAppChat: _inAppChat,
        active: true,
        rooms: roomPayloads,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hostel "${created['name']}" listed successfully!'),
        ),
      );

      Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        color: maroon.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: maroon.withValues(alpha: 0.2)),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: room['vacant'] == true
                              ? Colors.green.withValues(alpha: 0.15)
                              : maroon.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          room['vacant'] == true ? 'Vacant' : 'Filled',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: room['vacant'] == true
                                ? Colors.green[800]
                                : maroon,
                          ),
                        ),
                      ),
                    ],
                    if (room['bookingType'] == 'Seat' &&
                        room['availableSeats'] == 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: maroon.withValues(alpha: 0.12),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: maroon.withValues(alpha: 0.6),
                  ),
                ),
                if (((room['bookingType'] == 'Seat' &&
                            (room['availableSeats'] as int) > 0) ||
                        (room['bookingType'] == 'Room' &&
                            room['vacant'] == true)) &&
                    (room['availabilityDates'] as List?)?.isNotEmpty ==
                        true) ...[
                  const SizedBox(height: 2),
                  Text(
                    _availabilitySummary(room),
                    style: TextStyle(
                      fontSize: 11,
                      color: maroon.withValues(alpha: 0.55),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: maroon.withValues(alpha: 0.6),
              size: 18,
            ),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: maroon.withValues(alpha: 0.6),
              size: 18,
            ),
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
  final List<String> labels = const [
    'Info',
    'Rooms',
    'Pricing',
    'Facilities',
    'Contact',
  ];

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
                        color: done || active
                            ? maroon
                            : maroon.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: done
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              )
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: active
                                      ? Colors.white
                                      : maroon.withValues(alpha: 0.5),
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
                        color: active ? maroon : maroon.withValues(alpha: 0.4),
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (i < labels.length - 1)
                  Expanded(
                    child: Container(
                      height: 1.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: i < currentStep
                          ? maroon
                          : maroon.withValues(alpha: 0.2),
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
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  static const maroon = Color(0xFF800020);

  const _BottomButtons({
    required this.currentStep,
    required this.totalSteps,
    required this.isSubmitting,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = currentStep == totalSteps - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5),
        border: Border(top: BorderSide(color: maroon.withValues(alpha: 0.1))),
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
                onPressed: isSubmitting ? null : onBack,
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
              onPressed: isSubmitting ? null : (isLast ? onSubmit : onNext),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Color(0xFFF3E6D5)),
                      ),
                    )
                  : Text(
                      isLast ? 'Submit Hostel' : 'Next',
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
String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

String _availabilitySummary(Map<String, dynamic> room) {
  final raw = (room['availabilityDates'] as List?) ?? const [];
  if (raw.isEmpty) return '';
  final dates = raw.map((s) => DateTime.parse(s as String)).toList();
  final sameDateForAll = room['availabilitySameDate'] == true;
  final allSame =
      dates.map((d) => '${d.year}-${d.month}-${d.day}').toSet().length == 1;
  if (sameDateForAll || allSame) {
    return 'Available from ${_formatDate(dates.first)}';
  }
  return 'Seats available on individual dates';
}

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
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: maroon),
            ),
          ),
          Text(
            _formatDate(date),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: maroon,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _sectionTitle(String title, Color fg) => Text(
  title,
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: fg),
);

Widget _sectionLabel(String label, Color fg) => Text(
  label,
  style: TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: fg.withValues(alpha: 0.8),
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
}) => TextFormField(
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
    prefixIcon: Icon(
      icon,
      color: const Color(0xFF800020).withValues(alpha: 0.6),
      size: 20,
    ),
    labelStyle: TextStyle(
      color: const Color(0xFF800020).withValues(alpha: 0.7),
      fontSize: 13,
    ),
    hintStyle: TextStyle(
      color: const Color(0xFF800020).withValues(alpha: 0.35),
      fontSize: 13,
    ),
    filled: true,
    fillColor: const Color(0xFF800020).withValues(alpha: 0.06),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: const Color(0xFF800020).withValues(alpha: 0.2),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: const Color(0xFF800020).withValues(alpha: 0.2),
      ),
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
