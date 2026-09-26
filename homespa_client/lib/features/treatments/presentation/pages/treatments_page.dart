import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../booking/presentation/providers/booking_cart.dart';
import '../../domain/entities/treatment_category.dart';
import '../providers/treatments_providers.dart';
import '../widgets/category_chip.dart';
import '../widgets/treatment_list_item.dart';

class TreatmentsPage extends ConsumerStatefulWidget {
  const TreatmentsPage({super.key});

  @override
  ConsumerState<TreatmentsPage> createState() => _TreatmentsPageState();
}

class _TreatmentsPageState extends ConsumerState<TreatmentsPage> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        ref.read(treatmentsSearchQueryProvider.notifier).state = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search treatments…',
                  border: InputBorder.none,
                  hintStyle: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textMuted),
                ),
                style: AppTypography.bodyLarge
                    .copyWith(color: AppColors.textPrimary),
                onChanged: (val) {
                  ref.read(treatmentsSearchQueryProvider.notifier).state =
                      val;
                },
              )
            : Text(
                'Treatments',
                style: AppTypography.headingMedium
                    .copyWith(color: AppColors.textPrimary),
              ),
        centerTitle: false,
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final count = ref.watch(bookingCartProvider).itemCount;
              return Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                backgroundColor: AppColors.primary,
                child: IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined,
                      color: AppColors.textPrimary),
                  onPressed: () => context.push('/booking/cart'),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_showSearch) ...[
            const _CategoryChipsBar(),
            const Divider(height: 1),
          ],
          const Expanded(child: _TreatmentsList()),
        ],
      ),
    );
  }
}

// ── Category chips ─────────────────────────────────────────────────────────

class _CategoryChipsBar extends ConsumerStatefulWidget {
  const _CategoryChipsBar();

  @override
  ConsumerState<_CategoryChipsBar> createState() => _CategoryChipsBarState();
}

class _CategoryChipsBarState extends ConsumerState<_CategoryChipsBar> {
  void _applyPendingName(List<TreatmentCategory> categories) {
    final pending = ref.read(pendingCategoryNameProvider);
    if (pending == null) return;
    // Partial match handles 'Hot Stone' → 'Hot Stone Therapy' etc.
    final match = categories.where((c) {
      final cn = c.name.toLowerCase();
      final pn = pending.toLowerCase();
      return cn.contains(pn) || pn.contains(cn);
    }).firstOrNull;
    ref.read(selectedCategoryIdProvider.notifier).select(match?.id);
    ref.read(pendingCategoryNameProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedId = ref.watch(selectedCategoryIdProvider);

    // Fires when pending name changes while categories are already loaded
    ref.listen(pendingCategoryNameProvider, (_, next) {
      if (next != null) {
        categoriesAsync.whenData(_applyPendingName);
      }
    });

    return SizedBox(
      height: 52,
      child: categoriesAsync.when(
        loading: () => _buildShimmer(context),
        error: (_, __) => const SizedBox.shrink(),
        data: (categories) {
          // Fires when categories finish loading while a pending name exists
          final pending = ref.read(pendingCategoryNameProvider);
          if (pending != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _applyPendingName(categories),
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return CategoryChip(
                  label: 'All',
                  isSelected: selectedId == null,
                  onTap: () => ref
                      .read(selectedCategoryIdProvider.notifier)
                      .select(null),
                );
              }
              final category = categories[index - 1];
              return CategoryChip(
                label: category.name,
                isSelected: selectedId == category.id,
                onTap: () => ref
                    .read(selectedCategoryIdProvider.notifier)
                    .select(category.id),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) => Container(
        width: [60.0, 80.0, 72.0, 90.0, 66.0][i],
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

// ── Treatments list ────────────────────────────────────────────────────────

class _TreatmentsList extends ConsumerWidget {
  const _TreatmentsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedCategoryIdProvider);
    final searchQuery = ref.watch(treatmentsSearchQueryProvider);
    final effectiveCategoryId = searchQuery.isEmpty ? selectedId : null;
    final treatmentsAsync = ref.watch(treatmentsProvider(effectiveCategoryId));

    return treatmentsAsync.when(
      loading: () => ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const TreatmentListItemSkeleton(),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Could not load treatments',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.invalidate(treatmentsProvider(effectiveCategoryId)),
              child: Text(
                'Retry',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
      data: (treatments) {
        final filtered = searchQuery.isEmpty
            ? treatments
            : treatments
                .where((t) =>
                    t.name.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref.invalidate(treatmentsProvider(effectiveCategoryId));
            ref.invalidate(categoriesProvider);
          },
          child: filtered.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.25),
                    Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isEmpty
                                  ? 'No treatments found'
                                  : 'No results for "$searchQuery"',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => TreatmentListItem(
                    treatment: filtered[i],
                    onTap: () =>
                        context.push('/treatments/${filtered[i].id}'),
                  ),
                ),
        );
      },
    );
  }
}
