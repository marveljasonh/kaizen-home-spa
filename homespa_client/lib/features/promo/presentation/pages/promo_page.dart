import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../booking/presentation/providers/booking_cart.dart';
import '../../../promo/domain/entities/promo_banner.dart';
import '../providers/promo_providers.dart';
import '../providers/rewards_provider.dart';

class PromoPage extends ConsumerStatefulWidget {
  const PromoPage({super.key});

  @override
  ConsumerState<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends ConsumerState<PromoPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _codeController = TextEditingController();
  bool _isApplying = false;
  String? _applyError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _applyCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _isApplying = true; _applyError = null; });

    try {
      final voucher = await Supabase.instance.client
          .from('vouchers')
          .select('id')
          .eq('code', code)
          .eq('is_active', true)
          .maybeSingle();

      if (!mounted) return;

      if (voucher == null) {
        setState(() {
          _applyError = 'Promo code not found or inactive';
          _isApplying = false;
        });
        return;
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client.from('client_vouchers').upsert(
          {'client_id': userId, 'voucher_id': voucher['id']},
          onConflict: 'client_id,voucher_id',
        );
      }

      _codeController.clear();
      ref.invalidate(clientVouchersProvider);
      if (!mounted) return;
      setState(() { _isApplying = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voucher saved to My Vouchers!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _applyError = 'Failed to validate code. Try again.';
        _isApplying = false;
      });
    }
  }

  void _onRewardRedeemed() {
    ref.invalidate(myRedemptionsProvider);
    ref.invalidate(unusedVouchersProvider);
    _tabController.animateTo(0);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reward added to My Rewards!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _usePromoVoucher(String code) {
    // Voucher is applied during booking checkout in voucher_page.dart.
    context.go('/treatments');
  }

  Future<void> _useReward(Map<String, dynamic> redemption) async {
    debugPrint('[UseReward] full redemption data: ${redemption.toString()}');
    debugPrint('[UseReward] reward type: ${redemption['rewards']?['reward_type']}');
    debugPrint('[UseReward] reward_treatment_id: ${redemption['rewards']?['reward_treatment_id']}');
    debugPrint('[UseReward] reward_duration: ${redemption['rewards']?['reward_duration']}');

    final reward = (redemption['rewards'] as Map<String, dynamic>?) ?? {};
    final rewardType = (reward['reward_type'] as String?) ?? '';
    final rewardTitle = (reward['title'] as String?) ?? 'Reward';
    final rewardValue = (reward['reward_value'] as num?)?.toInt() ?? 0;

    debugPrint('[UseReward] parsed rewardType: $rewardType');
    debugPrint('[UseReward] parsed rewardTitle: $rewardTitle');

    if (rewardType == 'free_treatment') {
      final durationMinutes =
          (reward['reward_duration'] as Map<String, dynamic>?)?['duration_minutes'] as int? ?? 0;
      if (!mounted) return;
      ref.read(bookingCartProvider.notifier).applyFreeReward(
            redemption['id'] as String,
            rewardTitle,
            treatmentId: reward['reward_treatment_id'] as String?,
            durationMinutes: durationMinutes,
          );
      context.push('/booking/cart');
    } else {
      // Discount rewards are applied during booking in voucher_page.dart —
      // do not apply to cart here.
      context.go('/treatments');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);
    final redemptionsAsync = ref.watch(myRedemptionsProvider);
    final promoVouchersAsync = ref.watch(clientVouchersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Promos & Vouchers',
          style: AppTypography.headingMedium
              .copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle:
              AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Promos'),
            Tab(text: 'Point & Rewards'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Promos ─────────────────────────────────────────────────
          RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              ref.invalidate(bannersProvider);
              ref.invalidate(myRedemptionsProvider);
              ref.invalidate(clientVouchersProvider);
            },
            child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── Special Offers ────────────────────────────────────────────
              _SectionHeader(label: 'SPECIAL OFFERS'),
              bannersAsync.when(
                loading: () => _BannerSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
                data: (banners) => banners.isEmpty
                    ? _EmptyBanners()
                    : _BannerCarousel(banners: banners),
              ),

              const SizedBox(height: 8),

              // ── Enter Promo Code ──────────────────────────────────────────
              _SectionHeader(label: 'ENTER PROMO CODE'),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            onSubmitted: (_) => _applyCode(),
                            decoration: InputDecoration(
                              hintText: 'e.g. KAIZEN20',
                              errorText: _applyError,
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
                                    color: AppColors.border
                                        .withValues(alpha: 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: AppColors.primary, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFD32F2F)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _isApplying ? null : _applyCode,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isApplying
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Apply',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── My Vouchers ───────────────────────────────────────────────
              _SectionHeader(label: 'MY VOUCHERS'),
              promoVouchersAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (promoVouchers) {
                  if (promoVouchers.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        'Enter a promo code above to save vouchers here.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                    );
                  }
                  return Column(
                    children: promoVouchers.map((cv) {
                      final v = (cv['voucher'] as Map<String, dynamic>?) ?? {};
                      final code = (v['code'] as String?) ?? '';
                      return _PromoVoucherCard(
                        data: cv,
                        onUse: code.isNotEmpty ? () => _usePromoVoucher(code) : null,
                      );
                    }).toList(),
                  );
                },
              ),

              // ── My Rewards ────────────────────────────────────────────────
              _SectionHeader(label: 'MY REWARDS'),
              redemptionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (rewardRedemptions) {
                  if (rewardRedemptions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: Text(
                        'Redeem points in the Point & Rewards tab to see your rewards here.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      ...rewardRedemptions.map((r) => _VoucherRedemptionCard(
                        data: r,
                        onUse: () => _useReward(r),
                      )),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ],
            ),
          ),

          // ── Tab 2: Point & Rewards ────────────────────────────────────────
          _PointsRewardsTab(onRedeemed: _onRewardRedeemed),
        ],
      ),
    );
  }
}

