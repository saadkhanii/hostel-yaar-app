import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';
import '../../core/services/hostel_service.dart';
import '../../core/services/session_manager.dart';

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

  final _hostelService = HostelService();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _allHostels = [];
  bool _isLoading = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadHostels();
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

  void _onNavTap(int index) {
    switch (index) {
      case 0:
      // Already on Home.
        break;
      case 1:
        _goToSearch();
        break;
      case 2:
        NavigationService.navigateTo(AppRoutes.savedHostels);
        break;
      case 3:
        NavigationService.navigateTo(AppRoutes.myRequests);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : const Color(0xFF800020);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: maroon,
          onRefresh: _loadHostels,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello,',
                          style: TextStyle(
                            fontSize: 14,
                            color: fg.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          'Ali Hassan',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: fg,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => SessionManager.confirmAndLogout(context),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: maroon.withValues(alpha: 0.15),
                        child:
                        const Icon(Icons.person, color: maroon, size: 26),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Search Bar ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: maroon.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: maroon.withValues(alpha: 0.2)),
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
                        child: Icon(
                          Icons.tune,
                          color: maroon.withValues(alpha: 0.5),
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
                  ..._buildContent(isDark, fg),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),

      // ── Bottom Nav ─────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDark
            ? const Color(0xFF1D2128)
            : const Color(0xFFF3E6D5),
        selectedItemColor: maroon,
        unselectedItemColor: maroon.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_outlined),
            label: 'Requests',
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContent(bool isDark, Color fg) {
    return [
      // ── AI Recommendations ─────────────────────────────────
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'AI Recommendations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          GestureDetector(
            onTap: () => _goToSearch(),
            child: Text(
              'See all',
              style: TextStyle(
                fontSize: 13,
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
            color: maroon.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: maroon.withValues(alpha: 0.18)),
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
          height: 190,
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
                onTap: () => _openHostelDetail(context, hostel),
              );
            }).toList(),
          ),
        ),

      const SizedBox(height: 28),

      // ── Find Your Hostel ───────────────────────────────────
      Text(
        'Find Your Hostel',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg),
      ),
      const SizedBox(height: 14),

      _ActionCard(
        title: 'Tell AI What You Need',
        subtitle: 'Answer a few questions, get matched instantly',
        icon: Icons.auto_awesome,
        isDark: isDark,
        onTap: () => _goToSearch(),
      ),
      const SizedBox(height: 12),
      _ActionCard(
        title: 'Browse All Hostels',
        subtitle: 'See all available hostels in your city',
        icon: Icons.location_city_outlined,
        isDark: isDark,
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
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: fg,
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
            color: maroon.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: maroon.withValues(alpha: 0.18)),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
  final VoidCallback? onTap;

  const _HostelCard({
    required this.name,
    required this.location,
    required this.price,
    required this.type,
    required this.matchPercent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: maroon.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: maroon.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: maroon,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    matchPercent,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: maroon,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 12,
                  color: maroon.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      fontSize: 11,
                      color: maroon.withValues(alpha: 0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              price,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: maroon,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: maroon.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                type,
                style: TextStyle(
                  fontSize: 11,
                  color: maroon.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
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
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: maroon.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: maroon.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: maroon.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
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
                      fontWeight: FontWeight.w600,
                      color: maroon,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: maroon.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: maroon.withValues(alpha: 0.4),
            ),
          ],
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
  final VoidCallback? onTap;

  const _HostelListTile({
    required this.name,
    required this.location,
    required this.price,
    required this.type,
    required this.hasVacancy,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: maroon.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: maroon.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: maroon.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.home_work_outlined,
                color: maroon,
                size: 24,
              ),
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
                      fontWeight: FontWeight.w600,
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
    );
  }
}
