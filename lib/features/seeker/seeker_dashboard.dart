import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/hostel_service.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/hostel_thumbnail.dart';
import '../../shared/widgets/user_avatar.dart';

void _openHostelDetail(BuildContext context, Map<String, dynamic> hostel) {
  NavigationService.navigateTo(AppRoutes.hostelDetail, arguments: hostel);
}

class SeekerDashboard extends StatefulWidget {
  const SeekerDashboard({super.key});

  @override
  State<SeekerDashboard> createState() => _SeekerDashboardState();
}

class _SeekerDashboardState extends State<SeekerDashboard> {
  static const maroon = Color(0xFF800020);
  static const maroonDark = Color(0xFF5C0017);

  final _hostelService = HostelService();
  final _searchCtrl = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _authService = AuthService();
  String _userName = '';

  List<Map<String, dynamic>> _allHostels = [];
  bool _isLoading = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadHostels();
  }

  Future<void> _loadUserName() async {
    final name = await _authService.getFullName();
    if (!mounted) return;
    setState(() {
      _userName = name ?? 'there';
    });
  }


  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHostels() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final list = await _hostelService.listHostels();
      if (!mounted) return;
      setState(() {
        _allHostels = list;
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

  // Cheap picks: 3 cheapest hostels with vacancy, used as a stand-in for
  // "AI recommendations" until a real preference engine exists.
  List<Map<String, dynamic>> get _topRecommended {
    final withVacancy =
        _allHostels.where((h) => h['hasVacancy'] == true).toList()..sort(
          (a, b) => ((a['startingPrice'] as int?) ?? 0).compareTo(
            (b['startingPrice'] as int?) ?? 0,
          ),
        );
    return withVacancy.take(3).toList();
  }

  void _goToSearch([String? query]) {
    NavigationService.navigateTo(AppRoutes.hostelList, arguments: query);
  }

  void _onTabTap(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        // Already here.
        break;
      case AppTab.search:
        _goToSearch();
        break;
      case AppTab.saved:
        NavigationService.navigateTo(AppRoutes.savedHostels);
        break;
      case AppTab.requests:
        NavigationService.navigateTo(AppRoutes.myRequests);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : const Color(0xFF800020);
    final cardColor = isDark ? const Color(0xFF262B33) : Colors.white;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      endDrawer: const AppDrawer(),
      endDrawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: RefreshIndicator(
          color: maroon,
          onRefresh: _loadHostels,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [maroon, maroonDark],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: maroon.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userName.isEmpty ? '...' : _userName,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      UserAvatar(
                        size: 46,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        foregroundColor: Colors.white,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        onTap: () =>
                            _scaffoldKey.currentState?.openEndDrawer(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ── Search Bar ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.05,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: maroon.withValues(alpha: 0.5)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onSubmitted: (q) => _goToSearch(q),
                          decoration: InputDecoration(
                            hintText: 'Search hostels in your city...',
                            hintStyle: TextStyle(
                              color: maroon.withValues(alpha: 0.4),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _goToSearch(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: maroon.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.tune,
                            size: 18,
                            color: maroon.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Body: loading / error / content ──────────────
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(maroon),
                      ),
                    ),
                  )
                else if (_errorText != null)
                  _buildErrorState(fg)
                else
                  ..._buildContent(isDark, fg, cardColor),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),

      // ── Bottom Nav ─────────────────────────────────────────────
      bottomNavigationBar: AppBottomNav(
        isSeeker: true,
        currentTab: AppTab.home,
        onTap: _onTabTap,
      ),
    );
  }

  List<Widget> _buildContent(bool isDark, Color fg, Color cardColor) {
    return [
      // ── AI Recommendations ─────────────────────────────────
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'AI Recommendations',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
          GestureDetector(
            onTap: () => _goToSearch(),
            child: Text(
              'See all',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: maroon.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        'Best value picks near you',
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: fg.withValues(alpha: 0.5),
        ),
      ),
      const SizedBox(height: 14),

      if (_topRecommended.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: maroon, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No recommendations yet — no hostels with vacancies.',
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
        SizedBox(
          height: 262,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _topRecommended.map((hostel) {
              return _HostelCard(
                name: hostel['name'] as String? ?? '',
                location: hostel['city'] as String? ?? '',
                price: 'Rs. ${hostel['startingPrice'] ?? 0}/mo',
                type: hostel['type'] as String? ?? '',
                matchPercent: hostel['hasVacancy'] == true
                    ? 'Available'
                    : 'Full',
                photos: (hostel['photos'] as List?)?.cast<String>() ?? const [],
                isDark: isDark,
                cardColor: cardColor,
                onTap: () => _openHostelDetail(context, hostel),
              );
            }).toList(),
          ),
        ),

      const SizedBox(height: 28),

      // ── Find Your Hostel ───────────────────────────────────
      Text(
        'Find Your Hostel',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
      const SizedBox(height: 14),

      _ActionCard(
        title: 'Tell AI What You Need',
        subtitle: 'Answer a few questions, get matched instantly',
        icon: Icons.auto_awesome,
        isDark: isDark,
        cardColor: cardColor,
        onTap: () => _goToSearch(),
      ),
      const SizedBox(height: 12),
      _ActionCard(
        title: 'Browse All Hostels',
        subtitle: 'See all available hostels in your city',
        icon: Icons.location_city_outlined,
        isDark: isDark,
        cardColor: cardColor,
        onTap: () => _goToSearch(),
      ),

      const SizedBox(height: 28),

      // ── Available Hostels ──────────────────────────────────
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Available Hostels',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
          Text(
            '${_allHostels.length} hostel${_allHostels.length == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.5)),
          ),
        ],
      ),
      const SizedBox(height: 14),

      if (_allHostels.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.home_work_outlined, color: maroon, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No hostels listed yet. Check back soon.',
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
        ..._allHostels.map((hostel) {
          return _HostelListTile(
            name: hostel['name'] as String? ?? '',
            location: hostel['city'] as String? ?? '',
            price: 'Rs. ${hostel['startingPrice'] ?? 0}/mo',
            type: hostel['type'] as String? ?? '',
            hasVacancy: hostel['hasVacancy'] == true,
            photos: (hostel['photos'] as List?)?.cast<String>() ?? const [],
            isDark: isDark,
            cardColor: cardColor,
            onTap: () => _openHostelDetail(context, hostel),
          );
        }),
    ];
  }

  Widget _buildErrorState(Color fg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: fg.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'Could not load hostels',
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
            onPressed: _loadHostels,
            style: ElevatedButton.styleFrom(
              backgroundColor: maroon,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
    );
  }
}

// ── Horizontal Hostel Card ──────────────────────────────────────────────
class _HostelCard extends StatelessWidget {
  final String name;
  final String location;
  final String price;
  final String type;
  final String matchPercent;
  final List<String> photos;
  final bool isDark;
  final Color cardColor;
  final VoidCallback? onTap;

  const _HostelCard({
    required this.name,
    required this.location,
    required this.price,
    required this.type,
    required this.matchPercent,
    required this.photos,
    required this.isDark,
    required this.cardColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    final hasPhoto = photos.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Full-width photo ─────────────────────────
                SizedBox(
                  width: 180,
                  height: 110,
                  child: hasPhoto
                      ? Image.network(
                          photos.first,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: maroon.withValues(alpha: 0.08),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(maroon),
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stack) => Container(
                            color: maroon.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: maroon.withValues(alpha: 0.4),
                              size: 28,
                            ),
                          ),
                        )
                      : Container(
                          color: maroon.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.home_work_outlined,
                            color: maroon.withValues(alpha: 0.5),
                            size: 36,
                          ),
                        ),
                ),

                // ── Content ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Match badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: matchPercent == 'Available'
                              ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          matchPercent,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: matchPercent == 'Available'
                                ? const Color(0xFF2E7D32)
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Name
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: maroon,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: maroon.withValues(alpha: 0.55),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                fontSize: 11,
                                color: maroon.withValues(alpha: 0.55),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Price
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: maroon,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Type chip
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
                          type,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: maroon.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Action Card ─────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final Color cardColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
    required this.cardColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: maroon.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: maroon, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: maroon,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: maroon.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: maroon.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hostel List Tile ────────────────────────────────────────────────────
class _HostelListTile extends StatelessWidget {
  final String name;
  final String location;
  final String price;
  final String type;
  final bool hasVacancy;
  final List<String> photos;
  final bool isDark;
  final Color cardColor;
  final VoidCallback? onTap;

  const _HostelListTile({
    required this.name,
    required this.location,
    required this.price,
    required this.type,
    required this.hasVacancy,
    required this.photos,
    required this.isDark,
    required this.cardColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                HostelThumbnail(
                  photos: photos,
                  size: 48,
                  radius: 12,
                  iconSize: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: maroon,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: maroon.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            location,
                            style: TextStyle(
                              fontSize: 12,
                              color: maroon.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: hasVacancy
                            ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
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
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: maroon,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: maroon.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 10,
                          color: maroon.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
