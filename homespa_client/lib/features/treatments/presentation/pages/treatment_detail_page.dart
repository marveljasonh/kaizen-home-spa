import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/entities/treatment_duration.dart';
import '../providers/treatments_providers.dart';
import '../widgets/glass_icon_button.dart';

// ── Assets exported from Figma (kaizen › fullbodya, node 1626:4620) ───────────
const String _kHeroFallback = 'assets/images/treatments/detail_hero.png';
const String _kIconBack = 'assets/icons/chevron_left_33.svg';

// ── Figma values (402pt-wide frame) ──────────────────────────────────────────
const double _kSide = 29;
// Figma's content right edge is x 378 (cards and button), i.e. 24 from the
// right, while text starts 29 from the left.
const double _kSideRight = 24;
const double _kHeroMinHeight = 379;
const Color _kBg = Color(0xFF4E523B);
const Color _kBar = Color(0xFF313129);

/// Figma's "normal" line height for Montserrat (ascent + descent). Flutter's
/// default adds the font's line gap (~1.41), which drifts vertical spacing.
const double _kFigmaNormal = 1.219;

class TreatmentDetailPage extends ConsumerWidget {
  final String treatmentId;
  const TreatmentDetailPage({super.key, required this.treatmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treatmentAsync = ref.watch(treatmentDetailProvider(treatmentId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: treatmentAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.cream),
          ),
          error: (e, _) => _ErrorState(
            onRetry: () => ref.invalidate(treatmentDetailProvider(treatmentId)),
          ),
          data: (treatment) => _DetailBody(treatment: treatment),
        ),
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  final Treatment treatment;
  const _DetailBody({required this.treatment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedDurationIdProvider(treatment.id));
    final resolved = _resolveSelected(treatment, selectedId);
    final durations = [...treatment.durations]
      ..sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));

