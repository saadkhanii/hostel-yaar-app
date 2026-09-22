import 'package:flutter/material.dart';

import '../../core/services/booking_service.dart';
import '../../core/services/hostel_service.dart';

// ── Hostel Detail Screen ───────────────────────────────────────────────
// Shown when a seeker taps a hostel card on the list. Receives a hostel
// map via router arguments (already in Flutter camelCase shape from
// HostelService). On open, re-fetches by id so the seeker always sees
// fresh data — the passed-in map might be stale.
//
// Expected shape of the `hostel` map (matches HostelService output):
// {
//   'id', 'wardenId', 'name', 'city', 'address', 'type',
//   'latitude', 'longitude',
//   'facilities': List<String>,
//   'photos': List<String>,
//   'phone', 'whatsapp', 'inAppChat', 'active',
//   'startingPrice', 'hasVacancy', 'roomCount',
//   'createdAt', 'updatedAt',
//   'rooms': List<Map<String, dynamic>>  // camelCase, from _roomFromBackend
// }
class HostelDetailScreen extends StatefulWidget {
  final Map<String, dynamic> hostel;

  const HostelDetailScreen({super.key, required this.hostel});

  /// Fallback shape used when a caller navigates without arguments.
  static Map<String, dynamic> get sampleHostel => const {
    'id': '',
    'wardenId': '',
    'name': 'Hostel',
    'city': '',
    'address': '',
    'type': 'Boys',
    'latitude': null,
    'longitude': null,
    'facilities': <String>[],
    'photos': <String>[],
    'phone': '',
    'whatsapp': '',
    'inAppChat': false,
    'active': true,
    'startingPrice': 0,
    'hasVacancy': false,
    'roomCount': 0,
    'rooms': <Map<String, dynamic>>[],
  };

  @override
  State<HostelDetailScreen> createState() => _HostelDetailScreenState();
}

class _HostelDetailScreenState extends State<HostelDetailScreen> {
  static const maroon = Color(0xFF800020);
  static const maroonDark = Color(0xFF5C0017);

  final _hostelService = HostelService();
  final PageController _photoController = PageController();
  int _currentPhoto = 0;

  late Map<String, dynamic> _hostel;
  bool _isRefreshing = false;
  final Set<String> _requestedRooms = {};

