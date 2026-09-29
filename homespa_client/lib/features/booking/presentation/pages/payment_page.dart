import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/flow_widgets.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/booking_request.dart';
import '../providers/booking_cart.dart';
import '../providers/booking_providers.dart';
import '../widgets/booking_step_indicator.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool _isLoading = false;
  String? _successBookingId;

  Future<void> _confirmOrder(BookingCart cart) async {
    if ((!cart.isTotallyFree && cart.items.isEmpty) ||
        cart.address == null ||
        cart.scheduledAt == null) {
      return;
    }

    setState(() => _isLoading = true);

    // Already UTC: the Schedule page converts the picked WIB time.
    final scheduledAt = cart.scheduledAt!;

    // treatmentId is unused by the datasource insert but required by BookingRequest.
    final effectiveTreatmentId =
        cart.freeRewardTreatmentId ?? cart.treatment?.id ?? '';

    final request = BookingRequest(
      treatmentId: effectiveTreatmentId,
      treatmentDurationId: cart.selectedDuration?.id,
      therapistId: cart.therapist?.id,
      scheduledAt: scheduledAt,
      addressId: cart.address!.id,
      addressText: cart.address!.fullAddress,
      latitude: cart.address!.latitude,
      longitude: cart.address!.longitude,
      addressNotes: cart.address!.notes,
      voucherCode: cart.voucher?.code,
      paymentMethodId: cart.isTotallyFree ? 'reward' : 'cash',
      subtotal: cart.subtotal,
      discountAmount: cart.discountAmount,
      total: cart.total,
      items: cart.items
          .map(
            (item) => BookingItemRequest(
              treatmentDurationId: item.selectedDuration?.id,
              treatmentName: item.treatment.name,
              durationMinutes: item.durationMinutes,
              unitPrice: item.basePrice,
            ),
          )
          .toList(),
      freeRewardId: cart.freeRewardId,
      freeRewardTreatmentId: cart.freeRewardTreatmentId,
      freeRewardDurationMinutes: cart.freeRewardDurationMinutes,
      rewardRedemptionId: cart.rewardRedemptionId,
      addons: cart.items
          .expand((item) => item.addons)
          .map(
            (sel) => BookingAddonRequest(
              addonId: sel.addon.id,
              addonName: sel.addon.name,
              unitPrice: sel.addon.price,
              quantity: sel.quantity,
            ),
          )
          .toList(),
    );

    final result = await ref.read(createBookingUseCaseProvider).call(request);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: const Color(0xFFB3261E),
          ),
        );
      },
      (bookingId) {
        ref.read(bookingCartProvider.notifier).clearCart();
        setState(() => _successBookingId = bookingId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_successBookingId != null) {
      return _SuccessScreen(bookingId: _successBookingId!);
    }

    final cart = ref.watch(bookingCartProvider);

    return FlowScaffold(
      title: 'Payment',
      header: const BookingStepIndicator(currentStep: 6),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(kFlowGutter, 24, kFlowGutter, 8),
        children: [
          // ── Payment method ────────────────────────────────────────────────
          if (cart.isTotallyFree) ...[
            const _MethodCard(
              icon: Icons.card_giftcard_rounded,
              iconColor: kFlowGold,
              title: 'FREE — Reward Applied',
              titleColor: kFlowGold,
              subtitle: 'No payment required for this booking',
            ),
            const SizedBox(height: 28),
          ] else ...[
            const FlowSectionLabel('Payment Method'),
            const _MethodCard(
              icon: Icons.payments_rounded,
              title: 'Cash on Delivery',
              subtitle: 'Pay in cash when the therapist arrives',
              selected: true,
            ),
            const SizedBox(height: 28),
          ],

          // ── Order summary ─────────────────────────────────────────────────
          _OrderSummaryCard(cart: cart),
          const SizedBox(height: 32),
        ],
      ),
      bottomBar: FlowPrimaryButton(
        label: cart.isTotallyFree
            ? 'Confirm Order • FREE'
            : 'Confirm Order • ${formatRupiah(cart.total)}',
        isLoading: _isLoading,
        onTap: ((!cart.isTotallyFree && cart.items.isEmpty) || _isLoading)
            ? null
            : () => _confirmOrder(cart),
      ),
    );
  }
}