    void onAddToCart() {
      context
          .push(
            '/treatments/${treatment.id}/addons',
            extra: {'treatment': treatment, 'duration': resolved},
          )
          .then((_) {
            // Addon page dismissed (Skip or Add to Cart): return to the list,
            // where the snackbar shown from the addon page is visible.
            if (context.mounted) context.pop();
          });
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _Hero(treatment: treatment)),
                  SliverToBoxAdapter(
                    child: _TreatmentOptions(
                      treatment: treatment,
                      durations: durations,
                      selectedId: resolved?.id,
                      onSelected: (id) =>
                          ref
                                  .read(
                                    selectedDurationIdProvider(
                                      treatment.id,
                                    ).notifier,
                                  )
                                  .state =
                              id,
                    ),
                  ),
                ],
              ),
              // Back button stays put while the page scrolls under it.
              Positioned(
                top: 72,
                left: 30,
                child: GlassIconButton(
                  svgAsset: _kIconBack,
                  iconSize: 33,
                  iconOffset: const Offset(6.5, 8.5),
                  onTap: () => context.pop(),
                ),
              ),
            ],
          ),
        ),
        _CartBar(
          price: resolved?.price ?? treatment.displayPrice,
          onAddToCart: onAddToCart,
        ),
      ],
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final Treatment treatment;
  const _Hero({required this.treatment});

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(_kHeroFallback, fit: BoxFit.cover);
    final url = treatment.imageUrl;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _kHeroMinHeight),
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFFD9D9D9))),
          Positioned.fill(
            child: url != null && url.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => fallback,
                    errorWidget: (_, __, ___) => fallback,
                  )
                : fallback,
          ),
          // Gradient: clear at top → solid black at bottom.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xFF000000)],
                ),
              ),
            ),
          ),
          // Pill top 160 → title box 188 (h 89, 2 lines of 38.981) →
          // description 281; ~36 below it to the hero's 379 bottom.
          Padding(
            padding: const EdgeInsets.fromLTRB(_kSide, 160, _kSide, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _PricePill(
                  text: 'Starting from ${formatIdrK(treatment.startingPrice)}',
                ),
                const SizedBox(height: 4.725 + 5.52),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 269),
                  child: Text(
                    treatment.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Florian',
                      fontWeight: FontWeight.w400,
                      fontSize: 50,
                      color: Colors.white,
                      height: 38.981 / 50,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                  ),
                ),
                const SizedBox(height: 5.52 + 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 315),
                  child: Text(
                    treatment.description,
                    style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      height: _kFigmaNormal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final String text;
  const _PricePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 23.275,
      constraints: const BoxConstraints(minWidth: 155.844),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(5.06),
        boxShadow: const [
          BoxShadow(color: Color(0x38000000), blurRadius: 4.048), // 22%
        ],
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          maxLines: 1,
          style: GoogleFonts.montserrat(
            fontSize: 12.144,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Select Your Treatments ───────────────────────────────────────────────────

class _TreatmentOptions extends StatelessWidget {
  final Treatment treatment;
  final List<TreatmentDuration> durations;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const _TreatmentOptions({
    required this.treatment,
    required this.durations,
    required this.selectedId,
    required this.onSelected,
  });

  static const double _colGap = 17; // cards at x 29 and 212
  static const double _rowGap = 17; // rows at y 461 and 593

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < durations.length; i += 2) {
      Widget cell(int j) => j < durations.length
          ? Expanded(
              child: _OptionCard(
                duration: durations[j],
                selected: durations[j].id == selectedId,
                onTap: () => onSelected(durations[j].id),
              ),
            )
          : const Expanded(child: SizedBox.shrink());
      if (i > 0) rows.add(const SizedBox(height: _rowGap));
      rows.add(
        Row(
          children: [
            cell(i),
            const SizedBox(width: _colGap),
            cell(i + 1),
          ],
        ),
      );
    }

    // Title 400.43 (21.43 below hero) → subtitle 424 → grid 461.
    return Padding(
      // Grid ends 708; the price bar starts at 740.
      padding: const EdgeInsets.fromLTRB(_kSide, 21.43, _kSideRight, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Select Your Treatments'),
          const SizedBox(height: 4.07),
          _Muted('you can only pick one treatment.'),
          const SizedBox(height: 21.15),
          ...rows,
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final TreatmentDuration duration;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.duration,
    required this.selected,
    required this.onTap,
  });

  // CSS 154.02° gradient direction as a unit vector (x right, y down).
  static final double _dx = math.sin(154.02 * math.pi / 180);
  static final double _dy = -math.cos(154.02 * math.pi / 180);

  static const double _border = 0.563;

  @override
  Widget build(BuildContext context) {
    // Figma offsets from the card's outer edge: minutes (19, 58.67), label
    // (19, 86.59). Subtract the border, which Container adds as padding.
    const left = 19 - _border;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 115,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.016),
          // Border on both states keeps content from shifting.
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.transparent,
            width: _border,
          ),
          color: selected ? null : const Color(0x26BCBDB5), // 15%
          gradient: selected
              ? LinearGradient(
                  begin: Alignment(-_dx, -_dy),
                  end: Alignment(_dx, _dy),
                  colors: const [Color(0xFF353A30), Color(0xFF3D402F)],
                  stops: const [0.148, 1.0],
                )
              : null,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 58.67 - _border,
              left: left,
              right: 8,
              child: Text(
                '${duration.durationMinutes} MIN',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 22.295,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: _kFigmaNormal,
                ),
              ),
            ),
            Positioned(
              top: 86.59 - _border,
              left: left,
              right: 8,
              child: Text(
                'Signature Treatment',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  height: _kFigmaNormal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Price bar + Add To Cart ──────────────────────────────────────────────────

class _CartBar extends StatelessWidget {
  final double price;
  final VoidCallback onAddToCart;
  const _CartBar({required this.price, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    // Figma bar: y 740–854 (114 tall). Button 196×54 at y 760 (20 in), so 40
    // below it — 6 + a 34pt home-indicator area.
    final inset = MediaQuery.paddingOf(context).bottom;
    final double bottom = 6 + math.max(inset, 34.0);

    return Container(
      color: _kBar,
      padding: EdgeInsets.fromLTRB(_kSide, 20, _kSideRight, bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            // "Price Treatment" at y 763 (3 below the button top).
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price Treatment',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 14.323,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: _kFigmaNormal,
                  ),
                ),
                const SizedBox(height: 0.73), // price at y 781.19
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatIdrK(price),
                    maxLines: 1,
                    style: GoogleFonts.montserrat(
                      fontSize: 22.728,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: _kFigmaNormal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 196 wide at Figma size; on narrow screens the button gives up
          // width before the price label does.
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 196),
                child: Material(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(9.464),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9.464),
                    onTap: onAddToCart,
                    child: SizedBox(
                      height: 54,
                      child: Center(
                        child: Text(
                          'Add To Cart',
                          style: GoogleFonts.montserrat(
                            fontSize: 15.143,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared text styles ───────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.16,
        color: Colors.white.withValues(alpha: 0.71),
        height: _kFigmaNormal,
      ),
    );
  }
}

class _Muted extends StatelessWidget {
  final String text;
  const _Muted(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.13,
        color: Colors.white.withValues(alpha: 0.45),
        height: _kFigmaNormal,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Could not load treatment',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: AppColors.textOnDarkMuted,
            ),
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
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Back',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textOnDarkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

TreatmentDuration? _resolveSelected(Treatment treatment, String? selectedId) {
  if (treatment.durations.isEmpty) return null;
  if (selectedId != null) {
    for (final d in treatment.durations) {
      if (d.id == selectedId) return d;
    }
  }
  return treatment.defaultDuration;
}
