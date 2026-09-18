import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';
import '../../core/services/hostel_service.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/hostel_thumbnail.dart';
import 'hostel_rooms_screen.dart';

class ManageHostelsScreen extends StatefulWidget {
  const ManageHostelsScreen({super.key});

  @override
  State<ManageHostelsScreen> createState() => _ManageHostelsScreenState();
}

class _ManageHostelsScreenState extends State<ManageHostelsScreen> {
  static const maroon = Color(0xFF800020);

  final _hostelService = HostelService();

  List<Map<String, dynamic>> _hostels = [];
  bool _isLoading = true;
  String? _errorText;
  void _onWardenTabTap(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        NavigationService.navigateAndRemoveUntil(AppRoutes.wardenHome);
        break;
      case AppTab.hostels:
      // Already here.
        break;
      case AppTab.requests:
        NavigationService.navigateTo(AppRoutes.wardenRequests);
        break;
      case AppTab.alerts:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerts — coming soon')),
        );
        break;
      default:
        break;
    }
  }
  @override
  void initState() {
    super.initState();
    _loadHostels();
  }

  Future<void> _loadHostels() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final list = await _hostelService.listMyHostels();
      if (!mounted) return;
      setState(() {
        _hostels = list;
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

  // ── Active toggle (optimistic) ────────────────────────────────────────────
  //
  // Flip the switch immediately so the UI feels instant. If the PUT fails,
  // revert and show a snackbar.
  Future<void> _toggleActive(int index, bool value) async {
    final hostel = _hostels[index];
    final previous = hostel['active'] as bool? ?? true;

    setState(() => hostel['active'] = value);

    try {
      await _hostelService.updateHostel(hostel['id'] as String, active: value);
    } catch (e) {
      if (!mounted) return;
      setState(() => hostel['active'] = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update listing: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(int index) async {
    final hostel = _hostels[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark
            ? const Color(0xFF1D2128)
            : const Color(0xFFF3E6D5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove Hostel',
          style: TextStyle(color: maroon, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove "${hostel['name']}"? This cannot be undone.',
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

    try {
      await _hostelService.deleteHostel(hostel['id'] as String);
      if (!mounted) return;
      setState(() => _hostels.removeAt(index));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hostel removed')));
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

  // ── Edit (routes through AppRouter) ───────────────────────────────────────
  Future<void> _editHostel(int index) async {
    final hostel = _hostels[index];
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.editHostel,
      arguments: hostel,
    );
    if (result != null && mounted) {
      final updated = result as Map<String, dynamic>;

      // Persist the change to the backend.
      try {
        await _hostelService.updateHostel(
          hostel['id'] as String,
          name: updated['name'] as String?,
          city: updated['city'] as String?,
          address: updated['address'] as String?,
          type: updated['type'] as String?,
          phone: updated['phone'] as String?,
          whatsapp: updated['whatsapp'] as String?,
          inAppChat: updated['inAppChat'] as bool?,
          facilities: (updated['facilities'] as List?)?.cast<String>(),
          photos: (updated['photos'] as List?)?.cast<String>(),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not save changes: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
        return;
      }

      // Refresh from the server so the card reflects the true state.
      await _loadHostels();
    }
  }

  // ── Manage rooms (unchanged UI, no backend writes yet) ────────────────────
  Future<void> _openRoomManagement(int index) async {
    final hostel = _hostels[index];
    await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (_) => HostelRoomsScreen(
          hostelId: hostel['id'] as String,
          hostelName: hostel['name'] as String,
          rooms: (hostel['rooms'] as List).cast<Map<String, dynamic>>(),
        ),
      ),
    );
    // Rooms are persisted server-side, so just refresh the whole hostel
    // list to pick up any changes (room count, vacancy, price, etc.).
    await _loadHostels();
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
          'Listed Hostels',
          style: TextStyle(
            color: fg,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildBody(isDark, fg)),
      bottomNavigationBar: AppBottomNav(
        isSeeker: false,
        currentTab: AppTab.hostels,
        onTap: _onWardenTabTap,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: maroon,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Hostel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        onPressed: () async {
          await NavigationService.navigateTo(AppRoutes.addHostel);
          // Refresh on return so the newly-created hostel shows up.
          await _loadHostels();
        },
      ),
    );
  }

  Widget _buildBody(bool isDark, Color fg) {
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

    if (_hostels.isEmpty) {
      return _buildEmptyState(fg);
    }

    return RefreshIndicator(
      color: maroon,
      onRefresh: _loadHostels,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: _hostels.length,
        itemBuilder: (context, i) {
          final hostel = _hostels[i];
          return _HostelListingCard(
            hostel: hostel,
            isDark: isDark,
            onToggleActive: (v) => _toggleActive(i, v),
            onEdit: () => _editHostel(i),
            onDelete: () => _confirmDelete(i),
            onManageRooms: () => _openRoomManagement(i),
          );
        },
      ),
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
              size: 56,
              color: fg.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: fg.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorText!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadHostels,
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
              Icons.home_work_outlined,
              size: 56,
              color: fg.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hostels listed yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: fg.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap "Add Hostel" below to create your first listing.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hostel Listing Card ────────────────────────────────────────────────────
class _HostelListingCard extends StatelessWidget {
  final Map<String, dynamic> hostel;
  final bool isDark;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageRooms;

  const _HostelListingCard({
    required this.hostel,
    required this.isDark,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
    required this.onManageRooms,
  });

  static const maroon = Color(0xFF800020);
  static const activeGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final bool active = hostel['active'] as bool? ?? true;
    final rooms = ((hostel['rooms'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final int totalRoomsCount = rooms.length;

    // Occupancy across seats, since a "Seat" room can be partially vacant.
    // Rooms arrive camelCased from HostelService.
    final int totalSeats = rooms.fold<int>(
      0,
          (sum, r) => sum + ((r['roomType'] as int?) ?? 0),
    );
    final int vacantSeats = rooms.fold<int>(0, (sum, r) {
      final type = r['bookingType'] as String?;
      if (type == 'Seat') return sum + ((r['availableSeats'] as int?) ?? 0);
      return sum + ((r['vacant'] == true ? (r['roomType'] as int?) ?? 0 : 0));
    });
    final int filledSeats = totalSeats - vacantSeats;
    final double occupancyRatio = totalSeats == 0
        ? 0
        : filledSeats / totalSeats;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: maroon.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: maroon.withValues(alpha: active ? 0.2 : 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row ─────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HostelThumbnail(
                photos: (hostel['photos'] as List?)?.cast<String>() ?? const [],
                size: 52,
                radius: 12,
                iconSize: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hostel['name'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: maroon,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: maroon.withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            hostel['city'] as String? ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: maroon.withValues(alpha: 0.55),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: maroon.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        hostel['type'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: maroon.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Switch(
                    value: active,
                    onChanged: onToggleActive,
                    activeThumbColor: activeGreen,
                  ),
                  Text(
                    active ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? activeGreen
                          : maroon.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Occupancy stats ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _OccupancyStat(
                  label: 'Rooms',
                  value: '$totalRoomsCount',
                  color: maroon,
                ),
              ),
              Expanded(
                child: _OccupancyStat(
                  label: 'Filled Seats',
                  value: '$filledSeats',
                  color: activeGreen,
                ),
              ),
              Expanded(
                child: _OccupancyStat(
                  label: 'Vacant Seats',
                  value: '$vacantSeats',
                  color: vacantSeats > 0
                      ? Colors.orange.shade800
                      : maroon.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: occupancyRatio,
              minHeight: 6,
              backgroundColor: maroon.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(
                vacantSeats == 0 ? activeGreen : maroon,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Manage Rooms ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onManageRooms,
              style: ElevatedButton.styleFrom(
                backgroundColor: maroon,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(
                Icons.meeting_room_outlined,
                size: 16,
                color: Colors.white,
              ),
              label: const Text(
                'Manage Rooms',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Actions ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: maroon.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: maroon,
                  ),
                  label: const Text(
                    'Edit',
                    style: TextStyle(color: maroon, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Occupancy stat block ───────────────────────────────────────────────────
class _OccupancyStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OccupancyStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.75)),
        ),
      ],
    );
  }
}
