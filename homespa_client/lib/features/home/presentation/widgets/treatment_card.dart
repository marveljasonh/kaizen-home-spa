import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/treatment_preview.dart';

const double _kCardWidth = 180;
const double _kCardHeight = 220;

class TreatmentCard extends StatelessWidget {
  final TreatmentPreview treatment;
  final VoidCallback? onTap;

  const TreatmentCard({super.key, required this.treatment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcon(treatment.category);
    final hasImage =
        treatment.imageUrl != null && treatment.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _kCardWidth,
        height: _kCardHeight,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background: image or cream placeholder ──────────────
              if (hasImage)
                CachedNetworkImage(
                  imageUrl: treatment.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _Placeholder(icon: icon),
                  errorWidget: (_, __, ___) => _Placeholder(icon: icon),
                )
              else
                _Placeholder(icon: icon),

              // ── Dark gradient — only over real images ───────────────
              if (hasImage)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),

              // ── Duration badge ──────────────────────────────────────
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasImage
                        ? Colors.black.withValues(alpha: 0.45)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: hasImage
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${treatment.durationMinutes} min',
                        style: AppTypography.labelSmall.copyWith(
                          color: hasImage
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Name + price ────────────────────────────────────────
              Positioned(
                left: 12,
                right: 12,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      treatment.name,
                      style: AppTypography.headingSmall.copyWith(
                        color: hasImage
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'from ${formatRupiah(treatment.price)}',
                      style: AppTypography.labelMedium.copyWith(
                        color: hasImage
                            ? AppColors.gold
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Placeholder for treatments without an image ───────────────────────────────

class _Placeholder extends StatelessWidget {
  final IconData icon;
  const _Placeholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: AppColors.primary),
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class TreatmentCardSkeleton extends StatelessWidget {
  const TreatmentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.background,
      child: Container(
        width: _kCardWidth,
        height: _kCardHeight,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ── Category icon helper ──────────────────────────────────────────────────────

IconData _categoryIcon(String category) {
  return switch (category.toLowerCase()) {
    'massage' => Icons.self_improvement_rounded,
    'facial' => Icons.face_retouching_natural,
    'stone' || 'hot stone' => Icons.spa_rounded,
    'scrub' || 'body scrub' => Icons.bubble_chart_rounded,
    'aromatherapy' => Icons.local_florist_rounded,
    _ => Icons.spa_outlined,
  };
}
