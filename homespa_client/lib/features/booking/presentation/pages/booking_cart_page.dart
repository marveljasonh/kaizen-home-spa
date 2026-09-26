import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/booking_cart.dart';

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
    final text = Theme.of(context).textTheme;
    final hasContent = cart.items.isNotEmpty || cart.isFree;

    debugPrint('[Cart] items total: ${cart.items.fold(0.0, (sum, i) => sum + i.price)}');
    debugPrint('[Cart] discount amount: ${cart.discountAmount}');
    debugPrint('[Cart] voucher: ${cart.voucher}');
    debugPrint('[Cart] reward discount: ${cart.rewardDiscount} (type: ${cart.rewardDiscountType})');
    debugPrint('[Cart] calculated total: ${cart.total}');

    // Total rows in the list: free reward card (0 or 1) + regular items + order summary
    final freeOffset = cart.isFree ? 1 : 0;
    final listItemCount = freeOffset + cart.items.length + 1; // +1 = order summary

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          if (hasContent)
            TextButton(
              onPressed: () =>
                  ref.read(bookingCartProvider.notifier).clearCart(),
              child: const Text('Clear'),
            ),
        ],
      ),
      body: !hasContent
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 56, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('Your cart is empty',
                      style: text.titleMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/treatments'),
                    child: const Text('Browse Treatments'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: listItemCount,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final totalItems = freeOffset + cart.items.length;

                // Last index → order summary
                if (index == totalItems) {
                  return _OrderSummary(cart: cart);
                }

                // Index 0 when isFree → free reward card
                if (cart.isFree && index == 0) {
                  return _FreeRewardCartCard(
                    treatmentName:
                        cart.freeRewardTitle ?? 'Free Treatment',
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
      bottomNavigationBar: !hasContent
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: FilledButton(
                  onPressed: () => context.push('/booking/therapist'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    cart.isFree && cart.items.isEmpty
                        ? 'Book Free Treatment'
                        : 'Proceed to Booking',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
    );
  }
}

// ── Free reward cart card ──────────────────────────────────────────────────────

class _FreeRewardCartCard extends StatelessWidget {
  final String treatmentName;
  final VoidCallback onRemove;

  const _FreeRewardCartCard({
    required this.treatmentName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.goldLight.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldDark.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.goldLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.card_giftcard_rounded,
                color: AppColors.goldDark, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  treatmentName,
                  style:
                      text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.goldDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'FREE — Reward Applied',
                    style: text.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded,
                size: 20, color: AppColors.textSecondary),
            tooltip: 'Remove reward',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Regular cart item card ─────────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;

  const _CartItemCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                Icon(Icons.spa_rounded, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.treatment.name,
                    style: text.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(item.treatment.categoryName,
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${item.durationMinutes} min',
                        style: text.labelSmall
                            ?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    Text(
                      formatRupiah(item.basePrice),
                      style: text.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (item.addons.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...item.addons.map(
                    (sel) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline_rounded,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${sel.addon.name}'
                              '${sel.quantity > 1 ? ' ×${sel.quantity}' : ''}',
                              style: text.labelSmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          Text(
                            '+${formatRupiah(sel.subtotal)}',
                            style: text.labelSmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Item total: ${formatRupiah(item.price)}',
                    style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(item.price),
                    style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded,
                size: 20, color: AppColors.textSecondary),
            tooltip: 'Remove',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Order summary card ─────────────────────────────────────────────────────────

class _OrderSummary extends StatelessWidget {
  final BookingCart cart;
  const _OrderSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isAllFree = cart.isFree && cart.items.isEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORDER SUMMARY',
            style: AppTypography.overline.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Free reward line
          if (cart.isFree)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      cart.freeRewardTitle ?? 'Free Treatment',
                      style: text.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  Text(
                    'FREE',
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.goldDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

          // Regular items
          ...cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.addons.isNotEmpty
                          ? '${item.treatment.name} + add-ons'
                          : item.treatment.name,
                      style: text.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  Text(formatRupiah(item.price), style: text.bodyMedium),
                ],
              ),
            ),
          ),

          const Divider(height: 20),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style:
                      text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              Text(
                isAllFree ? 'FREE' : formatRupiah(cart.total),
                style: AppTypography.headingMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      isAllFree ? AppColors.goldDark : AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
