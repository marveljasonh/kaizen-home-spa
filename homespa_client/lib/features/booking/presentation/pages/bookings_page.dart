import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../providers/booking_providers.dart';

const _upcomingStatuses = {
  'pending',
  'accepted',
  'therapist_assigned',
  'rider_assigned',
  'on_the_way',
  'arrived',
  'in_progress',
};

const _pastStatuses = {'completed', 'cancelled'};

class BookingsPage extends ConsumerWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Please log in to view your bookings.')),
      );
    }

    final streamAsync = ref.watch(bookingHistoryStreamProvider(userId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('My Bookings',
              style: AppTypography.headingMedium
                  .copyWith(color: AppColors.textPrimary)),
          centerTitle: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
            labelStyle: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: streamAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _ErrorState(
            onRetry: () =>
                ref.invalidate(bookingHistoryStreamProvider(userId)),
          ),
          data: (bookings) {
            final upcoming = bookings
                .where((b) =>
                    _upcomingStatuses.contains(b['status'] as String? ?? ''))
                .toList();
            final past = bookings
                .where((b) =>
                    _pastStatuses.contains(b['status'] as String? ?? ''))
                .toList();
            final refresh = () async {
              ref.invalidate(bookingHistoryStreamProvider(userId));
            };
            return TabBarView(
              children: [
                _BookingsList(
                  bookings: upcoming,
                  emptyIcon: Icons.event_available_rounded,
                  emptyMessage: 'No upcoming bookings',
                  emptySubtitle: 'Your confirmed sessions will appear here.',
                  onRefresh: refresh,
                ),
                _BookingsList(
                  bookings: past,
                  emptyIcon: Icons.history_rounded,
                  emptyMessage: 'No past bookings',
                  emptySubtitle:
                      'Completed and cancelled bookings will appear here.',
                  onRefresh: refresh,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── List ───────────────────────────────────────────────────────────────────────

class _BookingsList extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;
  final IconData emptyIcon;
  final String emptyMessage;
  final String emptySubtitle;
  final Future<void> Function()? onRefresh;

  const _BookingsList({
    required this.bookings,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.emptySubtitle,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      final emptyWidget = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          _EmptyState(
              icon: emptyIcon, message: emptyMessage, subtitle: emptySubtitle),
        ],
      );
      if (onRefresh != null) {
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: onRefresh!,
          child: emptyWidget,
        );
      }
      return emptyWidget;
    }
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: onRefresh ?? () async {},
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) => _BookingCard(
          booking: bookings[i],
          onTap: () {
            final id = bookings[i]['id'] as String?;
            print('[BookingsPage] navigating to detail, bookingId: $id');
            context.push('/bookings/$id');
          },
        ),
      ),
    );
  }
}

// ── Card ───────────────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback? onTap;
  const _BookingCard({required this.booking, this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final status = booking['status'] as String? ?? 'pending';
    final bookingId = booking['id'] as String? ?? '';
    final total = (booking['total_amount'] as num?)?.toDouble() ?? 0.0;
    final discount = (booking['discount_amount'] as num?)?.toDouble() ?? 0.0;
    final address = booking['address_snapshot'] as String? ?? '—';
    final hasTherapist = booking['therapist_id'] != null;
    final statusColor = _statusColor(status);

    DateTime? scheduledAt;
    final scheduledRaw = booking['scheduled_at'] as String?;
    if (scheduledRaw != null) {
      scheduledAt = DateTime.tryParse(scheduledRaw);
    }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.spa_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kaizen Spa Service',
                          style: text.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '#${bookingId.length >= 8 ? bookingId.substring(0, 8).toUpperCase() : bookingId.toUpperCase()}',
                          style: text.labelSmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(
                    label: _statusLabel(status),
                    color: statusColor,
                  ),
                ],
              ),
            ),

            const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.border),

            // ── Detail rows ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  if (scheduledAt != null)
                    _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: _formatDate(scheduledAt),
                      text: text,
                    ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.person_outline_rounded,
                    label: hasTherapist ? 'Therapist Assigned' : 'Finding therapist…',
                    text: text,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: address,
                    text: text,
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (discount > 0)
                    Text(
                      'Saved ${formatRupiah(discount)}',
                      style: text.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    children: [
                      Text(
                        formatRupiah(total),
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'View Details',
                          style: text.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final wib = WIB.toWIB(dt);
    final date = DateFormat('EEE, d MMM y').format(wib);
    final time = DateFormat('HH:mm').format(wib);
    return '$date • $time WIB';
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

String _statusLabel(String status) => switch (status) {
      'pending' => 'Pending',
      'accepted' => 'Accepted',
      'therapist_assigned' => 'Assigned',
      'rider_assigned' => 'On the Way',
      'on_the_way' => 'On the Way',
      'arrived' => 'Arrived',
      'in_progress' => 'In Progress',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      _ => status,
    };

Color _statusColor(String status) => switch (status) {
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
      _ => AppColors.textSecondary,
    };

// ── Status badge ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Detail row ─────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextTheme text;
  final int maxLines;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.text,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.message, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 56,
                color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              message,
              style: text.titleMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: text.bodySmall?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('Could not load bookings',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
