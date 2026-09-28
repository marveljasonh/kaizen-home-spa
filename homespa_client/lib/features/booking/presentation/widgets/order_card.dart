import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../domain/entities/order_summary.dart';
import '../providers/order_history_providers.dart';

// Shared by Home → Recent Orders and the Order History page.

// ── Assets exported from Figma (kaizen › Home, node 1633:4768) ───────────────
const String _kCardBg = 'assets/images/home/recent_order_bg.png';
const String _kEmptyBg = 'assets/images/home/recent_orders_empty.png';
const String _kIconMore = 'assets/icons/more_22.svg';
const double _kRadius = 4.603;

/// Corner radius of the "#CODE" tag at design scale; the status pill reuses
/// it so both pills stay in sync.
const double _kTagRadius = 3.32;

/// Support line, shared with Profile → Contact Us.
const String kSupportWhatsApp = '6281234567890';

/// Figma tag style (order code / status): white 20% fill, hairline white
/// border, corners 3.32, 16.6 tall, Montserrat 8.4.
class _Tag extends StatelessWidget {
  final String text;
  final double scale;
  const _Tag(this.text, {this.scale = 1});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      height: 16.597 * s,
      constraints: BoxConstraints(minWidth: 65.413 * s),
      padding: EdgeInsets.symmetric(horizontal: 4 * s),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(_kTagRadius * s),
        border: Border.all(color: Colors.white, width: 0.195 * s),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            fontSize: 8.441 * s,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// Status pill colours, bright enough to read on the dark olive overlay.
const Color _kStatusAmber = Color(0xFFFFC857);
const Color _kStatusBlue = Color(0xFF8AB8FF);
const Color _kStatusLime = Color(0xFFCDDC7A);
const Color _kStatusGreen = Color(0xFF74D38E);
const Color _kStatusRed = Color(0xFFFF7B6E);

Color _statusColor(String status) => switch (status) {
  'pending' => _kStatusAmber,
  'accepted' ||
  'confirmed' ||
  'therapist_assigned' ||
  'rider_assigned' => _kStatusBlue,
  'on_the_way' || 'arrived' || 'in_progress' => _kStatusLime,
  'completed' => _kStatusGreen,
  'cancelled' => _kStatusRed,
  _ => Colors.white,
};

/// Translucent tinted status pill: [color] text on an 18% fill with a 40%
/// border. Corners match the "#CODE" tag at the same [scale].
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final double scale;
  const _StatusPill({
    required this.label,
    required this.color,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(_kTagRadius * scale),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.2,
      ),
    ),
  );
}

/// Order card (Figma 1633:4768): photo card under a dark olive overlay with
/// the order-code tag and ⋮ support menu on top, "Name +N" title, date/time,
/// then total price and Re-Order along the bottom. Tapping the card opens the
/// booking; ⋮ and Re-Order handle their own taps.
///
/// Designed at 222×149 (Home). Every offset and font size scales with the
/// width, so the Order History card at 341 wide is exactly 341×228.87.
class OrderCard extends ConsumerStatefulWidget {
  final OrderSummary order;

  /// Fixed width (Home row: 222). Null fills the available width.
  final double? width;

  /// Adds a colour-coded status pill next to the order code.
  final bool showStatus;

  const OrderCard({
    super.key,
    required this.order,
    this.width,
    this.showStatus = false,
  });

  static const double designWidth = 222;
  static const double designHeight = 149;

  /// Card height for a given width (keeps the 222:149 proportions).
  static double heightFor(double width) => width * designHeight / designWidth;

