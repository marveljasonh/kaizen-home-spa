import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/flow_widgets.dart';
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

    // UTC start time, set once the user has been through the Schedule step.
    final scheduledAt = cart.scheduledAt;

    final bookedIds = ref
        .watch(bookedTherapistIdsProvider(scheduledAt))
        .maybeWhen(data: (ids) => ids, orElse: () => const <String>{});

    return FlowScaffold(
      title: 'Choose Therapist',
      header: const BookingStepIndicator(currentStep: 2),
      body: therapistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildTherapistList(
          context,
          ref,
          const [],
          selectedTherapist,
          bookedIds,
        ),
        data: (therapists) => _buildTherapistList(
          context,
          ref,
          therapists,
          selectedTherapist,
          bookedIds,
        ),
      ),
      bottomBar: FlowPrimaryButton(
        label: 'Continue',
        onTap: () => context.push('/booking/schedule'),
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
    color: kFlowPageColor,
    backgroundColor: Colors.white,
    onRefresh: () async => ref.invalidate(therapistsProvider),
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(kFlowGutter, 20, kFlowGutter, 20),
      children: [
        // ── Any available (always at top, the default) ──────────────────────
        _TherapistTile(
          isSelected: selectedTherapist == null,
          name: 'Any Available Therapist',
          subtitle:
              "We'll assign the best available therapist for your booking",
          avatarChild: const Icon(
            Icons.people_rounded,
            size: 26,
            color: Colors.white,
          ),
          onTap: () =>
              ref.read(bookingCartProvider.notifier).selectTherapist(null),
        ),

        // Specific therapists are only those who have treated this client.
        if (therapists.isEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'You can choose a specific therapist after your first completed '
            'treatment.',
            style: flowBody(12, color: kFlowMuted, height: 1.4),
          ),
        ],

        if (therapists.isNotEmpty) ...[
          const SizedBox(height: 24),
          const FlowSectionLabel('Your therapists'),
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
      message = 'This therapist is currently unavailable';
    } else if (isBookedAtTime) {
      message = 'This therapist is already booked at your selected time';
    } else {
      message = 'This therapist is not available';
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final showBadge = status != null || isBookedAtTime;

    return Opacity(
      opacity: _effectiveAvailable ? 1.0 : 0.6,
      child: FlowCard(
        selected: isSelected,
        onTap: _effectiveAvailable
            ? onTap
            : () => _handleUnavailableTap(context),
        child: Row(
          children: [
            _Avatar(name: name, avatarUrl: avatarUrl, avatarChild: avatarChild),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: flowHeading(20, height: 1.2)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: flowBody(12, color: kFlowMuted, height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (rating != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: kFlowGold,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: flowBody(12, weight: FontWeight.w500),
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
            const SizedBox(width: 12),
            FlowCheckMark(selected: isSelected),
          ],
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
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: flowBody(11, weight: FontWeight.w600, color: color),
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
      'on_duty' => kFlowGold,
      'break' => const Color(0xFF9FD3DC),
      _ => kFlowMuted,
    };
  }
  if (isBookedAtTime) return kFlowGold;
  return const Color(0xFFB5DDA4);
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
          placeholder: (_, __) =>
              _InitialsCircle(name: name, avatarChild: avatarChild),
          errorWidget: (_, __, ___) =>
              _InitialsCircle(name: name, avatarChild: avatarChild),
        ),
      );
    }
    return _InitialsCircle(name: name, avatarChild: avatarChild);
  }
}

class _InitialsCircle extends StatelessWidget {
  final String name;
  final Widget? avatarChild;

  const _InitialsCircle({required this.name, required this.avatarChild});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      alignment: Alignment.center,
      child:
          avatarChild ??
          Text(
            name.trim().isEmpty
                ? '?'
                : name
                      .trim()
                      .split(' ')
                      .take(2)
                      .map((w) => w[0].toUpperCase())
                      .join(),
            style: flowHeading(20),
          ),
    );
  }
}
