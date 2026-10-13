import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/i18n/material_i18n.dart';
import '../../../../core/theme/app_colors.dart';

/// Figma "Back" glass button: 49px circle, white 10% fill, 0.746px white 50%
/// border, SVG icon placed at [iconOffset] (top-left, as positioned in Figma).
class GlassIconButton extends StatelessWidget {
  /// SVG icon; or pass a Material [icon] instead (centred, white).
  final String? svgAsset;
  final IconData? icon;
  final double iconSize;
  final Offset iconOffset;
  final VoidCallback onTap;
  final int badgeCount;

  /// White fill opacity (10% on Treatments; Home-style headers use 20%).
  final double fillAlpha;

  /// The SVG is a whole Figma button export (glass circle + border + icon).
  /// It is drawn at its root size [iconSize], offset by [iconOffset] (e.g.
  /// negative when the export's stroke sits outside the 49px circle), and
  /// the button draws no fill or border of its own.
  final bool svgIncludesFrame;

  /// True when the button sits on a themed header/page (not on a photo): in
  /// light mode it is drawn dark-on-light instead of white-on-dark. Buttons on
  /// photos keep the default (always white glass).
  final bool adaptive;

  static const double size = 49;
  static const double _border = 0.746;

  const GlassIconButton({
    super.key,
    this.svgAsset,
    this.icon,
    required this.iconSize,
    this.iconOffset = Offset.zero,
    required this.onTap,
    this.badgeCount = 0,
    this.fillAlpha = 0.10,
    this.svgIncludesFrame = false,
    this.adaptive = false,
  }) : assert((svgAsset == null) != (icon == null)),
       assert(!svgIncludesFrame || svgAsset != null);

  @override
  Widget build(BuildContext context) {
    final ink = adaptive && !AppColors.isDark; // dark glass on a light page
    final iconColor = ink ? AppColors.fg : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (svgIncludesFrame)
              Positioned(
                left: iconOffset.dx,
                top: iconOffset.dy,
                child: SvgPicture.asset(
                  svgAsset!,
                  width: iconSize,
                  height: iconSize,
                ),
              )
            else
              Container(
                width: size,
                height: size,
                alignment: icon != null ? Alignment.center : Alignment.topLeft,
                padding: icon != null
                    ? null
                    : EdgeInsets.only(
                        left: iconOffset.dx - _border,
                        top: iconOffset.dy - _border,
                      ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ink
                      ? AppColors.glassFill
                      : Colors.white.withValues(alpha: fillAlpha),
                  border: Border.all(
                    color: ink
                        ? AppColors.tint(0.25)
                        : Colors.white.withValues(alpha: 0.50),
                    width: _border,
                  ),
                ),
                child: icon != null
                    ? Icon(icon, size: iconSize, color: iconColor)
                    : SvgPicture.asset(
                        svgAsset!,
                        width: iconSize,
                        height: iconSize,
                        colorFilter: ink
                            ? ColorFilter.mode(iconColor, BlendMode.srcIn)
                            : null,
                      ),
              ),
            // Badge: 16px white dot at (33, 33), Montserrat Medium 8 #161616.
            if (badgeCount > 0)
              Positioned(
                left: 33,
                top: 33,
                child: Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ink ? AppColors.btnFill : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: ink ? Colors.white : const Color(0xFF161616),
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
