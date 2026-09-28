import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class FeaturedBanner extends StatefulWidget {
  const FeaturedBanner({super.key});

  @override
  State<FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<FeaturedBanner> {
  final _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  static const _banners = [
    _BannerData(
      overline: 'SIGNATURE COLLECTION',
      title: 'Relax.\nRestore.\nRenew.',
      subtitle: 'Premium spa treatments\ndelivered to your door',
      ctaLabel: 'Book Now',
      actionType: 'route',
      actionValue: '/treatments',
    ),
    _BannerData(
      overline: 'NEW TREATMENT',
      title: 'Hot Stone\nTherapy',
      subtitle: 'Deep relaxation with\nvolcanic basalt stones',
      ctaLabel: 'Explore',
      actionType: 'route',
      actionValue: '/treatments',
    ),
    _BannerData(
      overline: 'WEEKEND OFFER',
      title: '20% Off\nNew Clients',
      subtitle: 'Book any treatment this\nweekend and save',
      ctaLabel: 'Get Offer',
      actionType: 'route',
      actionValue: '/promo',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final next = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handleTap(BuildContext ctx, _BannerData banner) {
    switch (banner.actionType) {
      case 'treatment':
        if (banner.actionValue != null) {
          ctx.push('/treatments/${banner.actionValue}');
        }
      case 'url':
        if (banner.actionValue != null) {
          launchUrl(
            Uri.parse(banner.actionValue!),
            mode: LaunchMode.externalApplication,
          );
        }
      case 'route':
        if (banner.actionValue != null) ctx.go(banner.actionValue!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _banners.length,
              itemBuilder: (ctx, i) => _BannerItem(
                data: _banners[i],
                onTap: () => _handleTap(ctx, _banners[i]),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SmoothPageIndicator(
            controller: _pageController,
            count: _banners.length,
            effect: WormEffect(
              dotHeight: 6,
              dotWidth: 6,
              spacing: 6,
              activeDotColor: AppColors.primary,
              dotColor: AppColors.border,
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerItem extends StatelessWidget {
  final _BannerData data;
  final VoidCallback? onTap;
  const _BannerItem({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.overline,
                      style: AppTypography.overline.copyWith(
                        color: AppColors.gold,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.title,
                      style: AppTypography.headingLarge.copyWith(
                        color: Colors.white,
                        height: 1.15,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.70),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  data.ctaLabel.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.gold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerData {
  final String overline;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final String actionType;
  final String? actionValue;

  const _BannerData({
    required this.overline,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    this.actionType = 'none',
    this.actionValue,
  });
}
