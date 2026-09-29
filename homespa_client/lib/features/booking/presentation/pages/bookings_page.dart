import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../treatments/presentation/widgets/glass_icon_button.dart';
import '../../domain/entities/order_filters.dart';
import '../../domain/entities/order_summary.dart';
import '../providers/order_history_providers.dart';
import '../widgets/order_card.dart';
import '../widgets/order_filter_sheet.dart';

// History / Activities (Bookings tab; Home → Recent Orders → "View All").
// The hero reuses the Home hero (Figma 503:268) values; the cards are the
// shared OrderCard at 341×228.87 (Figma 1637:4949).

const String _kHeroImage = 'assets/images/home/hero.png';
const String _kIconSearch = 'assets/icons/search_24.svg';

const double _kGutterLeft = 30;
const double _kGutterRight = 31;
const double _kCardGap = 14;

/// Gap between the Search and Filter buttons (not yet checked against Figma).
const double _kHeaderButtonGap = 10;
const double _kHeroRadius = 40;
const double _kTabsTop = 150;
const double _kTabHeight = 54;

/// 70px taller than the tabs need (was 33 below them), so the hero runs on
/// under the first order card.
const double _kHeroHeight = _kTabsTop + _kTabHeight + 33 + 70;

/// Tabs → first order card (Figma: 25). The hero runs on under the card.
const double _kTabsToCards = 25;

enum BookingsTab {
  upcoming('Upcoming', 'No upcoming bookings right now.'),
  past('Past', 'You haven’t booked any treatments yet.');

  const BookingsTab(this.label, this.emptyMessage);
  final String label;
  final String emptyMessage;

  /// Upcoming: status NOT IN (completed, cancelled). Past: IN.
  bool matches(OrderSummary o) => switch (this) {
    BookingsTab.upcoming => !o.isCompleted && !o.isCancelled,
    BookingsTab.past => o.isCompleted || o.isCancelled,
  };

  /// `?tab=past` (Home "View All"); older `?filter=completed|cancelled` too.
  static BookingsTab fromQuery(Map<String, String> query) {
    final tab = query['tab'];
    final filter = query['filter'];
    if (tab == 'past' || filter == 'completed' || filter == 'cancelled') {
      return BookingsTab.past;
    }
    return BookingsTab.upcoming;
  }
}

class BookingsPage extends ConsumerStatefulWidget {
  final BookingsTab initialTab;
  const BookingsPage({super.key, this.initialTab = BookingsTab.upcoming});

