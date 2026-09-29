import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/widgets/florian_text.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/entities/treatment_duration.dart';
import '../providers/treatments_providers.dart';
import '../widgets/glass_icon_button.dart';

// ── Assets exported from Figma (kaizen › fullbodya, node 1626:4539) ───────────
const String _kHeroFallback = 'assets/images/treatments/detail_hero.png';
const String _kIconBack = 'assets/icons/chevron_left_33.svg';
const String _kIconCheck = 'assets/icons/check_circle_17.svg'; // 45% built in

// ── Figma values (402pt-wide frame) ──────────────────────────────────────────
const double _kSide = 29;
// Cards end at x 372, i.e. 30 from the right, while text starts 29 in.
const double _kSideRight = 30;
const double _kHeroMinHeight = 379;
const Color _kBg = Color(0xFF4E523B);

/// "What's Included?" rows (Figma 1626:4581 – 4589).
const List<String> _kIncluded = [
  'Certified professional therapist',
  'All equipment & supplies provided',
  'Post-treatment care tips',
];

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

    void onContinue() {
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
                  const SliverToBoxAdapter(child: _Included()),
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
        _ContinueBar(onTap: onContinue),
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
                if (treatment.startingPrice case final price?) ...[
                  _PricePill(text: 'Starting from ${formatIdrK(price)}'),
                  const SizedBox(height: 4.725 + 5.52),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 269),
                  child: FlorianText(
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

  static const double _colGap = 11; // cards at x 29 and 206
  static const double _rowGap = 9; // rows at y 461 and 577

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
      padding: const EdgeInsets.fromLTRB(_kSide, 21.43, _kSideRight, 0),
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

/// 166 × 107 duration card: minutes, label and a price chip. Selected: dark
/// gradient with a white 50% hairline; otherwise a 15% grey-olive fill.
class _OptionCard extends StatelessWidget {
  final TreatmentDuration duration;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.duration,
    required this.selected,
    required this.onTap,
  });

  // CSS 155.608° gradient direction as a unit vector (x right, y down).
  static final double _dx = math.sin(155.608 * math.pi / 180);
  static final double _dy = -math.cos(155.608 * math.pi / 180);

  static const Color _from = Color(0xFF353A30);
  static const Color _to = Color(0xFF3D402F);

  /// Figma stops are 14.802% → 103.17%; Flutter's end at 100% is the colour
  /// 96.4% of the way along.
  static final Color _toAtEnd = Color.lerp(
    _from,
    _to,
    (1 - 0.14802) / (1.0317 - 0.14802),
  )!;

  static const double _border = 0.5;

  @override
  Widget build(BuildContext context) {
    // Figma offsets from the card's outer edge; the border (kept on both
    // states so nothing shifts) is added by Container as padding.
    const left = 18 - _border;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 107,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.891),
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
                    colors: [_from, _toAtEnd],
                    stops: const [0.14802, 1.0],
                  )
                : null,
          ),
          child: Stack(
            children: [
              Positioned(
                top: 13 - _border,
                left: left,
                right: 8,
                child: Text(
                  '${duration.durationMinutes} MIN',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 21.713,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: _kFigmaNormal,
                  ),
                ),
              ),
              Positioned(
                top: 41 - _border,
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
              Positioned(
                top: 66 - _border,
                left: left,
                child: _PriceChip(price: duration.price, selected: selected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 89.888 × 27.546 chip, radius 4.461: "IDR" Regular + amount SemiBold.
class _PriceChip extends StatelessWidget {
  final double price;
  final bool selected;
  const _PriceChip({required this.price, required this.selected});

  @override
  Widget build(BuildContext context) {
    // "IDR 195K" → "IDR" + " 195K".
    final label = formatIdrK(price);
    final amount = label.startsWith('IDR') ? label.substring(3) : ' $label';
    TextStyle style(FontWeight w) => GoogleFonts.montserrat(
      fontSize: 13.383,
      fontWeight: w,
      color: Colors.white,
      height: _kFigmaNormal,
    );

    return Container(
      constraints: const BoxConstraints(minWidth: 89.888),
      height: 27.546,
      padding: const EdgeInsets.symmetric(horizontal: 4.461),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF5B6240) : const Color(0xFF50543E),
        borderRadius: BorderRadius.circular(4.461),
      ),
      child: Center(
        widthFactor: 1,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'IDR', style: style(FontWeight.w400)),
              TextSpan(text: amount, style: style(FontWeight.w600)),
            ],
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}

// ── What's Included? ─────────────────────────────────────────────────────────

class _Included extends StatelessWidget {
  const _Included();

  @override
  Widget build(BuildContext context) {
    // Grid ends 684 → title 708 → rows 738 / 766 / 793 (16 tall) → the
    // button 24 below the last row.
    const rowGaps = [12.0, 11.0];
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kSide, 24, _kSideRight, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('What’s Included?'),
          const SizedBox(height: 738 - (708 + 16 * _kFigmaNormal)),
          for (var i = 0; i < _kIncluded.length; i++) ...[
            if (i > 0) SizedBox(height: rowGaps[(i - 1) % rowGaps.length]),
            Row(
              children: [
                // 16 box; the exported icon draws 17 (stroke outside).
                SizedBox.square(
                  dimension: 16,
                  child: OverflowBox(
                    maxWidth: 17,
                    maxHeight: 17,
                    child: SvgPicture.asset(_kIconCheck, width: 17, height: 17),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(child: _Muted(_kIncluded[i])),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Continue ─────────────────────────────────────────────────────────────────

/// Figma button: #2C2C2C, 344 × 49 centred (29 in), radius 9.464, 34 above
/// the frame bottom (home-indicator area).
class _ContinueBar extends StatelessWidget {
  final VoidCallback onTap;
  const _ContinueBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final radius = BorderRadius.circular(9.464);
    return ColoredBox(
      color: _kBg,
      child: Padding(
        padding: EdgeInsets.fromLTRB(_kSide, 0, _kSide, math.max(inset, 34)),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 344),
            child: Material(
              color: const Color(0xFF2C2C2C),
              borderRadius: radius,
              child: InkWell(
                borderRadius: radius,
                onTap: onTap,
                child: SizedBox(
                  height: 49,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      'Continue',
                      style: GoogleFonts.montserrat(
                        fontSize: 15.143,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 0.85155,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
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
