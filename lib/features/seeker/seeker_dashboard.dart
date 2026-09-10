import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';

// Builds a placeholder hostel-detail map from the summary fields already on
// a dashboard card. Swap this for real per-hostel data (rooms, facilities,
// photos, contact info) once a shared Hostel model / backend exists — for
// now it lets tapping a card open a populated detail screen instead of
// nothing.
Map<String, dynamic> _demoHostelDetail({
  required String name,
  required String location,
  required String price,
  required String type,
  required String rating,
}) {
  final priceNum = int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 8000;
  return {
    'name': name,
    'city': location,
    'address': location,
    'type': type,
    'rating': double.tryParse(rating) ?? 4.0,
    'reviewCount': 20,
    'photos': <String>[],
    'facilities': ['WiFi', 'Meals', 'CCTV'],
    'phone': '+92 300 0000000',
    'whatsapp': '+92 300 0000000',
    'inAppChat': true,
    'rooms': [
      {
        'number': '1',
        'bookingType': 'Room',
        'roomType': 2,
        'availableSeats': 2,
        'attachedWashroom': true,
        'price': priceNum,
        'advance': priceNum,
        'vacant': true,
      },
    ],
  };
}

void _openHostelDetail(
    BuildContext context, {
      required String name,
      required String location,
      required String price,
      required String type,
      required String rating,
    }) {
  // Routed through AppRouter/AppRoutes.hostelDetail like every other screen
  // in this app, rather than a direct Navigator.push — see app_router.dart.
  NavigationService.navigateTo(
    AppRoutes.hostelDetail,
    arguments: _demoHostelDetail(
      name: name,
      location: location,
      price: price,
      type: type,
      rating: rating,
    ),
  );
}

class SeekerDashboard extends StatelessWidget {
  const SeekerDashboard({super.key});

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
              // ── Header ──────────────────────────────────────────
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
                          color: fg.withOpacity(0.6),
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
                    backgroundColor: maroon.withOpacity(0.15),
                    child: const Icon(Icons.person, color: maroon, size: 26),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Search Bar ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: maroon.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: maroon.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: maroon.withOpacity(0.5)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search hostels in your city...',
                          hintStyle: TextStyle(
                            color: maroon.withOpacity(0.4),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Icon(Icons.tune, color: maroon.withOpacity(0.5)),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── AI Recommendations ───────────────────────────────
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
                    onTap: () {
                      NavigationService.navigateTo(AppRoutes.hostelList);
                    },
                    child: Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 13,
                        color: maroon.withOpacity(0.6),
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
                  color: fg.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 14),

