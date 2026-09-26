import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../domain/entities/booking_detail_data.dart';
import '../../domain/entities/booking_record.dart';
import '../providers/booking_providers.dart';

class BookingDetailPage extends ConsumerWidget {
  final String bookingId;
  const BookingDetailPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingDetailProvider(bookingId));
    // Realtime status comes from the stream; falls back to notifier state
    final streamAsync = ref.watch(bookingDetailStreamProvider(bookingId));
    final rawStatus = streamAsync.value?['status'] as String? ??
        _bookingStatusToString(state.detail?.status) ??
        'pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Details'),
        centerTitle: false,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _ErrorView(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(bookingDetailProvider(bookingId).notifier).reload(),
                )
              : state.detail == null
                  ? const Center(child: Text('No data found'))
                  : _DetailBody(detail: state.detail!, realtimeStatus: rawStatus),
      bottomNavigationBar: state.detail != null &&
              rawStatus == 'completed' &&
              !state.detail!.hasExistingReview &&
              state.detail!.therapistId != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: FilledButton.icon(
                  onPressed: () => _showRatingSheet(context, state.detail!),
                  icon: const Icon(Icons.star_rounded),
                  label: const Text(
                    'Rate Your Experience',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _showRatingSheet(BuildContext context, BookingDetailData detail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _RatingBottomSheet(
        bookingId: bookingId,
        therapistName: detail.therapistName,
      ),
    );
  }
}

// ── Detail body ────────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final BookingDetailData detail;
  final String realtimeStatus;
  const _DetailBody({required this.detail, required this.realtimeStatus});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // ── Status + booking ID ─────────────────────────────────────────────
        Row(
          children: [
            _StatusBadge(status: realtimeStatus),
            const Spacer(),
            Text(
              '#${detail.bookingId.substring(0, 8).toUpperCase()}',
              style: text.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Date / time ─────────────────────────────────────────────────────
        _SectionCard(
          children: [
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Date & Time',
              value: '${DateFormat('EEEE, d MMMM y • HH:mm').format(WIB.toWIB(detail.scheduledAt))} WIB',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Therapist section ───────────────────────────────────────────────
        _SectionLabel(label: 'YOUR THERAPIST'),
        const SizedBox(height: 8),
        _TherapistSection(detail: detail),
        if (detail.therapistPhone != null &&
            detail.therapistPhone!.isNotEmpty &&
            realtimeStatus != 'pending' &&
            realtimeStatus != 'cancelled') ...[
          const SizedBox(height: 10),
          _WhatsAppButton(phone: detail.therapistPhone!),
        ],
        const SizedBox(height: 12),

        // ── Treatments ordered ──────────────────────────────────────────────
        _SectionLabel(label: 'TREATMENTS'),
        const SizedBox(height: 8),
        _SectionCard(
          children: detail.treatments.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Kaizen Spa Service',
                      style: text.bodyMedium,
                    ),
                  ),
                ]
              : detail.treatments
                  .map((t) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.durationMinutes > 0
                                        ? '${t.name} • ${t.durationMinutes} min'
                                        : t.name,
                                    style: text.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  if (t.quantity > 1)
                                    Text('x${t.quantity}',
                                        style: text.labelSmall?.copyWith(
                                            color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            if (t.price == 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.goldDark,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'FREE',
                                  style: text.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              )
                            else
                              Text(
                                formatRupiah(t.price * t.quantity),
                                style: AppTypography.labelLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary),
                              ),
                          ],
                        ),
                      ))
                  .toList(),
        ),

        // ── Add-ons ─────────────────────────────────────────────────────────
        if (detail.addons.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionLabel(label: 'ADD-ONS'),
          const SizedBox(height: 8),
          _SectionCard(
            children: detail.addons
                .map((a) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              a.quantity > 1
                                  ? '${a.name} x${a.quantity}'
                                  : a.name,
                              style: text.bodyMedium,
                            ),
                          ),
                          Text(
                            formatRupiah(a.price * a.quantity),
                            style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],

        const SizedBox(height: 12),

        // ── Location ────────────────────────────────────────────────────────
        _SectionLabel(label: 'LOCATION'),
        const SizedBox(height: 8),
        _SectionCard(
          children: [
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: detail.addressText.isNotEmpty
                  ? detail.addressText
                  : 'No address provided',
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Payment ─────────────────────────────────────────────────────────
        _SectionLabel(label: 'PAYMENT'),
        const SizedBox(height: 8),
        _SectionCard(
          children: [
            _InfoRow(
              icon: Icons.payment_rounded,
              label: 'Method',
              value: detail.paymentMethod.toUpperCase(),
            ),
            const Divider(height: 20),
            _PaymentRow(label: 'Subtotal', value: detail.subtotal),
            if (detail.discountAmount > 0)
              _PaymentRow(
                label: 'Discount',
                value: -detail.discountAmount,
                valueColor: const Color(0xFF10B981),
              ),
            if (detail.taxAmount > 0)
              _PaymentRow(label: 'Tax', value: detail.taxAmount),
            const Divider(height: 16),
            _PaymentRow(
              label: 'Total',
              value: detail.totalAmount,
              isBold: true,
            ),
          ],
        ),

        // ── Your review ──────────────────────────────────────────────────────
        if (detail.hasExistingReview) ...[
          const SizedBox(height: 12),
          _SectionLabel(label: 'YOUR REVIEW'),
          const SizedBox(height: 8),
          _YourReviewCard(
            rating: detail.existingRating ?? 0,
            reviewText: detail.existingReviewText,
          ),
        ],
      ],
    );
  }
}

