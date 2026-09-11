import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';
import '../../core/data/dummy_hostels.dart';

void _openHostelDetail(BuildContext context, Map<String, dynamic> hostel) {
  // Routed through AppRouter/AppRoutes.hostelDetail like every other screen
  // in this app, rather than a direct Navigator.push â€” see app_router.dart.
  NavigationService.navigateTo(AppRoutes.hostelDetail, arguments: hostel);
}

class SeekerDashboard extends StatefulWidget {
  const SeekerDashboard({super.key});

  @override
  State<SeekerDashboard> createState() => _SeekerDashboardState();
}

class _SeekerDashboardState extends State<SeekerDashboard> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _goToSearch([String? query]) {
    NavigationService.navigateTo(AppRoutes.hostelList, arguments: query);
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
      // Already on the dashboard â€” nothing to do.
        break;
      case 1:
        _goToSearch();
        break;
      case 2:
        NavigationService.navigateTo(AppRoutes.savedHostels);
        break;
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile â€” coming soon')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : const Color(0xFF800020);
    const maroon = Color(0xFF800020);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: maroon.withValues(alpha: 0.15),
                    child: const Icon(Icons.person, color: maroon, size: 26),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // â”€â”€ Search Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                      child: Icon(Icons.tune, color: maroon.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // â”€â”€ AI Recommendations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                'Based on your preferences',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: fg.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 14),

              // AI Recommendation Cards (horizontal scroll) â€” top matches
              // from the shared dummy dataset, sorted by matchPercent.
              SizedBox(
                height: 190,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: DummyHostels.topRecommended().map((hostel) {
                    return _HostelCard(
                      name: hostel['name'] as String,
                      location: hostel['city'] as String,
                      price: 'Rs. ${DummyHostels.startingPrice(hostel)}/mo',
                      type: hostel['type'] as String,
                      rating: (hostel['rating'] as double).toStringAsFixed(1),
                      matchPercent: '${hostel['matchPercent']}%',
                      onTap: () => _openHostelDetail(context, hostel),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 28),

              // â”€â”€ Find Your Hostel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Text(
                'Find Your Hostel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
              const SizedBox(height: 14),

              // AI Preference Button
              _ActionCard(
                title: 'Tell AI What You Need',
                subtitle: 'Answer a few questions, get matched instantly',
                icon: Icons.auto_awesome,
                isDark: isDark,
                onTap: () => _goToSearch(),
              ),
              const SizedBox(height: 12),
              // Browse All Button
              _ActionCard(
                title: 'Browse All Hostels',
                subtitle: 'See all available hostels in your city',
                icon: Icons.location_city_outlined,
                isDark: isDark,
                onTap: () => _goToSearch(),
              ),

              const SizedBox(height: 28),

              // â”€â”€ All Hostels List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available in Lahore',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  Text(
                    '${DummyHostels.all.length} hostels',
                    style: TextStyle(
                      fontSize: 12,
                      color: fg.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              ...DummyHostels.all.map((hostel) {
                return _HostelListTile(
                  name: hostel['name'] as String,
                  location: hostel['city'] as String,
                  price: 'Rs. ${DummyHostels.startingPrice(hostel)}/mo',
                  type: hostel['type'] as String,
                  rating: (hostel['rating'] as double).toStringAsFixed(1),
                  onTap: () => _openHostelDetail(context, hostel),
                );
              }),
            ],
          ),
        ),
      ),

      // â”€â”€ Bottom Nav â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5),
        selectedItemColor: maroon,
        unselectedItemColor: maroon.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

// â”€â”€ Horizontal Hostel Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _HostelCard extends StatelessWidget {
  final String name;
  final String location;
  final String price;
  final String type;
  final String rating;
  final String matchPercent;
  final VoidCallback? onTap;

  const _HostelCard({
    required this.name,
    required this.location,
    required this.price,
    required this.type,
    required this.rating,
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
            // Match badge
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
                    '$matchPercent match',
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
                Icon(Icons.location_on_outlined, size: 12, color: maroon.withValues(alpha: 0.6)),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(fontSize: 11, color: maroon.withValues(alpha: 0.6)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: maroon,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: maroon),
                    const SizedBox(width: 2),
                    Text(rating, style: const TextStyle(fontSize: 11, color: maroon)),
                  ],
                ),
              ],
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
                style: TextStyle(fontSize: 11, color: maroon.withValues(alpha: 0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Action Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                    style: TextStyle(fontSize: 12, color: maroon.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: maroon.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Hostel List Tile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _HostelListTile extends StatelessWidget {
  final String name;
  final String location;
  final String price;
  final String type;
  final String rating;
  final VoidCallback? onTap;

  const _HostelListTile({
    required this.name,
    required this.location,
    required this.price,
    required this.type,
    required this.rating,
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
              child: const Icon(Icons.home_work_outlined, color: maroon, size: 24),
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
                      Icon(Icons.location_on_outlined, size: 12, color: maroon.withValues(alpha: 0.5)),
                      const SizedBox(width: 2),
                      Text(
                        location,
                        style: TextStyle(fontSize: 12, color: maroon.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: maroon),
                    const SizedBox(width: 2),
                    Text(rating, style: const TextStyle(fontSize: 12, color: maroon)),
                  ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: maroon.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(fontSize: 10, color: maroon.withValues(alpha: 0.8)),
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
