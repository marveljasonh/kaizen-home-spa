import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/treatments/presentation/widgets/glass_icon_button.dart';
import '../theme/app_colors.dart';
import 'flow_widgets.dart';

// Hero pages (Profile and its sub-pages): the Promos hero (Figma kaizen ›
// promo 1650:2680) as a self-contained block above a #434930 page, History
// gutters and card rhythm, glass cards with order-card corners, "#CODE"-tag pills and olive
// small buttons.

const String kHeroImage = 'assets/images/home/hero.png';
const String _kIconBack = 'assets/icons/chevron_left_33.svg';

// ── Layout (History page) ─────────────────────────────────────────────────────
const double kPageGutterLeft = 30;
const double kPageGutterRight = 31;
const double kPageCardGap = 14;

// ── Hero (Promos, Figma 1650:2680 – 1650:2683) ───────────────────────────────
const double kHeroRadius = 40;
const double kHeroLabelTop = 76.99;
const double kHeroTitleTop = 102.88;
const double kHeroButtonsTop = 72;

/// Top of the first row under the title (Promos tabs, Profile avatar row).
const double kHeroRowTop = 143;

/// Bottom of the "Vouchers" / page title line box (102.88 + 19.296).
const double kHeroTitleBottom = kHeroTitleTop + 19.296;

/// Hero padding under its last row (Promos: tabs end 189, hero ends 219).
const double kHeroBottomPadding = 30;

/// Hero → first section (Promos: hero ends 219, "Special Offers" at 239).
const double kHeroContentGap = 20;

// ── Cards, pills, buttons ─────────────────────────────────────────────────────
/// Order card corners (4.603 at 222 wide) at the 341 History width.
const double kGlassCardRadius = 4.603 * 341 / 222;

/// "#CODE" tag corners (3.32 at 222 wide) at the 341 History width.
const double kTagRadius = 3.32 * 341 / 222;
const double kButtonRadius = 10;
const double kSmallButtonHeight = 44;

/// Status colours used on Promos (Active / Expired).
const Color kStatusActive = Color(0xFF74D38E);
const Color kStatusDanger = Color(0xFFFF7B6E);

const _kHeroCorners = BorderRadius.only(
  bottomLeft: Radius.circular(kHeroRadius),
  bottomRight: Radius.circular(kHeroRadius),
);

/// Hero photo layer: photo under a clear → black gradient, 40px bottom
/// corners, two drop shadows (Promos, Figma 1650:2680).
class KaizenHeroBackground extends StatelessWidget {
  final double height;
  const KaizenHeroBackground({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        borderRadius: _kHeroCorners,
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000), // 15%
            blurRadius: 4,
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
            Image.asset(kHeroImage, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xFF000000)],
                ),
              ),
            ),
            // Approximates Figma's inset shadow (0 3 7.8 4, white 12%);
            // Flutter has no inset box shadow.
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

/// Small Montserrat label over a large CalSans title (Promos: "Promos" /
/// "Vouchers"). With [onBack], a glass back button sits at the left (as on
/// Treatments) and the titles are centred between the side buttons.
class KaizenHeroTitle extends StatelessWidget {
  final String label;
  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const KaizenHeroTitle({
    super.key,
    required this.label,
    required this.title,
    this.onBack,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final centred = onBack != null;
    // Keep centred titles clear of the 49px buttons on either side.
    const inset = kPageGutterLeft + GlassIconButton.size + 8;
    final left = centred ? inset : kPageGutterLeft;
    final right = centred ? inset : kPageGutterRight;
    final align = centred ? TextAlign.center : TextAlign.start;

    return Stack(
      children: [
        Positioned(
          top: kHeroLabelTop,
          left: left,
          right: right,
          child: Text(
            label,
            textAlign: align,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 18.028,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 17.393 / 18.028,
            ).copyWith(leadingDistribution: TextLeadingDistribution.even),
          ),
        ),
        Positioned(
          top: kHeroTitleTop,
          left: left,
          right: right,
          child: Text(
            title,
            textAlign: align,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'CalSans',
              fontWeight: FontWeight.w600,
              fontSize: 30,
              color: Colors.white,
              height: 19.296 / 30,
              leadingDistribution: TextLeadingDistribution.even,
            ),
          ),
        ),
        if (onBack != null)
          Positioned(
            top: kHeroButtonsTop,
            left: kPageGutterLeft,
            child: GlassIconButton(
              svgAsset: _kIconBack,
              iconSize: 33,
              iconOffset: const Offset(6.5, 8.5),
              onTap: onBack!,
            ),
          ),
        if (actions.isNotEmpty)
          Positioned(
            top: kHeroButtonsTop,
            right: kPageGutterRight,
            child: Row(children: actions),
          ),
      ],
    );
  }
}

