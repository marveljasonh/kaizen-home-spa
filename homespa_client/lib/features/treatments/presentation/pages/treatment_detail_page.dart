import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/entities/treatment_duration.dart';
import '../providers/treatments_providers.dart';
import '../widgets/duration_selector.dart';

class TreatmentDetailPage extends ConsumerWidget {
  final String treatmentId;
  const TreatmentDetailPage({super.key, required this.treatmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treatmentAsync = ref.watch(treatmentDetailProvider(treatmentId));

    return treatmentAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text('Could not load treatment',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.invalidate(treatmentDetailProvider(treatmentId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (treatment) => _TreatmentDetailScaffold(treatment: treatment),
    );
  }
}

// ── Main scaffold ──────────────────────────────────────────────────────────

class _TreatmentDetailScaffold extends ConsumerWidget {
  final Treatment treatment;
  const _TreatmentDetailScaffold({required this.treatment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedDurationIdProvider(treatment.id));
    final resolved = _resolveSelected(treatment, selectedId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _HeroAppBar(treatment: treatment),
          SliverToBoxAdapter(
            child: _DetailContent(
              treatment: treatment,
              selectedId: selectedId,
              resolved: resolved,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BookingBar(
        price: resolved?.price ?? treatment.displayPrice,
        durationMinutes:
            resolved?.durationMinutes ?? treatment.displayDurationMinutes,
        onBook: () {
          context
              .push(
                '/treatments/${treatment.id}/addons',
                extra: {
                  'treatment': treatment,
                  'duration': resolved,
                },
              )
              .then((_) {
            // Addon page has been dismissed (Skip or Add to Cart).
            // Pop treatment detail so the user lands on the treatments list
            // where the snackbar (shown from the addon page) is visible.
            if (context.mounted) context.pop();
          });
        },
      ),
    );
  }
}

// ── Hero app bar ───────────────────────────────────────────────────────────

class _HeroAppBar extends StatelessWidget {
  final Treatment treatment;
  const _HeroAppBar({required this.treatment});

  @override
  Widget build(BuildContext context) {
    const color = AppColors.secondary;
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.secondary,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: (treatment.imageUrl != null && treatment.imageUrl!.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: treatment.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => _HeroPlaceholder(
                  color: color,
                  categoryName: treatment.categoryName,
                ),
                errorWidget: (context, url, error) => _HeroPlaceholder(
                  color: color,
                  categoryName: treatment.categoryName,
                ),
              )
            : _HeroPlaceholder(
                color: color,
                categoryName: treatment.categoryName,
              ),
        title: Text(
          treatment.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
      ),
    );
  }
}

// ── Detail content ─────────────────────────────────────────────────────────

class _DetailContent extends ConsumerWidget {
  final Treatment treatment;
  final String? selectedId;
  final TreatmentDuration? resolved;

  const _DetailContent({
    required this.treatment,
    required this.selectedId,
    required this.resolved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final color = _categoryColor(treatment.categoryName);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category row
          _Badge(label: treatment.categoryName, color: color),
          const SizedBox(height: 20),

          // Description
          Text('About', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            treatment.description.isNotEmpty
                ? treatment.description
                : 'A premium spa experience tailored to your needs, '
                    'delivered by certified therapists in the comfort of your home.',
            style: text.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),

          // Duration selector
          if (treatment.durations.isNotEmpty) ...[
            Text(
              'Select Duration',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            DurationSelector(
              durations: treatment.durations,
              selectedId: selectedId ?? treatment.defaultDuration?.id,
              onSelected: (id) => ref
                  .read(selectedDurationIdProvider(treatment.id).notifier)
                  .state = id,
            ),
            const SizedBox(height: 28),
          ],

          // What's included
          Text(
            "What's Included",
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ..._inclusions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(item, style: text.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100), // space for bottom bar
        ],
      ),
    );
  }

  static const _inclusions = [
    'Certified professional therapist',
    'All equipment & supplies provided',
    'Pre-treatment consultation',
    'Post-treatment care tips',
  ];
}

// ── Booking bar ────────────────────────────────────────────────────────────

class _BookingBar extends StatelessWidget {
  final double price;
  final int durationMinutes;
  final VoidCallback onBook;

  const _BookingBar({
    required this.price,
    required this.durationMinutes,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.15))),
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatRupiah(price),
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '$durationMinutes min session',
                  style: text.labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: FilledButton(
                onPressed: onBook,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _HeroPlaceholder extends StatelessWidget {
  final Color color;
  final String categoryName;
  const _HeroPlaceholder({required this.color, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Icon(
          _categoryIcon(categoryName),
          size: 96,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

TreatmentDuration? _resolveSelected(Treatment treatment, String? selectedId) {
  if (treatment.durations.isEmpty) return null;
  if (selectedId != null) {
    try {
      return treatment.durations.firstWhere((d) => d.id == selectedId);
    } catch (_) {}
  }
  return treatment.defaultDuration;
}

Color _categoryColor(String name) {
  return switch (name.toLowerCase()) {
    'massage' => AppColors.primary,
    'facial' => AppColors.primaryDark,
    'stone' || 'hot stone' => AppColors.secondary,
    'scrub' || 'body scrub' => AppColors.gold,
    'aromatherapy' => AppColors.primaryDark,
    _ => AppColors.primary,
  };
}

IconData _categoryIcon(String name) {
  return switch (name.toLowerCase()) {
    'massage' => Icons.self_improvement_rounded,
    'facial' => Icons.face_retouching_natural,
    'stone' || 'hot stone' => Icons.spa_rounded,
    'scrub' || 'body scrub' => Icons.bubble_chart_rounded,
    'aromatherapy' => Icons.local_florist_rounded,
    _ => Icons.spa_outlined,
  };
}
