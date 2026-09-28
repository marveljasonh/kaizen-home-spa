import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

// Welcome (Figma kaizen › splash, 1653:4369, 393×852). Shown once, right
// after a new account is created: Get Started → the Client Intake Form.
// Reached with `go`, so hardware back exits instead of returning to sign-up.

const String _kBackground = 'assets/images/splash/splash_bg.png'; // pricelist1
const String _kLogo = 'assets/images/splash/logo_mark.png'; // Asset 16@4xxs 1

/// Fill under the photo (shown while it decodes).
const Color _kBaseFill = Color(0xFF5E6443);
const Color _kGetStarted = Color(0xFF5B6240);

// ── Figma geometry (frame 393 × 852) ──────────────────────────────────────────
const double _kLogoTop = 111;
const double _kLogoWidth = 26.821;
const double _kLogoHeight = 21.555;
const double _kHeadlineTop = 852 / 2 - 261.21; // 164.79
const double _kHeadlineWidth = 294.555;
const double _kGutter = 20;
const double _kButtonHeight = 45;
const double _kButtonRadius = 12;

const double _kButtonWidth = 171;

/// Body copy bottom (685.38 + 3 lines × 11.83 × 1.461) → buttons top 749.
const double _kBodyToButtons = 749 - (685.38 + 3 * 11.83 * 1.461);

/// Buttons bottom (749 + 45) → frame bottom 852.
const double _kButtonsBottom = 852 - (749 + 45);

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _entrance,
    curve: Curves.easeOut,
  );
  late final Animation<double> _rise = CurvedAnimation(
    parent: _entrance,
    curve: Curves.easeOutCubic,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Start once the photo is decoded, so it doesn't pop in mid-fade.
    precacheImage(const AssetImage(_kBackground), context).whenComplete(() {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// Hand the new account over to the Client Intake Form.
  void _getStarted() {
    ref.read(justSignedUpProvider.notifier).state = false;
    context.go('/intake');
  }

  /// Fade in with a slight rise and scale; ends at the exact Figma layout.
  Widget _enter(Widget child, {double rise = 12, double scale = 0.96}) {
    return FadeTransition(
      opacity: _fade,
      child: AnimatedBuilder(
        animation: _rise,
        builder: (context, child) {
          final t = _rise.value;
          return Transform.translate(
            offset: Offset(0, rise * (1 - t)),
            child: Transform.scale(
              scale: scale + (1 - scale) * t,
              child: child,
            ),
          );
        },
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBaseFill,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background: photo + clear → 84% near-black gradient ─────────
            FadeTransition(
              opacity: _fade,
              child: Image.asset(
                _kBackground,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xD60D0D0A)],
                  stops: [0.0653, 0.99999],
                ),
              ),
            ),

            // ── Logo ────────────────────────────────────────────────────────
            Positioned(
              top: _kLogoTop,
              left: 0,
              right: 0,
              child: Center(child: _enter(const _Logo(), rise: 8, scale: 0.9)),
            ),

            // ── Headline ────────────────────────────────────────────────────
            Positioned(
              top: _kHeadlineTop,
              left: 0,
              right: 0,
              child: Center(
                child: _enter(
                  const SizedBox(
                    width: _kHeadlineWidth,
                    child: Text(
                      'Your Relaxation\nExperience Starts\nHere',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Florian',
                        fontWeight: FontWeight.w400,
                        fontSize: 44.308,
                        height: 40.706 / 44.308,
                        leadingDistribution: TextLeadingDistribution.even,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Color(0x8F000000), // 56%
                            offset: Offset(0, 1.339),
                            blurRadius: 3.616,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Body copy + buttons (anchored to the bottom) ────────────────
            Positioned(
              left: _kGutter,
              right: _kGutter,
              bottom: _kButtonsBottom,
              child: FadeTransition(
                opacity: _fade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Take a moment to relax and recharge. Enjoy a soothing '
                      'spa experience in the comfort of your home, created to '
                      'leave you feeling refreshed and renewed.',
                      textAlign: TextAlign.justify,
                      style: GoogleFonts.montserrat(
                        fontSize: 11.83,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.461,
                      ),
                    ),
                    const SizedBox(height: _kBodyToButtons),
                    // Figma's primary button (171 × 45), centred; Sign In is
                    // dropped because the account already exists.
                    Center(
                      child: SizedBox(
                        width: _kButtonWidth,
                        child: _WelcomeButton(
                          label: 'Get Started',
                          fill: _kGetStarted,
                          onTap: _getStarted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo mark with Figma's drop shadow (0 1.272 6.404, black 67%), which
/// follows the mark's shape rather than its bounding box.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    const mark = Image(
      image: AssetImage(_kLogo),
      width: _kLogoWidth,
      height: _kLogoHeight,
      fit: BoxFit.cover,
    );
    return SizedBox(
      width: _kLogoWidth,
      height: _kLogoHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 1.272,
            child: ImageFiltered(
              // CSS blur 6.404 → sigma 3.202.
              imageFilter: ImageFilter.blur(sigmaX: 3.202, sigmaY: 3.202),
              child: const ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Color(0xAB000000),
                  BlendMode.srcIn,
                ),
                child: mark,
              ),
            ),
          ),
          mark,
        ],
      ),
    );
  }
}

/// Figma "Get Started": 171 × 45, radius 12, Montserrat Medium 15,
/// tracking −0.15.
class _WelcomeButton extends StatelessWidget {
  final String label;
  final Color fill;
  final VoidCallback onTap;

  const _WelcomeButton({
    required this.label,
    required this.fill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_kButtonRadius),
    );
    return Semantics(
      button: true,
      child: Material(
        color: fill,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _kButtonHeight,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
