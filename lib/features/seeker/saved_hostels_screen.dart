import 'package:flutter/material.dart';
import 'package:hostel_yaar/core/data/saved_hostels_store.dart';
import 'package:hostel_yaar/core/routes/app_routes.dart';
import 'package:hostel_yaar/core/routes/navigation_service.dart';
import 'package:hostel_yaar/core/data/dummy_hostels.dart';

// â”€â”€ Saved Hostels Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Reached from the bottom nav "Saved" tab on the Seeker Dashboard. Reads from
// SavedHostelsStore (see saved_hostels_store.dart) â€” the same store the
// heart icon on HostelDetailScreen writes to â€” so anything saved there shows
// up here immediately, and un-saving here updates the detail screen too.
class SavedHostelsScreen extends StatefulWidget {
  const SavedHostelsScreen({super.key});

  @override
  State<SavedHostelsScreen> createState() => _SavedHostelsScreenState();
}

class _SavedHostelsScreenState extends State<SavedHostelsScreen> {
  static const maroon = Color(0xFF800020);
  final _store = SavedHostelsStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() => setState(() {});

  void _openHostelDetail(Map<String, dynamic> hostel) {
    NavigationService.navigateTo(AppRoutes.hostelDetail, arguments: hostel);
  }

  void _unsave(Map<String, dynamic> hostel) {
    _store.remove(hostel);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${hostel['name']} from saved'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _store.save(hostel),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : const Color(0xFF800020);
    final saved = _store.all;

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
          'Saved Hostels',
          style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: saved.isEmpty
            ? _buildEmptyState(fg)
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          itemCount: saved.length,
          itemBuilder: (context, i) {
            final hostel = saved[i];
            return _SavedHostelCard(
              hostel: hostel,
              startingPrice: DummyHostels.startingPrice(hostel),
              hasVacancy: DummyHostels.hasVacancy(hostel),
              onTap: () => _openHostelDetail(hostel),
              onUnsave: () => _unsave(hostel),
            );
          },
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
            Icon(Icons.favorite_border, size: 52, color: fg.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'No saved hostels yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fg.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the heart on any hostel to save it here for later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => NavigationService.navigateTo(AppRoutes.hostelList),
              style: ElevatedButton.styleFrom(
                backgroundColor: maroon,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Browse Hostels',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Saved Hostel Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SavedHostelCard extends StatelessWidget {
  final Map<String, dynamic> hostel;
  final int startingPrice;
  final bool hasVacancy;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  const _SavedHostelCard({
    required this.hostel,
    required this.startingPrice,
    required this.hasVacancy,
    required this.onTap,
    required this.onUnsave,
  });

  static const maroon = Color(0xFF800020);

  @override
  Widget build(BuildContext context) {
    final facilities = (hostel['facilities'] as List).cast<String>();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: maroon.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: maroon.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: maroon.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.home_work_outlined, color: maroon, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hostel['name'] as String,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: maroon),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onUnsave,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.favorite, size: 20, color: maroon),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: maroon.withValues(alpha: 0.55)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          hostel['city'] as String,
                          style: TextStyle(fontSize: 12, color: maroon.withValues(alpha: 0.55)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 12, color: maroon),
                      const SizedBox(width: 2),
                      Text(
                        (hostel['rating'] as double).toStringAsFixed(1),
                        style: const TextStyle(fontSize: 11, color: maroon, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: maroon.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hostel['type'] as String,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: maroon.withValues(alpha: 0.8)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: hasVacancy ? const Color(0xFF2E7D32).withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hasVacancy ? 'Vacant' : 'Full',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: hasVacancy ? const Color(0xFF2E7D32) : Colors.orange.shade800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${facilities.length} amenities',
                        style: TextStyle(fontSize: 11, color: maroon.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'From Rs. $startingPrice/mo',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: maroon),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