/// Hero page (Promos layout): a self-contained hero block — photo, 40px
/// bottom corners, shadow — only as tall as its content, then the page
/// content below it on #434930 after the Promos hero → section gap. The hero
/// is the first item of the scroll view, so both scroll together and never
/// overlap.
class KaizenHeroPage extends StatelessWidget {
  final String label;
  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;

  /// Content under the title from [kHeroRowTop] (e.g. the avatar row).
  final Widget? heroRow;
  final double heroRowHeight;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  /// Fixed bottom action (e.g. a [FlowPrimaryButton]).
  final Widget? bottomBar;

  /// False while a child needs the drag gestures (e.g. a map being panned).
  final bool scrollable;

  const KaizenHeroPage({
    super.key,
    required this.label,
    required this.title,
    required this.children,
    this.onBack,
    this.actions = const [],
    this.heroRow,
    this.heroRowHeight = 0,
    this.onRefresh,
    this.bottomBar,
    this.scrollable = true,
  });

  /// Title-only heroes end [kHeroBottomPadding] under the title; with a
  /// [heroRow], under the row (as Promos does under its tabs).
  double get heroHeight =>
      (heroRow == null ? kHeroTitleBottom : kHeroRowTop + heroRowHeight) +
      kHeroBottomPadding;

  @override
  Widget build(BuildContext context) {
    Widget list = ListView(
      physics: scrollable
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        SizedBox(
          height: heroHeight,
          child: Stack(
            children: [
              Positioned.fill(child: KaizenHeroBackground(height: heroHeight)),
              Positioned.fill(
                child: KaizenHeroTitle(
                  label: label,
                  title: title,
                  onBack: onBack,
                  actions: actions,
                ),
              ),
              if (heroRow != null)
                Positioned(
                  top: kHeroRowTop,
                  left: kPageGutterLeft,
                  right: kPageGutterRight,
                  height: heroRowHeight,
                  child: heroRow!,
                ),
            ],
          ),
        ),
        const SizedBox(height: kHeroContentGap),
        ...children,
      ],
    );
    if (onRefresh != null) {
      list = RefreshIndicator(
        color: AppColors.cream,
        backgroundColor: AppColors.darkOlive,
        onRefresh: onRefresh!,
        child: list,
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: flowTheme(context),
        child: Scaffold(
          backgroundColor: AppColors.darkOlive, // #434930
          body: list,
          bottomNavigationBar: bottomBar == null
              ? null
              : FlowBottomBar(child: bottomBar!),
        ),
      ),
    );
  }
}

/// Horizontal History gutters (30 left, 31 right).
class KaizenGutter extends StatelessWidget {
  final Widget child;
  const KaizenGutter(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      left: kPageGutterLeft,
      right: kPageGutterRight,
    ),
    child: child,
  );
}

/// Section label between cards (Montserrat Medium 14, 70% white).
class KaizenSectionLabel extends StatelessWidget {
  final String text;
  const KaizenSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      kPageGutterLeft,
      14,
      kPageGutterRight,
      10,
    ),
    child: Text(
      text,
      style: flowBody(14, weight: FontWeight.w500, color: kFlowMuted),
    ),
  );
}

/// Glass card (Promos / Cart): white 10% fill, hairline white 15% border,
/// order-card corners. Tappable when [onTap] is set.
class KaizenGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const KaizenGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(kGlassCardRadius);
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Gold-tinted square behind an icon (Promos reward tile).
class KaizenIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  const KaizenIconTile(this.icon, {super.key, this.color = AppColors.gold});

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(kButtonRadius),
      border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
    ),
    child: Icon(icon, size: 22, color: color),
  );
}

