import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/entities/treatment_category.dart';
import '../providers/treatments_providers.dart';
import 'cart_glass_button.dart';
import 'glass_icon_button.dart';

// ── Assets exported from Figma (kaizen › Massage, node 243:510) ──────────────
const String _kHeroImage = 'assets/images/home/hero.png';
const String _kIconBack = 'assets/icons/chevron_left_33.svg';

/// Fallback photo for treatments without an `image_url`, with Figma's crop.
const String _kCardFallback = 'assets/images/treatments/treatment_card_1.png';
const Alignment _kCardFallbackCrop = Alignment(0, 0.632);

/// Header copy per category. Only Massage has copy in the design so far.
const Map<String, String> _kCategoryDescriptions = {
  'Massage':
      'A range of massage services focused on relaxation, muscle '
      'relief, and overall well-being, performed by skilled therapists using '
      'professional techniques.',
};

// ── Figma layout values (402pt-wide frame) ───────────────────────────────────
const double _kHeroHeight = 320;
const double _kCardsTop = 214.14;
const double _kCardSide = 32;
const double _kCardHeight = 206.443;
const double _kCardGap = 16.417;
const Color _kPricePill = Color(0xFF4E523B);
const Color _kOrderPill = Color(0xFF313129);

/// Treatments within one category (Figma: "Massage").
class CategoryTreatmentsView extends ConsumerWidget {
  final TreatmentCategory? category;
  final String categoryId;
  final VoidCallback onBack;

