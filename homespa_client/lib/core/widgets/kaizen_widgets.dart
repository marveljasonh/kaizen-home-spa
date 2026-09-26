import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

// ── Primary button ────────────────────────────────────────────────────────────

class KaizenPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool showArrow;
  final bool isLoading;

  const KaizenPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.showArrow = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        decoration: BoxDecoration(
          color: onTap == null && !isLoading
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else ...[
              Text(
                label.toUpperCase(),
                style: AppTypography.buttonLabel.copyWith(color: Colors.white),
              ),
              if (showArrow) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 18),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ── Ghost button ──────────────────────────────────────────────────────────────

class KaizenGhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const KaizenGhostButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label.toUpperCase(),
          style: AppTypography.buttonLabel.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class KaizenSectionHeader extends StatelessWidget {
  final String overlineTitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const KaizenSectionHeader({
    super.key,
    required this.overlineTitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            overlineTitle,
            style: AppTypography.headingSmall
                .copyWith(color: AppColors.textPrimary),
          ),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.primary),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_rounded,
                    size: 14, color: AppColors.primary),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Feature tile ──────────────────────────────────────────────────────────────

class KaizenFeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const KaizenFeatureTile({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.labelSmall
              .copyWith(color: AppColors.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Promo banner ──────────────────────────────────────────────────────────────

class KaizenPromoBanner extends StatelessWidget {
  final String headline;
  final String subtext;
  final VoidCallback? onTap;

  const KaizenPromoBanner({
    super.key,
    required this.headline,
    required this.subtext,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'LIMITED OFFER',
                      style: AppTypography.overline
                          .copyWith(color: AppColors.gold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    headline,
                    style: AppTypography.headingMedium.copyWith(
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtext,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Booking field ─────────────────────────────────────────────────────────────

class KaizenBookingField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool hasDropdown;
  final VoidCallback? onTap;

  const KaizenBookingField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.hasDropdown = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: AppTypography.overline
                        .copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasDropdown)
              const Icon(Icons.expand_more_rounded,
                  color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
