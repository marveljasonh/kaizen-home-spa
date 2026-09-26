import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../promo/presentation/providers/rewards_provider.dart';
import '../providers/booking_cart.dart';
import '../providers/booking_providers.dart';
import '../widgets/booking_step_indicator.dart';

class VoucherPage extends ConsumerStatefulWidget {
  const VoucherPage({super.key});

  @override
  ConsumerState<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends ConsumerState<VoucherPage> {
  final _codeController = TextEditingController();
  bool _isValidating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _applyReward(Map<String, dynamic> redemption) {
    final reward = (redemption['rewards'] as Map<String, dynamic>?) ?? {};
    final rewardType = (reward['reward_type'] as String?) ?? '';
    final notifier = ref.read(bookingCartProvider.notifier);

    if (rewardType == 'free_treatment') {
      final title = (reward['title'] as String?) ?? 'Free Treatment';
      final duration =
          (reward['reward_duration'] as Map?)?['duration_minutes'] as int? ?? 0;
      notifier.applyFreeReward(
        redemption['id'] as String,
        title,
        treatmentId: reward['reward_treatment_id'] as String?,
        durationMinutes: duration,
      );
    } else {
      final rewardValue = (reward['reward_value'] as num?)?.toInt() ?? 0;
      final type = rewardType == 'discount_percentage' ? 'percentage' : 'flat';
      notifier.applyDiscountReward(
        redemption['id'] as String,
        rewardValue,
        type,
      );
    }
  }

  Future<void> _applyVoucher([String? overrideCode]) async {
    final code =
        (overrideCode ?? _codeController.text.trim()).toUpperCase();
    if (code.isEmpty) return;
    setState(() { _isValidating = true; _errorMessage = null; });
    try {
      final result =
          await ref.read(validateVoucherUseCaseProvider).call(code);
      result.fold(
        (failure) => setState(() => _errorMessage = failure.message),
        (voucher) {
          ref.read(bookingCartProvider.notifier).applyVoucher(voucher);
          if (overrideCode == null) _codeController.clear();
        },
      );
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(bookingCartProvider);
    final clientVouchersAsync = ref.watch(clientVouchersProvider);
    final myRedemptionsAsync = ref.watch(myRedemptionsProvider);
    final text = Theme.of(context).textTheme;

    // Vouchers are only blocked when the cart has nothing to discount
    // (i.e. free reward only, no paid treatments).
    final hasPaidItems = cart.items.any((item) => item.price > 0);
    final lockVouchers = cart.isFree && !hasPaidItems;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Voucher & Discounts'),
        bottom: const BookingStepIndicator(currentStep: 5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Applied voucher ─────────────────────────────────────────────
            if (cart.voucher != null) ...[
              _AppliedVoucherCard(
                voucher: cart.voucher!,
                onRemove: () {
                  ref.read(bookingCartProvider.notifier).removeVoucher();
                },
                savings: cart.discountAmount,
              ),
              const SizedBox(height: 16),
            ],

            // ── Applied free reward ──────────────────────────────────────────
            if (cart.isFree) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.goldLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.goldDark.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.card_giftcard_rounded,
                        color: AppColors.goldDark, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cart.freeRewardTitle ?? 'Free Reward',
                        style: text.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldDark),
                      ),
                    ),
                    Text('Applied',
                        style: text.labelSmall?.copyWith(
                            color: AppColors.goldDark,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Only block vouchers when there are no paid items to discount.
              if (lockVouchers)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.amber.shade800, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your free reward covers everything — no voucher needed.',
                          style: text.bodySmall
                              ?.copyWith(color: Colors.amber.shade800),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vouchers apply to your paid treatments only.',
                          style: text.bodySmall
                              ?.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],

            // ── My vouchers ─────────────────────────────────────────────────
            clientVouchersAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (clientVouchers) {
                if (clientVouchers.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Vouchers',
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ...clientVouchers.map((cv) {
                      final v =
                          (cv['voucher'] as Map<String, dynamic>?) ?? {};
                      final code = (v['code'] as String?) ?? '';
                      final isApplied = cart.voucher?.code == code;
                      // Skip expired
                      final exp = v['expires_at'] as String?;
                      final expired = exp != null &&
                          (DateTime.tryParse(exp)
                                  ?.isBefore(DateTime.now()) ??
                              false);
                      if (expired) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AvailableVoucherCard(
                          code: code,
                          displayDiscount: _discountText(v),
                          description: v['description'] as String?,
                          expiresAt: exp != null
                              ? DateTime.tryParse(exp)
                              : null,
                          isApplied: isApplied,
                          isLocked: lockVouchers,
                          onUse: () => _applyVoucher(code),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),

            // ── My rewards ──────────────────────────────────────────────────
            myRedemptionsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (redemptions) {
                if (redemptions.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Rewards',
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ...redemptions.map((r) {
                      final reward =
                          (r['rewards'] as Map<String, dynamic>?) ?? {};
                      final title = (reward['title'] as String?) ?? 'Reward';
                      final description = reward['description'] as String?;
                      final rewardType =
                          (reward['reward_type'] as String?) ?? '';
                      final rewardValue =
                          (reward['reward_value'] as num?)?.toDouble() ?? 0;
                      final treatmentName =
                          (reward['reward_treatment'] as Map?)?['name']
                              as String?;
                      final durationMinutes =
                          (reward['reward_duration'] as Map?)?[
                              'duration_minutes'] as int?;

                      final isFreeType = rewardType == 'free_treatment';
                      final isApplied = isFreeType
                          ? cart.freeRewardId == (r['id'] as String?)
                          : cart.rewardRedemptionId == (r['id'] as String?);
                      // Free treatments are never locked — selecting one just
                      // replaces the current free reward. Discount rewards are
                      // locked when the cart has no paid items to discount.
                      final isLocked =
                          isFreeType ? false : (lockVouchers && !isApplied);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SelectableRewardCard(
                          title: title,
                          description: description,
                          rewardType: rewardType,
                          rewardValue: rewardValue,
                          treatmentName: treatmentName,
                          durationMinutes: durationMinutes,
                          isApplied: isApplied,
                          isLocked: isLocked,
                          onUse: () => _applyReward(r),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),

            // ── Input ───────────────────────────────────────────────────────
            Text('Enter Voucher Code',
                style:
                    text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'e.g. KAIZEN20',
                      errorText: _errorMessage,
                      filled: true,
                      fillColor: AppColors.surfaceVariant
                          .withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFFD32F2F)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => _applyVoucher(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isValidating ? null : _applyVoucher,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isValidating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Apply',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),

            // ── Order summary ───────────────────────────────────────────────
            if (cart.discountAmount > 0) ...[
              const SizedBox(height: 32),
              Text('Savings',
                  style: text.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('You save',
                        style: text.bodyMedium
                            ?.copyWith(color: AppColors.primary)),
                    Text(
                      '-${formatRupiah(cart.discountAmount)}',
                      style: AppTypography.headingSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: FilledButton(
            onPressed: () => context.push('/booking/review'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              (cart.voucher != null ||
                      cart.rewardRedemptionId != null ||
                      cart.isFree)
                  ? 'Continue'
                  : 'Skip & Continue',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

String _discountText(Map<String, dynamic> v) {
  final type = v['discount_type'] as String?;
  final value = (v['discount_value'] as num?)?.toDouble() ?? 0;
  if (type == 'percentage') return '${value.toInt()}% off';
  if (type == 'flat') return '${formatRupiah(value)} off';
  return '';
}

// ── Available voucher card ─────────────────────────────────────────────────────

class _AvailableVoucherCard extends StatelessWidget {
  final String code;
  final String displayDiscount;
  final String? description;
  final DateTime? expiresAt;
  final bool isApplied;
  final bool isLocked;
  final VoidCallback onUse;

  const _AvailableVoucherCard({
    required this.code,
    required this.displayDiscount,
    this.description,
    this.expiresAt,
    required this.isApplied,
    this.isLocked = false,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final effectiveColor = isLocked
        ? AppColors.surfaceVariant.withValues(alpha: 0.5)
        : isApplied
            ? AppColors.primaryLight.withValues(alpha: 0.2)
            : AppColors.surface;
    final borderColor = isLocked
        ? AppColors.border.withValues(alpha: 0.15)
        : isApplied
            ? AppColors.primary.withValues(alpha: 0.5)
            : AppColors.border.withValues(alpha: 0.2);
    final accentColor =
        isLocked ? AppColors.textMuted : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(14)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            code,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isLocked
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (description != null &&
                              description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(description!,
                                style: text.bodySmall?.copyWith(
                                    color: AppColors.textSecondary)),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            displayDiscount,
                            style: text.bodySmall?.copyWith(
                              color: isLocked
                                  ? AppColors.textMuted
                                  : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (expiresAt != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Expires ${DateFormat('d MMM y').format(expiresAt!)}',
                              style: text.labelSmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isLocked)
                      Icon(Icons.lock_outline_rounded,
                          color: AppColors.textMuted, size: 18)
                    else if (isApplied)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Applied',
                          style: text.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      )
                    else
                      FilledButton.tonal(
                        onPressed: onUse,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(72, 34),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Use This',
                            style: TextStyle(fontWeight: FontWeight.w600)),
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

// ── Selectable reward card ────────────────────────────────────────────────────

class _SelectableRewardCard extends StatelessWidget {
  final String title;
  final String? description;
  final String rewardType;
  final double rewardValue;
  final String? treatmentName;
  final int? durationMinutes;
  final bool isApplied;
  final bool isLocked;
  final VoidCallback onUse;

  const _SelectableRewardCard({
    required this.title,
    required this.description,
    required this.rewardType,
    required this.rewardValue,
    this.treatmentName,
    this.durationMinutes,
    required this.isApplied,
    this.isLocked = false,
    required this.onUse,
  });

  String get _rewardLabel {
    if (rewardType == 'free_treatment') {
      final name = treatmentName ?? 'Treatment';
      return durationMinutes != null
          ? 'Free $name ($durationMinutes min)'
          : 'Free $name';
    }
    if (rewardType == 'discount_percentage') {
      return '${rewardValue.toInt()}% off';
    }
    return '${formatRupiah(rewardValue)} off';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final cardColor = isLocked
        ? AppColors.surfaceVariant.withValues(alpha: 0.5)
        : isApplied
            ? AppColors.goldLight.withValues(alpha: 0.3)
            : AppColors.surface;
    final borderColor = isLocked
        ? AppColors.border.withValues(alpha: 0.15)
        : isApplied
            ? AppColors.goldDark.withValues(alpha: 0.5)
            : AppColors.border.withValues(alpha: 0.2);
    final iconBg = isLocked
        ? AppColors.surfaceVariant
        : isApplied
            ? AppColors.goldLight
            : AppColors.surfaceVariant;
    final iconColor = isLocked
        ? AppColors.textMuted
        : isApplied
            ? AppColors.goldDark
            : AppColors.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.card_giftcard_rounded,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(description!,
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    _rewardLabel,
                    style: text.bodySmall?.copyWith(
                      color: AppColors.goldDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isLocked)
              Icon(Icons.lock_outline_rounded,
                  color: AppColors.textMuted, size: 18)
            else if (isApplied)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.goldDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Applied',
                  style: text.labelSmall?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              )
            else
              FilledButton.tonal(
                onPressed: onUse,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(72, 34),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Use This',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Applied voucher card ───────────────────────────────────────────────────────

class _AppliedVoucherCard extends StatelessWidget {
  final dynamic voucher;
  final double savings;
  final VoidCallback onRemove;

  const _AppliedVoucherCard({
    required this.voucher,
    required this.savings,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(voucher.code as String,
                    style: text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                Text(
                  '${voucher.displayDiscount} applied',
                  style: text.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRemove,
            child: Text('Remove',
                style: TextStyle(color: const Color(0xFFD32F2F), fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
