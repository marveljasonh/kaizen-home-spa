import 'package:flutter/material.dart';
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

/// Card order and Indonesian subtitles from the design. Categories not listed
/// here are appended after these, without a subtitle.
const Map<String, String> _kCategorySubtitles = {
  'Massage': 'Treatment Pemijatan',
  'Hair Care': 'Treatment Rambut',
  'Nail Care': 'Treatment Kuku',
};

/// Figma: Florian Regular, underlined.
TextStyle _categoryTitleStyle() => const TextStyle(
  fontFamily: 'Florian',
  fontSize: 50.709,
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
          // Figma: Services uses a photo backdrop; Massage uses #4E523B.
          backgroundColor: AppColors.darkOliveLight,
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
          color: AppColors.cream,
          backgroundColor: AppColors.darkOliveLight,
          onRefresh: () async => ref.invalidate(categoriesProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            // Header top is 77 from the screen top; last card ends 53 above
            // the nav bar (26.84 of that comes from the trailing card gap).
            padding: const EdgeInsets.fromLTRB(_kGutter, 77, _kGutter, 26.16),
            children: [
              const _CategoryHeader(),
              const SizedBox(height: 33), // 159 − (77 + 49)
              ...categoriesAsync
                  .when(
                    loading: () =>
                        List.generate(3, (i) => const _CategoryCard.skeleton()),
                    error: (_, __) => [
                      _CategoryError(
                        onRetry: () => ref.invalidate(categoriesProvider),
                      ),
                    ],
                    data: (categories) => [
                      for (final c in _sortForDesign(categories))
                        _CategoryCard(
                          title: c.name,
                          subtitle: _kCategorySubtitles[c.name],
                          onTap: () => ref
                              .read(selectedCategoryIdProvider.notifier)
                              .select(c.id),
                        ),
                    ],
                  )
                  .expand((card) => [card, const SizedBox(height: 26.84)]),
            ],
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
  final VoidCallback? onTap;

  const _CategoryCard({
    required String this.title,
    required this.subtitle,
    required VoidCallback this.onTap,
  });

  const _CategoryCard.skeleton() : title = null, subtitle = null, onTap = null;

  static const double _height = 170.439;
  static const double _border = 0.5;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _height,
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
                    top: 52.22 - _border,
                    left: 16,
                    right: 16,
                    // Long category names shrink to fit rather than clip.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: FlorianText(
                        title!,
                        textAlign: TextAlign.center,
                        style: _categoryTitleStyle(),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  if (subtitle != null)
                    Positioned(
                      top: 103.64 - _border,
                      left: 16,
                      right: 16,
                      child: Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            GoogleFonts.montserrat(
                              fontSize: 16.324,
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
              color: AppColors.cream,
            ),
          ),
        ),
      ],
    );
  }
}
