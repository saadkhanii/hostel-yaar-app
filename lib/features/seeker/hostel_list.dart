import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';
import '../../core/data/dummy_hostels.dart';

// ── Hostel List / Search Screen ────────────────────────────────────────────
// Reached from the Seeker Dashboard via "Browse All Hostels" / "Tell AI What
// You Need" / "See all". Takes an optional initial search query as its
// `arguments` string (kept nullable/loose to match how other screens in this
// app pass arguments through NavigationService).
//
// Dummy data below matches the `hostel` map shape expected by
// HostelDetailScreen (see hostel_detail.dart) so tapping a result opens a
// fully populated detail screen already. Swap `DummyHostels.all` for a real
// Firestore-backed list once the backend exists.
class HostelListScreen extends StatefulWidget {
  final String? initialQuery;

  const HostelListScreen({super.key, this.initialQuery});

  @override
  State<HostelListScreen> createState() => _HostelListScreenState();
}

enum _PriceFilter { all, under8k, from8kTo12k, above12k }

enum _SortOption { recommended, priceLowHigh, priceHighLow, rating }

class _HostelListScreenState extends State<HostelListScreen> {
  static const maroon = Color(0xFF800020);

  late final TextEditingController _searchCtrl;
  String _selectedType = 'All';
  _PriceFilter _priceFilter = _PriceFilter.all;
  _SortOption _sortOption = _SortOption.recommended;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialQuery ?? '');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }


  bool _matchesPriceFilter(int price) {
    switch (_priceFilter) {
      case _PriceFilter.all:
        return true;
      case _PriceFilter.under8k:
        return price < 8000;
      case _PriceFilter.from8kTo12k:
        return price >= 8000 && price <= 12000;
      case _PriceFilter.above12k:
        return price > 12000;
    }
  }

  List<Map<String, dynamic>> get _filteredHostels {
    final query = _searchCtrl.text.trim().toLowerCase();

    final results = DummyHostels.all.where((h) {
      final matchesQuery = query.isEmpty ||
          (h['name'] as String).toLowerCase().contains(query) ||
          (h['city'] as String).toLowerCase().contains(query);
      final matchesType = _selectedType == 'All' || h['type'] == _selectedType;
      final matchesPrice = _matchesPriceFilter(DummyHostels.startingPrice(h));
      return matchesQuery && matchesType && matchesPrice;
    }).toList();

    switch (_sortOption) {
      case _SortOption.recommended:
        results.sort((a, b) => (b['matchPercent'] as int).compareTo(a['matchPercent'] as int));
        break;
      case _SortOption.priceLowHigh:
        results.sort((a, b) => DummyHostels.startingPrice(a).compareTo(DummyHostels.startingPrice(b)));
        break;
      case _SortOption.priceHighLow:
        results.sort((a, b) => DummyHostels.startingPrice(b).compareTo(DummyHostels.startingPrice(a)));
        break;
      case _SortOption.rating:
        results.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
        break;
    }
    return results;
  }

  bool get _hasActiveFilters => _selectedType != 'All' || _priceFilter != _PriceFilter.all;

  void _openHostelDetail(Map<String, dynamic> hostel) {
    NavigationService.navigateTo(AppRoutes.hostelDetail, arguments: hostel);
  }

  // ── Sort / Filter bottom sheet ─────────────────────────────────────────
  void _showFilterSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _PriceFilter tempPrice = _priceFilter;
    _SortOption tempSort = _sortOption;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort & Filter',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: maroon),
              ),
              const SizedBox(height: 20),

              const Text('Price Range', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: maroon)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ('All', _PriceFilter.all),
                  ('Under Rs. 8,000', _PriceFilter.under8k),
                  ('Rs. 8,000 – 12,000', _PriceFilter.from8kTo12k),
                  ('Above Rs. 12,000', _PriceFilter.above12k),
                ].map((entry) {
                  final (label, value) = entry;
                  final selected = tempPrice == value;
                  return GestureDetector(
                    onTap: () => setSheetState(() => tempPrice = value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? maroon : maroon.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? maroon : maroon.withOpacity(0.25)),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : maroon,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              const Text('Sort By', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: maroon)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ('Recommended', _SortOption.recommended),
                  ('Price: Low to High', _SortOption.priceLowHigh),
                  ('Price: High to Low', _SortOption.priceHighLow),
                  ('Top Rated', _SortOption.rating),
                ].map((entry) {
                  final (label, value) = entry;
                  final selected = tempSort == value;
                  return GestureDetector(
                    onTap: () => setSheetState(() => tempSort = value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? maroon : maroon.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? maroon : maroon.withOpacity(0.25)),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : maroon,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 26),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: maroon),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setSheetState(() {
                          tempPrice = _PriceFilter.all;
                          tempSort = _SortOption.recommended;
                        });
                      },
                      child: const Text('Reset', style: TextStyle(color: maroon)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: maroon,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          _priceFilter = tempPrice;
                          _sortOption = tempSort;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Apply',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : const Color(0xFF800020);
    final results = _filteredHostels;

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
          'Find Hostels',
          style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Search + Filter row ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
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
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(fontSize: 14, color: maroon),
                              decoration: InputDecoration(
                                hintText: 'Search by name or area...',
                                hintStyle: TextStyle(color: maroon.withOpacity(0.4), fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() => _searchCtrl.clear()),
                              child: Icon(Icons.close, size: 18, color: maroon.withOpacity(0.5)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _hasActiveFilters ? maroon : maroon.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: maroon.withOpacity(_hasActiveFilters ? 1 : 0.2)),
                      ),
                      child: Icon(
                        Icons.tune,
                        color: _hasActiveFilters ? Colors.white : maroon.withOpacity(0.6),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Type filter chips ────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: ['All', 'Boys', 'Girls', 'Mixed'].map((type) {
                  final selected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? maroon : maroon.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? maroon : maroon.withOpacity(0.25)),
                        ),
                        child: Text(
                          type,
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

            const SizedBox(height: 12),

            // ── Result count ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${results.length} hostel${results.length == 1 ? '' : 's'} found',
                    style: TextStyle(fontSize: 12, color: fg.withOpacity(0.5)),
                  ),
                  if (_hasActiveFilters)
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedType = 'All';
                        _priceFilter = _PriceFilter.all;
                      }),
                      child: Text(
                        'Clear filters',
                        style: TextStyle(fontSize: 12, color: maroon.withOpacity(0.7), decoration: TextDecoration.underline),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Results list ──────────────────────────────────────────
            Expanded(
              child: results.isEmpty
                  ? _buildEmptyState(fg)
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: results.length,
                itemBuilder: (context, i) {
                  final hostel = results[i];
                  return _HostelResultCard(
                    hostel: hostel,
                    startingPrice: DummyHostels.startingPrice(hostel),
                    hasVacancy: DummyHostels.hasVacancy(hostel),
                    onTap: () => _openHostelDetail(hostel),
                  );
                },
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
            Icon(Icons.search_off, size: 52, color: fg.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No hostels match your search',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fg.withOpacity(0.8)),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different keyword or adjust your filters.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: fg.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hostel Result Card ──────────────────────────────────────────────────────
class _HostelResultCard extends StatelessWidget {
  final Map<String, dynamic> hostel;
  final int startingPrice;
  final bool hasVacancy;
  final VoidCallback onTap;

  const _HostelResultCard({
    required this.hostel,
    required this.startingPrice,
    required this.hasVacancy,
    required this.onTap,
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
          color: maroon.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: maroon.withOpacity(0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: maroon.withOpacity(0.12),
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
                      Row(
                        children: [
                          const Icon(Icons.star, size: 13, color: maroon),
                          const SizedBox(width: 2),
                          Text(
                            (hostel['rating'] as double).toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, color: maroon, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
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
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: hasVacancy ? const Color(0xFF2E7D32).withOpacity(0.12) : Colors.orange.withOpacity(0.15),
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'From Rs. ${startingPrice.toString()}/mo',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: maroon),
                      ),
                      Text(
                        '${facilities.length} amenities',
                        style: TextStyle(fontSize: 11, color: maroon.withOpacity(0.5)),
                      ),
                    ],
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