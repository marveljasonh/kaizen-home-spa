import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/booking_cart.dart';
import '../widgets/booking_step_indicator.dart';

class ReviewConfirmPage extends ConsumerWidget {
  const ReviewConfirmPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(bookingCartProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Review & Confirm'),
        bottom: const BookingStepIndicator(currentStep: 6),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('Booking Details'),
            const SizedBox(height: 12),
            _DetailCard(
              children: [
                _DetailRow(
                  icon: Icons.spa_outlined,
                  label: cart.itemCount > 1 ? 'Treatments' : 'Treatment',
                  value: cart.isTotallyFree
                      ? (cart.freeRewardTitle ?? 'Free Treatment')
                      : cart.itemCount > 1
                          ? '${cart.itemCount} treatments'
                          : (cart.treatment?.name ?? '—'),
                ),
                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Therapist',
                  value: cart.therapist?.name ?? 'Any Available',
                ),
                if (cart.selectedDate != null && cart.selectedTimeSlot != null)
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Schedule',
                    value:
                        '${DateFormat('EEE, MMM d').format(cart.selectedDate!)} '
                        '• ${cart.selectedTimeSlot!.displayLabel}',
                  ),
                if (cart.address != null)
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: cart.address!.fullAddress,
                    isLast: true,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle('Order Summary'),
            const SizedBox(height: 12),
            _DetailCard(
              children: [
                if (cart.isTotallyFree) ...[
                  // No paid items — entire booking is covered by the reward
                  _FreeItemRow(
                    title: cart.freeRewardTitle ?? 'Free Treatment',
                    durationMinutes: cart.freeRewardDurationMinutes,
                  ),
                ] else ...[
                  // Paid items
                  ...cart.items.expand((item) => [
                    _PriceRow(
                      label: item.durationMinutes > 0
                          ? '${item.treatment.name} • ${item.durationMinutes} min'
                          : item.treatment.name,
                      value: formatRupiah(item.basePrice),
                    ),
                    ...item.addons.map((sel) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            sel.addon.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        )),
                  ]),
                  // Free reward shown as a treatment item with FREE badge pill
                  if (cart.isFree)
                    _FreeItemRow(
                        title: cart.freeRewardTitle ?? 'Free Treatment'),
                  if (cart.voucher != null)
                    _PriceRow(
                      label: 'Voucher (${cart.voucher!.code})',
                      value: '-${formatRupiah(cart.discountAmount)}',
                      valueColor: AppColors.primary,
                    ),
                  if (cart.rewardDiscount != null)
                    _PriceRow(
                      label: 'Reward Discount',
                      value: '-${formatRupiah(cart.rewardDiscount!)}',
                      valueColor: AppColors.primary,
                    ),
                ],
                const Divider(height: 24),
                _PriceRow(
                  label: 'Total',
                  value: cart.isTotallyFree ? 'FREE' : formatRupiah(cart.total),
                  isBold: true,
                  valueColor: cart.isTotallyFree ? AppColors.primary : null,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'By confirming, you agree to our cancellation policy. '
                      'Free cancellation up to 2 hours before the session.',
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: FilledButton(
            onPressed: () {
              debugPrint('Confirm tapped');
              debugPrint('Cart isFree: ${cart.isFree}');
              debugPrint('Cart freeRewardId: ${cart.freeRewardId}');
              debugPrint('Cart freeRewardTitle: ${cart.freeRewardTitle}');
              debugPrint('Cart freeRewardTreatmentId: ${cart.freeRewardTreatmentId}');
              debugPrint('Cart items count: ${cart.items.length}');
              debugPrint('Cart address: ${cart.address?.fullAddress}');
              debugPrint('Cart date: ${cart.selectedDate}');
              debugPrint('Cart timeSlot: ${cart.selectedTimeSlot}');
              debugPrint('Cart total: ${cart.total}');
              try {
                context.push('/booking/payment');
              } catch (e) {
                debugPrint('Submit error: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              cart.isTotallyFree ? 'Confirm Booking (FREE)' : 'Confirm & Choose Payment',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: text.labelSmall
                            ?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: text.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              height: 1,
              color: AppColors.border.withValues(alpha: 0.15),
              indent: 30),
      ],
    );
  }
}

class _FreeItemRow extends StatelessWidget {
  final String title;
  final int? durationMinutes;
  const _FreeItemRow({required this.title, this.durationMinutes});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final label = durationMinutes != null
        ? '$title • $durationMinutes min'
        : title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.goldLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'FREE',
              style: TextStyle(
                color: AppColors.goldDark,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;
  final bool isLast;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final labelStyle = isBold
        ? AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)
        : text.bodyMedium?.copyWith(color: AppColors.textSecondary);
    final valueStyle = isBold
        ? AppTypography.headingSmall.copyWith(
            fontWeight: FontWeight.w700, color: AppColors.primary)
        : text.bodyMedium
            ?.copyWith(color: valueColor ?? AppColors.textSecondary);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