// ── Payment method card ────────────────────────────────────────────────────────

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final String subtitle;
  final bool selected;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = Colors.white,
    this.titleColor = Colors.white,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return FlowCard(
      selected: selected,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(kFlowRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: flowBody(
                    15,
                    weight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: flowBody(12, color: kFlowMuted)),
              ],
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 8),
            const FlowCheckMark(selected: true),
          ],
        ],
      ),
    );
  }
}

// ── Order summary card ─────────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  final BookingCart cart;

  const _OrderSummaryCard({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(kFlowRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: flowHeading(20)),
          const SizedBox(height: 16),

          // Paid treatment items
          ...cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryRow(
                    label: item.durationMinutes > 0
                        ? '${item.treatment.name} • ${item.durationMinutes} min'
                        : item.treatment.name,
                    value: formatRupiah(item.basePrice),
                  ),
                  ...item.addons.map(
                    (sel) => Padding(
                      padding: const EdgeInsets.only(top: 4, left: 12),
                      child: _SummaryRow(
                        label: '+ ${sel.addon.name}',
                        value: formatRupiah(sel.subtotal),
                        dimmed: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Free reward shown as a treatment item with FREE badge pill
          if (cart.isFree)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      cart.freeRewardDurationMinutes != null
                          ? '${cart.freeRewardTitle ?? 'Free Treatment'} • ${cart.freeRewardDurationMinutes} min'
                          : cart.freeRewardTitle ?? 'Free Treatment',
                      style: flowBody(13, color: kFlowMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: kFlowGold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: kFlowGold.withValues(alpha: 0.6),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'FREE',
                      style: flowBody(
                        11,
                        weight: FontWeight.w700,
                        color: kFlowGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const _Divider(),

          // Subtotal (paid items only)
          _SummaryRow(label: 'Subtotal', value: formatRupiah(cart.subtotal)),

          // Voucher / discount reward line
          if (cart.discountAmount > 0) ...[
            const SizedBox(height: 6),
            _SummaryRow(
              label: cart.voucher != null
                  ? 'Voucher (${cart.voucher!.code})'
                  : 'Discount',
              value: '-${formatRupiah(cart.discountAmount)}',
              valueColor: kFlowGold,
            ),
          ],

          const _Divider(),

          // Total
          Row(
            children: [
              Expanded(child: Text('Total', style: flowHeading(22))),
              Text(
                cart.isTotallyFree ? 'FREE' : formatRupiah(cart.total),
                style: flowHeading(
                  22,
                  color: cart.isTotallyFree ? kFlowGold : Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool dimmed;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.dimmed = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = flowBody(dimmed ? 12 : 13, color: kFlowMuted);
    final valueStyle = dimmed
        ? flowBody(12, color: kFlowMuted)
        : flowBody(
            13,
            weight: FontWeight.w500,
            color: valueColor ?? Colors.white,
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: labelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.3)),
  );
}

// ── Success screen ─────────────────────────────────────────────────────────────

class _SuccessScreen extends StatelessWidget {
  final String bookingId;
  const _SuccessScreen({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final shortId = bookingId.length >= 8
        ? bookingId.substring(0, 8).toUpperCase()
        : bookingId.toUpperCase();

    // No back button — success is a terminal state
    return Theme(
      data: flowTheme(context),
      child: Scaffold(
        backgroundColor: kFlowPageColor,
        body: Stack(
          children: [
            const Positioned.fill(child: FlowBackground()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Check icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: kFlowAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.2),
                        boxShadow: kFlowCardShadow,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 28),

                    Text(
                      'Booking Confirmed!',
                      style: flowHeading(28),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(kFlowRadius),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        'Booking #$shortId',
                        style: flowBody(
                          14,
                          weight: FontWeight.w600,
                        ).copyWith(letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Our therapist will arrive at your location at the scheduled time. Pay in cash on arrival.',
                      style: flowBody(14, color: kFlowMuted, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    FlowPrimaryButton(
                      label: 'Back to Home',
                      onTap: () => context.go('/'),
                    ),
                    const SizedBox(height: 12),
                    FlowSecondaryButton(
                      label: 'View My Bookings',
                      onTap: () => context.go('/bookings'),
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