              // AI Recommendation Cards (horizontal scroll)
              SizedBox(
                height: 190,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _HostelCard(
                      name: 'Green View Hostel',
                      location: 'Gulberg, Lahore',
                      price: 'Rs. 8,000/mo',
                      type: 'Boys',
                      rating: '4.5',
                      matchPercent: '94%',
                      onTap: () => _openHostelDetail(
                        context,
                        name: 'Green View Hostel',
                        location: 'Gulberg, Lahore',
                        price: 'Rs. 8,000/mo',
                        type: 'Boys',
                        rating: '4.5',
                      ),
                    ),
                    _HostelCard(
                      name: 'Sunrise Boys Hostel',
                      location: 'Model Town, Lahore',
                      price: 'Rs. 7,500/mo',
                      type: 'Boys',
                      rating: '4.2',
                      matchPercent: '88%',
                      onTap: () => _openHostelDetail(
                        context,
                        name: 'Sunrise Boys Hostel',
                        location: 'Model Town, Lahore',
                        price: 'Rs. 7,500/mo',
                        type: 'Boys',
                        rating: '4.2',
                      ),
                    ),
                    _HostelCard(
                      name: 'Al-Noor Girls Hostel',
                      location: 'Johar Town, Lahore',
                      price: 'Rs. 9,000/mo',
                      type: 'Girls',
                      rating: '4.7',
                      matchPercent: '81%',
                      onTap: () => _openHostelDetail(
                        context,
                        name: 'Al-Noor Girls Hostel',
                        location: 'Johar Town, Lahore',
                        price: 'Rs. 9,000/mo',
                        type: 'Girls',
                        rating: '4.7',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Find Your Hostel ─────────────────────────────────
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
                onTap: () {
                  NavigationService.navigateTo(AppRoutes.hostelList);
                },
              ),
              const SizedBox(height: 12),
              // Browse All Button
              _ActionCard(
                title: 'Browse All Hostels',
                subtitle: 'See all available hostels in your city',
                icon: Icons.location_city_outlined,
                isDark: isDark,
                onTap: () {
                  NavigationService.navigateTo(AppRoutes.hostelList);
                },
              ),

              const SizedBox(height: 28),

              // ── All Hostels List ─────────────────────────────────
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
                    '12 hostels',
                    style: TextStyle(
                      fontSize: 12,
                      color: fg.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _HostelListTile(
                name: 'Green View Hostel',
                location: 'Gulberg, Lahore',
                price: 'Rs. 8,000/mo',
                type: 'Boys',
                rating: '4.5',
                onTap: () => _openHostelDetail(
                  context,
                  name: 'Green View Hostel',
                  location: 'Gulberg, Lahore',
                  price: 'Rs. 8,000/mo',
                  type: 'Boys',
                  rating: '4.5',
                ),
              ),
              _HostelListTile(
                name: 'Sunrise Boys Hostel',
                location: 'Model Town, Lahore',
                price: 'Rs. 7,500/mo',
                type: 'Boys',
                rating: '4.2',
                onTap: () => _openHostelDetail(
                  context,
                  name: 'Sunrise Boys Hostel',
                  location: 'Model Town, Lahore',
                  price: 'Rs. 7,500/mo',
                  type: 'Boys',
                  rating: '4.2',
                ),
              ),
              _HostelListTile(
                name: 'Al-Noor Girls Hostel',
                location: 'Johar Town, Lahore',
                price: 'Rs. 9,000/mo',
                type: 'Girls',
                rating: '4.7',
                onTap: () => _openHostelDetail(
                  context,
                  name: 'Al-Noor Girls Hostel',
                  location: 'Johar Town, Lahore',
                  price: 'Rs. 9,000/mo',
                  type: 'Girls',
                  rating: '4.7',
                ),
              ),
              _HostelListTile(
                name: 'City Comfort Hostel',
                location: 'DHA Phase 5, Lahore',
                price: 'Rs. 11,000/mo',
                type: 'Mixed',
                rating: '4.0',
                onTap: () => _openHostelDetail(
                  context,
                  name: 'City Comfort Hostel',
                  location: 'DHA Phase 5, Lahore',
                  price: 'Rs. 11,000/mo',
                  type: 'Mixed',
                  rating: '4.0',
                ),
              ),
            ],
          ),
        ),
      ),

      // ── Bottom Nav ───────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5),
        selectedItemColor: maroon,
        unselectedItemColor: maroon.withOpacity(0.4),
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
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

// ── Horizontal Hostel Card ────────────────────────────────────────────────────
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
          color: maroon.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: maroon.withOpacity(0.25)),
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
                Icon(Icons.location_on_outlined, size: 12, color: maroon.withOpacity(0.6)),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(fontSize: 11, color: maroon.withOpacity(0.6)),
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
                color: maroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                type,
                style: TextStyle(fontSize: 11, color: maroon.withOpacity(0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Card ──────────────────────────────────────────────────────────────
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
          color: maroon.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: maroon.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: maroon.withOpacity(0.12),
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
                    style: TextStyle(fontSize: 12, color: maroon.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: maroon.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

// ── Hostel List Tile ─────────────────────────────────────────────────────────
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
          color: maroon.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: maroon.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: maroon.withOpacity(0.12),
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
                      Icon(Icons.location_on_outlined, size: 12, color: maroon.withOpacity(0.5)),
                      const SizedBox(width: 2),
                      Text(
                        location,
                        style: TextStyle(fontSize: 12, color: maroon.withOpacity(0.5)),
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
                    color: maroon.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(fontSize: 10, color: maroon.withOpacity(0.8)),
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