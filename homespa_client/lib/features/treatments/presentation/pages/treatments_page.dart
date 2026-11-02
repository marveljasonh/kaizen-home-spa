import '../../../../core/i18n/material_i18n.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/florian_text.dart';
import '../../domain/entities/treatment_category.dart';
import '../providers/treatments_providers.dart';
import '../widgets/cart_glass_button.dart';
import '../widgets/category_treatments_view.dart';

// ── Assets exported from Figma (kaizen › Services, node 451:376) ─────────────
const String _kCategoriesBg = 'assets/images/treatments/categories_bg.png';

// ── Figma layout values (402pt-wide frame) ───────────────────────────────────
const double _kGutter = 30;
const double _kHeaderTop = 77;
const double _kHeaderHeight = 49;
const double _kHeaderGap = 33; // 159 − (77 + 49)
const double _kCardGap = 26.84;
const double _kBottomPad = 26.16; // with the trailing card gap: 53 above navbar
const double _kCardDesignHeight = 170.439;
// Below this the title/subtitle get hard to read — fall back to scrolling.
const double _kCardMinHeight = 112;

/// Card order and Indonesian subtitles from the design. Categories not listed
/// here are appended after these, without a subtitle.
const Map<String, String> _kCategorySubtitles = {
  'Massage': 'Treatment Pemijatan',
  'Combo Massage': 'Paket Pijat Kombinasi',
  'Mom & Baby': 'Perawatan Ibu & Bayi',
  'Scrub, Nails & Hair': 'Perawatan Lulur, Kuku & Rambut',
};

/// Figma: Florian Regular, underlined. [scale] shrinks it with the card.
TextStyle _categoryTitleStyle(double scale) => TextStyle(
  fontFamily: 'Florian',
  fontSize: 50.709 * scale,
  fontWeight: FontWeight.w400,
  color: Colors.white,
  height: 40.04 / 50.709,
  decoration: TextDecoration.underline,
  decorationColor: Colors.white,
  leadingDistribution: TextLeadingDistribution.even,
);

class TreatmentsPage extends ConsumerStatefulWidget {
  const TreatmentsPage({super.key});

  @override
  ConsumerState<TreatmentsPage> createState() => _TreatmentsPageState();
}

class _TreatmentsPageState extends ConsumerState<TreatmentsPage> {
  void _backToCategories() =>
      ref.read(selectedCategoryIdProvider.notifier).select(null);

  void _applyPendingName(List<TreatmentCategory> categories) {
    final pending = ref.read(pendingCategoryNameProvider);
    if (pending == null) return;
    // Partial match handles 'Hot Stone' → 'Hot Stone Therapy' etc.
    final match = categories.where((c) {
      final cn = c.name.toLowerCase();
      final pn = pending.toLowerCase();
      return cn.contains(pn) || pn.contains(cn);
    }).firstOrNull;
    ref.read(selectedCategoryIdProvider.notifier).select(match?.id);
    ref.read(pendingCategoryNameProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedId = ref.watch(selectedCategoryIdProvider);

    // Resolve a category requested from elsewhere (e.g. Home), whether it
    // arrives before or after the categories finish loading.
    ref.listen(pendingCategoryNameProvider, (_, next) {
      if (next != null) categoriesAsync.whenData(_applyPendingName);
    });
    if (ref.read(pendingCategoryNameProvider) != null &&
        categoriesAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _applyPendingName(categoriesAsync.requireValue),
      );
    }

    final showCategories = selectedId == null;
    final selected = (categoriesAsync.valueOrNull ?? const [])
        .where((c) => c.id == selectedId)
        .firstOrNull;

    return PopScope(
      canPop: showCategories,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToCategories();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          // Figma: Services uses a photo backdrop; Massage uses the page colour.
          backgroundColor: AppColors.tabPage,
          body: showCategories
              ? const _CategorySelectionView()
              : CategoryTreatmentsView(
                  category: selected,
                  categoryId: selectedId,
                  onBack: _backToCategories,
                ),
        ),
      ),
    );
  }
}

// ── Category selection (Figma: Services) ─────────────────────────────────────

