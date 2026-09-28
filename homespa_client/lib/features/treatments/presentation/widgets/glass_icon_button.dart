import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
  }) : assert((svgAsset == null) != (icon == null)),
       assert(!svgIncludesFrame || svgAsset != null);

  @override
  Widget build(BuildContext context) {
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
                  color: Colors.white.withValues(alpha: fillAlpha),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.50),
                    width: _border,
                  ),
                ),
                child: icon != null
                    ? Icon(icon, size: iconSize, color: Colors.white)
                    : SvgPicture.asset(
                        svgAsset!,
                        width: iconSize,
                        height: iconSize,
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF161616),
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
