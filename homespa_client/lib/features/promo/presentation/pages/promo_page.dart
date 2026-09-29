import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/flow_widgets.dart';
import '../../../../core/widgets/kaizen_page.dart';
import '../../../booking/presentation/providers/booking_cart.dart';
import '../../../promo/domain/entities/promo_banner.dart';
import '../../../treatments/presentation/widgets/glass_icon_button.dart';
import '../../../booking/presentation/providers/booking_providers.dart';
import '../providers/promo_providers.dart';
import '../providers/rewards_provider.dart';

// Promos / Vouchers (Promo tab). Hero from Figma kaizen › promo (1650:2679):
// spa photo under a clear → black gradient with 40px bottom corners, glass
// filter + search buttons, History-style tab pills; glass cards on the
// #434930 page, CalSans titles and Montserrat body text.

const String _kIconSearch = 'assets/icons/search_24.svg'; // Icon/Search/24
const String _kIconFilter = 'assets/icons/filter_49.svg'; // Frame 33620

// ── Layout ────────────────────────────────────────────────────────────────────
const double _kGutterLeft = 30;
const double _kGutterRight = 31; // tabs and search end at x 371 of 402
const double _kCardGap = 14;

// ── Hero (Figma 1650:2680 – 1650:2695) ───────────────────────────────────────
const double _kHeroHeight = 219;
const double _kLabelTop = 76.99; // "Promos"
const double _kTitleTop = 102.88; // "Vouchers"
const double _kHeaderButtonsTop = 72;

/// Filter ends at x 306, search starts at x 322.
const double _kHeaderButtonGap = 16;

/// Filter export is 50.4913 square: the 49px circle plus its outside stroke.
const double _kFilterSvgSize = 50.4913;
const double _kFilterSvgInset = -0.745637;
const double _kTabsTop = 143;
const double _kTabHeight = 46;
const double _kTabGap = 13.179; // 193.911 → 207.09
const double _kTabLabelTop = 11; // label y 154 in a tab at y 143
const double _kTabLabelHeight = 20;

/// Search field that opens under the hero: 16 gap + 48 field.
const double _kSearchGap = 16;
const double _kSearchHeight = 48;

// ── Special Offers (Figma kaizen › promo, node 1650:2747) ────────────────────
// Banners: 222.129 × 146.2, radius 5.095, photo under a clear → 83% black
// gradient; title and subtitle 18.11 in from the left, 13.7 up from the bottom.
const double _kPromosTop = 20; // hero bottom 219 → section title 239
const double _kOffersTitleToBanners =
    14.675; // subtitle bottom 284.825 → banner 299.5
const double _kOffersToNext = 20.3; // banner bottom 445.7 → My Vouchers 466
const double _kBannerWidth = 222.129;
const double _kBannerHeight = 146.2;
const double _kBannerGap = 13; // second banner at x 265.13
const double _kBannerRadius = 5.095; // Home card corners
const double _kBannerTextLeft = 18.11; // text x 48.11 on a banner at x 30
const double _kBannerTextRight = 25.19; // subtitle box 178.935 wide
const double _kBannerTextBottom = 13.7; // subtitle bottom 432 → banner 445.7
const String _kBannerFallbackImage = 'assets/images/promo/special_offer_bg.png';

/// Order card corners (4.603 at 222 wide) at the 341 History width.
const double _kCardRadius = 4.603 * 341 / 222;

/// "#CODE" tag corners (3.32 at 222 wide) at the 341 History width.
const double _kTagRadius = 3.32 * 341 / 222;
const double _kButtonRadius = 10;
const double _kPillHeight = 44;

/// Point & Rewards content starts 25 below the hero.
const double _kRewardsTop = 25;

const Color _kPillOlive = AppColors.darkOliveLight; // #4E523B
const Color _kGold = AppColors.gold;
const Color _kMuted = AppColors.textOnDarkMuted;
const Color _kActive = Color(0xFF74D38E);
const Color _kExpired = Color(0xFFFF7B6E);

class PromoPage extends ConsumerStatefulWidget {
  const PromoPage({super.key});

  @override
  ConsumerState<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends ConsumerState<PromoPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// One per tab, so the hero scrolls away with whichever list is showing.
  final _promosScroll = ScrollController();
  final _rewardsScroll = ScrollController();

  final _codeController = TextEditingController();
  bool _isApplying = false;
  String? _applyError;