  const CategoryTreatmentsView({
    super.key,
    required this.category,
    required this.categoryId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treatmentsAsync = ref.watch(treatmentsProvider(categoryId));

    return RefreshIndicator(
      color: AppColors.cream,
      backgroundColor: AppColors.darkOlive,
      onRefresh: () async => ref.invalidate(treatmentsProvider(categoryId)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _kHeroHeight,
                child: _Hero(),
              ),
              _Header(category: category, onBack: onBack),
              // Cards start inside the hero and overlap it.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  _kCardSide,
                  _kCardsTop,
                  _kCardSide,
                  _kCardGap,
                ),
                child: treatmentsAsync.when(
                  loading: () => Column(
                    children: List.generate(
                      3,
                      (_) => const _CardFrame(
                        child: ColoredBox(color: AppColors.darkOlive),
                      ),
                    ),
                  ),
                  error: (_, __) => _Message(
                    text: 'Could not load treatments',
                    onRetry: () =>
                        ref.invalidate(treatmentsProvider(categoryId)),
                  ),
                  data: (treatments) => treatments.isEmpty
                      ? const _Message(text: 'No treatments yet')
                      : Column(
                          children: [
                            for (final t in treatments)
                              TreatmentPhotoCard(
                                treatment: t,
                                onTap: () =>
                                    context.push('/treatments/${t.id}'),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Hero & header ────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      bottomLeft: Radius.circular(60),
      bottomRight: Radius.circular(60),
    );
    return Container(
      decoration: const BoxDecoration(
        borderRadius: radius,
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
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(_kHeroImage, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xD9000000)],
                ),
              ),
            ),
            // Approximates Figma's inset shadow (0 3 7.8 4, white 12%).
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
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

class _Header extends StatelessWidget {
  final TreatmentCategory? category;
  final VoidCallback onBack;
  const _Header({required this.category, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final name = category?.name ?? '';
    final description = _kCategoryDescriptions[name];
    // Keep centred titles clear of the 49px buttons on either side.
    const titleInset = 30 + GlassIconButton.size + 8;

    return SizedBox(
      height: _kCardsTop,
      child: Stack(
        children: [
          Positioned(
            top: 72,
            left: 30,
            child: GlassIconButton(
              svgAsset: _kIconBack,
              iconSize: 33,
              iconOffset: const Offset(6.5, 8.5),
              onTap: onBack,
            ),
          ),
          const Positioned(top: 72, right: 33, child: CartGlassButton()),
          Positioned(
            top: 63,
            left: titleInset,
            right: titleInset,
            child: Text(
              'Treatment',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                height: 31.584 / 20,
              ).copyWith(leadingDistribution: TextLeadingDistribution.even),
            ),
          ),
          Positioned(
            top: 95,
            left: titleInset,
            right: titleInset,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'CalSans',
                fontWeight: FontWeight.w600,
                fontSize: 40,
                color: Colors.white,
                height: 31.584 / 40,
                leadingDistribution: TextLeadingDistribution.even,
              ),
            ),
          ),
          if (description != null)
            Positioned(
              top: 143,
              left: 29,
              right: 32,
              child: Text(
                description,
                textAlign: TextAlign.center,
                // 3 lines at 402pt; a 4th on narrow phones still clears the
                // first card (top 214).
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Treatment card ───────────────────────────────────────────────────────────

class _CardFrame extends StatelessWidget {
  final Widget child;
  const _CardFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    // Figma height is the minimum; cards grow if a long name wraps.
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: _kCardHeight),
      margin: const EdgeInsets.only(bottom: _kCardGap),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(20.24),
      ),
      child: child,
    );
  }
}

/// Photo treatment card (Treatments list, Search results).
class TreatmentPhotoCard extends StatelessWidget {
  final Treatment treatment;
  final VoidCallback onTap;

  const TreatmentPhotoCard({
    super.key,
    required this.treatment,
    required this.onTap,
  });

  // Figma (card-relative, 338×206.443 card):
  //   pills   x 21.25, y 88.05 — 155.844 + gap 8.1 + 91.078, h 23.275
  //   name    x 25,    y 113.86 — Cal Sans 26 / 33.868, first line at 116.93
  //   desc    x 25.3,  y 151.8  — Montserrat Light 12.144
  static const double _pillsLeft = 21.25;
  static const double _pillsTop = 88.05;
  static const double _pillGap = 8.1;
  static const double _textLeft = 25;
  // Right inset for wrapping text, so long names never reach the edge.
  static const double _textRight = 21.25;

  static String _startingFrom(double price) =>
      'Starting From ${formatIdrK(price)}';

  @override
  Widget build(BuildContext context) {
    final startingPrice = treatment.startingPrice;
    final fallbackImage = Image.asset(
      _kCardFallback,
      fit: BoxFit.cover,
      alignment: _kCardFallbackCrop,
    );
    final url = treatment.imageUrl;

    return GestureDetector(
      onTap: onTap,
      child: _CardFrame(
        child: Stack(
          children: [
            Positioned.fill(
              child: url != null && url.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox.shrink(),
                      errorWidget: (_, __, ___) => fallbackImage,
                    )
                  : fallbackImage,
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xD9000000)],
                  ),
                ),
              ),
            ),
            // Content is top-anchored at Figma's offsets and sizes the card;
            // the card only grows past 206.4 if a long name wraps.
            Padding(
              padding: const EdgeInsets.only(top: _pillsTop, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: _pillsLeft, right: 16),
                    // Side-by-side pills sized to content; only drops to a
                    // second line on screens too narrow for both.
                    child: Wrap(
                      spacing: _pillGap,
                      runSpacing: 6,
                      children: [
                        if (startingPrice != null)
                          _Pill(
                            text: _startingFrom(startingPrice),
                            color: _kPricePill,
                            minWidth: 155.844,
                          ),
                        _Pill(
                          text: 'Order Now',
                          color: _kOrderPill,
                          minWidth: 91.078,
                          onTap: onTap,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _textLeft,
                      5.6,
                      _textRight,
                      1,
                    ),
                    child: Text(
                      treatment.name,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'CalSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 26,
                        letterSpacing: 0.39,
                        color: Colors.white,
                        height: 33.868 / 26,
                        leadingDistribution: TextLeadingDistribution.even,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 25.3,
                      right: _textRight,
                    ),
                    child: Text(
                      treatment.description,
                      // 2 lines at Figma width; narrow phones may need a 3rd.
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 12.144,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
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

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final double minWidth;
  final VoidCallback? onTap;

  const _Pill({
    required this.text,
    required this.color,
    required this.minWidth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Figma width is the minimum; the pill hugs its text beyond that. No
    // Container.alignment here — that would stretch the pill to full width.
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 23.275,
        constraints: BoxConstraints(minWidth: minWidth),
        // Figma's 155.844 pill leaves ~4.8px around "Starting From IDR 175K".
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
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
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 12.144,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  const _Message({required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 140),
      child: Column(
        children: [
          Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: AppColors.textOnDarkMuted,
            ),
          ),
          if (onRetry != null)
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
      ),
    );
  }
}
