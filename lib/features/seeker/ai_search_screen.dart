import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';
import '../../core/services/ai_service.dart';

/// Free-text hostel search, powered by Gemini on the backend.
///
/// Flow:
///  1. User types (or taps an example chip to fill) a description.
///  2. We POST it to /ai/search. The backend extracts filters and
///     returns matching hostels + a one-line explanation.
///  3. We render filter chips (what the LLM understood), the
///     explanation, and the matching hostels.
///
/// Tapping a hostel opens the standard HostelDetail screen — same as
/// from the dashboard — so we don't duplicate detail UI.
class AiSearchScreen extends StatefulWidget {
  const AiSearchScreen({super.key});

  @override
  State<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends State<AiSearchScreen> {
  static const maroon = Color(0xFF800020);
  static const maroonDark = Color(0xFF5C0017);

  final _inputCtrl = TextEditingController();
  final _aiService = AiService();
  final _scrollCtrl = ScrollController();

  bool _loading = false;
  String? _errorText;
  AiSearchResult? _result;

  /// Example prompts shown as tappable chips. Tapping fills the input
  /// and runs the search immediately — this both teaches the user the
  /// kind of query the LLM handles well and gives them something to
  /// try without thinking.
  static const List<String> _examples = [
    'Boys hostel in Lahore under 15k with WiFi',
    'Girls hostel with meals and laundry',
    'Cheap seat with WiFi near university',
    'Single room under 20k in Karachi',
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _search([String? overrideQuery]) async {
    final query = (overrideQuery ?? _inputCtrl.text).trim();
    if (query.isEmpty || _loading) return;

    // If a chip was tapped, mirror its text into the field.
    if (overrideQuery != null) _inputCtrl.text = overrideQuery;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      final result = await _aiService.search(query);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });

      // Bounce back to the top so the user sees the chips + explanation
      // before the results list.
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
        _result = null;
      });
    }
  }

  void _openHostel(Map<String, dynamic> hostel) {
    NavigationService.navigateTo(AppRoutes.hostelDetail, arguments: hostel);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : maroon;
    final cardColor = isDark ? const Color(0xFF262B33) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: Column(                       // <-- no SafeArea wrapper
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(cardColor, isDark),
                  const SizedBox(height: 16),
                  _buildExamples(fg),
                  const SizedBox(height: 20),
                  if (_loading) _buildLoading(),
                  if (!_loading && _errorText != null) _buildError(fg),
                  if (!_loading && _errorText == null && _result == null)
                    _buildIntro(fg),
                  if (!_loading && _errorText == null && _result != null)
                    ..._buildResults(_result!, isDark, cardColor, fg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 8,
        16,
        14,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [maroon, maroonDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Search',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Describe what you\'re looking for',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────

  Widget _buildSearchBar(Color cardColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText:
                'e.g. "boys hostel in Lahore under 15k with wifi"',
                hintStyle: TextStyle(
                  color: maroon.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _loading ? null : () => _search(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _loading
                      ? [
                    maroon.withValues(alpha: 0.4),
                    maroonDark.withValues(alpha: 0.4),
                  ]
                      : const [maroon, maroonDark],
                ),
                shape: BoxShape.circle,
                boxShadow: _loading
                    ? null
                    : [
                  BoxShadow(
                    color: maroon.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _loading
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                  AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Examples strip ────────────────────────────────────────────────

  Widget _buildExamples(Color fg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try one of these',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _examples.map((ex) {
            return GestureDetector(
              onTap: _loading ? null : () => _search(ex),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: maroon.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: maroon.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  ex,
                  style: TextStyle(
                    fontSize: 12,
                    color: maroon.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── States: intro, loading, error ─────────────────────────────────

  Widget _buildIntro(Color fg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: maroon.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 36,
              color: maroon.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tell us what you need',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Write it like you\'d tell a friend. '
                'Budget, city, facilities, and the type of room all help.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: fg.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(maroon),
            ),
            SizedBox(height: 14),
            Text(
              'Thinking...',
              style: TextStyle(
                fontSize: 13,
                color: maroon,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(Color fg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 42,
              color: maroon.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Could not search',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorText!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: fg.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _search(),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: maroon,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Results ───────────────────────────────────────────────────────

  List<Widget> _buildResults(
      AiSearchResult result,
      bool isDark,
      Color cardColor,
      Color fg,
      ) {
    return [
      if (result.explanation.isNotEmpty) ...[
        Text(
          result.explanation,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fg,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
      ],
      if (_filterChips(result.filters).isNotEmpty) ...[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _filterChips(result.filters),
        ),
        const SizedBox(height: 20),
      ],
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            result.hostels.isEmpty
                ? 'No matches'
                : '${result.hostels.length} match${result.hostels.length == 1 ? '' : 'es'}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (result.hostels.isEmpty)
        _buildNoResults(fg)
      else
        ...result.hostels.map(
              (h) => _AiHostelTile(
            hostel: h,
            isDark: isDark,
            cardColor: cardColor,
            onTap: () => _openHostel(h),
          ),
        ),
    ];
  }

  Widget _buildNoResults(Color fg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: maroon.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_off,
            color: maroon.withValues(alpha: 0.5),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nothing matched. Try relaxing a filter — '
                  'a higher budget, a different city, or fewer facilities.',
              style: TextStyle(
                fontSize: 12,
                color: fg.withValues(alpha: 0.7),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build small pill widgets showing what the LLM understood.
  List<Widget> _filterChips(Map<String, dynamic> filters) {
    final chips = <String>[];

    if (filters['city'] != null && (filters['city'] as String).isNotEmpty) {
      chips.add(filters['city'] as String);
    }
    if (filters['type'] != null) {
      chips.add(filters['type'] as String);
    }
    if (filters['booking_type'] != null) {
      chips.add(filters['booking_type'] as String);
    }

    final minP = filters['min_price'] as int?;
    final maxP = filters['max_price'] as int?;
    if (minP != null && maxP != null) {
      chips.add('Rs. $minP – $maxP');
    } else if (maxP != null) {
      chips.add('Up to Rs. $maxP');
    } else if (minP != null) {
      chips.add('From Rs. $minP');
    }

    final facilities = (filters['facilities'] as List?)?.cast<String>() ?? [];
    chips.addAll(facilities);

    return chips.map((label) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: maroon.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: maroon.withValues(alpha: 0.85),
          ),
        ),
      );
    }).toList();
  }
}

// ── Result tile ────────────────────────────────────────────────────

/// Same visual language as the dashboard's hostel list tile, but
/// self-contained so we don't couple this screen to that file's
/// private widget.
class _AiHostelTile extends StatelessWidget {
  final Map<String, dynamic> hostel;
  final bool isDark;
  final Color cardColor;
  final VoidCallback onTap;

  const _AiHostelTile({
    required this.hostel,
    required this.isDark,
    required this.cardColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);

    final name = hostel['name'] as String? ?? '';
    final city = hostel['city'] as String? ?? '';
    final price = (hostel['startingPrice'] as int?) ?? 0;
    final type = hostel['type'] as String? ?? '';
    final hasVacancy = hostel['hasVacancy'] == true;
    final photos =
        (hostel['photos'] as List?)?.cast<String>() ?? const <String>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.18 : 0.04,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                _thumbnail(photos),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                          Expanded(
                            child: Text(
                              city,
                              style: TextStyle(
                                fontSize: 12,
                                color: maroon.withValues(alpha: 0.5),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Rs. $price/mo',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: maroon,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
                        color: maroon.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 10,
                          color: maroon.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: maroon.withValues(alpha: 0.35),
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

  Widget _thumbnail(List<String> photos) {
    const maroon = Color(0xFF800020);
    const double size = 56;

    if (photos.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: maroon.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.home_work_outlined,
          color: maroon.withValues(alpha: 0.5),
          size: 26,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        photos.first,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: size,
            height: size,
            color: maroon.withValues(alpha: 0.08),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(maroon),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stack) => Container(
          width: size,
          height: size,
          color: maroon.withValues(alpha: 0.1),
          child: Icon(
            Icons.broken_image_outlined,
            color: maroon.withValues(alpha: 0.35),
            size: 22,
          ),
        ),
      ),
    );
  }
}