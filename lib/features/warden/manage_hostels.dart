import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';

class ManageHostelsScreen extends StatefulWidget {
  const ManageHostelsScreen({super.key});

  @override
  State<ManageHostelsScreen> createState() => _ManageHostelsScreenState();
}

class _ManageHostelsScreenState extends State<ManageHostelsScreen> {
  static const maroon = Color(0xFF800020);

  // ── Dummy data — replace with data fetched from Firestore ────────────
  final List<Map<String, dynamic>> _hostels = [
    {
      'name': 'Green View Hostel',
      'city': 'Gulberg, Lahore',
      'type': 'Boys',
      'totalRooms': 18,
      'vacantRooms': 4,
      'active': true,
    },
    {
      'name': 'Sunrise Boys Hostel',
      'city': 'Model Town, Lahore',
      'type': 'Boys',
      'totalRooms': 12,
      'vacantRooms': 0,
      'active': true,
    },
    {
      'name': 'Al-Noor Girls Hostel',
      'city': 'Johar Town, Lahore',
      'type': 'Girls',
      'totalRooms': 18,
      'vacantRooms': 6,
      'active': false,
    },
  ];

  void _confirmDelete(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Hostel', style: TextStyle(color: maroon, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove "${_hostels[index]['name']}"? This cannot be undone.',
          style: TextStyle(color: maroon.withOpacity(0.75)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: maroon.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () {
              setState(() => _hostels.removeAt(index));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hostel removed')),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _editHostel(int index) {
    // TODO: navigate to AddHostelScreen in edit mode once it supports
    // pre-filling from an existing hostel.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Editing existing hostels is coming soon')),
    );
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
          'My Listed Hostels',
          style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _hostels.isEmpty
            ? _buildEmptyState(fg)
            : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: _hostels.length,
          itemBuilder: (context, i) {
            final hostel = _hostels[i];
            return _HostelListingCard(
              hostel: hostel,
              isDark: isDark,
              onToggleActive: (v) => setState(() => hostel['active'] = v),
              onEdit: () => _editHostel(i),
              onDelete: () => _confirmDelete(i),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: maroon,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Hostel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () => NavigationService.navigateTo(AppRoutes.addHostel),
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
            Icon(Icons.home_work_outlined, size: 56, color: fg.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No hostels listed yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg.withOpacity(0.8)),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap "Add Hostel" below to create your first listing.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: fg.withOpacity(0.5)),
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

  const _HostelListingCard({
    required this.hostel,
    required this.isDark,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  static const maroon = Color(0xFF800020);
  static const activeGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final bool active = hostel['active'] as bool;
    final int totalRooms = hostel['totalRooms'] as int;
    final int vacantRooms = hostel['vacantRooms'] as int;
    final int filledRooms = totalRooms - vacantRooms;
    final double occupancyRatio = totalRooms == 0 ? 0 : filledRooms / totalRooms;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: maroon.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: maroon.withOpacity(active ? 0.2 : 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: thumbnail, name/city, status toggle ──────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: maroon.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home_work_outlined, color: maroon, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hostel['name'] as String,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: maroon),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: maroon.withOpacity(0.55)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            hostel['city'] as String,
                            style: TextStyle(fontSize: 12, color: maroon.withOpacity(0.55)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: maroon.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        hostel['type'] as String,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: maroon.withOpacity(0.8)),
                      ),
                    ),
                  ],
                ),
              ),
              // Active/Inactive toggle
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Switch(
                    value: active,
                    onChanged: onToggleActive,
                    activeColor: activeGreen,
                  ),
                  Text(
                    active ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: active ? activeGreen : maroon.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Occupancy stats ────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _OccupancyStat(
                  label: 'Total Rooms',
                  value: '$totalRooms',
                  color: maroon,
                ),
              ),
              Expanded(
                child: _OccupancyStat(
                  label: 'Filled',
                  value: '$filledRooms',
                  color: activeGreen,
                ),
              ),
              Expanded(
                child: _OccupancyStat(
                  label: 'Vacant',
                  value: '$vacantRooms',
                  color: vacantRooms > 0 ? Colors.orange.shade800 : maroon.withOpacity(0.4),
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
              backgroundColor: maroon.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(
                vacantRooms == 0 ? activeGreen : maroon,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Actions ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: maroon.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16, color: maroon),
                  label: const Text('Edit', style: TextStyle(color: maroon, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Small occupancy stat block used inside the card ─────────────────────────
class _OccupancyStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OccupancyStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: color.withOpacity(0.75)),
        ),
      ],
    );
  }
}