// ── Point & Rewards tab ────────────────────────────────────────────────────────

class _PointsRewardsTab extends ConsumerStatefulWidget {
  final VoidCallback onRedeemed;
  const _PointsRewardsTab({required this.onRedeemed});

  @override
  ConsumerState<_PointsRewardsTab> createState() => _PointsRewardsTabState();
}

class _PointsRewardsTabState extends ConsumerState<_PointsRewardsTab> {
  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client.from('reward_redemptions').insert({
        'client_id': userId,
        'reward_id': reward['id'],
        'points_spent': reward['points_required'],
      });

      await Supabase.instance.client.from('rewards').update({
        'total_redeemed': ((reward['total_redeemed'] as int?) ?? 0) + 1,
      }).eq('id', reward['id']);

      // Deduct points by inserting a negative entry
      await Supabase.instance.client.from('client_points').insert({
        'client_id': userId,
        'points_earned': -(reward['points_required'] as int),
        'description': 'Redeemed: ${reward['title']}',
        'booking_id': null,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Redemption failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (!mounted) return;

    ref.invalidate(clientTotalPointsProvider);
    ref.invalidate(rewardsProvider);
    widget.onRedeemed();
  }

  @override
  Widget build(BuildContext context) {
    final pointsAsync = ref.watch(clientTotalPointsProvider);
    final rewardsAsync = ref.watch(rewardsProvider);

    final totalPoints = pointsAsync.maybeWhen(data: (v) => v, orElse: () => 0);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(clientTotalPointsProvider);
        ref.invalidate(rewardsProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // ── Points balance card ──────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.stars_rounded,
                      color: AppColors.goldDark, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR POINTS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalPoints pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Available rewards ────────────────────────────────────────────
          _SectionHeader(label: 'AVAILABLE REWARDS'),
          rewardsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Could not load rewards: $e',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            data: (rewards) {
              if (rewards.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.card_giftcard_rounded,
                          size: 48,
                          color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text('No rewards available yet',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }
              return Column(
                children: rewards
                    .map((r) => _RewardCard(
                          reward: r,
                          totalPoints: totalPoints,
                          onRedeem: () => _redeemReward(r),
                        ))
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Reward card ────────────────────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  final Map<String, dynamic> reward;
  final int totalPoints;
  final VoidCallback onRedeem;
  const _RewardCard({
    required this.reward,
    required this.totalPoints,
    required this.onRedeem,
  });

  String _rewardDetailText() {
    final type = reward['reward_type'] as String?;
    final value = (reward['reward_value'] as num?)?.toDouble() ?? 0;
    switch (type) {
      case 'free_treatment':
        final name =
            (reward['reward_treatment'] as Map?)?['name'] as String? ??
                'Treatment';
        final duration =
            (reward['reward_duration'] as Map?)?['duration_minutes'] as int?;
        return duration != null ? 'Free $name ($duration min)' : 'Free $name';
      case 'discount_percentage':
        return '${value.toInt()}% discount on your order';
      case 'discount_flat':
        return '${formatRupiah(value)} off your order';
      default:
        return reward['description'] as String? ?? 'Special reward';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pointsRequired = (reward['points_required'] as int?) ?? 0;
    final canRedeem = totalPoints >= pointsRequired;
    final progress = pointsRequired > 0
        ? (totalPoints / pointsRequired).clamp(0.0, 1.0)
        : 1.0;
    final title = (reward['title'] as String?) ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row + points badge
          Row(
            children: [
              const Icon(Icons.card_giftcard_rounded,
                  color: AppColors.goldDark, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pointsRequired pts',
                  style: const TextStyle(
                    color: AppColors.goldDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Reward text
          Text(
            _rewardDetailText(),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.surfaceVariant,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$totalPoints / $pointsRequired pts',
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),

          // Redeem button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canRedeem ? onRedeem : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canRedeem ? AppColors.primary : AppColors.surfaceVariant,
                foregroundColor:
                    canRedeem ? Colors.white : AppColors.textMuted,
                elevation: 0,
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                canRedeem
                    ? 'Redeem'
                    : 'Need ${pointsRequired - totalPoints} more pts',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Voucher redemption card ────────────────────────────────────────────────────

class _VoucherRedemptionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onUse;
  const _VoucherRedemptionCard({required this.data, this.onUse});

  String _rewardDetailText(Map<String, dynamic> reward) {
    final type = reward['reward_type'] as String?;
    final value = (reward['reward_value'] as num?)?.toDouble() ?? 0;
    switch (type) {
      case 'free_treatment':
        final name =
            (reward['reward_treatment'] as Map?)?['name'] as String? ??
                'Treatment';
        final duration =
            (reward['reward_duration'] as Map?)?['duration_minutes'] as int?;
        return duration != null ? 'Free $name ($duration min)' : 'Free $name';
      case 'discount_percentage':
        return '${value.toInt()}% discount on your order';
      case 'discount_flat':
        return '${formatRupiah(value)} off your order';
      default:
        return reward['description'] as String? ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final reward = (data['rewards'] as Map<String, dynamic>?) ?? {};
    final rewardTitle = (reward['title'] as String?) ?? 'Reward';
    final isUsed = (data['is_used'] as bool?) ?? false;
    final usedAt = data['used_at'] as String?;
    final detailText = _rewardDetailText(reward);

    final String statusText;
    if (isUsed && usedAt != null) {
      final d = DateTime.tryParse(usedAt);
      final formatted =
          d != null ? '${d.day}/${d.month}/${d.year}' : '';
      statusText = 'Used on $formatted';
    } else if (isUsed) {
      statusText = 'Used';
    } else {
      statusText = 'Active – tap Use to redeem';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isUsed ? AppColors.surfaceVariant : AppColors.goldLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              color: isUsed ? AppColors.textMuted : AppColors.goldDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rewardTitle,
                  style: text.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (detailText.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUsed
                          ? AppColors.surfaceVariant
                          : AppColors.goldLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      detailText,
                      style: text.bodySmall?.copyWith(
                        color: isUsed
                            ? AppColors.textMuted
                            : AppColors.goldDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isUsed
                        ? AppColors.textMuted
                        : const Color(0xFF155724),
                  ),
                ),
              ],
            ),
          ),
          if (!isUsed) ...[
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onUse,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldDark,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: const Size(60, 36),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Use',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(
        label,
        style: AppTypography.overline.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Banner carousel ────────────────────────────────────────────────────────────

class _BannerCarousel extends StatelessWidget {
  final List<PromoBanner> banners;
  const _BannerCarousel({required this.banners});

  static const _gradients = [
    [AppColors.secondary, AppColors.primary],
    [AppColors.primary, AppColors.primaryDark],
    [AppColors.primaryDark, AppColors.secondary],
    [AppColors.secondary, AppColors.primaryDark],
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: banners.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final banner = banners[i];
          final grad = _gradients[i % _gradients.length];
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: grad,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: banner.imageUrl != null
                      ? Image.network(
                          banner.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        )
                      : null,
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (banner.subtitle != null)
                        Text(
                          banner.subtitle!,
                          style: text.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Text(
                        banner.title,
                        style: text.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BannerSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 2,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => Container(
          width: 280,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _EmptyBanners extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'No active promotions',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ── Promo voucher card ─────────────────────────────────────────────────────────

class _PromoVoucherCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onUse;
  const _PromoVoucherCard({required this.data, this.onUse});

  String _discountText(Map<String, dynamic> v) {
    final type = v['discount_type'] as String?;
    final value = (v['discount_value'] as num?)?.toDouble() ?? 0;
    if (type == 'percentage') return '${value.toInt()}% off';
    if (type == 'flat') return '${formatRupiah(value)} off';
    return '';
  }

  bool _isExpired(Map<String, dynamic> v) {
    final exp = v['expires_at'] ?? v['valid_until'];
    if (exp == null) return false;
    return DateTime.tryParse(exp as String)?.isBefore(DateTime.now()) ?? false;
  }

  String? _expiryText(Map<String, dynamic> v) {
    final raw = (v['expires_at'] ?? v['valid_until']) as String?;
    if (raw == null) return null;
    final d = DateTime.tryParse(raw);
    if (d == null) return null;
    return 'Valid until ${d.day}/${d.month}/${d.year}';
  }

  String? _minOrderText(Map<String, dynamic> v) {
    final min = (v['min_order_amount'] as num?)?.toDouble();
    if (min == null || min <= 0) return null;
    return 'Min. order ${formatRupiah(min)}';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final voucher = (data['voucher'] as Map<String, dynamic>?) ?? {};
    final code = (voucher['code'] as String?) ?? '';
    final description = voucher['description'] as String?;
    final discount = _discountText(voucher);
    final expired = _isExpired(voucher);
    final expiry = _expiryText(voucher);
    final minOrder = _minOrderText(voucher);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: expired ? AppColors.textMuted : AppColors.primary,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_offer_rounded,
                      color: expired ? AppColors.textMuted : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            code,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: expired
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (description != null && description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(description,
                                style: text.bodySmall?.copyWith(
                                    color: AppColors.textSecondary)),
                          ],
                          if (discount.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(discount,
                                style: text.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)),
                          ],
                          if (minOrder != null) ...[
                            const SizedBox(height: 2),
                            Text(minOrder,
                                style: text.bodySmall?.copyWith(
                                    color: AppColors.textSecondary)),
                          ],
                          if (expiry != null) ...[
                            const SizedBox(height: 2),
                            Text(expiry,
                                style: text.bodySmall?.copyWith(
                                    color: expired
                                        ? AppColors.textMuted
                                        : AppColors.textSecondary,
                                    fontSize: 11)),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            expired ? 'Expired' : 'Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: expired
                                  ? AppColors.textMuted
                                  : const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!expired) ...[
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: onUse,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          minimumSize: const Size(60, 36),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Use',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ],
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


