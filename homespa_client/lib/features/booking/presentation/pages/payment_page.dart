import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/timezone_helper.dart';
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
        cart.selectedDate == null ||
        cart.selectedTimeSlot == null) {
      return;
    }

    setState(() => _isLoading = true);

    // selectedDate and selectedTimeSlot.hour are in WIB (UTC+7).
    // Build a UTC DateTime: treat the WIB fields as UTC-midnight, then subtract 7h.
    final scheduledAt = DateTime.utc(
      cart.selectedDate!.year,
      cart.selectedDate!.month,
      cart.selectedDate!.day,
      cart.selectedTimeSlot!.hour,
    ).subtract(const Duration(hours: WIB.offsetHours));

    // treatmentId is unused by the datasource insert but required by BookingRequest.
    final effectiveTreatmentId =
        cart.freeRewardTreatmentId ?? cart.treatment?.id ?? '';

    final request = BookingRequest(
      treatmentId: effectiveTreatmentId,
      treatmentDurationId: cart.selectedDuration?.id,
      therapistId: cart.therapist?.id,
      scheduledAt: scheduledAt,
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
              .map((item) => BookingItemRequest(
                    treatmentDurationId: item.selectedDuration?.id,
                    treatmentName: item.treatment.name,
                    durationMinutes: item.durationMinutes,
                    unitPrice: item.basePrice,
                  ))
              .toList(),
      freeRewardId: cart.freeRewardId,
      freeRewardTreatmentId: cart.freeRewardTreatmentId,
      freeRewardDurationMinutes: cart.freeRewardDurationMinutes,
      rewardRedemptionId: cart.rewardRedemptionId,
      addons: cart.items
          .expand((item) => item.addons)
          .map((sel) => BookingAddonRequest(
                addonId: sel.addon.id,
                addonName: sel.addon.name,
                unitPrice: sel.addon.price,
                quantity: sel.quantity,
              ))
          .toList(),
    );

    final result =
        await ref.read(createBookingUseCaseProvider).call(request);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Theme.of(context).colorScheme.error,
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
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment'),
        bottom: const BookingStepIndicator(currentStep: 6),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        children: [
          // ── Payment method ────────────────────────────────────────────────
          if (cart.isTotallyFree) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.goldLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.goldDark.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.goldDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.card_giftcard_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FREE — Reward Applied',
                            style: text.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldDark)),
                        const SizedBox(height: 2),
                        Text('No payment required for this booking',
                            style: text.bodySmall
                                ?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ] else ...[
            Text('Payment Method',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _CodCard(text: text),
            const SizedBox(height: 28),
          ],

          // ── Order summary ─────────────────────────────────────────────────
          Text('Order Summary',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _OrderSummaryCard(
            cart: cart,
            text: text,
          ),
          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: FilledButton(
            onPressed: ((!cart.isTotallyFree && cart.items.isEmpty) || _isLoading)
                ? null
                : () => _confirmOrder(cart),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    cart.isTotallyFree
                        ? 'Confirm Order • FREE'
                        : 'Confirm Order • ${formatRupiah(cart.total)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── COD card ───────────────────────────────────────────────────────────────────

class _CodCard extends StatelessWidget {
  final TextTheme text;
  const _CodCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.payments_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cash on Delivery',
                    style: text.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Pay in cash when the therapist arrives',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.check_circle_rounded,
              color: AppColors.primary, size: 22),
        ],
      ),
    );
  }
}

// ── Order summary card ─────────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  final BookingCart cart;
  final TextTheme text;

  const _OrderSummaryCard({
    required this.cart,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Paid treatment items
          ...cart.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryRow(
                      label: item.durationMinutes > 0
                          ? '${item.treatment.name} • ${item.durationMinutes} min'
                          : item.treatment.name,
                      value: formatRupiah(item.basePrice),
                      text: text,
                    ),
                    ...item.addons.map(
                      (sel) => Padding(
                        padding: const EdgeInsets.only(top: 4, left: 12),
                        child: _SummaryRow(
                          label: '+ ${sel.addon.name}',
                          value: formatRupiah(sel.subtotal),
                          text: text,
                          dimmed: true,
                        ),
                      ),
                    ),
                  ],
                ),
              )),

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
                      style: text.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
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
            ),

          _Divider(),

          // Subtotal (paid items only)
          _SummaryRow(
            label: 'Subtotal',
            value: formatRupiah(cart.subtotal),
            text: text,
          ),

          // Voucher / discount reward line
          if (cart.discountAmount > 0) ...[
            const SizedBox(height: 6),
            _SummaryRow(
              label: cart.voucher != null
                  ? 'Voucher (${cart.voucher!.code})'
                  : 'Discount',
              value: '-${formatRupiah(cart.discountAmount)}',
              text: text,
              valueColor: AppColors.primary,
            ),
          ],

          _Divider(),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: AppTypography.labelLarge
                      .copyWith(fontWeight: FontWeight.w800)),
              Text(
                cart.isTotallyFree ? 'FREE' : formatRupiah(cart.total),
                style: AppTypography.headingMedium.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.primary),
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
  final TextTheme text;
  final bool dimmed;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.text,
    this.dimmed = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = dimmed
        ? text.bodySmall?.copyWith(color: AppColors.textSecondary)
        : text.bodyMedium?.copyWith(color: AppColors.textSecondary);
    final valueStyle = dimmed
        ? text.bodySmall?.copyWith(color: AppColors.textSecondary)
        : text.bodyMedium?.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label,
              style: labelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
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
        child: Divider(
            height: 1, color: AppColors.border.withValues(alpha: 0.2)),
      );
}

// ── Success screen ─────────────────────────────────────────────────────────────

class _SuccessScreen extends StatelessWidget {
  final String bookingId;
  const _SuccessScreen({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final shortId = bookingId.length >= 8
        ? bookingId.substring(0, 8).toUpperCase()
        : bookingId.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      // No back button — success is a terminal state
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Check icon
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 56),
              ),
              const SizedBox(height: 28),

              Text('Booking Confirmed!',
                  style: text.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Booking #$shortId',
                  style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Our therapist will arrive at your location at the scheduled time. Pay in cash on arrival.',
                style: text.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              FilledButton(
                onPressed: () => context.go('/'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back to Home',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/bookings'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('View My Bookings',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