  final _searchController = TextEditingController();
  bool _searching = false;
  String _query = '';

  /// Filter sheet: hide used/expired vouchers and rewards, and rewards the
  /// client can't afford yet.
  bool _onlyUsable = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: ref.read(promoTabRequestProvider) ?? 0,
    );
    // Cleared after the first frame (providers can't be modified mid-build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(promoTabRequestProvider.notifier).state = null;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promosScroll.dispose();
    _rewardsScroll.dispose();
    _codeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() => setState(() {
    _searching = !_searching;
    if (!_searching) {
      _searchController.clear();
      _query = '';
    }
  });

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(onlyUsable: _onlyUsable),
    );
    if (result != null && mounted) setState(() => _onlyUsable = result);
  }

  /// Case-insensitive match on any of [fields]; everything matches when the
  /// search is empty.
  bool _matches(Iterable<String?> fields) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return fields.any((f) => f != null && f.toLowerCase().contains(q));
  }

  double get _contentTop =>
      _kHeroHeight + (_searching ? _kSearchGap + _kSearchHeight : 0);

  /// Saves the code to My Vouchers. Never applies it to the cart — that
  /// happens on the voucher step during booking.
  Future<void> _applyCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _isApplying = true;
      _applyError = null;
    });

    try {
      final result = await ref
          .read(validateVoucherUseCaseProvider)
          .call(code);

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _applyError = failure.message;
            _isApplying = false;
          });
        },
        (_) {
          _codeController.clear();
          ref.invalidate(clientVouchersProvider);
          setState(() {
            _isApplying = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Promo code is valid — apply it at checkout!'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
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
    debugPrint(
      '[UseReward] reward type: ${redemption['rewards']?['reward_type']}',
    );
    debugPrint(
      '[UseReward] reward_treatment_id: ${redemption['rewards']?['reward_treatment_id']}',
    );
    debugPrint(
      '[UseReward] reward_duration: ${redemption['rewards']?['reward_duration']}',
    );

    final reward = (redemption['rewards'] as Map<String, dynamic>?) ?? {};
    final rewardType = (reward['reward_type'] as String?) ?? '';
    final rewardTitle = (reward['title'] as String?) ?? 'Reward';

    debugPrint('[UseReward] parsed rewardType: $rewardType');
    debugPrint('[UseReward] parsed rewardTitle: $rewardTitle');

    if (rewardType == 'free_treatment') {
      final durationMinutes =
          (reward['reward_duration']
                  as Map<String, dynamic>?)?['duration_minutes']
              as int? ??
          0;
      if (!mounted) return;
      // Marked used only when the booking is confirmed.
      ref
          .read(bookingCartProvider.notifier)
          .applyFreeReward(
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

  Future<void> _refreshPromos() async {
    ref.invalidate(bannersProvider);
    ref.invalidate(myRedemptionsProvider);
    ref.invalidate(clientVouchersProvider);
    try {
      await Future.wait([
        ref.read(bannersProvider.future),
        ref.read(myRedemptionsProvider.future),
        ref.read(clientVouchersProvider.future),
      ]);
    } catch (_) {
      // Each section shows its own error/empty state.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Another page asked for a tab while this one was already built.
    ref.listen<int?>(promoTabRequestProvider, (_, tab) {
      if (tab == null) return;
      _tabController.animateTo(tab);
      ref.read(promoTabRequestProvider.notifier).state = null;
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkOlive, // #434930
        // Layered hero (as on History): each tab's list scrolls under the
        // hero, and the hero moves up with the list that is showing.
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                _buildPromosTab(),
                _PointsRewardsTab(
                  controller: _rewardsScroll,
                  topPadding: _contentTop + _kRewardsTop,
                  onlyAffordable: _onlyUsable,
                  matches: _matches,
                  query: _query,
                  onRedeemed: _onRewardRedeemed,
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  _tabController,
                  _promosScroll,
                  _rewardsScroll,
                ]),
                builder: (context, child) {
                  final scroll = _tabController.index == 0
                      ? _promosScroll
                      : _rewardsScroll;
                  final offset = scroll.hasClients ? scroll.offset : 0.0;
                  return Transform.translate(
                    offset: Offset(0, -offset.clamp(0.0, _contentTop + 40)),
                    child: child,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: _kHeroHeight,
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: KaizenHeroBackground(height: _kHeroHeight),
                          ),
                          ListenableBuilder(
                            listenable: _tabController,
                            builder: (context, _) => _HeroContent(
                              activeIndex: _tabController.index,
                              onTab: _tabController.animateTo,
                              onSearch: _toggleSearch,
                              onFilter: _openFilters,
                              activeFilterCount: _onlyUsable ? 1 : 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_searching)
                      _SearchField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v.trim()),
                        onClose: _toggleSearch,
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

  Widget _buildPromosTab() {
    final bannersAsync = ref.watch(bannersProvider);
    final redemptionsAsync = ref.watch(myRedemptionsProvider);
    final vouchersAsync = ref.watch(clientVouchersProvider);

    // Special Offers is hidden when there is nothing to promote — an empty
    // banner slot is just noise. The other sections show an empty state.
    final banners = (bannersAsync.value ?? const <PromoBanner>[])
        .where((b) => _matches([b.title, b.subtitle]))
        .toList();
    final showOffers =
        (bannersAsync.isLoading && _query.isEmpty) || banners.isNotEmpty;

    return _RefreshList(
      controller: _promosScroll,
      onRefresh: _refreshPromos,
      topPadding: _contentTop + _kPromosTop,
      children: [
        if (showOffers) ...[
          const _SectionHeader(
            title: 'Special Offers',
            subtitle: 'Limited-time deals from Kaizen Home Spa',
            bottomGap: _kOffersTitleToBanners,
          ),
          _BannerList(
            banners: banners,
            loading: bannersAsync.isLoading && banners.isEmpty,
          ),
          const SizedBox(height: _kOffersToNext),
        ],

        // ── My Vouchers ────────────────────────────────────────────────────
        const _SectionHeader(
          title: 'My Vouchers',
          subtitle: 'Promo codes saved to your account',
        ),
        _Gutter(
          _PromoCodeField(
            controller: _codeController,
            error: _applyError,
            isSaving: _isApplying,
            onSave: _applyCode,
          ),
        ),
        const SizedBox(height: _kCardGap),
        ...vouchersAsync.when(
          loading: () => const [_CardSkeleton()],
          error: (_, _) => const [
            _EmptySection(
              icon: Icons.cloud_off_rounded,
              message: 'We couldn’t load your vouchers. Pull to refresh.',
            ),
          ],
          data: (all) {
            final vouchers = all.where((cv) {
              final v = (cv['voucher'] as Map<String, dynamic>?) ?? {};
              return (!_onlyUsable || _isVoucherUsable(cv)) &&
                  _matches([v['code'] as String?, v['description'] as String?]);
            }).toList();
            if (all.isEmpty) {
              return const [
                _EmptySection(
                  icon: Icons.local_offer_outlined,
                  message: 'Enter a promo code above to save vouchers here.',
                ),
              ];
            }
            if (vouchers.isEmpty) {
              return [
                _EmptySection(
                  icon: Icons.search_off_rounded,
                  message: _noMatchMessage('vouchers'),
                ),
              ];
            }
            return [
              for (final cv in vouchers) ...[
                _Gutter(
                  _VoucherCard(
                    data: cv,
                    onUse: (code) => _usePromoVoucher(code),
                  ),
                ),
                const SizedBox(height: _kCardGap),
              ],
            ];
          },
        ),
        const SizedBox(height: 14),

        // ── My Rewards ─────────────────────────────────────────────────────
        const _SectionHeader(
          title: 'My Rewards',
          subtitle: 'Rewards you’ve redeemed with points',
        ),
        ...redemptionsAsync.when(
          loading: () => const [_CardSkeleton()],
          error: (_, _) => const [
            _EmptySection(
              icon: Icons.cloud_off_rounded,
              message: 'We couldn’t load your rewards. Pull to refresh.',
            ),
          ],
          data: (all) {
            final redemptions = all.where((r) {
              final reward = (r['rewards'] as Map<String, dynamic>?) ?? {};
              return (!_onlyUsable || r['is_used'] != true) &&
                  _matches([reward['title'] as String?]);
            }).toList();
            if (all.isEmpty) {
              return const [
                _EmptySection(
                  icon: Icons.card_giftcard_rounded,
                  message:
                      'Redeem points in Point & Rewards to see your rewards here.',
                ),
              ];
            }
            if (redemptions.isEmpty) {
              return [
                _EmptySection(
                  icon: Icons.search_off_rounded,
                  message: _noMatchMessage('rewards'),
                ),
              ];
            }
            return [
              for (final r in redemptions) ...[
                _Gutter(_RedemptionCard(data: r, onUse: () => _useReward(r))),
                const SizedBox(height: _kCardGap),
              ],
            ];
          },
        ),
      ],
    );
  }

  String _noMatchMessage(String what) => _query.isNotEmpty
      ? 'No $what match “$_query”.'
      : 'No usable $what right now.';
}

/// Same rules as [_VoucherCard]: not used and not past its expiry.
bool _isVoucherUsable(Map<String, dynamic> cv) {
  final v = (cv['voucher'] as Map<String, dynamic>?) ?? {};
  final expiryRaw = (v['expires_at'] ?? v['valid_until']) as String?;
  final expiry = expiryRaw == null ? null : DateTime.tryParse(expiryRaw);
  final isExpired = expiry?.isBefore(DateTime.now()) ?? false;
  final isUsed = cv['is_used'] == true || cv['used_at'] != null;
  return !isUsed && !isExpired;
}

// ── Point & Rewards tab ───────────────────────────────────────────────────────

class _PointsRewardsTab extends ConsumerStatefulWidget {
  final ScrollController controller;
  final double topPadding;

  /// Filter sheet: only rewards the client has enough points for.
  final bool onlyAffordable;
  final bool Function(Iterable<String?> fields) matches;
  final String query;
  final VoidCallback onRedeemed;

  const _PointsRewardsTab({
    required this.controller,
    required this.topPadding,
    required this.onlyAffordable,
    required this.matches,
    required this.query,
    required this.onRedeemed,
  });

  @override
  ConsumerState<_PointsRewardsTab> createState() => _PointsRewardsTabState();
}

class _PointsRewardsTabState extends ConsumerState<_PointsRewardsTab> {
  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    try {
      // Platform deducts the points atomically (fails on low balance).
      await redeemReward(reward['id'] as String);
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

  Future<void> _refresh() async {
    ref.invalidate(clientTotalPointsProvider);
    ref.invalidate(rewardsProvider);
    try {
      await Future.wait([
        ref.read(clientTotalPointsProvider.future),
        ref.read(rewardsProvider.future),
      ]);
    } catch (_) {
      // Shown inline below.
    }
  }

  @override
  Widget build(BuildContext context) {
    final pointsAsync = ref.watch(clientTotalPointsProvider);
    final rewardsAsync = ref.watch(rewardsProvider);
    final totalPoints = pointsAsync.maybeWhen(data: (v) => v, orElse: () => 0);

    return _RefreshList(
      controller: widget.controller,
      onRefresh: _refresh,
      topPadding: widget.topPadding,
      children: [
        _Gutter(
          _PointsBalanceCard(
            points: totalPoints,
            loading: pointsAsync.isLoading && !pointsAsync.hasValue,
          ),
        ),
        const SizedBox(height: 28),
        const _SectionHeader(
          title: 'Available Rewards',
          subtitle: 'Spend your points on treatments and discounts',
        ),
        ...rewardsAsync.when(
          loading: () => const [_CardSkeleton(), _CardSkeleton()],
          error: (e, _) => [
            const _EmptySection(
              icon: Icons.cloud_off_rounded,
              message: 'We couldn’t load rewards. Pull to refresh.',
            ),
          ],
          data: (all) {
            final rewards = all.where((r) {
              final needed = (r['points_required'] as int?) ?? 0;
              return (!widget.onlyAffordable || totalPoints >= needed) &&
                  widget.matches([
                    r['title'] as String?,
                    r['description'] as String?,
                  ]);
            }).toList();
            if (all.isEmpty) {
              return const [
                _EmptySection(
                  icon: Icons.card_giftcard_rounded,
                  message: 'No rewards available yet.',
                ),
              ];
            }
            if (rewards.isEmpty) {
              return [
                _EmptySection(
                  icon: Icons.search_off_rounded,
                  message: widget.query.isNotEmpty
                      ? 'No rewards match “${widget.query}”.'
                      : 'No rewards you can redeem yet.',
                ),
              ];
            }
            return [
              for (final r in rewards) ...[
                _Gutter(
                  _RewardCard(
                    reward: r,
                    totalPoints: totalPoints,
                    onRedeem: () => _redeemReward(r),
                  ),
                ),
                const SizedBox(height: _kCardGap),
              ],
            ];
          },
        ),
      ],
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

/// Hero foreground: "Promos" / "Vouchers", filter + search, and the tabs.
class _HeroContent extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTab;
  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final int activeFilterCount;

  const _HeroContent({
    required this.activeIndex,
    required this.onTab,
    required this.onSearch,
    required this.onFilter,
    required this.activeFilterCount,
  });

  static const _tabs = ['Promos', 'Rewards'];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: _kLabelTop,
          left: _kGutterLeft,
          child: Text(
            'Promos',
            style: GoogleFonts.montserrat(
              fontSize: 18.028,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 17.393 / 18.028,
            ).copyWith(leadingDistribution: TextLeadingDistribution.even),
          ),
        ),
        const Positioned(
          top: _kTitleTop,
          left: _kGutterLeft,
          child: Text(
            'Vouchers',
            style: TextStyle(
              fontFamily: 'CalSans',
              fontWeight: FontWeight.w600,
              fontSize: 30,
              color: Colors.white,
              height: 19.296 / 30,
              leadingDistribution: TextLeadingDistribution.even,
            ),
          ),
        ),
        Positioned(
          top: _kHeaderButtonsTop,
          right: _kGutterRight,
          child: Row(
            children: [
              GlassIconButton(
                svgAsset: _kIconFilter,
                svgIncludesFrame: true,
                iconSize: _kFilterSvgSize,
                iconOffset: const Offset(_kFilterSvgInset, _kFilterSvgInset),
                badgeCount: activeFilterCount,
                onTap: onFilter,
              ),
              const SizedBox(width: _kHeaderButtonGap),
              GlassIconButton(
                svgAsset: _kIconSearch,
                iconSize: 25.565,
                iconOffset: const Offset(11.72, 11.72),
                onTap: onSearch,
              ),
            ],
          ),
        ),
        Positioned(
          top: _kTabsTop,
          left: _kGutterLeft,
          right: _kGutterRight,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: _kTabGap),
                Expanded(
                  child: _TabPill(
                    label: _tabs[i],
                    active: i == activeIndex,
                    onTap: () => onTab(i),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Figma tab: 46 tall, radius 10, Montserrat Regular 17 label 11 from the
/// top. Active: white with dark olive text. Inactive: #4E523B, white text.
class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: active,
      button: true,
      child: Material(
        color: active ? Colors.white : AppColors.darkOliveLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kButtonRadius),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kButtonRadius),
          ),
          onTap: onTap,
          child: SizedBox(
            height: _kTabHeight,
            child: Padding(
              padding: const EdgeInsets.only(top: _kTabLabelTop),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: active ? AppColors.darkOliveLight : Colors.white,
                    height: _kTabLabelHeight / 17,
                  ).copyWith(leadingDistribution: TextLeadingDistribution.even),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keyword search under the hero (banner title, voucher code, reward title).
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kButtonRadius),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.5),
        width: 0.5,
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _kGutterLeft,
        _kSearchGap,
        _kGutterRight,
        0,
      ),
      child: SizedBox(
        height: _kSearchHeight,
        child: Material(
          color: AppColors.darkOlive,
          borderRadius: BorderRadius.circular(_kButtonRadius),
          child: TextField(
            controller: controller,
            autofocus: true,
            onChanged: onChanged,
            cursorColor: Colors.white,
            textInputAction: TextInputAction.search,
            style: GoogleFonts.montserrat(fontSize: 14, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search offers, voucher codes, rewards',
              hintStyle: GoogleFonts.montserrat(fontSize: 14, color: _kMuted),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              suffixIcon: IconButton(
                tooltip: 'Close search',
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: onClose,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Filter sheet: everything, or only what can be used right now. Pops the
/// chosen value, or null when dismissed.
class _FilterSheet extends StatelessWidget {
  final bool onlyUsable;
  const _FilterSheet({required this.onlyUsable});

  @override
  Widget build(BuildContext context) {
    Widget option(String title, String subtitle, bool value) {
      final selected = value == onlyUsable;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(_kButtonRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(_kButtonRadius),
            onTap: () => Navigator.of(context).pop(value),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: flowBody(
                            15,
                            weight: FontWeight.w500,
                            color: selected
                                ? AppColors.darkOliveLight
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: flowBody(
                            12,
                            color: selected
                                ? AppColors.darkOliveLight
                                : _kMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_rounded,
                      color: AppColors.darkOliveLight,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkOlive,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        _kGutterLeft,
        20,
        _kGutterRight,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Show', style: flowHeading(22, height: 1.2)),
          const SizedBox(height: 14),
          option('Everything', 'All offers, vouchers and rewards', false),
          option(
            'Ready to use',
            'Hide used or expired vouchers and rewards, and rewards you '
                'don’t have enough points for yet',
            true,
          ),
        ],
      ),
    );
  }
}

// ── Shared building blocks ────────────────────────────────────────────────────

class _RefreshList extends StatelessWidget {
  final ScrollController controller;
  final Future<void> Function() onRefresh;
  final List<Widget> children;
  final double topPadding;
  const _RefreshList({
    required this.controller,
    required this.onRefresh,
    required this.children,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.cream,
      backgroundColor: AppColors.darkOlive,
      onRefresh: onRefresh,
      // Spinner appears under the hero, not behind it.
      edgeOffset: _kHeroHeight,
      child: ListView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: topPadding, bottom: 32),
        children: children,
      ),
    );
  }
}

class _Gutter extends StatelessWidget {
  final Widget child;
  const _Gutter(this.child);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: _kGutterLeft, right: _kGutterRight),
    child: child,
  );
}

/// Home section title: CalSans title over a small Montserrat subtitle.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final double bottomGap;
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.bottomGap = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(_kGutterLeft, 0, _kGutterRight, bottomGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'CalSans',
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 23.741,
              letterSpacing: 0.2374,
              height: 32.54 / 23.741,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 10.898,
              fontWeight: FontWeight.w400,
              height: 1.219,
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass card (Cart summary / Add-ons): white 10% fill, hairline white
/// border, order-card corners.
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(_kCardRadius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
    ),
    child: child,
  );
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptySection({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _kGutterLeft,
        4,
        _kGutterRight,
        _kCardGap,
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: _kMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: flowBody(13, color: _kMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      _kGutterLeft,
      0,
      _kGutterRight,
      _kCardGap,
    ),
    child: Container(
      height: 112,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
    ),
  );
}

/// Tinted status pill (History status style) with "#CODE" tag corners.
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(_kTagRadius),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      label,
      maxLines: 1,
      style: flowBody(11, weight: FontWeight.w500, color: color, height: 1.2),
    ),
  );
}

/// "#CODE" tag: white 20% fill, hairline white border.
class _CodeTag extends StatelessWidget {
  final String code;
  const _CodeTag(this.code);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(_kTagRadius),
      border: Border.all(color: Colors.white, width: 0.3),
    ),
    child: Text(
      code,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: flowBody(12, weight: FontWeight.w500).copyWith(letterSpacing: 0.8),
    ),
  );
}

/// Small olive action (Re-Order style), 44px tall for an easy tap target.
class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_kButtonRadius);
    return Semantics(
      button: true,
      child: Material(
        color: _kPillOlive,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 84,
              minHeight: _kPillHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: flowBody(15, weight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gold-tinted square behind an icon.
class _IconTile extends StatelessWidget {
  final IconData icon;
  final bool muted;
  const _IconTile(this.icon, {this.muted = false});

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: (muted ? Colors.white : _kGold).withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(_kButtonRadius),
      border: Border.all(
        color: (muted ? Colors.white : _kGold).withValues(alpha: 0.35),
        width: 0.5,
      ),
    ),
    child: Icon(icon, size: 22, color: muted ? _kMuted : _kGold),
  );
}

/// "Free Full Body Massage 90 min", "20% discount", "Rp 20.000 discount".
String _rewardBenefit(Map<String, dynamic> reward) {
  final type = reward['reward_type'] as String?;
  final value = (reward['reward_value'] as num?)?.toDouble() ?? 0;
  switch (type) {
    case 'free_treatment':
      final name =
          (reward['reward_treatment'] as Map?)?['name'] as String? ??
          'Treatment';
      final duration =
          (reward['reward_duration'] as Map?)?['duration_minutes'] as int?;
      return duration != null ? 'Free $name $duration min' : 'Free $name';
    case 'discount_percentage':
      return '${value.toInt()}% discount';
    case 'discount_flat':
      return '${formatRupiah(value)} discount';
    default:
      return reward['description'] as String? ?? 'Special reward';
  }
}

// ── Promo code field ──────────────────────────────────────────────────────────

class _PromoCodeField extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final bool isSaving;
  final VoidCallback onSave;

  const _PromoCodeField({
    required this.controller,
    required this.error,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 0.5]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kButtonRadius),
      borderSide: BorderSide(color: c, width: w),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => onSave(),
            cursorColor: Colors.white,
            style: flowBody(14).copyWith(letterSpacing: 0.8),
            decoration: InputDecoration(
              hintText: 'Enter promo code',
              hintStyle: flowBody(14, color: _kMuted),
              errorText: error,
              errorStyle: flowBody(12, color: const Color(0xFFFFB4A8)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.10),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              border: border(Colors.white.withValues(alpha: 0.5)),
              enabledBorder: border(Colors.white.withValues(alpha: 0.5)),
              focusedBorder: border(Colors.white, 1),
              errorBorder: border(const Color(0xFFFFB4A8)),
              focusedErrorBorder: border(const Color(0xFFFFB4A8), 1),
            ),
          ),
        ),
        const SizedBox(width: 10),
        isSaving
            ? const SizedBox(
                width: 84,
                height: _kPillHeight,
                child: Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : _PillButton(label: 'Save', onTap: onSave),
      ],
    );
  }
}

// ── Special Offers banners ────────────────────────────────────────────────────

/// Horizontal banner row (Figma 1650:2750 / 1650:2764): Home "Popular" card
/// styling, bleeding off the right edge like the Home carousel.
class _BannerList extends StatelessWidget {
  final List<PromoBanner> banners;
  final bool loading;
  const _BannerList({required this.banners, required this.loading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kBannerHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
          left: _kGutterLeft,
          right: _kGutterRight,
        ),
        itemCount: loading ? 2 : banners.length,
        separatorBuilder: (_, _) => const SizedBox(width: _kBannerGap),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(_kBannerRadius),
          child: SizedBox(
            width: _kBannerWidth,
            child: loading
                ? ColoredBox(color: Colors.white.withValues(alpha: 0.06))
                : _BannerCard(banner: banners[i]),
          ),
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final PromoBanner banner;
  const _BannerCard({required this.banner});

  static const _fallback = Image(
    image: AssetImage(_kBannerFallbackImage),
    fit: BoxFit.cover,
  );

  @override
  Widget build(BuildContext context) {
    final hasImage = banner.imageUrl != null && banner.imageUrl!.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasImage)
          Image.network(
            banner.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback,
          )
        else
          _fallback,
        // Figma gradient: clear from 2.846% → 83% black at the bottom.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0xD4000000)],
              stops: [0.02846, 1.0],
            ),
          ),
        ),
        Positioned(
          left: _kBannerTextLeft,
          right: _kBannerTextRight,
          bottom: _kBannerTextBottom,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                banner.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'CalSans',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 19.396,
                  height: 25.02 / 19.396, // title 393.66 → subtitle 418.68
                  leadingDistribution: TextLeadingDistribution.even,
                ),
              ),
              if (banner.subtitle != null && banner.subtitle!.isNotEmpty)
                Text(
                  banner.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 9.698,
                    fontWeight: FontWeight.w400,
                    height: 13.325 / 9.698,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── My Vouchers card ──────────────────────────────────────────────────────────

class _VoucherCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ValueChanged<String> onUse;
  const _VoucherCard({required this.data, required this.onUse});

  @override
  Widget build(BuildContext context) {
    final v = (data['voucher'] as Map<String, dynamic>?) ?? {};
    final code = (v['code'] as String?) ?? '';
    final description = v['description'] as String?;

    final type = v['discount_type'] as String?;
    final value = (v['discount_value'] as num?)?.toDouble() ?? 0;
    final discount = switch (type) {
      'percentage' => '${value.toInt()}% OFF',
      'flat' => '${formatRupiah(value)} OFF',
      _ => 'Voucher',
    };

    final expiryRaw = (v['expires_at'] ?? v['valid_until']) as String?;
    final expiry = expiryRaw == null ? null : DateTime.tryParse(expiryRaw);
    final isExpired = expiry?.isBefore(DateTime.now()) ?? false;
    final isUsed = data['is_used'] == true || data['used_at'] != null;
    final minOrder = (v['min_order_amount'] as num?)?.toDouble();

    final (String status, Color statusColor) = isUsed
        ? ('Used', _kMuted)
        : isExpired
        ? ('Expired', _kExpired)
        : ('Active', _kActive);
    final usable = !isUsed && !isExpired && code.isNotEmpty;

    final details = [
      if (minOrder != null && minOrder > 0)
        'Min. purchase ${formatRupiah(minOrder)}',
      if (expiry != null)
        '${isExpired ? 'Expired' : 'Valid until'} '
            '${DateFormat('d MMM y').format(expiry.toLocal())}',
    ];

    return Opacity(
      opacity: usable ? 1 : 0.6,
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    discount,
                    style: flowHeading(24, height: 1.1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                _StatusPill(status, statusColor),
              ],
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: flowBody(12.5, color: Colors.white70, height: 1.35),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (code.isNotEmpty) _CodeTag(code),
                      for (final line in details) ...[
                        const SizedBox(height: 6),
                        Text(line, style: flowBody(12, color: _kMuted)),
                      ],
                    ],
                  ),
                ),
                if (usable) ...[
                  const SizedBox(width: 12),
                  _PillButton(label: 'Use', onTap: () => onUse(code)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── My Rewards card ───────────────────────────────────────────────────────────

class _RedemptionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onUse;
  const _RedemptionCard({required this.data, required this.onUse});

  @override
  Widget build(BuildContext context) {
    final reward = (data['rewards'] as Map<String, dynamic>?) ?? {};
    final title = (reward['title'] as String?) ?? 'Reward';
    final isUsed = (data['is_used'] as bool?) ?? false;

    return Opacity(
      opacity: isUsed ? 0.6 : 1,
      child: _GlassCard(
        child: Row(
          children: [
            _IconTile(Icons.card_giftcard_rounded, muted: isUsed),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: flowHeading(18, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _rewardBenefit(reward),
                    style: flowBody(13, color: Colors.white70, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  _StatusPill(
                    isUsed ? 'Used' : 'Active',
                    isUsed ? _kMuted : _kActive,
                  ),
                ],
              ),
            ),
            if (!isUsed) ...[
              const SizedBox(width: 12),
              _PillButton(label: 'Use', onTap: onUse),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Points balance ────────────────────────────────────────────────────────────

class _PointsBalanceCard extends StatelessWidget {
  final int points;
  final bool loading;
  const _PointsBalanceCard({required this.points, required this.loading});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const _IconTile(Icons.star_rounded),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Points',
                  style: flowBody(12, weight: FontWeight.w500, color: _kMuted),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: loading
                            ? '—'
                            : NumberFormat.decimalPattern('id').format(points),
                        style: flowHeading(34, height: 1),
                      ),
                      TextSpan(
                        text: '  pts',
                        style: flowBody(14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reward card (Point & Rewards) ─────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  final Map<String, dynamic> reward;
  final int totalPoints;
  final VoidCallback onRedeem;

  const _RewardCard({
    required this.reward,
    required this.totalPoints,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final pointsRequired = (reward['points_required'] as int?) ?? 0;
    final canRedeem = totalPoints >= pointsRequired;
    final progress = pointsRequired > 0
        ? (totalPoints / pointsRequired).clamp(0.0, 1.0)
        : 1.0;
    final title = (reward['title'] as String?) ?? '';

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(title, style: flowHeading(18, height: 1.2))),
              const SizedBox(width: 10),
              _StatusPill('$pointsRequired pts', _kGold),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _rewardBenefit(reward),
            style: flowBody(13, color: Colors.white70, height: 1.3),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(_kGold),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${totalPoints.clamp(0, pointsRequired)} / $pointsRequired pts',
            style: flowBody(11.5, color: _kMuted),
          ),
          const SizedBox(height: 14),
          _RedeemButton(
            label: canRedeem
                ? 'Redeem'
                : 'Need ${pointsRequired - totalPoints} more pts',
            onTap: canRedeem ? onRedeem : null,
          ),
        ],
      ),
    );
  }
}

/// White primary button when [onTap] is set; muted glass when disabled.
class _RedeemButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _RedeemButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final radius = BorderRadius.circular(_kButtonRadius);
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: enabled
              ? BorderSide.none
              : BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: SizedBox(
            height: _kPillHeight,
            width: double.infinity,
            child: Center(
              child: Text(
                label,
                style: flowBody(
                  15,
                  weight: FontWeight.w500,
                  color: enabled ? AppColors.darkOliveLight : _kMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
