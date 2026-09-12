import 'package:flutter/material.dart';

// ── Warden Booking Requests Inbox ──────────────────────────────────────────
// Reached from the Warden Dashboard's "Requests" stat card. Shows booking
// requests seekers send from HostelDetailScreen's "Send Request" action.
//
// Dummy data below is self-contained for now — swap `_requests` for a real
// Firestore-backed stream once HostelDetailScreen actually writes booking
// requests (see the TODO in hostel_detail.dart's `_requestBooking`) instead
// of only showing a snackbar.
class WardenRequestsScreen extends StatefulWidget {
  const WardenRequestsScreen({super.key});

  @override
  State<WardenRequestsScreen> createState() => _WardenRequestsScreenState();
}

enum _RequestFilter { all, pending, accepted, rejected }

class _WardenRequestsScreenState extends State<WardenRequestsScreen> {
  static const maroon = Color(0xFF800020);

  _RequestFilter _filter = _RequestFilter.all;

  // ── Dummy data ─────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _requests = [
    {
      'seekerName': 'Ali Hassan',
      'seekerPhone': '+92 300 1112233',
      'hostelName': 'Green View Hostel',
      'roomNumber': '101',
      'bookingType': 'Room',
      'roomType': 2,
      'price': 16000,
      'requestedAt': DateTime.now().subtract(const Duration(hours: 2)),
      'moveInDate': DateTime.now().add(const Duration(days: 5)),
      'status': 'Pending',
    },
    {
      'seekerName': 'Bilal Ahmed',
      'seekerPhone': '+92 300 4445566',
      'hostelName': 'Green View Hostel',
      'roomNumber': '201',
      'bookingType': 'Seat',
      'roomType': 4,
      'price': 8000,
      'requestedAt': DateTime.now().subtract(const Duration(hours: 5)),
      'moveInDate': DateTime.now().add(const Duration(days: 2)),
      'status': 'Pending',
    },
    {
      'seekerName': 'Hamza Khan',
      'seekerPhone': '+92 300 7778899',
      'hostelName': 'Sunrise Boys Hostel',
      'roomNumber': '1',
      'bookingType': 'Seat',
      'roomType': 3,
      'price': 7500,
      'requestedAt': DateTime.now().subtract(const Duration(days: 1)),
      'moveInDate': DateTime.now().add(const Duration(days: 10)),
      'status': 'Accepted',
    },
    {
      'seekerName': 'Usman Tariq',
      'seekerPhone': '+92 300 9990011',
      'hostelName': 'Sunrise Boys Hostel',
      'roomNumber': '1',
      'bookingType': 'Seat',
      'roomType': 3,
      'price': 7500,
      'requestedAt': DateTime.now().subtract(const Duration(days: 2)),
      'moveInDate': DateTime.now().add(const Duration(days: 3)),
      'status': 'Rejected',
    },
    {
      'seekerName': 'Ahmad Raza',
      'seekerPhone': '+92 300 2223311',
      'hostelName': 'Al-Noor Girls Hostel',
      'roomNumber': '5',
      'bookingType': 'Room',
      'roomType': 1,
      'price': 9000,
      'requestedAt': DateTime.now().subtract(const Duration(minutes: 40)),
      'moveInDate': DateTime.now().add(const Duration(days: 1)),
      'status': 'Pending',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    final list = switch (_filter) {
      _RequestFilter.all => _requests,
      _RequestFilter.pending => _requests.where((r) => r['status'] == 'Pending').toList(),
      _RequestFilter.accepted => _requests.where((r) => r['status'] == 'Accepted').toList(),
      _RequestFilter.rejected => _requests.where((r) => r['status'] == 'Rejected').toList(),
    };
    // Newest first.
    list.sort((a, b) => (b['requestedAt'] as DateTime).compareTo(a['requestedAt'] as DateTime));
    return list;
  }

  int get _pendingCount => _requests.where((r) => r['status'] == 'Pending').length;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // Formats the seeker's requested move-in date, e.g. "15 Sep 2026".
  String _formatMoveInDate(DateTime dt) => '${dt.day} ${_months[dt.month - 1]} ${dt.year}';

