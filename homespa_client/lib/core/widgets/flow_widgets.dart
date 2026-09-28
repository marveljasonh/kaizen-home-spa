import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/treatments/presentation/widgets/glass_icon_button.dart';
import '../theme/app_colors.dart';

// Dark booking-flow design system (My Cart, Add-ons, booking steps):
// #313129 header with 24px bottom corners, #434930 page with a faint radial
// glow, CalSans headings, Montserrat body, olive cards and white primary
// buttons. Material widgets inside [FlowScaffold] get a matching dark theme.

const Color kFlowHeaderColor = AppColors.secondary; // #313129
const Color kFlowPageColor = AppColors.darkOlive; // #434930
const Color kFlowCardColor = AppColors.darkOliveLight; // #4E523B
const Color kFlowAccent = Color(0xFF5B6240); // olive (Re-Order button)
const Color kFlowGold = AppColors.gold;
const Color kFlowMuted = AppColors.textOnDarkMuted;
const double kFlowGutter = 20;
const double kFlowRadius = 10;
const double kFlowButtonHeight = 54;

const String _kIconBack = 'assets/icons/chevron_left_33.svg';

TextStyle flowBody(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = Colors.white,
  double? height,
}) => GoogleFonts.montserrat(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
);

TextStyle flowHeading(
  double size, {
  Color color = Colors.white,
  double? height,
}) => TextStyle(
  fontFamily: 'CalSans',
  fontWeight: FontWeight.w600,
  fontSize: size,
  color: color,
  height: height,
);

/// Dark theme for stock Material widgets (text fields, radios, checkboxes,
/// list tiles, dialogs' text) used inside the booking flow.
ThemeData flowTheme(BuildContext context) {
  final base = Theme.of(context);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: kFlowAccent,
        brightness: Brightness.dark,
      ).copyWith(
        primary: Colors.white,
        onPrimary: AppColors.darkOliveLight,
        secondary: kFlowAccent,
        onSecondary: Colors.white,
        surface: kFlowCardColor,
        onSurface: Colors.white,
        onSurfaceVariant: kFlowMuted,
        outline: Colors.white.withValues(alpha: 0.5),
        outlineVariant: Colors.white.withValues(alpha: 0.2),
        error: const Color(0xFFFFB4A8),
      );
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(kFlowRadius),
    borderSide: BorderSide(
      color: Colors.white.withValues(alpha: 0.5),
      width: 0.5,
    ),
  );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: kFlowPageColor,
    textTheme: GoogleFonts.montserratTextTheme(
      base.textTheme,
    ).apply(bodyColor: Colors.white, displayColor: Colors.white),
    iconTheme: const IconThemeData(color: Colors.white),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.2),
      thickness: 0.5,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.10),
      hintStyle: flowBody(14, color: kFlowMuted),
      labelStyle: flowBody(14, color: kFlowMuted),
      floatingLabelStyle: flowBody(14),
      prefixIconColor: Colors.white,
      suffixIconColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: Colors.white),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.white),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? kFlowAccent : null,
      ),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? Colors.white
            : Colors.white.withValues(alpha: 0.6),
      ),
    ),
    listTileTheme: ListTileThemeData(
      textColor: Colors.white,
      iconColor: Colors.white,
      titleTextStyle: flowBody(14, weight: FontWeight.w500),
      subtitleTextStyle: flowBody(12, color: kFlowMuted),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Colors.white,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        textStyle: flowBody(13, weight: FontWeight.w500),
      ),
    ),
    snackBarTheme: base.snackBarTheme,
  );
}

/// Page shell: #313129 header (back button, optional subtitle, CalSans
/// title, optional trailing actions and [header] extra such as the step
/// indicator), then [body] on #434930 with a faint radial glow.
class FlowScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Shown under the title inside the header (e.g. BookingStepIndicator).
  final Widget? header;
  final Widget body;
  final Widget? bottomBar;

  /// Defaults to pop (or '/' when there is nothing to pop).
  final VoidCallback? onBack;
  final bool showBack;

  const FlowScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.header,
    this.bottomBar,
    this.onBack,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: flowTheme(context),
        child: Scaffold(
          backgroundColor: kFlowPageColor,
          body: Stack(
            children: [
              const Positioned.fill(child: FlowBackground()),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FlowHeader(
                    title: title,
                    subtitle: subtitle,
                    actions: actions,
                    bottom: header,
                    showBack: showBack,
                    onBack:
                        onBack ??
                        () =>
                            context.canPop() ? context.pop() : context.go('/'),
                  ),
                  Expanded(child: body),
                ],
              ),
            ],
          ),
          bottomNavigationBar: bottomBar == null
              ? null
              : FlowBottomBar(child: bottomBar!),
        ),
      ),
    );
  }
}