  @override
  ConsumerState<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingsPage> {
  late BookingsTab _tab = widget.initialTab;
  final _searchController = TextEditingController();
  final _scroll = ScrollController();
  bool _searching = false;
  String _query = '';
  OrderFilters _filters = OrderFilters.none;

  @override
  void didUpdateWidget(covariant BookingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-entering via "View All" while the tab is alive switches to Past.
    if (oldWidget.initialTab != widget.initialTab) _tab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toggleSearch() => setState(() {
    _searching = !_searching;
    if (!_searching) {
      _searchController.clear();
      _query = '';
    }
  });

  Future<void> _openFilters() async {
    final result = await showOrderFilterSheet(context, _filters);
    if (result != null && mounted) setState(() => _filters = result);
  }

  bool _matchesQuery(OrderSummary o) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return o.code.toLowerCase().contains(q) ||
        o.items.any((i) => i.treatmentName.toLowerCase().contains(q));
  }

  Future<void> _refresh() async {
    ref.invalidate(orderHistoryProvider);
    try {
      await ref.read(orderHistoryProvider.future);
    } catch (_) {
      // The error state is shown by the list itself.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Signed-out users are redirected to login by the router; the provider
    // also returns an empty list without a user.
    final ordersAsync = ref.watch(orderHistoryProvider);
    // Treatment ids for the selected categories (resolved from the catalog).
    final categoryTreatmentIds = _filters.categoryIds.isEmpty
        ? null
        : ref.watch(
            categoryTreatmentIdsProvider(categoryKeyOf(_filters.categoryIds)),
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkOliveLight, // #4E523B
        body: RefreshIndicator(
          color: AppColors.cream,
          backgroundColor: AppColors.darkOlive,
          onRefresh: _refresh,
          // Layered hero: the photo/gradient layer sits *behind* the scroll
          // view and moves with it, so the order cards slide over its lower
          // edge. Title, buttons and tabs scroll in the first sliver on top.
          child: Stack(
            children: [
              ListenableBuilder(
                listenable: _scroll,
                builder: (context, child) {
                  final offset = _scroll.hasClients ? _scroll.offset : 0.0;
                  return Transform.translate(
                    offset: Offset(0, -offset.clamp(0.0, _kHeroHeight + 40)),
                    child: child,
                  );
                },
                child: const _HeroBackground(),
              ),
              CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    // Ends 25px below the tabs, so the cards start over the hero.
                    child: SizedBox(
                      height: _kTabsTop + _kTabHeight + _kTabsToCards,
                      child: _HeroContent(
                        tab: _tab,
                        onTab: (t) => setState(() => _tab = t),
                        onSearch: _toggleSearch,
                        onFilter: _openFilters,
                        activeFilterCount: _filters.activeCount,
                      ),
                    ),
                  ),
                  if (_searching)
                    SliverToBoxAdapter(
                      child: _SearchField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v.trim()),
                        onClose: _toggleSearch,
                      ),
                    ),
                  ...ordersAsync.when(
                    loading: () => [const _SkeletonSliver()],
                    error: (_, __) => [
                      _MessageSliver(
                        'We couldn’t load your orders right now.',
                        onRetry: _refresh,
                      ),
                    ],
                    data: (orders) {
                      if (categoryTreatmentIds != null &&
                          !categoryTreatmentIds.hasValue) {
                        return categoryTreatmentIds.hasError
                            ? [
                                _MessageSliver(
                                  'We couldn’t apply the category filter.',
                                  onRetry: _refresh,
                                ),
                              ]
                            : [const _SkeletonSliver()];
                      }
                      final treatmentIds = categoryTreatmentIds?.value;
                      final visible = orders
                          .where(_tab.matches)
                          .where(_matchesQuery)
                          .where((o) => _filters.matchesDate(o.scheduledAt))
                          .where(
                            (o) =>
                                treatmentIds == null ||
                                o.items.any(
                                  (i) => treatmentIds.contains(i.treatmentId),
                                ),
                          )
                          .toList();
                      if (visible.isEmpty) {
                        return [
                          _PaddedSliver(
                            SliverToBoxAdapter(
                              child: OrderEmptyState(
                                message: _query.isNotEmpty
                                    ? 'No orders match “$_query”.'
                                    : !_filters.isEmpty
                                    ? 'No orders match these filters.'
                                    : _tab.emptyMessage,
                              ),
                            ),
                          ),
                        ];
                      }
                      // Lazily built, so long histories scroll smoothly.
                      return [
                        _PaddedSliver(
                          SliverList.separated(
                            itemCount: visible.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: _kCardGap),
                            // Full width minus gutters → 341 × 228.87 at 402pt.
                            itemBuilder: (_, i) => OrderCard(
                              key: ValueKey(visible[i].id),
                              order: visible[i],
                              showStatus: true,
                            ),
                          ),
                        ),
                      ];
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 25)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────

const _kHeroCorners = BorderRadius.only(
  bottomLeft: Radius.circular(_kHeroRadius),
  bottomRight: Radius.circular(_kHeroRadius),
);

/// Hero photo layer (Home hero values: photo, 33%→77% gradient, 40px bottom
/// corners, shadows). Painted behind the scroll view.
class _HeroBackground extends StatelessWidget {
  const _HeroBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kHeroHeight,
      decoration: const BoxDecoration(
        borderRadius: _kHeroCorners,
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000), // 15%
            blurRadius: 9.4,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x54000000), // 33%
            blurRadius: 26.3,
            spreadRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _kHeroCorners,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(_kHeroImage, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x54000000), Color(0xC4000000)], // 33% → 77%
                ),
              ),
            ),
            // Approximates Figma's inset shadow (0 3 7.8 4, white 12%).
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: _kHeroCorners,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero foreground: "History" / "Activities", search, and the tabs.
class _HeroContent extends StatelessWidget {
  final BookingsTab tab;
  final ValueChanged<BookingsTab> onTab;
  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final int activeFilterCount;

