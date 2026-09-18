import 'package:flutter/material.dart';
import 'package:hostel_yaar/core/routes/app_routes.dart';
import 'package:hostel_yaar/core/routes/navigation_service.dart';
import 'package:hostel_yaar/core/services/hostel_service.dart';

import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/hostel_thumbnail.dart';

// ── Saved Hostels Screen ───────────────────────────────────────────────
// Reached from the seeker dashboard's Saved tab. Reads from
// GET /saved-hostels — the same endpoint the heart icon on
// HostelDetailScreen writes to, so anything saved there shows up here.
class SavedHostelsScreen extends StatefulWidget {
  const SavedHostelsScreen({super.key});

  @override
  State<SavedHostelsScreen> createState() => _SavedHostelsScreenState();
}

class _SavedHostelsScreenState extends State<SavedHostelsScreen> {
  static const maroon = Color(0xFF800020);

  final _hostelService = HostelService();

  List<Map<String, dynamic>> _saved = [];
  bool _isLoading = true;
  String? _errorText;

  void _onTabTap(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        NavigationService.navigateAndRemoveUntil(AppRoutes.seekerHome);
        break;
      case AppTab.alerts:
        NavigationService.navigateTo(AppRoutes.notifications);
        break;
      case AppTab.saved:
      // Already here.
        break;
      case AppTab.requests:
        NavigationService.navigateTo(AppRoutes.myRequests);
        break;
      default:
        break;
    }
  }
  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final rows = await _hostelService.listSavedHostels();
      if (!mounted) return;
      setState(() {
        _saved = rows;
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

  void _openHostelDetail(Map<String, dynamic> hostel) {
    NavigationService.navigateTo(AppRoutes.hostelDetail, arguments: hostel);
  }

  Future<void> _unsave(Map<String, dynamic> hostel) async {
    final id = hostel['id'] as String?;
    if (id == null) return;

    try {
      await _hostelService.unsaveHostel(id);
      if (!mounted) return;

      setState(() {
        _saved.removeWhere(
              (s) => (s['hostel'] as Map<String, dynamic>)['id'] == id,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed ${hostel['name']} from saved'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              try {
                await _hostelService.saveHostel(id);
                if (mounted) _loadSaved();
              } catch (_) {
                // Silent — a failed undo isn't worth another snackbar.
              }
            },
          ),
        ),
      );
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
          'Saved Hostels',
          style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
        body: SafeArea(child: _buildBody(isDark, fg)),
        bottomNavigationBar: AppBottomNav(
          isSeeker: true,
          currentTab: AppTab.saved,
          onTap: _onTabTap,
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
                'Could not load saved hostels',
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
                style:
                TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadSaved,
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

    if (_saved.isEmpty) {
      return _buildEmptyState(fg);
    }

    return RefreshIndicator(
      color: maroon,
      onRefresh: _loadSaved,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        itemCount: _saved.length,
        itemBuilder: (context, i) {
          final entry = _saved[i];
          final hostel = entry['hostel'] as Map<String, dynamic>;
          return _SavedHostelCard(
            hostel: hostel,
            onTap: () => _openHostelDetail(hostel),
            onUnsave: () => _unsave(hostel),
          );
        },
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
            Icon(Icons.favorite_border,
                size: 52, color: fg.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'No saved hostels yet',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: fg.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the heart on any hostel to save it here for later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  NavigationService.navigateTo(AppRoutes.hostelList),
              style: ElevatedButton.styleFrom(
                backgroundColor: maroon,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Browse Hostels',
                style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Saved Hostel Card ─────────────────────────────────────────────────
class _SavedHostelCard extends StatelessWidget {
  final Map<String, dynamic> hostel;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  const _SavedHostelCard({
    required this.hostel,
    required this.onTap,
    required this.onUnsave,
  });

  static const maroon = Color(0xFF800020);

  @override
  Widget build(BuildContext context) {
    final facilities =
        (hostel['facilities'] as List?)?.cast<String>() ?? const [];
    final startingPrice = (hostel['startingPrice'] as int?) ?? 0;
    final hasVacancy = hostel['hasVacancy'] == true;

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
            HostelThumbnail(
              photos: (hostel['photos'] as List?)?.cast<String>() ?? const [],
              size: 60,
              radius: 12,
              iconSize: 28,
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
                          hostel['name'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: maroon,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onUnsave,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.favorite,
                              size: 20, color: maroon),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 12, color: maroon.withValues(alpha: 0.55)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          hostel['city'] as String? ?? '',
                          style: TextStyle(
                              fontSize: 12,
                              color: maroon.withValues(alpha: 0.55)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: maroon.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hostel['type'] as String? ?? '',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: maroon.withValues(alpha: 0.8)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: hasVacancy
                              ? const Color(0xFF2E7D32)
                              .withValues(alpha: 0.12)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hasVacancy ? 'Vacant' : 'Full',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: hasVacancy
                                ? const Color(0xFF2E7D32)
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${facilities.length} amenities',
                        style: TextStyle(
                            fontSize: 11,
                            color: maroon.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'From Rs. $startingPrice/mo',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: maroon),
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