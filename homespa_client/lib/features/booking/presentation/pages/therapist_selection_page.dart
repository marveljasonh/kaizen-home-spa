import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/therapist.dart';
import '../providers/booking_cart.dart';
import '../providers/booking_providers.dart';
import '../widgets/booking_step_indicator.dart';

class TherapistSelectionPage extends ConsumerWidget {
  const TherapistSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final therapistsAsync = ref.watch(therapistsProvider);
    final cart = ref.watch(bookingCartProvider);
    final selectedTherapist = cart.therapist;

    // Derive the exact scheduled datetime from cart selection
    final scheduledAt = (cart.selectedDate != null && cart.selectedTimeSlot != null)
        ? DateTime(
            cart.selectedDate!.year,
            cart.selectedDate!.month,
            cart.selectedDate!.day,
            cart.selectedTimeSlot!.hour,
          )
        : null;

    final bookedIds = ref
        .watch(bookedTherapistIdsProvider(scheduledAt))
        .maybeWhen(data: (ids) => ids, orElse: () => const <String>{});

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Therapist'),
        bottom: const BookingStepIndicator(currentStep: 2),
      ),
      body: therapistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildTherapistList(
            context, ref, const [], selectedTherapist, bookedIds),
        data: (therapists) =>
            _buildTherapistList(context, ref, therapists, selectedTherapist, bookedIds),
      ),
      bottomNavigationBar: _ContinueBar(
        onContinue: () => context.push('/booking/schedule'),
      ),
    );
  }
}

Widget _buildTherapistList(
  BuildContext context,
  WidgetRef ref,
  List<Therapist> therapists,
  Therapist? selectedTherapist,
  Set<String> bookedIds,
) {
  return RefreshIndicator(
    color: AppColors.primary,
    backgroundColor: AppColors.surface,
    onRefresh: () async => ref.invalidate(therapistsProvider),
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // ── Pick Any (always at top) ────────────────────────────────────────
        _TherapistTile(
          isSelected: selectedTherapist == null,
          name: 'Pick Any Therapist',
          subtitle: "We'll assign the best available therapist for your booking",
          avatarChild: const Icon(Icons.people_rounded, size: 26),
          onTap: () =>
              ref.read(bookingCartProvider.notifier).selectTherapist(null),
        ),

        if (therapists.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Therapists',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          ...therapists.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TherapistTile(
                isSelected: selectedTherapist?.id == t.id,
                name: t.name,
                subtitle: t.specialties.isNotEmpty
                    ? t.specialties.join(' • ')
                    : t.bio ?? '',
                rating: t.rating > 0 ? t.rating : null,
                reviewCount: t.reviewCount > 0 ? t.reviewCount : null,
                avatarUrl: t.avatarUrl,
                status: t.status,
                isAvailable: t.isAvailable,
                isBookedAtTime: bookedIds.contains(t.id),
                onTap: () =>
                    ref.read(bookingCartProvider.notifier).selectTherapist(t),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

// ── Therapist tile ─────────────────────────────────────────────────────────────

class _TherapistTile extends StatelessWidget {
  final bool isSelected;
  final String name;
  final String subtitle;
  final double? rating;
  final int? reviewCount;
  final String? avatarUrl;
  final Widget? avatarChild;
  final VoidCallback onTap;
  final String? status;
  final bool isAvailable;
  final bool isBookedAtTime;

  const _TherapistTile({
    required this.isSelected,
    required this.name,
    required this.subtitle,
    this.rating,
    this.reviewCount,
    this.avatarUrl,
    this.avatarChild,
    required this.onTap,
    this.status,
    this.isAvailable = true,
    this.isBookedAtTime = false,
  });

  bool get _effectiveAvailable => isAvailable && !isBookedAtTime;

  void _handleUnavailableTap(BuildContext context) {
    final String message;
    if (!isAvailable) {
      message = 'This therapist is not working today';
    } else if (isBookedAtTime) {
      message = 'This therapist is already booked at your selected time';
    } else {
      message = 'This therapist is not available';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final showBadge = status != null || isBookedAtTime;

    return Opacity(
      opacity: _effectiveAvailable ? 1.0 : 0.6,
      child: GestureDetector(
        onTap: _effectiveAvailable ? onTap : () => _handleUnavailableTap(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryLight.withValues(alpha: 0.5)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.border.withValues(alpha: 0.2),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _Avatar(
                name: name,
                avatarUrl: avatarUrl,
                avatarChild: avatarChild,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: text.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: text.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                    if (rating != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Color(0xFFFFC107)),
                          const SizedBox(width: 3),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: text.labelSmall?.copyWith(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                    if (showBadge) ...[
                      const SizedBox(height: 8),
                      _TherapistStatusBadge(
                        status: status,
                        isAvailable: isAvailable,
                        isBookedAtTime: isBookedAtTime,
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status badge ───────────────────────────────────────────────────────────────

class _TherapistStatusBadge extends StatelessWidget {
  final String? status;
  final bool isAvailable;
  final bool isBookedAtTime;
  const _TherapistStatusBadge({
    required this.status,
    required this.isAvailable,
    this.isBookedAtTime = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = _statusLabel(status, isAvailable, isBookedAtTime);
    final color = _statusColor(status, isAvailable, isBookedAtTime);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String? status, bool isAvailable, bool isBookedAtTime) {
  if (!isAvailable) {
    return switch (status) {
      'on_duty' => 'In Service',
      'break' => 'On Break',
      'off' => 'Day Off',
      _ => 'Unavailable',
    };
  }
  if (isBookedAtTime) return 'Booked';
  return 'Available';
}

Color _statusColor(String? status, bool isAvailable, bool isBookedAtTime) {
  if (!isAvailable) {
    return switch (status) {
      'on_duty' => const Color(0xFF856404),
      'break' => const Color(0xFF0C5460),
      _ => const Color(0xFF6B6B68),
    };
  }
  if (isBookedAtTime) return const Color(0xFF856404);
  return const Color(0xFF155724);
}

// ── Avatar ─────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final Widget? avatarChild;

  const _Avatar({
    required this.name,
    required this.avatarUrl,
    required this.avatarChild,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          placeholder: (_, __) => _InitialsCircle(
              name: name, avatarChild: avatarChild),
          errorWidget: (_, __, ___) => _InitialsCircle(
              name: name, avatarChild: avatarChild),
        ),
      );
    }
    return _InitialsCircle(name: name, avatarChild: avatarChild);
  }
}

class _InitialsCircle extends StatelessWidget {
  final String name;
  final Widget? avatarChild;

  const _InitialsCircle(
      {required this.name, required this.avatarChild});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: avatarChild ??
          Text(
            name.trim().isEmpty
                ? '?'
                : name
                    .trim()
                    .split(' ')
                    .take(2)
                    .map((w) => w[0].toUpperCase())
                    .join(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
    );
  }
}

// ── Continue bar ───────────────────────────────────────────────────────────────

class _ContinueBar extends StatelessWidget {
  final VoidCallback? onContinue;
  const _ContinueBar({this.onContinue});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