  @override
  ConsumerState<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<OrderCard> {
  bool _reordering = false;

  Future<void> _reorder() async {
    if (_reordering) return;
    setState(() => _reordering = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final added = await reorderIntoCart(ref, widget.order);
      if (added > 0) {
        router.push('/booking/cart');
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('These treatments are no longer available.'),
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Couldn’t re-order right now. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  void _openDetails() => context.push('/bookings/${widget.order.id}');

  static String _formatWhen(DateTime dt) {
    final wib = WIB.toWIB(dt);
    return '${DateFormat('EEE, d MMM y').format(wib)} | '
        '${DateFormat('HH.mm').format(wib)} WIB';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = widget.width ?? constraints.maxWidth;
        return _buildCard(width, width / OrderCard.designWidth);
      },
    );
  }

  /// [s] = width / 222. All numbers below are Figma's 222×149 values.
  Widget _buildCard(double width, double s) {
    final order = widget.order;

    return GestureDetector(
      onTap: _openDetails,
      child: Container(
        width: width,
        height: OrderCard.heightFor(width),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(_kRadius * s),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(_kCardBg, fit: BoxFit.cover)),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xF0252620), Color(0xC731322C)],
                  ),
                ),
              ),
            ),
            // Order-code tag: 65.4×16.6 at (15.98, 12); status tag beside it.
            Positioned(
              left: 15.98 * s,
              top: 12 * s,
              right: (12.54 + 22.913 + 8) * s,
              child: Row(
                children: [
                  _Tag('# ${order.code}', scale: s),
                  if (widget.showStatus) ...[
                    SizedBox(width: 6 * s),
                    Flexible(
                      child: _StatusPill(
                        label: order.statusLabel,
                        color: _statusColor(order.status),
                        scale: s,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ⋮ menu: 22px circle at (187, 12); the SVG includes its stroke.
            // 8px of invisible padding enlarges the tap target.
            Positioned(
              right: 12.54 * s - _OrderMenuButton.hitPad,
              top: 11.54 * s - _OrderMenuButton.hitPad,
              child: _OrderMenuButton(bookingCode: order.code, scale: s),
            ),
            // Title: Montserrat SemiBold 19.23 / 18.55, 131.8 wide, block
            // centred on y 56.1 (so one line sits in the middle).
            Positioned(
              left: 15 * s,
              right: 75.2 * s,
              top: 37.55 * s,
              height: 37.1 * s,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _FitTitle(order.title, scale: s),
              ),
            ),
            Positioned(
              left: 15.98 * s,
              right: 18 * s,
              top: 83.6 * s,
              child: Text(
                _formatWhen(order.scheduledAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 7.677 * s,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              left: 18 * s,
              top: 114 * s,
              right: (13.13 + 69.872 + 8) * s,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Price',
                    style: GoogleFonts.montserrat(
                      fontSize: 7.093 * s,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.219,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatIdrK(order.total),
                      style: GoogleFonts.montserrat(
                        fontSize: 11.255 * s,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.219,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Re-Order: 69.9×24.7, #5B6240, corners 4.11, at (139, 114).
            if (order.canReorder)
              Positioned(
                right: 13.13 * s,
                top: 114 * s,
                child: Material(
                  color: const Color(0xFF5B6240),
                  borderRadius: BorderRadius.circular(4.112 * s),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4.112 * s),
                    onTap: _reordering ? null : _reorder,
                    child: SizedBox(
                      width: 69.872 * s,
                      height: 24.679 * s,
                      child: Center(
                        child: _reordering
                            ? SizedBox.square(
                                dimension: 12 * s,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Re-Order',
                                style: GoogleFonts.montserrat(
                                  fontSize: 9.869 * s,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                ),
                              ),
                      ),
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

/// Figma ⋮ button (circular, outlined). Opens support options for the order.
/// Its own tap handler wins the gesture arena, so the card's tap-to-details
/// doesn't fire.
class _OrderMenuButton extends StatelessWidget {
  final String bookingCode;
  final double scale;
  const _OrderMenuButton({required this.bookingCode, this.scale = 1});

  static const double hitPad = 8;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Order options',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showOrderSupportSheet(context, bookingCode),
        child: Padding(
          padding: const EdgeInsets.all(hitPad),
          child: SvgPicture.asset(
            _kIconMore,
            width: 22.913 * scale,
            height: 22.913 * scale,
          ),
        ),
      ),
    );
  }
}

Future<void> showOrderSupportSheet(BuildContext context, String bookingCode) {
  Future<void> openWhatsApp(String message) async {
    final uri = Uri.parse(
      'https://wa.me/$kSupportWhatsApp?text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                'Order #$bookingCode',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.support_agent_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Request Help'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                openWhatsApp(
                  'Hi Kaizen, I need help with my order #$bookingCode.',
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.report_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Report an Issue'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                openWhatsApp(
                  'Hi Kaizen, I would like to report an issue with my order '
                  '#$bookingCode.',
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// Figma empty state: 341×149 photo panel with a dark olive overlay, the
/// message 44 from the top and an outlined "Explore Treatments" pill at 68.
class OrderEmptyState extends StatelessWidget {
  final String message;
  const OrderEmptyState({
    super.key,
    this.message = 'You haven’t booked any treatments yet.',
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kRadius),
      child: SizedBox(
        height: OrderCard.designHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _kEmptyBg,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xF0252620), Color(0xC731322C)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 44, 16, 0),
              child: Column(
                children: [
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 11.806,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.219,
                    ),
                  ),
                  const SizedBox(height: 9.61), // pill top at 68
                  Material(
                    color: Colors.white.withValues(alpha: 0.07),
                    shape: const StadiumBorder(
                      side: BorderSide(color: Colors.white, width: 0.634),
                    ),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => context.go('/treatments'),
                      child: SizedBox(
                        width: 142,
                        height: 38.036,
                        child: Center(
                          child: Text(
                            'Explore Treatments',
                            style: GoogleFonts.montserrat(
                              fontSize: 11.17,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),
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

/// Figma title (Montserrat SemiBold 19.23 / 18.55, 2 lines). Names that fit
/// keep Figma's size and line breaks; longer ones shrink (to 75% at most)
/// instead of being cut off, and only then ellipsize.
class _FitTitle extends StatelessWidget {
  final String text;
  final double scale;
  const _FitTitle(this.text, {required this.scale});

  static const int _maxLines = 2;
  static const double _minFactor = 0.75;

  TextStyle _style(double factor) => GoogleFonts.montserrat(
    fontSize: 19.232 * scale * factor,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2885 * scale * factor,
    color: Colors.white,
    height: 18.55 / 19.232,
  ).copyWith(leadingDistribution: TextLeadingDistribution.even);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var factor = 1.0;
        while (factor > _minFactor) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: _style(factor)),
            maxLines: _maxLines,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          final fits = !painter.didExceedMaxLines;
          painter.dispose();
          if (fits) break;
          factor -= 0.05;
        }
        return Text(
          text,
          maxLines: _maxLines,
          overflow: TextOverflow.ellipsis,
          style: _style(factor.clamp(_minFactor, 1.0)),
        );
      },
    );
  }
}
