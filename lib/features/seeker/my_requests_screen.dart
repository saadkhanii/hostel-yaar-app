import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';
import '../../core/services/booking_service.dart';
import '../../shared/widgets/app_bottom_nav.dart';

/// Seeker-facing screen: everything the current seeker has requested,
/// with status. Reached from the bottom-nav "Requests" tab.
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

enum _StatusFilter { all, pending, accepted, rejected }

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  static const maroon = Color(0xFF800020);

  final _bookingService = BookingService();

  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _errorText;
  _StatusFilter _filter = _StatusFilter.all;
  void _onTabTap(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        NavigationService.navigateAndRemoveUntil(AppRoutes.seekerHome);
        break;
      case AppTab.alerts:
        NavigationService.navigateTo(AppRoutes.notifications);
        break;
      case AppTab.saved:
        NavigationService.navigateTo(AppRoutes.savedHostels);
        break;
      case AppTab.requests:
      // Already here.
        break;
      default:
        break;
    }
  }
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
      final list = await _bookingService.listMyRequests();
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
    if (_filter == _StatusFilter.all) return _requests;
    final target = _filter.name; // 'pending', 'accepted', 'rejected'
    return _requests.where((r) => r['status'] == target).toList();
  }

  int _count(_StatusFilter f) {
    if (f == _StatusFilter.all) return _requests.length;
    return _requests.where((r) => r['status'] == f.name).length;
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : const Color(0xFF800020);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'My Booking Requests',
          style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildBody(fg)),
      bottomNavigationBar: AppBottomNav(
        isSeeker: true,
        currentTab: AppTab.requests,
        onTap: _onTabTap,
      ),
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
        // ── Filter chips ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                (_StatusFilter.all, 'All'),
                (_StatusFilter.pending, 'Pending'),
                (_StatusFilter.accepted, 'Accepted'),
                (_StatusFilter.rejected, 'Rejected'),
              ].map((entry) {
                final (value, label) = entry;
                final selected = _filter == value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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

        // ── List ───────────────────────────────────────────────
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
                return _MyRequestCard(
                  request: req,
                  formatDate: _formatDate,
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
            Icon(Icons.error_outline,
                size: 48, color: fg.withValues(alpha: 0.4)),
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
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
              label: const Text('Retry',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
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
            Icon(Icons.inbox_outlined,
                size: 52, color: fg.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'No requests yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: fg.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Browse hostels and tap "Request to Book" on a room to send your first request.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyState(Color fg) {
    final label = switch (_filter) {
      _StatusFilter.all => 'No requests yet',
      _StatusFilter.pending => 'No pending requests',
      _StatusFilter.accepted => 'No accepted requests',
      _StatusFilter.rejected => 'No rejected requests',
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
class _MyRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final String Function(String?) formatDate;

  const _MyRequestCard({
    required this.request,
    required this.formatDate,
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

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String? ?? 'pending';
    final moveIn = formatDate(request['moveInDate'] as String?);
    final createdAt = formatDate(request['createdAt'] as String?);
    final message = request['message'] as String?;
    final wardenReply = request['wardenReply'] as String?;

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
            children: [
              Expanded(
                child: Text(
                  request['hostelName'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: maroon,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 12, color: maroon.withValues(alpha: 0.55)),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  request['hostelCity'] as String? ?? '',
                  style: TextStyle(
                      fontSize: 12,
                      color: maroon.withValues(alpha: 0.55)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: maroon.withValues(alpha: 0.12)),
          const SizedBox(height: 12),

          Row(
            children: [
              Icon(Icons.door_front_door_outlined,
                  size: 14, color: maroon.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                'Room ${request['roomNumber']} • ${request['roomType']} Seater',
                style: TextStyle(
                    fontSize: 12, color: maroon.withValues(alpha: 0.75)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.event_outlined,
                  size: 14, color: maroon.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                'Move-in: $moveIn',
                style: TextStyle(
                    fontSize: 12, color: maroon.withValues(alpha: 0.75)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule_outlined,
                  size: 14, color: maroon.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                'Requested on $createdAt',
                style: TextStyle(
                    fontSize: 12, color: maroon.withValues(alpha: 0.55)),
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
                border:
                Border.all(color: _statusColor(status).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Warden\'s reply',
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
        ],
      ),
    );
  }
}