import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/rider_assignment.dart';
import '../../../shared/widgets/status_badge.dart';
import 'rider_provider.dart';

const _bg = Color(0xFFFAF7F2);
const _card = Color(0xFFF5F0E8);
const _primary = Color(0xFF4E523B);
const _divider = Color(0xFFE0D9CE);
const _textPrimary = Color(0xFF1A1A14);
const _textSecondary = Color(0xFF7A7565);

class RiderHistoryPage extends ConsumerWidget {
  const RiderHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(riderActiveHistoryProvider);
    final completedAsync = ref.watch(riderCompletedHistoryProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'History',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ),
              Container(
                color: Colors.white,
                child: TabBar(
                  tabs: const [
                    Tab(text: 'Active'),
                    Tab(text: 'Completed'),
                  ],
                  labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                  labelColor: _primary,
                  unselectedLabelColor: _textSecondary,
                  indicatorColor: _primary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: _divider,
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _AssignmentList(
                      assignmentsAsync: activeAsync,
                      emptyMessage: 'No active assignments',
                      emptySubtitle: 'Active assignments will appear here',
                      emptyIcon: Icons.assignment_outlined,
                      onRefresh: () => ref.invalidate(riderActiveHistoryProvider),
                    ),
                    _AssignmentList(
                      assignmentsAsync: completedAsync,
                      emptyMessage: 'No completed assignments',
                      emptySubtitle: 'Completed assignments will appear here',
                      emptyIcon: Icons.check_circle_outline_rounded,
                      onRefresh: () =>
                          ref.invalidate(riderCompletedHistoryProvider),
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

class _AssignmentList extends StatelessWidget {
  final AsyncValue<List<RiderAssignment>> assignmentsAsync;
  final String emptyMessage;
  final String emptySubtitle;
  final IconData emptyIcon;
  final VoidCallback onRefresh;

  const _AssignmentList({
    required this.assignmentsAsync,
    required this.emptyMessage,
    required this.emptySubtitle,
    required this.emptyIcon,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return assignmentsAsync.when(
      data: (assignments) {
        if (assignments.isEmpty) {
          return RefreshIndicator(
            color: _primary,
            backgroundColor: _card,
            onRefresh: () async => onRefresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  child: _EmptyState(
                    message: emptyMessage,
                    subtitle: emptySubtitle,
                    icon: emptyIcon,
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: _primary,
          backgroundColor: _card,
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: assignments.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HistoryCard(
                assignment: assignments[i],
                onTap: () => context
                    .push('/rider-history-detail/${assignments[i].id}'),
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _primary)),
      error: (_, __) => Center(
        child: Text(
          'Failed to load assignments',
          style: GoogleFonts.inter(color: _textSecondary),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final RiderAssignment assignment;
  final VoidCallback onTap;

  const _HistoryCard({required this.assignment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    assignment.shortId,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                ),
                StatusBadge(status: assignment.status),
              ],
            ),
            if (assignment.scheduledAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule_outlined,
                      size: 14, color: _textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('EEE, d MMM yyyy • HH:mm')
                        .format(assignment.scheduledAt!),
                    style: GoogleFonts.inter(
                        fontSize: 12, color: _textSecondary),
                  ),
                ],
              ),
            ],
            if (assignment.address != null) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: _textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      assignment.address!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View details',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 11, color: _primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final String subtitle;
  final IconData icon;

  const _EmptyState({
    required this.message,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: _primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 13, color: _textSecondary),
          ),
        ],
      ),
    );
  }
}
