import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/auth/presentation/providers/auth_state.dart';
import '../../../treatments/presentation/providers/treatments_providers.dart';
import '../providers/home_providers.dart';
import '../widgets/featured_banner.dart';
import '../widgets/treatment_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref.invalidate(popularTreatmentsProvider);
            ref.invalidate(categoriesProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _GreetingHeader(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const FeaturedBanner(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionHeader(
                  title: 'Our Services',
                  onViewAll: () => context.go('/treatments'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(child: _ServiceCategories()),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionHeader(
                  title: 'Popular Treatments',
                  onViewAll: () => context.go('/treatments'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(child: _PopularTreatments()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Greeting ────────────────────────────────────────────────────────────────

class _GreetingHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final name = authState is AuthAuthenticated
        ? (authState.user.name?.split(' ').first ?? 'Friend')
        : 'Friend';
    final hour = WIB.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $name',
                style: AppTypography.headingMedium
                    .copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'What would you like today?',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
                size: 26,
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFD32F2F),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTypography.overline.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            'View all',
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

// ── Service categories ────────────────────────────────────────────────────────

class _ServiceCategories extends ConsumerWidget {
  const _ServiceCategories();

  static IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('massage')) return Icons.self_improvement_rounded;
    if (n.contains('facial') || n.contains('face')) {
      return Icons.face_retouching_natural;
    }
    if (n.contains('scrub') || n.contains('body')) {
      return Icons.bubble_chart_rounded;
    }
    if (n.contains('stone') || n.contains('hot')) return Icons.spa_rounded;
    if (n.contains('aroma')) return Icons.local_florist_rounded;
    if (n.contains('nail')) return Icons.brush_rounded;
    if (n.contains('hair')) return Icons.content_cut_rounded;
    if (n.contains('wax')) return Icons.auto_fix_high_rounded;
    if (n.contains('foot') || n.contains('reflex')) {
      return Icons.directions_walk_rounded;
    }
    if (n.contains('relax') || n.contains('therapy')) {
      return Icons.healing_rounded;
    }
    return Icons.spa_outlined;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return SizedBox(
      height: 96,
      child: categoriesAsync.when(
        loading: () => _CategoryShimmer(),
        error: (_, __) => const SizedBox.shrink(),
        data: (categories) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (ctx, i) {
            final cat = categories[i];
            return GestureDetector(
              onTap: () {
                ref.read(pendingCategoryNameProvider.notifier).state =
                    cat.name;
                ctx.go('/treatments');
              },
              child: SizedBox(
                width: 64,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _iconFor(cat.name),
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.background,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, __) => Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Popular treatments ────────────────────────────────────────────────────────

class _PopularTreatments extends ConsumerWidget {
  const _PopularTreatments();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treatmentsAsync = ref.watch(popularTreatmentsProvider);
    return SizedBox(
      height: 240,
      child: treatmentsAsync.when(
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          itemBuilder: (_, __) => const TreatmentCardSkeleton(),
        ),
        error: (_, __) => Center(
          child: Text(
            'Could not load treatments',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textMuted),
          ),
        ),
        data: (treatments) => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: treatments.length,
          itemBuilder: (_, i) => TreatmentCard(
            treatment: treatments[i],
            onTap: () => context.push('/treatments/${treatments[i].id}'),
          ),
        ),
      ),
    );
  }
}