// ── Therapist section ──────────────────────────────────────────────────────────

class _TherapistSection extends StatelessWidget {
  final BookingDetailData detail;
  const _TherapistSection({required this.detail});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    if (detail.therapistId == null) {
      // Therapist not yet assigned
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Finding your therapist…',
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Therapist assigned
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: detail.therapistAvatarUrl != null &&
                    detail.therapistAvatarUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: detail.therapistAvatarUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        _InitialsAvatar(name: detail.therapistName ?? 'T'),
                  )
                : _InitialsAvatar(name: detail.therapistName ?? 'T'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.therapistName ?? 'Therapist',
                  style:
                      text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (detail.therapistRating != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Color(0xFFFFC107)),
                      const SizedBox(width: 3),
                      Text(
                        detail.therapistRating!.toStringAsFixed(1),
                        style: text.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── WhatsApp button ────────────────────────────────────────────────────────────

class _WhatsAppButton extends StatelessWidget {
  final String phone;
  const _WhatsAppButton({required this.phone});

  Future<void> _launch() async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final waPhone = clean.startsWith('0') ? '62${clean.substring(1)}' : clean;
    final url = Uri.parse('https://wa.me/$waPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _launch,
      icon: const Icon(Icons.chat_rounded, size: 18, color: Colors.white),
      label: const Text(
        'Chat Therapist',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 46),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  const _InitialsAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ── Rating bottom sheet ────────────────────────────────────────────────────────

class _RatingBottomSheet extends ConsumerStatefulWidget {
  final String bookingId;
  final String? therapistName;

  const _RatingBottomSheet({
    required this.bookingId,
    required this.therapistName,
  });

  @override
  ConsumerState<_RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends ConsumerState<_RatingBottomSheet> {
  double _rating = 0;
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // ref is provided by ConsumerState
    final detailState = ref.watch(bookingDetailProvider(widget.bookingId));
    final isSubmitting = detailState.isSubmittingReview;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Rate Your Experience',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (widget.therapistName != null) ...[
            const SizedBox(height: 4),
            Text(
              'How was your session with ${widget.therapistName}?',
              style:
                  text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 24),

          // Star rating
          Center(
            child: RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 44,
              itemPadding: const EdgeInsets.symmetric(horizontal: 6),
              itemBuilder: (_, __) =>
                  const Icon(Icons.star_rounded, color: Color(0xFFFFC107)),
              onRatingUpdate: (r) => setState(() => _rating = r),
            ),
          ),

          const SizedBox(height: 24),

          // Review text field
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write a review (optional)…',
              filled: true,
              fillColor:
                  AppColors.surfaceVariant.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 20),

          // Submit button
          FilledButton(
            onPressed: _rating == 0 || isSubmitting
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);
                    try {
                      await ref
                          .read(bookingDetailProvider(widget.bookingId).notifier)
                          .submitReview(
                            rating: _rating,
                            reviewText: _reviewController.text,
                          );
                      if (!mounted) return;
                      nav.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Review submitted — thank you!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Could not submit review: $e'),
                          backgroundColor: const Color(0xFFD32F2F),
                        ),
                      );
                    }
                  },
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Submit Review',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Shared UI widgets ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'pending' => const Color(0xFFF59E0B),
      'accepted' ||
      'therapist_assigned' ||
      'rider_assigned' ||
      'on_the_way' ||
      'arrived' =>
        const Color(0xFF3B82F6),
      'in_progress' => const Color(0xFF8B5CF6),
      'completed' => const Color(0xFF10B981),
      'cancelled' => const Color(0xFF6B7280),
      _ => const Color(0xFF6B7280),
    };
    final label = switch (status) {
      'pending' => 'Pending',
      'accepted' => 'Accepted',
      'therapist_assigned' => 'Therapist Assigned',
      'rider_assigned' => 'On the Way',
      'on_the_way' => 'On the Way',
      'arrived' => 'Arrived',
      'in_progress' => 'In Progress',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.textSecondary,
          ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: text.labelSmall
                      ?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: text.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  final Color? valueColor;
  const _PaymentRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final weight = isBold ? FontWeight.w800 : FontWeight.w500;
    final style = isBold
        ? AppTypography.headingSmall.copyWith(
            fontWeight: weight,
            color: valueColor ?? AppColors.primary,
          )
        : text.bodyMedium?.copyWith(
            fontWeight: weight,
            color: valueColor ?? AppColors.textPrimary,
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: text.bodyMedium?.copyWith(
                  color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: weight)),
          Text(
            value < 0
                ? '-${formatRupiah(-value)}'
                : formatRupiah(value),
            style: style,
          ),
        ],
      ),
    );
  }
}

// ── Your review card ───────────────────────────────────────────────────────────

class _YourReviewCard extends StatelessWidget {
  final double rating;
  final String? reviewText;
  const _YourReviewCard({required this.rating, this.reviewText});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _SectionCard(
      children: [
        Row(
          children: [
            ...List.generate(
              5,
              (i) => Icon(
                i < rating.round()
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 22,
                color: const Color(0xFFFFC107),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${rating.toStringAsFixed(0)}/5',
              style: text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        if (reviewText != null && reviewText!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            reviewText!,
            style: text.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Could not load booking details',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

String? _bookingStatusToString(BookingStatus? status) => switch (status) {
      BookingStatus.pending => 'pending',
      BookingStatus.confirmed => 'therapist_assigned',
      BookingStatus.inProgress => 'in_progress',
      BookingStatus.completed => 'completed',
      BookingStatus.cancelled => 'cancelled',
      null => null,
    };