class _CategorySelectionView extends ConsumerWidget {
  const _CategorySelectionView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFD9D9D9)),
        Image.asset(_kCategoriesBg, fit: BoxFit.cover),
        // Gradient: clear until 13.385% → 85% black at bottom.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0xD9000000)],
              stops: [0.13385, 1.0],
            ),
          ),
        ),
        RefreshIndicator(
          color: AppColors.fg,
          backgroundColor: AppColors.card,
          onRefresh: () async => ref.invalidate(categoriesProvider),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Shrink cards so all categories fit the viewport (down to a
              // readable minimum, past which the list scrolls again).
              double cardHeight(int count) {
                final available =
                    constraints.maxHeight -
                    _kHeaderTop -
                    _kHeaderHeight -
                    _kHeaderGap -
                    _kBottomPad -
                    _kCardGap * count; // trailing gap after every card
                return (available / count).clamp(
                  _kCardMinHeight,
                  _kCardDesignHeight,
                );
              }

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                // Header top is 77 from the screen top; last card ends 53
                // above the nav bar (26.84 of that is the trailing card gap).
                padding: const EdgeInsets.fromLTRB(
                  _kGutter,
                  _kHeaderTop,
                  _kGutter,
                  _kBottomPad,
                ),
                children: [
                  const _CategoryHeader(),
                  const SizedBox(height: _kHeaderGap),
                  ...categoriesAsync
                      .when(
                        loading: () => List.generate(
                          3,
                          (i) =>
                              _CategoryCard.skeleton(height: cardHeight(3)),
                        ),
                        error: (_, __) => [
                          _CategoryError(
                            onRetry: () => ref.invalidate(categoriesProvider),
                          ),
                        ],
                        data: (categories) {
                          final sorted = _sortForDesign(categories);
                          final height = cardHeight(sorted.length);
                          return [
                            for (final c in sorted)
                              _CategoryCard(
                                title: c.name,
                                subtitle: _kCategorySubtitles[c.name],
                                height: height,
                                onTap: () => ref
                                    .read(selectedCategoryIdProvider.notifier)
                                    .select(c.id),
                              ),
                          ];
                        },
                      )
                      .expand(
                        (card) => [card, const SizedBox(height: _kCardGap)],
                      ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  static List<TreatmentCategory> _sortForDesign(List<TreatmentCategory> cs) {
    final order = _kCategorySubtitles.keys.toList();
    int rank(TreatmentCategory c) {
      final i = order.indexOf(c.name);
      return i == -1 ? order.length : i;
    }

    return [...cs]..sort((a, b) => rank(a).compareTo(rank(b)));
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kaizen Mobile Spa’s',
                style: GoogleFonts.montserrat(
                  fontSize: 15.273,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 19.296 / 15.273,
                ).copyWith(leadingDistribution: TextLeadingDistribution.even),
              ),
              const SizedBox(height: 7.584), // 103.88 − (77 + 19.296)
              const Text(
                'Treatments',
                style: TextStyle(
                  fontFamily: 'CalSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 30,
                  color: Colors.white,
                  height: 19.296 / 30,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
              ),
            ],
          ),
        ),
        const CartGlassButton(),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final double height;
  final VoidCallback? onTap;

  const _CategoryCard({
    required String this.title,
    required this.subtitle,
    required this.height,
    required VoidCallback this.onTap,
  });

  const _CategoryCard.skeleton({required this.height})
    : title = null,
      subtitle = null,
      onTap = null;

  static const double _border = 0.5;

  @override
  Widget build(BuildContext context) {
    // Figma positions/type assume a 170.439pt card; scale with the height.
    final scale = height / _kCardDesignHeight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xBF353A30), // #353A30 @ 75%
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.50),
            width: _border,
          ),
        ),
        child: title == null
            ? null
            : Stack(
                children: [
                  Positioned(
                    top: 52.22 * scale - _border,
                    left: 16,
                    right: 16,
                    // Long category names shrink to fit rather than clip.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: FlorianText(
                        title!,
                        textAlign: TextAlign.center,
                        style: _categoryTitleStyle(scale),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  if (subtitle != null)
                    Positioned(
                      top: 103.64 * scale - _border,
                      left: 16,
                      right: 16,
                      child: Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            GoogleFonts.montserrat(
                              fontSize: 16.324 * scale,
                              fontWeight: FontWeight.w300,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              height: 12.89 / 16.324,
                            ).copyWith(
                              leadingDistribution: TextLeadingDistribution.even,
                            ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _CategoryError extends StatelessWidget {
  final VoidCallback onRetry;
  const _CategoryError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Text(
          'Could not load categories',
          style: GoogleFonts.montserrat(fontSize: 14, color: Colors.white),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(
            'Retry',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFFAF7F2), // on the photo backdrop
            ),
          ),
        ),
      ],
    );
  }
}