/// Faint depth for the flat #434930 page: a soft light glow top-right and a
/// soft shade bottom-left.
class FlowBackground extends StatelessWidget {
  const FlowBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.9, -0.55),
          radius: 1.1,
          colors: [Color(0x14FFFFFF), Color(0x00FFFFFF)], // 8% → 0
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-1, 1),
            radius: 1.2,
            colors: [Color(0x26000000), Color(0x00000000)], // 15% → 0
          ),
        ),
      ),
    );
  }
}

class FlowHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? bottom;
  final bool showBack;
  final VoidCallback onBack;

  const FlowHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.actions = const [],
    this.bottom,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: kFlowHeaderColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kFlowGutter, 16, kFlowGutter, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBack || actions.isNotEmpty) ...[
                Row(
                  children: [
                    if (showBack)
                      GlassIconButton(
                        svgAsset: _kIconBack,
                        iconSize: 33,
                        iconOffset: const Offset(6.5, 8.5),
                        fillAlpha: 0.10,
                        onTap: onBack,
                      ),
                    const Spacer(),
                    ...actions,
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (subtitle != null) ...[
                Text(subtitle!, style: flowBody(18, height: 1.25)),
                const SizedBox(height: 4),
              ],
              Text(title, style: flowHeading(32, height: 1.1)),
              if (bottom != null) ...[const SizedBox(height: 16), bottom!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom action area (safe-area aware) for a [FlowPrimaryButton] etc.
class FlowBottomBar extends StatelessWidget {
  final Widget child;
  const FlowBottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kFlowPageColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kFlowGutter, 12, kFlowGutter, 16),
          child: child,
        ),
      ),
    );
  }
}

/// Flat card on the flow page: solid #4E523B, radius 10, 1px white 12%
/// border. [selected] adds a white border and olive tint.
class FlowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;
  final VoidCallback? onTap;

  const FlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(kFlowRadius);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: selected ? kFlowAccent : kFlowCardColor,
        borderRadius: radius,
        // Flat: solid fill + 1px border, no shadow.
        border: Border.all(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.12),
          width: selected ? 1.2 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Soft shadow for photo cards (My Cart) — flat FlowCards don't use it.
const List<BoxShadow> kFlowCardShadow = [
  BoxShadow(color: Color(0x2E000000), blurRadius: 12, offset: Offset(0, 4)),
];

/// Uppercase-free section label (Montserrat Medium 14, 70% white).
class FlowSectionLabel extends StatelessWidget {
  final String text;
  const FlowSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: flowBody(14, weight: FontWeight.w500, color: kFlowMuted),
    ),
  );
}

/// White button, dark olive Montserrat 18 text (active History tab style).
class FlowPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const FlowPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isLoading;
    return _FlowButton(
      label: label,
      onTap: enabled ? onTap : null,
      isLoading: isLoading,
      fill: Colors.white.withValues(alpha: enabled || isLoading ? 1 : 0.35),
      textColor: AppColors.darkOliveLight,
    );
  }
}

/// Olive button with white text.
class FlowSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const FlowSecondaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isLoading;
    return _FlowButton(
      label: label,
      onTap: enabled ? onTap : null,
      isLoading: isLoading,
      fill: kFlowAccent.withValues(alpha: enabled || isLoading ? 1 : 0.5),
      textColor: Colors.white,
      border: Colors.white.withValues(alpha: 0.3),
    );
  }
}

class _FlowButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color fill;
  final Color textColor;
  final Color? border;

  const _FlowButton({
    required this.label,
    required this.onTap,
    required this.isLoading,
    required this.fill,
    required this.textColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(kFlowRadius);
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: border == null
              ? BorderSide.none
              : BorderSide(color: border!, width: 0.5),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: SizedBox(
            height: kFlowButtonHeight,
            width: double.infinity,
            child: Center(
              child: isLoading
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: textColor,
                      ),
                    )
                  : Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: flowBody(
                        18,
                        weight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass pill (white 10%, 0.5 white 50% border) for header actions / chips.
class FlowGlassPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  const FlowGlassPill({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.10),
      shape: StadiumBorder(
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Text(
            label,
            style: flowBody(
              13,
              weight: selected ? FontWeight.w500 : FontWeight.w400,
              color: selected ? AppColors.darkOliveLight : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Round selection mark: olive fill with a white check when selected.
class FlowCheckMark extends StatelessWidget {
  final bool selected;
  final double size;
  const FlowCheckMark({super.key, required this.selected, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? kFlowAccent : Colors.transparent,
        border: Border.all(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: size * 0.68, color: Colors.white)
          : null,
    );
  }
}