  void _accept(Map<String, dynamic> request) {
    setState(() => request['status'] = 'Accepted');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Accepted ${request['seekerName']}\'s request')),
    );
  }

  void _reject(Map<String, dynamic> request) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Request', style: TextStyle(color: maroon, fontWeight: FontWeight.bold)),
        content: Text(
          'Reject ${request['seekerName']}\'s request for Room ${request['roomNumber']}?',
          style: TextStyle(color: maroon.withValues(alpha: 0.75)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: maroon.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () {
              setState(() => request['status'] = 'Rejected');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Rejected ${request['seekerName']}\'s request')),
              );
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : const Color(0xFF800020);
    final results = _filtered;

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
          'Booking Requests',
          style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Filter chips ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ('All', _RequestFilter.all, _requests.length),
                    ('Pending', _RequestFilter.pending, _pendingCount),
                    ('Accepted', _RequestFilter.accepted, _requests.where((r) => r['status'] == 'Accepted').length),
                    ('Rejected', _RequestFilter.rejected, _requests.where((r) => r['status'] == 'Rejected').length),
                  ].map((entry) {
                    final (label, value, count) = entry;
                    final selected = _filter == value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? maroon : maroon.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selected ? maroon : maroon.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            '$label ($count)',
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
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: results.isEmpty
                  ? _buildEmptyState(fg)
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: results.length,
                itemBuilder: (context, i) {
                  final request = results[i];
                  return _RequestCard(
                    request: request,
                    timeAgo: _timeAgo(request['requestedAt'] as DateTime),
                    moveInDate: (request['moveInDate'] as DateTime?) != null
                        ? _formatMoveInDate(request['moveInDate'] as DateTime)
                        : null,
                    onAccept: () => _accept(request),
                    onReject: () => _reject(request),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color fg) {
    final label = switch (_filter) {
      _RequestFilter.all => 'No booking requests yet',
      _RequestFilter.pending => 'No pending requests',
      _RequestFilter.accepted => 'No accepted requests',
      _RequestFilter.rejected => 'No rejected requests',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 52, color: fg.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fg.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Request Card ────────────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final String timeAgo;
  final String? moveInDate;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.timeAgo,
    required this.moveInDate,
    required this.onAccept,
    required this.onReject,
  });

  static const maroon = Color(0xFF800020);
  static const activeGreen = Color(0xFF2E7D32);

  Color _statusColor(String status) {
    switch (status) {
      case 'Accepted':
        return activeGreen;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String;
    final isPending = status == 'Pending';
    final bookingType = request['bookingType'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: maroon.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: maroon.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: seeker + status badge ────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: maroon.withValues(alpha: 0.15),
                child: const Icon(Icons.person, color: maroon, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['seekerName'] as String,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: maroon),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request['seekerPhone'] as String,
                      style: TextStyle(fontSize: 12, color: maroon.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor(status)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: maroon.withValues(alpha: 0.12)),
          const SizedBox(height: 12),

          // ── Booking details ────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.home_work_outlined, size: 14, color: maroon.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${request['hostelName']} • Room ${request['roomNumber']}',
                  style: TextStyle(fontSize: 12, color: maroon.withValues(alpha: 0.75)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.bed_outlined, size: 14, color: maroon.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                '${request['roomType']} Seater • ${bookingType == 'Room' ? 'Complete Room' : 'Per Seat'}',
                style: TextStyle(fontSize: 12, color: maroon.withValues(alpha: 0.75)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (moveInDate != null) ...[
            Row(
              children: [
                Icon(Icons.event_outlined, size: 14, color: maroon.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(
                  'Wants to move in: $moveInDate',
                  style: TextStyle(fontSize: 12, color: maroon.withValues(alpha: 0.75)),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PKR ${request['price']} / ${bookingType == 'Room' ? 'room' : 'seat'} / month',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: maroon),
              ),
              Text(
                timeAgo,
                style: TextStyle(fontSize: 11, color: maroon.withValues(alpha: 0.5)),
              ),
            ],
          ),

          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onReject,
                    child: const Text('Reject', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: maroon,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onAccept,
                    child: const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}