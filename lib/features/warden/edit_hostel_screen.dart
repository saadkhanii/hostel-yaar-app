import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/cloudinary_service.dart';

// Edits a hostel's own details — name, type, location, facilities, contact,
// and photos. Deliberately does NOT touch rooms/pricing; those are managed
// from HostelRoomsScreen instead, reached via "Manage Rooms" on the card.
//
// Pass in the existing hostel map from ManageHostelsScreen; on save, this
// screen pops with a new map the caller should merge back in (it carries
// over anything it doesn't edit, like 'active' and 'rooms', untouched).
class EditHostelScreen extends StatefulWidget {
  final Map<String, dynamic> hostel;

  const EditHostelScreen({super.key, required this.hostel});

  @override
  State<EditHostelScreen> createState() => _EditHostelScreenState();
}

class _EditHostelScreenState extends State<EditHostelScreen> {
  static const maroon = Color(0xFF800020);

  final _formKey = GlobalKey<FormState>();
  final _cloudinaryService = CloudinaryService();
  final _imagePicker = ImagePicker();
  final Set<String> _uploadingPhotos = {};

  late final _nameCtrl = TextEditingController(
    text: widget.hostel['name'] as String? ?? '',
  );
  late final _cityCtrl = TextEditingController(
    text: widget.hostel['city'] as String? ?? '',
  );
  late final _addressCtrl = TextEditingController(
    text: widget.hostel['address'] as String? ?? '',
  );
  late String _selectedType = widget.hostel['type'] as String? ?? 'Boys';

  late final _phoneCtrl = TextEditingController(
    text: widget.hostel['phone'] as String? ?? '',
  );
  late final _whatsappCtrl = TextEditingController(
    text: widget.hostel['whatsapp'] as String? ?? '',
  );
  late bool _inAppChat = widget.hostel['inAppChat'] as bool? ?? true;

  static const _facilityIcons = {
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

  // Pre-fill from the hostel's existing facilities where present.
  late final Map<String, bool> _facilities = {
    for (final f in _facilityIcons.keys)
      f: ((widget.hostel['facilities'] as List?) ?? const []).contains(f),
  };

  late final List<String> _photos = List<String>.from(
    widget.hostel['photos'] as List? ?? const [],
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  // ── Photo picking & upload ─────────────────────────────────────────

  Future<void> _pickAndUploadPhoto() async {
    final source = await _pickSource();
    if (source == null) return;

    final XFile? picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return;

    final file = File(picked.path);
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
              leading: const Icon(Icons.camera_alt_outlined, color: maroon),
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

  // ── Save ───────────────────────────────────────────────────────────

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final selectedFacilities = _facilities.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final updated = Map<String, dynamic>.from(widget.hostel)
      ..['name'] = _nameCtrl.text.trim()
      ..['type'] = _selectedType
      ..['city'] = _cityCtrl.text.trim()
      ..['address'] = _addressCtrl.text.trim()
      ..['facilities'] = selectedFacilities
      ..['phone'] = _phoneCtrl.text.trim()
      ..['whatsapp'] = _whatsappCtrl.text.trim()
      ..['inAppChat'] = _inAppChat
      ..['photos'] = _photos;

    Navigator.pop(context, updated);
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
          'Edit Hostel',
          style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
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
                          color:
                          selected ? maroon : maroon.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? maroon
                                : maroon.withValues(alpha: 0.25),
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

              const SizedBox(height: 28),
              _sectionTitle('Facilities', fg),
              const SizedBox(height: 6),
              Text(
                'Select all that apply',
                style:
                TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.5)),
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
                    onTap: () =>
                        setState(() => _facilities[facility] = !selected),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                        selected ? maroon : maroon.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? maroon
                              : maroon.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _facilityIcons[facility] ??
                                Icons.check_circle_outline,
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

              const SizedBox(height: 28),
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
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                color: maroon.withValues(alpha: 0.6)),
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
                style:
                TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.5)),
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
                                valueColor:
                                AlwaysStoppedAnimation(maroon),
                              ),
                            ),
                          )
                              : Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder:
                                (context, child, progress) {
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
                                      AlwaysStoppedAnimation(
                                          maroon),
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder:
                                (context, error, stack) => Container(
                              color: maroon.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: maroon.withValues(alpha: 0.4),
                              ),
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
                        border:
                        Border.all(color: maroon.withValues(alpha: 0.25)),
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
                                fontSize: 11,
                                color: maroon.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroon,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _handleSave,
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared small widgets ─────────────────────────────────────────────
Widget _sectionTitle(String title, Color fg) => Text(
  title,
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: fg),
);

Widget _sectionLabel(String label, Color fg) => Text(
  label,
  style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: fg.withValues(alpha: 0.8)),
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
        prefixIcon: Icon(icon,
            color: const Color(0xFF800020).withValues(alpha: 0.6), size: 20),
        labelStyle: TextStyle(
            color: const Color(0xFF800020).withValues(alpha: 0.7),
            fontSize: 13),
        hintStyle: TextStyle(
            color: const Color(0xFF800020).withValues(alpha: 0.35),
            fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF800020).withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: const Color(0xFF800020).withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: const Color(0xFF800020).withValues(alpha: 0.2)),
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