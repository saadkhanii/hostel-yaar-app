import 'package:flutter/material.dart';

import '../../core/services/booking_service.dart';

// ── Warden Booking Requests Inbox ──────────────────────────────────────
// Reached from the Warden Dashboard's "Requests" stat card and the
// bottom-nav "Requests" tab. Shows real booking requests from seekers,
// with Accept / Reject actions persisted to the backend.
class WardenRequestsScreen extends StatefulWidget {
  const WardenRequestsScreen({super.key});

  @override
  State<WardenRequestsScreen> createState() => _WardenRequestsScreenState();
}

enum _RequestFilter { all, pending, accepted, rejected }

class _WardenRequestsScreenState extends State<WardenRequestsScreen> {
  static const maroon = Color(0xFF800020);

  final _bookingService = BookingService();

  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _errorText;
  _RequestFilter _filter = _RequestFilter.all;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final list = await _bookingService.listWardenRequests();
      if (!mounted) return;
      setState(() {
        _requests = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == _RequestFilter.all) return _requests;
    return _requests.where((r) => r['status'] == _filter.name).toList();
  }

  int _count(_RequestFilter f) {
    if (f == _RequestFilter.all) return _requests.length;
    return _requests.where((r) => r['status'] == f.name).length;
  }

  // ── Accept ─────────────────────────────────────────────────────────

  Future<void> _accept(Map<String, dynamic> request) async {
    final reply = await _promptReply(
      title: 'Accept Request',
      message:
          'Accept ${request['seekerName']}\'s request for Room ${request['roomNumber']}?',
      actionLabel: 'Accept',
      actionColor: const Color(0xFF2E7D32),
      hint: 'Optional message to the seeker',
    );
    if (reply == null) return;

    try {
      final updated = await _bookingService.acceptRequest(
        request['id'] as String,
        wardenReply: reply,
      );
      if (!mounted) return;
      setState(() {
        final idx = _requests.indexWhere((r) => r['id'] == updated['id']);
        if (idx != -1) _requests[idx] = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Accepted ${request['seekerName']}\'s request')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not accept: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  // ── Reject ─────────────────────────────────────────────────────────

  Future<void> _reject(Map<String, dynamic> request) async {
    final reply = await _promptReply(
      title: 'Reject Request',
      message:
          'Reject ${request['seekerName']}\'s request for Room ${request['roomNumber']}?',
      actionLabel: 'Reject',
      actionColor: Colors.red,
      hint: 'Optional reason (e.g. room already booked)',
    );
    if (reply == null) return;

    try {
      final updated = await _bookingService.rejectRequest(
        request['id'] as String,
        wardenReply: reply,
      );
      if (!mounted) return;
      setState(() {
        final idx = _requests.indexWhere((r) => r['id'] == updated['id']);
        if (idx != -1) _requests[idx] = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rejected ${request['seekerName']}\'s request')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not reject: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  /// Shows a dialog with a title, message, optional reply text field, and
  /// Cancel / Action buttons. Returns the reply text on confirm, or null
  /// if the user cancelled. Returns empty string if confirmed with no reply.
  Future<String?> _promptReply({
    required String title,
    required String message,
    required String actionLabel,
    required Color actionColor,
    required String hint,
  }) async {
    final replyCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark
            ? const Color(0xFF1D2128)
            : const Color(0xFFF3E6D5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(color: maroon, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(color: maroon.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: replyCtrl,
              maxLines: 3,
              maxLength: 500,
              style: const TextStyle(fontSize: 13, color: maroon),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: maroon.withValues(alpha: 0.4),
                ),
                counterStyle: TextStyle(
                  fontSize: 10,
                  color: maroon.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: maroon.withValues(alpha: 0.06),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
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
            ),
          ],
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
            child: Text(
              actionLabel,
              style: TextStyle(color: actionColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return null;
    return replyCtrl.text.trim();
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
          'Booking Requests',
          style: TextStyle(
            color: fg,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildBody(fg)),
    );
  }

  Widget _buildBody(Color fg) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(maroon),
        ),
      );
    }

    if (_errorText != null) {
      return _buildErrorState(fg);
    }

    if (_requests.isEmpty) {
      return _buildEmptyState(fg);
    }

    final results = _filtered;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  [
                    (_RequestFilter.all, 'All'),
                    (_RequestFilter.pending, 'Pending'),
                    (_RequestFilter.accepted, 'Accepted'),
                    (_RequestFilter.rejected, 'Rejected'),
                  ].map((entry) {
                    final (value, label) = entry;
                    final selected = _filter == value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? maroon
                                : maroon.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? maroon
                                  : maroon.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            '$label (${_count(value)})',
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
              ? _buildFilteredEmptyState(fg)
              : RefreshIndicator(
                  color: maroon,
                  onRefresh: _loadRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final req = results[i];
                      return _RequestCard(
                        request: req,
                        onAccept: () => _accept(req),
                        onReject: () => _reject(req),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildErrorState(Color fg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: fg.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load requests',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: fg.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorText!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: maroon,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
              label: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color fg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 52,
              color: fg.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No booking requests yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: fg.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyState(Color fg) {
    final label = switch (_filter) {
      _RequestFilter.all => 'No requests yet',
      _RequestFilter.pending => 'No pending requests',
      _RequestFilter.accepted => 'No accepted requests',
      _RequestFilter.rejected => 'No rejected requests',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: fg.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}

// ── Request card ──────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  static const maroon = Color(0xFF800020);
  static const activeGreen = Color(0xFF2E7D32);

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return activeGreen;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange.shade800;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso);
      return '${d.day} ${_months[d.month - 1]} ${d.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final bookingType = request['roomBookingType'] as String? ?? 'Room';
    final moveIn = _formatDate(request['moveInDate'] as String?);
    final createdAt = _formatDate(request['createdAt'] as String?);
    final message = request['message'] as String?;
    final wardenReply = request['wardenReply'] as String?;
    final price = request['roomPrice'] ?? 0;

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
                      request['seekerName'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: maroon,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Requested on $createdAt',
                      style: TextStyle(
                        fontSize: 11,
                        color: maroon.withValues(alpha: 0.55),
                      ),
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
                  _statusLabel(status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(status),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: maroon.withValues(alpha: 0.12)),
          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                Icons.home_work_outlined,
                size: 14,
                color: maroon.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${request['hostelName']} • Room ${request['roomNumber']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: maroon.withValues(alpha: 0.75),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.bed_outlined,
                size: 14,
                color: maroon.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                '${request['roomType']} Seater • ${bookingType == 'Room' ? 'Complete Room' : 'Per Seat'}',
                style: TextStyle(
                  fontSize: 12,
                  color: maroon.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.event_outlined,
                size: 14,
                color: maroon.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                'Wants to move in: $moveIn',
                style: TextStyle(
                  fontSize: 12,
                  color: maroon.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PKR $price / ${bookingType == 'Room' ? 'room' : 'seat'} / month',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: maroon,
                ),
              ),
            ],
          ),

          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: maroon.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: maroon.withValues(alpha: 0.1)),
              ),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: maroon.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],

          if (wardenReply != null && wardenReply.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _statusColor(status).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your reply',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(status),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wardenReply,
                    style: TextStyle(
                      fontSize: 12,
                      color: maroon.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.red.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onReject,
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: maroon,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onAccept,
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
