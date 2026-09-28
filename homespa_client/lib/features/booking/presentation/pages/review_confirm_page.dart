import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../../../core/widgets/flow_widgets.dart';
import '../providers/booking_cart.dart';
import '../widgets/booking_step_indicator.dart';

class ReviewConfirmPage extends ConsumerWidget {
  const ReviewConfirmPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(bookingCartProvider);
    return FlowScaffold(
      title: 'Review & Confirm',
      header: const BookingStepIndicator(currentStep: 6),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(kFlowGutter, 24, kFlowGutter, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailCard(
              title: 'Booking Details',
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
                if (cart.scheduledAt != null)
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Schedule',
                    value:
                        '${DateFormat('EEE, MMM d').format(WIB.toWIB(cart.scheduledAt!))} '
                        '• ${WIB.formatTime(cart.scheduledAt!)} WIB',
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
            const SizedBox(height: 16),
            _DetailCard(
              title: 'Order Summary',
              children: [
                if (cart.isTotallyFree) ...[
                  // No paid items — entire booking is covered by the reward
                  _FreeItemRow(
                    title: cart.freeRewardTitle ?? 'Free Treatment',
                    durationMinutes: cart.freeRewardDurationMinutes,
                  ),
                ] else ...[
                  // Paid items
                  ...cart.items.expand(
                    (item) => [
                      _PriceRow(
                        label: item.durationMinutes > 0
                            ? '${item.treatment.name} • ${item.durationMinutes} min'
                            : item.treatment.name,
                        value: formatRupiah(item.basePrice),
                      ),
                      ...item.addons.map(
                        (sel) => Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 8),
                          child: Text(
                            sel.addon.name,
                            style: flowBody(12, color: kFlowMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Free reward shown as a treatment item with FREE badge pill
                  if (cart.isFree)
                    _FreeItemRow(
                      title: cart.freeRewardTitle ?? 'Free Treatment',
                    ),
                  if (cart.voucher != null)
                    _PriceRow(
                      label: 'Voucher (${cart.voucher!.code})',
                      value: '-${formatRupiah(cart.discountAmount)}',
                      valueColor: kFlowGold,
                    ),
                  if (cart.rewardDiscount != null)
                    _PriceRow(
                      label: 'Reward Discount',
                      value: '-${formatRupiah(cart.rewardDiscount!)}',
                      valueColor: kFlowGold,
                    ),
                ],
                Divider(height: 24, color: Colors.white.withValues(alpha: 0.2)),
                _PriceRow(
                  label: 'Total',
                  value: cart.isTotallyFree ? 'FREE' : formatRupiah(cart.total),
                  isBold: true,
                  valueColor: cart.isTotallyFree ? kFlowGold : null,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(kFlowRadius),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: kFlowMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'By confirming, you agree to our cancellation policy. '
                      'Free cancellation up to 2 hours before the session.',
                      style: flowBody(12, color: kFlowMuted, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomBar: FlowPrimaryButton(
        label: cart.isTotallyFree
            ? 'Confirm Booking (FREE)'
            : 'Confirm & Choose Payment',
        onTap: () {
          debugPrint('Confirm tapped');
          debugPrint('Cart isFree: ${cart.isFree}');
          debugPrint('Cart freeRewardId: ${cart.freeRewardId}');
          debugPrint('Cart freeRewardTitle: ${cart.freeRewardTitle}');
          debugPrint(
            'Cart freeRewardTreatmentId: ${cart.freeRewardTreatmentId}',
          );
          debugPrint('Cart items count: ${cart.items.length}');
          debugPrint('Cart address: ${cart.address?.fullAddress}');
          debugPrint(
            'Cart scheduledAt: ${cart.scheduledAt} UTC '
            '(${WIB.formatTime(cart.scheduledAt!)} WIB)',
          );
          debugPrint('Cart total: ${cart.total}');
          try {
            context.push('/booking/payment');
          } catch (e) {
            debugPrint('Submit error: $e');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _DetailCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return FlowCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: flowHeading(20)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: flowBody(12, color: kFlowMuted)),
                    const SizedBox(height: 2),
                    Text(value, style: flowBody(14, weight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.2),
            indent: 30,
          ),
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
    final label = durationMinutes != null
        ? '$title • $durationMinutes min'
        : title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: flowBody(13, color: kFlowMuted)),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: kFlowGold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kFlowGold, width: 0.5),
            ),
            child: Text(
              'FREE',
              style: flowBody(11, weight: FontWeight.w700, color: kFlowGold),
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
    final labelStyle = isBold
        ? flowHeading(22)
        : flowBody(13, color: kFlowMuted);
    final valueStyle = isBold
        ? flowHeading(22, color: valueColor ?? Colors.white)
        : flowBody(13, color: valueColor ?? Colors.white);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          const SizedBox(width: 12),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
