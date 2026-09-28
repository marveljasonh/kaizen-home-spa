import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/treatment.dart';

class TreatmentListItem extends StatelessWidget {
  final Treatment treatment;
  final VoidCallback? onTap;

  const TreatmentListItem({super.key, required this.treatment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(treatment.categoryName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left image block
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: 110,
                height: 116,
                child:
                    treatment.imageUrl != null && treatment.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: treatment.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _GradientBlock(
                          color: color,
                          name: treatment.categoryName,
                        ),
                        errorWidget: (_, __, ___) => _GradientBlock(
                          color: color,
                          name: treatment.categoryName,
                        ),
                      )
                    : _GradientBlock(
                        color: color,
                        name: treatment.categoryName,
                      ),
              ),
            ),

            // Right content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        treatment.categoryName.toUpperCase(),
                        style: AppTypography.overline.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Name
                    Text(
                      treatment.name,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Description placeholder (2 lines of body)
                    if (treatment.name.length > 10)
                      Text(
                        'Professional in-home treatment',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),

                    // Duration + price row
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${treatment.displayDurationMinutes} min',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'from ${formatRupiah(treatment.displayPrice)}',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TreatmentListItemSkeleton extends StatelessWidget {
  const TreatmentListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.background,
      child: Container(
        height: 116,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 110,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 10,
                      width: 60,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 13,
                      width: double.infinity,
                      color: AppColors.surfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 11,
                      width: 140,
                      color: AppColors.surfaceVariant,
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

class _GradientBlock extends StatelessWidget {
  final Color color;
  final String name;
  const _GradientBlock({required this.color, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.secondary,
      child: Center(
        child: Icon(
          _categoryIcon(name),
          size: 36,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

Color _categoryColor(String categoryName) {
  return switch (categoryName.toLowerCase()) {
    'massage' => AppColors.primary,
    'facial' => AppColors.primaryDark,
    'stone' || 'hot stone' => AppColors.secondary,
    'scrub' || 'body scrub' => AppColors.gold,
    'aromatherapy' => AppColors.primaryDark,
    _ => AppColors.primary,
  };
}

IconData _categoryIcon(String categoryName) {
  return switch (categoryName.toLowerCase()) {
    'massage' => Icons.self_improvement_rounded,
    'facial' => Icons.face_retouching_natural,
    'stone' || 'hot stone' => Icons.spa_rounded,
    'scrub' || 'body scrub' => Icons.bubble_chart_rounded,
    'aromatherapy' => Icons.local_florist_rounded,
    _ => Icons.spa_outlined,
  };
}
