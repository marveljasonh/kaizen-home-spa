import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/flow_widgets.dart';
import '../providers/booking_cart.dart';

// My Cart on the booking-flow shell (FlowScaffold: #313129 header, #434930
// page): photo cards under the order-card overlay, a glass summary panel and
// a white primary button.

/// Fallback photo for treatments without an `image_url` (Treatments list).
const String _kCardFallback = 'assets/images/treatments/treatment_card_1.png';
const Alignment _kCardFallbackCrop = Alignment(0, 0.632);

const double _kGutterLeft = 30;
const double _kGutterRight = 31;
const double _kCardGap = 14;

/// Order card corners (4.603 at 222 wide) at the 341 History width.
const double _kCardRadius = 4.603 * 341 / 222;
const double _kButtonRadius = 10;
const Color _kPillOlive = Color(0xFF5B6240); // Re-Order button
const Color _kRewardGold = AppColors.gold;

TextStyle _montserrat(
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

TextStyle _calSans(double size, {double? height}) => TextStyle(
  fontFamily: 'CalSans',
  fontWeight: FontWeight.w600,
  fontSize: size,
  color: Colors.white,
  height: height,
);

class BookingCartPage extends ConsumerStatefulWidget {
  const BookingCartPage({super.key});

  @override
  ConsumerState<BookingCartPage> createState() => _BookingCartPageState();
}

class _BookingCartPageState extends ConsumerState<BookingCartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(bookingCartProvider);
    final hasContent = cart.items.isNotEmpty || cart.isFree;

    debugPrint(
      '[Cart] items total: ${cart.items.fold(0.0, (sum, i) => sum + i.price)}',
    );
    debugPrint('[Cart] discount amount: ${cart.discountAmount}');
    debugPrint('[Cart] voucher: ${cart.voucher}');
    debugPrint(
      '[Cart] reward discount: ${cart.rewardDiscount} (type: ${cart.rewardDiscountType})',
    );
    debugPrint('[Cart] calculated total: ${cart.total}');

    // Total rows in the list: free reward card (0 or 1) + regular items + order summary
    final freeOffset = cart.isFree ? 1 : 0;
    final listItemCount =
        freeOffset + cart.items.length + 1; // +1 = order summary

    return FlowScaffold(
      subtitle: 'Your',
      title: 'My Cart',
      onBack: () =>
          context.canPop() ? context.pop() : context.go('/treatments'),
      actions: [
        if (hasContent)
          FlowGlassPill(
            label: 'Clear',
            onTap: () => ref.read(bookingCartProvider.notifier).clearCart(),
          ),
      ],
      bottomBar: !hasContent
          ? null
          : FlowPrimaryButton(
              label: cart.isFree && cart.items.isEmpty
                  ? 'Book Free Treatment'
                  : 'Proceed to Booking',
              onTap: () => context.push('/booking/therapist'),
            ),
      body: !hasContent
          ? const _EmptyCart()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                _kGutterLeft,
                24,
                _kGutterRight,
                24,
              ),
              itemCount: listItemCount,
              separatorBuilder: (_, __) => const SizedBox(height: _kCardGap),
              itemBuilder: (context, index) {
                final totalItems = freeOffset + cart.items.length;

                // Last index → order summary
                if (index == totalItems) {
                  return _OrderSummary(cart: cart);
                }

                // Index 0 when isFree → free reward card
                if (cart.isFree && index == 0) {
                  return _FreeRewardCartCard(
                    treatmentName: cart.freeRewardTitle ?? 'Free Treatment',
                    onRemove: () => ref
                        .read(bookingCartProvider.notifier)
                        .removeFreeReward(),
                  );
                }

                // Regular treatment card
                final itemIndex = index - freeOffset;
                final item = cart.items[itemIndex];
                return _CartItemCard(
                  item: item,
                  onRemove: () => ref
                      .read(bookingCartProvider.notifier)
                      .removeItem(itemIndex),
                );
              },
            ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kGutterLeft, 40, _kGutterRight, 0),
      child: Column(
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 48,
            color: AppColors.textOnDarkMuted,
          ),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: _calSans(22)),
          const SizedBox(height: 8),
          Text(
            'Add a treatment to start your booking.',
            textAlign: TextAlign.center,
            style: _montserrat(13, color: AppColors.textOnDarkMuted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 220,
            child: FlowPrimaryButton(
              label: 'Browse Treatments',
              onTap: () => context.go('/treatments'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card building blocks ─────────────────────────────────────────────────────

/// Photo card frame with the order-card overlay (#252620 94% → #31322C 78%).
class _PhotoCardFrame extends StatelessWidget {
  final String? imageUrl;
  final Widget child;

  const _PhotoCardFrame({required this.imageUrl, required this.child});

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      _kCardFallback,
      fit: BoxFit.cover,
      alignment: _kCardFallbackCrop,
    );
    final url = imageUrl;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: kFlowCardShadow,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: url != null && url.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox.shrink(),
                    errorWidget: (_, __, ___) => fallback,
                  )
                : fallback,
          ),
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
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}

/// Order-card tag: white 20% fill, hairline white border.
class _Tag extends StatelessWidget {
  final String text;
  final Color? fill;
  const _Tag(this.text, {this.fill});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: fill ?? Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white, width: 0.3),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _montserrat(12),
        ),
      ),
    );
  }
}

