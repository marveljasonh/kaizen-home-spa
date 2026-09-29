import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../booking/presentation/widgets/order_card.dart';
import '../../domain/entities/treatment_preview.dart';
import '../providers/home_providers.dart';

// ── Assets exported from Figma (kaizen › Home, node 503:268) ─────────────────
const String _kHeroImage = 'assets/images/home/hero.png';
const List<String> _kTreatmentFallbacks = [
  'assets/images/home/treatment_full_body.png',
  'assets/images/home/treatment_face.png',
];
const String _kIconSearch = 'assets/icons/search_24.svg';

// ── Figma layout values (402pt-wide frame) ───────────────────────────────────
const double _kGutterLeft = 30;
const double _kGutterRight = 31;
const Color _kContactText = Color(0xFF7D7D7C);

TextStyle _buttonTextStyle(Color color, double fontSize) =>
    GoogleFonts.montserrat(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: color,
    );

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkOliveLight, // #4E523B
        body: RefreshIndicator(
          color: AppColors.cream,
          backgroundColor: AppColors.darkOliveLight,
          onRefresh: () async {
            ref.invalidate(popularTreatmentsProvider);
            ref.invalidate(recentOrdersProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: const [
              // Hero is edge-to-edge and runs under the status bar.
              _HeroSection(),
              SizedBox(height: 20), // hero ends 295 → title 315
              _SectionTitle(
                title: 'Popular Treatment',
                subtitle:
                    'Top-rated treatments for relaxation and body recovery.',
              ),
              SizedBox(height: 14.68), // cards at 375.5
              _PopularTreatments(),
              SizedBox(height: 24.11), // cards end 521.7 → title 545.81
              _RecentOrdersSection(),
              SizedBox(height: 25), // 752 → nav bar at 777
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero ───────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      bottomLeft: Radius.circular(40),
      bottomRight: Radius.circular(40),
    );
    return Container(
      height: 295,
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
            // Gradient: clear at top → 85% black at bottom.
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
                borderRadius: radius,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.5,
                ),
              ),
            ),
            Positioned(
              top: 63,
              left: _kGutterLeft,
              child: Text(
                'Body',
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
                'Relaxation',
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
              child: _GlassButton(
                svgAsset: _kIconSearch,
                width: 49,
                height: 49,
                iconSize: 25.565,
                iconOffset: const Offset(11.72, 11.72),
                borderWidth: 0.746,
                onTap: () => context.push('/search'),
              ),
            ),
            Positioned(
              top: 142,
              left: _kGutterLeft,
              right: _kGutterRight,
              child: Text(
                'We provide high-quality body relaxation experiences using '
                'expert touch and carefully selected techniques to rejuvenate '
                'your body and mind.',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Positioned(
              top: 208,
              left: _kGutterLeft,
              right: _kGutterRight,
              child: Row(
                children: [
                  Expanded(
                    child: _HeroButton(
                      label: 'Book Now',
                      fontSize: 18,
                      background: AppColors.darkOliveLight,
                      foreground: Colors.white,
                      onTap: () => context.go('/treatments'),
                    ),
                  ),
                  const SizedBox(width: 21),
                  Expanded(
                    child: _HeroButton(
                      label: 'Contact Us',
                      fontSize: 19,
                      background: Colors.white,
                      foreground: _kContactText,
                      onTap: () => context.go('/profile'),
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

/// Translucent pill/circle button: 20% white fill, 50% white hairline border.
/// [iconOffset] is the icon's top-left inside the button, as placed in Figma.
class _GlassButton extends StatelessWidget {
  final String svgAsset;
  final VoidCallback onTap;
  final double width;
  final double height;
  final double iconSize;
  final Offset iconOffset;
  final double borderWidth;

  const _GlassButton({
    required this.svgAsset,
    required this.onTap,
    required this.width,
    required this.height,
    required this.iconSize,
    required this.iconOffset,
    required this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Figma's border sits inside the frame; offset the icon by the stroke so
    // it lands at the same absolute position.
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.topLeft,
        padding: EdgeInsets.only(
          left: iconOffset.dx - borderWidth,
          top: iconOffset.dy - borderWidth,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          color: Colors.white.withValues(alpha: 0.20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.50),
            width: borderWidth,
          ),
        ),
        child: SvgPicture.asset(svgAsset, width: iconSize, height: iconSize),
      ),
    );
    return button;
  }
}

class _HeroButton extends StatelessWidget {
  final String label;
  final double fontSize;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _HeroButton({
    required this.label,
    required this.fontSize,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Center(
            child: Text(
              label,
              style: _buttonTextStyle(foreground, fontSize),
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  /// Optional action at the end of the title line (e.g. "View All").
  final Widget? trailing;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: _kGutterLeft, right: _kGutterRight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title line box is 32.54px in Figma (title top → subtitle top).
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'CalSans',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 23.741,
                    letterSpacing: 0.2374,
                    height: 32.54 / 23.741,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          Text(
            subtitle,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 10.898,
              fontWeight: FontWeight.w400,
              height: 1.219,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Popular treatments ───────────────────────────────────────────────────────

const double _kCardWidth = 222.129;
const double _kCardHeight = 146.2;
const double _kCardGap = 13.47; // second card at x 265.6
const double _kCardRadius = 5.095;

class _PopularTreatments extends ConsumerWidget {
  const _PopularTreatments();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treatmentsAsync = ref.watch(popularTreatmentsProvider);
    const listPadding = EdgeInsets.only(left: _kGutterLeft);

    return SizedBox(
      height: _kCardHeight,
      child: treatmentsAsync.when(
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: listPadding,
          itemCount: 3,
          itemBuilder: (_, __) =>
              const _CardShell(child: ColoredBox(color: AppColors.darkOlive)),
        ),
        error: (_, __) => Center(
          child: Text(
            'Could not load treatments',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textOnDarkMuted,
            ),
          ),
        ),
        data: (treatments) {
          if (treatments.isEmpty) {
            return Center(
              child: Text(
                'No treatments yet',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textOnDarkMuted,
                ),
              ),
            );
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: listPadding,
            itemCount: treatments.length,
            itemBuilder: (_, i) => _PopularTreatmentCard(
              treatment: treatments[i],
              fallbackImage:
                  _kTreatmentFallbacks[i % _kTreatmentFallbacks.length],
              onTap: () => context.push('/treatments/${treatments[i].id}'),
            ),
          );
        },
      ),
    );
  }
}

/// Rounded card frame used by both the skeleton and the real card.
class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kCardWidth,
      margin: const EdgeInsets.only(right: _kCardGap),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      child: child,
    );
  }
}

class _PopularTreatmentCard extends StatelessWidget {
  final TreatmentPreview treatment;
  final String fallbackImage;
  final VoidCallback onTap;

  const _PopularTreatmentCard({
    required this.treatment,
    required this.fallbackImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(fallbackImage, fit: BoxFit.cover);
    final hasRemote =
        treatment.imageUrl != null && treatment.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: _CardShell(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasRemote)
              CachedNetworkImage(
                imageUrl: treatment.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: AppColors.darkOlive),
                errorWidget: (_, __, ___) => fallback,
              )
            else
              fallback,
            // Gradient: clear from 2.846% → 50% black at bottom.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x80000000)],
                  stops: [0.02846, 1.0],
                ),
              ),
            ),
            // Bottom-anchored (14.06 from the bottom, as in Figma) so a name
            // that wraps to two lines grows upward instead of off the card.
            Positioned(
              left: 18.12,
              right: 18.12,
              bottom: 14.06,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    treatment.name,
                    style: const TextStyle(
                      fontFamily: 'CalSans',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 20.379,
                      height: 25.8 / 20.379, // 493.52 − 467.72 in Figma
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Most Popular Treatment',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 10.189,
                      fontWeight: FontWeight.w400,
                      height: 14.122 / 10.189,
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

// ── Recent orders ────────────────────────────────────────────────────────────

const double _kOrderCardWidth = 222;
const double _kOrderCardHeight = 149;
const double _kOrderCardGap = 14; // second card at x 266
const double _kOrderRadius = 4.603;

/// "Recent Orders" title, plus the latest completed bookings or the empty
/// state. "View All" only appears when there is at least one completed order.
class _RecentOrdersSection extends ConsumerWidget {
  const _RecentOrdersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(recentOrdersProvider);
    final hasOrders = ordersAsync.valueOrNull?.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Recent Orders',
          subtitle: 'View and manage your latest orders in one place.',
          trailing: hasOrders ? const _ViewAllButton() : null,
        ),
        const SizedBox(height: 11.36), // content at 603
        ordersAsync.when(
          loading: () => SizedBox(
            height: _kOrderCardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: _kGutterLeft),
              itemCount: 2,
              itemBuilder: (_, __) => Container(
                width: _kOrderCardWidth,
                margin: const EdgeInsets.only(right: _kOrderCardGap),
                decoration: BoxDecoration(
                  color: AppColors.darkOlive,
                  borderRadius: BorderRadius.circular(_kOrderRadius),
                ),
              ),
            ),
          ),
          error: (_, __) => const _EmptyPadding(
            OrderEmptyState(message: 'We couldn’t load your orders right now.'),
          ),
          data: (orders) {
            if (orders.isEmpty) return const _EmptyPadding(OrderEmptyState());
            return SizedBox(
              height: _kOrderCardHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: _kGutterLeft),
                itemCount: orders.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: _kOrderCardGap),
                  child: OrderCard(
                    order: orders[i],
                    width: _kOrderCardWidth,
                    showStatus: true,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go('/bookings?tab=past'),
      // Same height as the title line (32.54) so the subtitle doesn't move.
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 32.54),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.only(left: 8),
      ),
      child: Text(
        'View All',
        style: GoogleFonts.montserrat(
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.62),
          decoration: TextDecoration.underline,
          decorationColor: Colors.white.withValues(alpha: 0.62),
        ),
      ),
    );
  }
}

class _EmptyPadding extends StatelessWidget {
  final Widget child;
  const _EmptyPadding(this.child);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: _kGutterLeft, right: _kGutterRight),
    child: child,
  );
}