/// Small olive action (Promos "Use"): #4E523B, white Montserrat 15, radius
/// 10, 44 tall. [color] tints the label (e.g. [kStatusDanger] for Delete).
class KaizenSmallButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;

  const KaizenSmallButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(kButtonRadius);
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.darkOliveLight, // #4E523B
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 84,
              minHeight: kSmallButtonHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: flowBody(15, weight: FontWeight.w500, color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "#CODE" style pill: white 20% fill, 0.3 white border, tag corners. With
/// [color], a tinted status pill (Promos Active / Expired).
class KaizenPill extends StatelessWidget {
  final String label;
  final Color? color;
  const KaizenPill(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final tint = color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tint == null
            ? Colors.white.withValues(alpha: 0.2)
            : tint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(kTagRadius),
        border: tint == null
            ? Border.all(color: Colors.white, width: 0.3)
            : Border.all(color: tint.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: flowBody(
          12,
          weight: FontWeight.w500,
          color: tint ?? Colors.white,
        ).copyWith(letterSpacing: 0.8),
      ),
    );
  }
}

/// Choice row styled like the Promos tabs: 46 tall, radius 10, active white
/// with dark olive text, inactive #4E523B with white text.
class KaizenChoiceTabs<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  const KaizenChoiceTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(kButtonRadius);
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 13.179), // Promos tab gap
          Expanded(
            child: Semantics(
              button: true,
              selected: options[i].$1 == selected,
              child: Material(
                color: options[i].$1 == selected
                    ? Colors.white
                    : AppColors.darkOliveLight,
                shape: RoundedRectangleBorder(
                  borderRadius: radius,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: InkWell(
                  borderRadius: radius,
                  onTap: () => onSelected(options[i].$1),
                  child: SizedBox(
                    height: 46,
                    child: Center(
                      child: Text(
                        options[i].$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: flowBody(
                          15,
                          color: options[i].$1 == selected
                              ? AppColors.darkOliveLight
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Dark confirmation dialog (#313129, CalSans title, Montserrat body) with
/// a Cancel small button and a white confirm button. Resolves to true only
/// when confirmed.
Future<bool> showKaizenConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.secondary, // #313129
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: kPageGutterLeft),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: flowHeading(24, height: 1.2)),
            const SizedBox(height: 10),
            Text(message, style: flowBody(14, color: kFlowMuted, height: 1.45)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: KaizenSmallButton(
                    label: 'Cancel',
                    onTap: () => Navigator.of(ctx).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogConfirmButton(
                    label: confirmLabel,
                    destructive: destructive,
                    onTap: () => Navigator.of(ctx).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

class _DialogConfirmButton extends StatelessWidget {
  final String label;
  final bool destructive;
  final VoidCallback onTap;

  const _DialogConfirmButton({
    required this.label,
    required this.destructive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(kButtonRadius);
    return Material(
      color: Colors.white,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: SizedBox(
          height: kSmallButtonHeight,
          child: Center(
            child: Text(
              label,
              style: flowBody(
                15,
                weight: FontWeight.w600,
                color: destructive
                    ? const Color(0xFFC0392B)
                    : AppColors.darkOliveLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round avatar. With a non-empty [url] (or picked [bytes]) the photo is
/// cropped to the circle with BoxFit.cover; otherwise — and when the photo
/// fails to load — CalSans initials on a #4E523B circle.
class KaizenAvatar extends StatelessWidget {
  final String? url;
  final Uint8List? bytes;
  final String initials;
  final double size;

  const KaizenAvatar({
    super.key,
    this.url,
    this.bytes,
    required this.initials,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final link = url?.trim() ?? '';
    final Widget content;
    if (bytes != null) {
      content = Image.memory(
        bytes!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _initials(),
      );
    } else if (link.isNotEmpty) {
      content = CachedNetworkImage(
        imageUrl: link,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Plain olive while loading; initials only if it fails.
        placeholder: (_, _) =>
            const ColoredBox(color: AppColors.darkOliveLight),
        errorWidget: (_, _, _) => _initials(),
      );
    } else {
      content = _initials();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: ClipOval(child: content),
    );
  }

  Widget _initials() => Container(
    width: size,
    height: size,
    color: AppColors.darkOliveLight, // #4E523B
    alignment: Alignment.center,
    child: Text(initials, style: flowHeading(size * 0.36)),
  );
}

/// "AB" from a full name, else the first letter of [email].
String kaizenInitials(String? name, String email) {
  final n = name?.trim() ?? '';
  if (n.isEmpty) return email.isNotEmpty ? email[0].toUpperCase() : '?';
  final parts = n.split(RegExp(r'\s+'));
  return parts.length >= 2
      ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
      : parts[0][0].toUpperCase();
}