/// Small olive action (Re-Order style), used for Remove.
class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: _kPillOlive,
        borderRadius: BorderRadius.circular(6.3),
        child: InkWell(
          borderRadius: BorderRadius.circular(6.3),
          onTap: onTap,
          child: SizedBox(
            width: 107,
            height: 38,
            child: Center(child: Text(label, style: _montserrat(15))),
          ),
        ),
      ),
    );
  }
}

// ── Free reward cart card ────────────────────────────────────────────────────

class _FreeRewardCartCard extends StatelessWidget {
  final String treatmentName;
  final VoidCallback onRemove;

  const _FreeRewardCartCard({
    required this.treatmentName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _PhotoCardFrame(
      imageUrl: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Tag('FREE — Reward Applied', fill: _kRewardGold),
          const SizedBox(height: 14),
          Text(
            treatmentName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _calSans(26, height: 33.868 / 26),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _PriceBlock(label: 'Price', value: 'FREE'),
              ),
              _PillButton(label: 'Remove', onTap: onRemove),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Regular cart item card ───────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;

  const _CartItemCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return _PhotoCardFrame(
      imageUrl: item.treatment.imageUrl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (item.treatment.categoryName.isNotEmpty)
                _Tag(item.treatment.categoryName),
              _Tag('${item.durationMinutes} min'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.treatment.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _calSans(26, height: 33.868 / 26),
          ),
          const SizedBox(height: 4),
          Text(
            formatRupiah(item.basePrice),
            style: _montserrat(12, weight: FontWeight.w300),
          ),
          if (item.addons.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final sel in item.addons)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '+ ${sel.addon.name}'
                        '${sel.quantity > 1 ? ' ×${sel.quantity}' : ''}',
                        style: _montserrat(12, weight: FontWeight.w300),
                      ),
                    ),
                    Text(
                      '+${formatRupiah(sel.subtotal)}',
                      style: _montserrat(12, weight: FontWeight.w300),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _PriceBlock(
                  label: item.addons.isNotEmpty ? 'Item Total' : 'Price',
                  value: formatRupiah(item.price),
                ),
              ),
              _PillButton(label: 'Remove', onTap: onRemove),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Total Price" label over a SemiBold value (order card bottom-left).
class _PriceBlock extends StatelessWidget {
  final String label;
  final String value;
  const _PriceBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _montserrat(11, height: 1.219)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: _montserrat(18, weight: FontWeight.w600, height: 1.219),
          ),
        ),
      ],
    );
  }
}

// ── Order summary ────────────────────────────────────────────────────────────

class _OrderSummary extends StatelessWidget {
  final BookingCart cart;
  const _OrderSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    final isAllFree = cart.isFree && cart.items.isEmpty;
    final muted = _montserrat(13, color: AppColors.textOnDarkMuted);
    final value = _montserrat(13);

    Widget line(String label, String amount, {TextStyle? amountStyle}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(label, style: muted)),
              const SizedBox(width: 12),
              Text(amount, style: amountStyle ?? value),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(_kButtonRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: _calSans(20)),
          const SizedBox(height: 16),

          // Free reward line
          if (cart.isFree)
            line(
              cart.freeRewardTitle ?? 'Free Treatment',
              'FREE',
              amountStyle: _montserrat(
                13,
                weight: FontWeight.w600,
                color: _kRewardGold,
              ),
            ),

          // Regular items
          for (final item in cart.items)
            line(
              item.addons.isNotEmpty
                  ? '${item.treatment.name} + add-ons'
                  : item.treatment.name,
              formatRupiah(item.price),
            ),

          // Voucher / reward discounts (already included in the total)
          if (cart.discountAmount > 0)
            line(
              cart.voucher != null
                  ? 'Discount (${cart.voucher!.code})'
                  : 'Discount',
              '−${formatRupiah(cart.discountAmount)}',
              amountStyle: _montserrat(
                13,
                weight: FontWeight.w500,
                color: _kRewardGold,
              ),
            ),

          Divider(height: 18, color: Colors.white.withValues(alpha: 0.3)),

          // Total
          Row(
            children: [
              Expanded(child: Text('Total', style: _calSans(22))),
              Text(
                isAllFree ? 'FREE' : formatRupiah(cart.total),
                style: _calSans(
                  22,
                ).copyWith(color: isAllFree ? _kRewardGold : Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