  const _HeroContent({
    required this.tab,
    required this.onTab,
    required this.onSearch,
    required this.onFilter,
    required this.activeFilterCount,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 63,
          left: _kGutterLeft,
          child: Text(
            'History',
            style: GoogleFonts.montserrat(
              fontSize: 25,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 31.584 / 25,
            ),
          ),
        ),
        const Positioned(
          top: 98,
          left: _kGutterLeft,
          child: Text(
            'Activities',
            style: TextStyle(
              fontFamily: 'CalSans',
              fontWeight: FontWeight.w600,
              fontSize: 40,
              color: Colors.white,
              height: 31.584 / 40,
            ),
          ),
        ),
        Positioned(
          top: 72,
          right: _kGutterRight,
          child: Row(
            children: [
              GlassIconButton(
                icon: Icons.tune_rounded,
                iconSize: 24,
                fillAlpha: 0.20,
                badgeCount: activeFilterCount,
                onTap: onFilter,
              ),
              const SizedBox(width: _kHeaderButtonGap),
              GlassIconButton(
                svgAsset: _kIconSearch,
                iconSize: 25.565,
                iconOffset: const Offset(11.72, 11.72),
                fillAlpha: 0.20,
                onTap: onSearch,
              ),
            ],
          ),
        ),
        Positioned(
          top: _kTabsTop,
          left: _kGutterLeft,
          right: _kGutterRight,
          child: Row(
            children: [
              for (final t in BookingsTab.values) ...[
                if (t != BookingsTab.values.first) const SizedBox(width: 21),
                Expanded(
                  child: _TabPill(
                    label: t.label,
                    active: t == tab,
                    onTap: () => onTab(t),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Active: white with dark olive text. Inactive: olive with white text.
class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: active,
      button: true,
      child: Material(
        color: active ? Colors.white : AppColors.darkOliveLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onTap: onTap,
          child: SizedBox(
            height: _kTabHeight,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: active ? AppColors.darkOliveLight : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kGutterLeft, 16, _kGutterRight, 0),
      child: TextField(
        controller: controller,
        autofocus: true,
        onChanged: onChanged,
        cursorColor: Colors.white,
        style: GoogleFonts.montserrat(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search by treatment or order code',
          hintStyle: GoogleFonts.montserrat(
            fontSize: 14,
            color: AppColors.textOnDarkMuted,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.10),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          suffixIcon: IconButton(
            tooltip: 'Close search',
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: onClose,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ── Loading / message states ─────────────────────────────────────────────────

class _PaddedSliver extends StatelessWidget {
  final Widget sliver;
  const _PaddedSliver(this.sliver);

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(_kGutterLeft, 0, _kGutterRight, 0),
    sliver: sliver,
  );
}

class _SkeletonSliver extends StatelessWidget {
  const _SkeletonSliver();

  @override
  Widget build(BuildContext context) {
    return _PaddedSliver(
      SliverList.separated(
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: _kCardGap),
        itemBuilder: (_, __) => AspectRatio(
          aspectRatio: OrderCard.designWidth / OrderCard.designHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.darkOlive,
              borderRadius: BorderRadius.circular(4.603 * 341 / 222),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageSliver extends StatelessWidget {
  final String message;
  final Future<void> Function()? onRetry;
  const _MessageSliver(this.message, {this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _PaddedSliver(
      SliverToBoxAdapter(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: AppColors.textOnDarkMuted,
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text(
                  'Retry',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cream,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
