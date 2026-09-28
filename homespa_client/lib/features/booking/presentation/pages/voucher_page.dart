import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/flow_widgets.dart';
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
    final code = (overrideCode ?? _codeController.text.trim()).toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });
    try {
      final result = await ref.read(validateVoucherUseCaseProvider).call(code);
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

    // Vouchers are only blocked when the cart has nothing to discount
    // (i.e. free reward only, no paid treatments).
    final hasPaidItems = cart.items.any((item) => item.price > 0);
    final lockVouchers = cart.isFree && !hasPaidItems;

    return FlowScaffold(
      title: 'Voucher & Discounts',
      header: const BookingStepIndicator(currentStep: 5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(kFlowGutter, 24, kFlowGutter, 24),
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
              FlowCard(
                selected: true,
                child: Row(
                  children: [
                    const Icon(
                      Icons.card_giftcard_rounded,
                      color: kFlowGold,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cart.freeRewardTitle ?? 'Free Reward',
                        style: flowHeading(16),
                      ),
                    ),
                    Text(
                      'Applied',
                      style: flowBody(
                        12,
                        weight: FontWeight.w600,
                        color: kFlowGold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Only block vouchers when there are no paid items to discount.
              if (lockVouchers)
                const _InfoBanner(
                  text:
                      'Your free reward covers everything — no voucher needed.',
                  highlight: true,
                )
              else
                const _InfoBanner(
                  text: 'Vouchers apply to your paid treatments only.',
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
                    const FlowSectionLabel('My Vouchers'),
                    const SizedBox(height: 2),
                    ...clientVouchers.map((cv) {
                      final v = (cv['voucher'] as Map<String, dynamic>?) ?? {};
                      final code = (v['code'] as String?) ?? '';
                      final isApplied = cart.voucher?.code == code;
                      // Skip expired
                      final exp = v['expires_at'] as String?;
                      final expired =
                          exp != null &&
                          (DateTime.tryParse(exp)?.isBefore(DateTime.now()) ??
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
                    const SizedBox(height: 16),
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
                    const FlowSectionLabel('My Rewards'),
                    const SizedBox(height: 2),
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
                          (reward['reward_duration']
                                  as Map?)?['duration_minutes']
                              as int?;

                      final isFreeType = rewardType == 'free_treatment';
                      final isApplied = isFreeType
                          ? cart.freeRewardId == (r['id'] as String?)
                          : cart.rewardRedemptionId == (r['id'] as String?);
                      // Free treatments are never locked — selecting one just
                      // replaces the current free reward. Discount rewards are
                      // locked when the cart has no paid items to discount.
                      final isLocked = isFreeType
                          ? false
                          : (lockVouchers && !isApplied);

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
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // ── Input ───────────────────────────────────────────────────────
            const FlowSectionLabel('Enter Voucher Code'),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    style: flowBody(15, weight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'e.g. KAIZEN20',
                      errorText: _errorMessage,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 17,
                      ),
                    ),
                    onSubmitted: (_) => _applyVoucher(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 96,
                  child: FlowSecondaryButton(
                    label: 'Apply',
                    onTap: _isValidating ? null : _applyVoucher,
                    isLoading: _isValidating,
                  ),
                ),
              ],
            ),

            // ── Order summary ───────────────────────────────────────────────
            if (cart.discountAmount > 0) ...[
              const SizedBox(height: 32),
              const FlowSectionLabel('Savings'),
              const SizedBox(height: 2),
              FlowCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('You save', style: flowBody(14, color: kFlowMuted)),
                    Text(
                      '-${formatRupiah(cart.discountAmount)}',
                      style: flowHeading(20, color: kFlowGold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomBar: FlowPrimaryButton(
        label:
            (cart.voucher != null ||
                cart.rewardRedemptionId != null ||
                cart.isFree)
            ? 'Continue'
            : 'Skip & Continue',
        onTap: () => context.push('/booking/review'),
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

// ── Info banner ───────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final String text;
  final bool highlight;

  const _InfoBanner({required this.text, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final color = highlight ? kFlowGold : kFlowMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(kFlowRadius),
        border: Border.all(
          color: highlight
              ? kFlowGold.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.18),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: flowBody(12, color: color)),
          ),
        ],
      ),
    );
  }
}

// ── Trailing action (lock / applied / use) ────────────────────────────────────

class _CardAction extends StatelessWidget {
  final bool isLocked;
  final bool isApplied;
  final VoidCallback onUse;

  const _CardAction({
    required this.isLocked,
    required this.isApplied,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      return const Icon(
        Icons.lock_outline_rounded,
        color: kFlowMuted,
        size: 18,
      );
    }
    if (isApplied) return const FlowCheckMark(selected: true);
    return FlowGlassPill(label: 'Use This', onTap: onUse);
  }
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
    return Opacity(
      opacity: isLocked ? 0.55 : 1,
      child: FlowCard(
        selected: isApplied,
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: flowHeading(17).copyWith(letterSpacing: 0.5),
                  ),
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(description!, style: flowBody(12, color: kFlowMuted)),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    displayDiscount,
                    style: flowBody(
                      13,
                      weight: FontWeight.w600,
                      color: isLocked ? kFlowMuted : kFlowGold,
                    ),
                  ),
                  if (expiresAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Expires ${DateFormat('d MMM y').format(expiresAt!)}',
                      style: flowBody(11, color: kFlowMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _CardAction(isLocked: isLocked, isApplied: isApplied, onUse: onUse),
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
    return Opacity(
      opacity: isLocked ? 0.55 : 1,
      child: FlowCard(
        selected: isApplied,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(kFlowRadius),
              ),
              child: Icon(
                Icons.card_giftcard_rounded,
                color: isApplied ? kFlowGold : kFlowMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: flowHeading(16)),
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(description!, style: flowBody(12, color: kFlowMuted)),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _rewardLabel,
                    style: flowBody(
                      13,
                      weight: FontWeight.w600,
                      color: isLocked ? kFlowMuted : kFlowGold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _CardAction(isLocked: isLocked, isApplied: isApplied, onUse: onUse),
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
    return FlowCard(
      selected: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.local_offer_rounded, color: kFlowGold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucher.code as String,
                  style: flowHeading(17).copyWith(letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '${voucher.displayDiscount} applied',
                  style: flowBody(
                    12,
                    weight: FontWeight.w500,
                    color: kFlowGold,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRemove,
            child: Text(
              'Remove',
              style: flowBody(13, color: const Color(0xFFFFB4A8)),
            ),
          ),
        ],
      ),
    );
  }
}