  static const Map<String, IconData> _facilityIcons = {
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

  @override
  void initState() {
    super.initState();
    _hostel = widget.hostel;
    _refreshFromBackend();
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  bool _isSaved = false;
  bool _isTogglingSave = false;

  Future<void> _refreshFromBackend() async {
    final id = _hostel['id'] as String?;
    if (id == null || id.isEmpty) return;

    setState(() => _isRefreshing = true);

    try {
      final results = await Future.wait([
        _hostelService.getHostel(id),
        _isSavedOnServer(id),
        _pendingRoomNumbersFor(id),
      ]);

      if (!mounted) return;
      setState(() {
        _hostel = results[0] as Map<String, dynamic>;
        _isSaved = results[1] as bool;
        _requestedRooms
          ..clear()
          ..addAll(results[2] as Set<String>);
        _isRefreshing = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  /// Room numbers the current seeker already has a pending request for,
  /// in this specific hostel.
  Future<Set<String>> _pendingRoomNumbersFor(String hostelId) async {
    try {
      final requests = await BookingService().listMyRequests();
      return requests
          .where((r) =>
      r['hostelId'] == hostelId && r['status'] == 'pending')
          .map((r) => (r['roomNumber'] as String?) ?? '')
          .where((s) => s.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  /// Whether the current seeker has already saved this hostel.
  Future<bool> _isSavedOnServer(String hostelId) async {
    try {
      final saved = await _hostelService.listSavedHostels();
      return saved.any((s) => (s['hostel'] as Map)['id'] == hostelId);
    } catch (_) {
      return false;
    }
  }

  /// Toggle save state. Optimistic — flips locally, reverts on failure.
  Future<void> _toggleSave() async {
    final id = _hostel['id'] as String?;
    if (id == null || id.isEmpty || _isTogglingSave) return;

    final previous = _isSaved;
    setState(() {
      _isSaved = !_isSaved;
      _isTogglingSave = true;
    });

    try {
      if (_isSaved) {
        await _hostelService.saveHostel(id);
      } else {
        await _hostelService.unsaveHostel(id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaved = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update saved list: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isTogglingSave = false);
    }
  }

  List<Map<String, dynamic>> get _rooms =>
      ((_hostel['rooms'] as List?) ?? const []).cast<Map<String, dynamic>>();

  bool _isRoomAvailable(Map<String, dynamic> room) {
    return room['bookingType'] == 'Room'
        ? room['vacant'] == true
        : ((room['availableSeats'] as int?) ?? 0) > 0;
  }

  int get _availableRoomCount => _rooms.where(_isRoomAvailable).length;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  Future<void> _requestBooking(Map<String, dynamic> room) async {
    DateTime? moveInDate;
    final messageCtrl = TextEditingController();
    bool isSubmitting = false;
    String? errorText;
    final isSeatRequest = room['bookingType'] == 'Seat';
    final availableSeats = (room['availableSeats'] as int?) ?? 0;
    final dialogTitle = isSeatRequest ? 'Request a Seat' : 'Request to Book';
    final dialogBody = isSeatRequest
        ? 'Send a request to book a seat in Room ${room['number']} at ${_hostel['name']}? There are $availableSeats seat${availableSeats == 1 ? '' : 's'} available. The warden will assign you one.'
        : 'Send a booking request for the whole of Room ${room['number']} at ${_hostel['name']}? The warden will confirm availability before you pay any advance.';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final dialogIsDark = Theme.of(context).brightness == Brightness.dark;
          final dialogCardColor =
          dialogIsDark ? const Color(0xFF262B33) : Colors.white;
          return AlertDialog(
            backgroundColor: dialogIsDark
                ? const Color(0xFF1D2128)
                : const Color(0xFFF3E6D5),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              dialogTitle,
              style: const TextStyle(
                color: maroon,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dialogBody,
                    style: TextStyle(color: maroon.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'When do you want to move in?',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: maroon),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: moveInDate ??
                            DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => moveInDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: dialogCardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                                alpha: dialogIsDark ? 0.2 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              color: maroon, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              moveInDate == null
                                  ? 'Select a date'
                                  : _formatDate(moveInDate!),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: maroon,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Message (optional)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: maroon),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: messageCtrl,
                    maxLines: 3,
                    maxLength: 500,
                    style: const TextStyle(fontSize: 13, color: maroon),
                    decoration: InputDecoration(
                      hintText: 'e.g. I\'m a student looking to move in soon.',
                      hintStyle: TextStyle(
                          fontSize: 12,
                          color: maroon.withValues(alpha: 0.4)),
                      counterStyle: TextStyle(
                          fontSize: 10, color: maroon.withValues(alpha: 0.4)),
                      filled: true,
                      fillColor: dialogCardColor,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: maroon, width: 1.5),
                      ),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      errorText!,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: Text('Cancel',
                    style: TextStyle(color: maroon.withValues(alpha: 0.6))),
              ),
              TextButton(
                onPressed: moveInDate == null || isSubmitting
                    ? null
                    : () async {
                  setDialogState(() {
                    isSubmitting = true;
                    errorText = null;
                  });
                  // Capture these BEFORE the await so we don't
                  // touch context across an async gap.
                  final messenger = ScaffoldMessenger.of(this.context);
                  final navigator = Navigator.of(dialogContext);

                  try {
                    await BookingService().createRequest(
                      hostelId: _hostel['id'] as String,
                      roomId: room['id'] as String,
                      moveInDate: moveInDate!,
                      message: messageCtrl.text,
                    );

                    if (!mounted) return;
                    navigator.pop();

                    setState(() =>
                        _requestedRooms.add(room['number'] as String));

                    // Refresh the hostel so any server-side change (e.g.
                    // seat counts updated by the warden) is reflected.
                    _refreshFromBackend();

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          isSeatRequest
                              ? 'Seat request sent for Room ${room['number']}! '
                              'The warden will assign you a seat.'
                              : 'Request sent for Room ${room['number']}! '
                              'The warden will respond soon.',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    setDialogState(() {
                      isSubmitting = false;
                      errorText =
                          e.toString().replaceFirst('Exception: ', '');
                    });
                  }
                },
                style: TextButton.styleFrom(foregroundColor: maroon),
                child: isSubmitting
                    ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(maroon),
                  ),
                )
                    : const Text('Send Request',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _contactAction(String label) {
    // TODO: wire to url_launcher (tel:/https://wa.me/) once we add it.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : const Color(0xFF800020);
    final cardColor = isDark ? const Color(0xFF262B33) : Colors.white;
    final hostel = _hostel;
    final photos = (hostel['photos'] as List?)?.cast<String>() ?? const [];
    final facilities =
        (hostel['facilities'] as List?)?.cast<String>() ?? const [];

    // No AppBar here on purpose — the photo carousel bleeds to the very
    // top of the screen (behind the status bar) and carries its own
    // back / save buttons as an overlay so they stay legible over
    // whatever photo is showing.
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoCarousel(photos),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(fg, hostel),
                        const SizedBox(height: 18),
                        _buildQuickStats(isDark, cardColor),
                        const SizedBox(height: 24),
                        _sectionTitle('Facilities', fg),
                        const SizedBox(height: 12),
                        _buildFacilities(facilities),
                        const SizedBox(height: 24),
                        _sectionTitle('Rooms & Availability', fg),
                        const SizedBox(height: 6),
                        Text(
                          'Rent and advance shown are per room, or per seat for shared listings.',
                          style: TextStyle(
                              fontSize: 12,
                              color: fg.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 12),
                        if (_rooms.isEmpty)
                          Text(
                            'No rooms listed yet.',
                            style: TextStyle(
                                fontSize: 12,
                                color: fg.withValues(alpha: 0.5)),
                          )
                        else
                          ..._rooms.map(
                                (room) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _DetailRoomCard(
                                room: room,
                                available: _isRoomAvailable(room),
                                requested:
                                _requestedRooms.contains(room['number']),
                                isDark: isDark,
                                cardColor: cardColor,
                                onRequest: () => _requestBooking(room),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        _sectionTitle('Location', fg),
                        const SizedBox(height: 10),
                        _buildAddress(fg, hostel, isDark, cardColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildContactBar(hostel),
        ],
      ),
    );
  }

  Widget _buildPhotoCarousel(List<String> photos) {
    // Extra height plus the status-bar inset so the image reaches the
    // very top edge of the screen instead of stopping below an app bar.
    final topInset = MediaQuery.of(context).padding.top;
    final carouselHeight = 260 + topInset;

    return SizedBox(
      height: carouselHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photos.isEmpty)
            Container(
              color: maroon.withValues(alpha: 0.1),
              child: Icon(Icons.home_work_outlined,
                  size: 56, color: maroon.withValues(alpha: 0.35)),
            )
          else
            PageView.builder(
              controller: _photoController,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _currentPhoto = i),
              itemBuilder: (context, i) => Image.network(
                photos[i],
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  color: maroon.withValues(alpha: 0.1),
                  child: Icon(Icons.broken_image_outlined,
                      color: maroon.withValues(alpha: 0.35)),
                ),
              ),
            ),
          if (photos.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(photos.length, (i) {
                  final active = i == _currentPhoto;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color:
                      active ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          if (_isRefreshing)
            Positioned(
              top: topInset,
              left: 0,
              right: 0,
              child: const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(maroon),
              ),
            ),
          // Back / save buttons float on the image itself so they're
          // reachable regardless of scroll position, with a translucent
          // dark backdrop that keeps them visible over any photo.
          Positioned(
            top: topInset + 8,
            left: 16,
            child: _photoOverlayButton(
              icon: Icons.arrow_back_ios_new,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: topInset + 8,
            right: 16,
            child: _photoOverlayButton(
              icon: _isSaved ? Icons.favorite : Icons.favorite_border,
              onTap: _isTogglingSave ? null : _toggleSave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoOverlayButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildHeader(Color fg, Map<String, dynamic> hostel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                hostel['name'] as String? ?? '',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: fg),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: maroon.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hostel['type'] as String? ?? '',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: maroon.withValues(alpha: 0.8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: 14, color: fg.withValues(alpha: 0.55)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                hostel['city'] as String? ?? '',
                style:
                TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.55)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(bool isDark, Color cardColor) {
    final starting = _hostel['startingPrice'] as int? ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _quickStat(
              icon: Icons.payments_outlined,
              value: starting > 0 ? 'Rs. $starting' : '—',
              label: 'Starting from',
            ),
          ),
          Container(width: 1, height: 34, color: maroon.withValues(alpha: 0.15)),
          Expanded(
            child: _quickStat(
              icon: Icons.event_available_outlined,
              value: '$_availableRoomCount / ${_rooms.length}',
              label: 'Listings open',
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: maroon, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: maroon)),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: maroon.withValues(alpha: 0.6))),
          ],
        ),
      ],
    );
  }

  Widget _buildFacilities(List<String> facilities) {
    if (facilities.isEmpty) {
      return Text(
        'No facilities listed yet.',
        style: TextStyle(fontSize: 12, color: maroon.withValues(alpha: 0.5)),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: facilities.map((f) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: maroon.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: maroon.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_facilityIcons[f] ?? Icons.check_circle_outline,
                  size: 15, color: maroon),
              const SizedBox(width: 6),
              Text(f,
                  style: const TextStyle(
                      fontSize: 12,
                      color: maroon,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddress(
      Color fg, Map<String, dynamic> hostel, bool isDark, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hostel['address'] as String? ?? '',
            style:
            TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _contactAction('Map'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: maroon),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.map_outlined, size: 16, color: maroon),
              label: const Text('View on Map',
                  style: TextStyle(color: maroon, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactBar(Map<String, dynamic> hostel) {
    final hasWhatsapp = ((hostel['whatsapp'] as String?) ?? '').isNotEmpty;
    final hasChat = hostel['inAppChat'] == true;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [maroon, maroonDark],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: maroon.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      // top: false — the bar's own gradient already paints behind the
      // home indicator; SafeArea here only pushes the buttons up so
      // they aren't obscured by it.
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              _contactIconButton(
                  Icons.call_outlined, 'Call', () => _contactAction('Call')),
              if (hasWhatsapp) ...[
                const SizedBox(width: 10),
                _contactIconButton(Icons.chat_outlined, 'WhatsApp',
                        () => _contactAction('WhatsApp')),
              ],
              if (hasChat) ...[
                const SizedBox(width: 10),
                _contactIconButton(Icons.forum_outlined, 'Chat',
                        () => _contactAction('In-app chat')),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactIconButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(icon, size: 16, color: Colors.white),
        label:
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  }
}

Widget _sectionTitle(String title, Color fg) => Text(
  title,
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg),
);

// ── Room Card (seeker-facing, read-only + request action) ──────────────
class _DetailRoomCard extends StatelessWidget {
  final Map<String, dynamic> room;
  final bool available;
  final bool requested;
  final bool isDark;
  final Color cardColor;
  final VoidCallback onRequest;

  const _DetailRoomCard({
    required this.room,
    required this.available,
    required this.requested,
    required this.isDark,
    required this.cardColor,
    required this.onRequest,
  });

  static const maroon = Color(0xFF800020);

  @override
  Widget build(BuildContext context) {
    final isSeatRoom = room['bookingType'] == 'Seat';
    final price = (room['price'] as int?) ?? 0;
    final advance = (room['advance'] as int?) ?? 0;
    final seats = (room['availableSeats'] as int?) ?? 0;
    final type = (room['roomType'] as int?) ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.door_front_door_outlined,
                  color: maroon, size: 18),
              const SizedBox(width: 8),
              Text(
                'Room ${room['number']}',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: maroon),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: available
                      ? Colors.green.withValues(alpha: 0.15)
                      : maroon.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  available
                      ? (isSeatRoom ? '$seats seats open' : 'Vacant')
                      : (isSeatRoom ? 'Full' : 'Filled'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: available ? Colors.green[800] : maroon,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$type Seater • '
                '${isSeatRoom ? 'Per Seat' : 'Complete Room'} • '
                '${room['attachedWashroom'] == true ? 'Attached WR' : 'Shared WR'}',
            style: TextStyle(
                fontSize: 12, color: maroon.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rs. $price/mo',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: maroon),
                    ),
                    Text(
                      'Advance: Rs. $advance',
                      style: TextStyle(
                          fontSize: 11, color: maroon.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: (available && !requested) ? onRequest : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  requested ? Colors.green.withValues(alpha: 0.15) : maroon,
                  disabledBackgroundColor: requested
                      ? Colors.green.withValues(alpha: 0.15)
                      : maroon.withValues(alpha: 0.25),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (requested) ...[
                      Icon(Icons.check_circle,
                          size: 14, color: Colors.green[800]),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      requested
                          ? 'Requested'
                          : (available
                          ? (isSeatRoom ? 'Request a Seat' : 'Request to Book')
                          : 'Unavailable'),
                      style: TextStyle(
                        color: requested ? Colors.green[800] : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}