import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/timezone_helper.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/order_card.dart';
import 'dashboard_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  String get _greeting {
    final hour = WIB.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(therapistProfileProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final upcomingAsync = ref.watch(upcomingOrdersProvider);
    final todayAsync = ref.watch(todayBookingsProvider);
    final availabilityState = ref.watch(availabilityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.cardBg,
        onRefresh: () async {
          ref.invalidate(therapistProfileProvider);
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(upcomingOrdersProvider);
          ref.invalidate(todayBookingsProvider);
        },
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context, profileAsync, availabilityState, ref),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsSection(statsAsync, profileAsync),
                    const SizedBox(height: 24),
                    _buildTodayScheduleSection(todayAsync, context),
                    const SizedBox(height: 24),
                    _buildUpcomingSection(upcomingAsync, context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AsyncValue<dynamic> profileAsync, AsyncValue<bool> availabilityState, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              profileAsync.when(
                data: (profile) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_greeting,',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile?.name ?? 'Employee',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox(height: 48),
                error: (_, __) => Text(
                  '$_greeting!',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              _buildAvailabilityToggle(context, availabilityState, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityToggle(BuildContext context, AsyncValue<bool> state, WidgetRef ref) {
    final isAvailable = state.value ?? false;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAvailable ? AppColors.success : Colors.white.withOpacity(0.4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isAvailable ? 'Available for bookings today' : 'Not available today',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Transform.scale(
          scale: 0.85,
          child: Switch(
            value: isAvailable,
            onChanged: state.isLoading
                ? null
                : (value) {
                    if (value) {
                      ref.read(availabilityProvider.notifier).setAvailable();
                    } else {
                      _showUnavailableSheet(context, ref);
                    }
                  },
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.success,
          ),
        ),
      ],
    );
  }

  void _showUnavailableSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        void setStatus(String status) {
          Navigator.of(context).pop();
          ref.read(availabilityProvider.notifier).setUnavailable(status);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Set your status',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.coffee_rounded, color: AppColors.primary),
              title: Text('Break / Short rest',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text('Taking a short break',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
              onTap: () => setStatus('break'),
            ),
            ListTile(
              leading: const Icon(Icons.home_rounded, color: AppColors.primary),
              title: Text('Day off',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text('Not working today',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
              onTap: () => setStatus('off'),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildTodayScheduleSection(AsyncValue<List<Booking>> todayAsync, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TODAY'S SCHEDULE",
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        todayAsync.when(
          data: (bookings) {
            final count = bookings.length;
            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Text(
                      count == 0
                          ? 'No bookings today'
                          : 'You have $count booking${count == 1 ? '' : 's'} today',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (bookings.isNotEmpty) ...[
                    const Divider(height: 1, color: AppColors.divider),
                    for (int i = 0; i < bookings.length; i++) ...[
                      _buildScheduleRow(bookings[i], context),
                      if (i < bookings.length - 1)
                        const Divider(height: 1, color: AppColors.divider),
                    ],
                    const SizedBox(height: 4),
                  ],
                ],
              ),
            );
          },
          loading: () => Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildScheduleRow(Booking booking, BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(booking.scheduledTime);
    final dotColor = _statusDotColor(booking.status);

    return GestureDetector(
      onTap: () => context.push('/order-detail/${booking.id}'),
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              timeStr,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              booking.clientName ?? 'Client',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Color _statusDotColor(String status) {
    switch (status) {
      case 'completed': return AppColors.success;
      case 'in_progress': return const Color(0xFF3498DB);
      case 'cancelled': return const Color(0xFFE74C3C);
      default: return AppColors.accent;
    }
  }

  Widget _buildStatsSection(AsyncValue<Map<String, int>> statsAsync, AsyncValue<dynamic> profileAsync) {
    final profile = profileAsync.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OVERVIEW',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: "Today's Orders",
                value: statsAsync.when(
                  data: (s) => s['today'].toString(),
                  loading: () => '—',
                  error: (_, __) => '?',
                ),
                icon: Icons.today_outlined,
                color: const Color(0xFF3498DB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'This Week',
                value: statsAsync.when(
                  data: (s) => s['week'].toString(),
                  loading: () => '—',
                  error: (_, __) => '?',
                ),
                icon: Icons.date_range_outlined,
                color: const Color(0xFF9B59B6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Rating',
                value: profile != null ? profile.displayRating : '—',
                icon: Icons.star_outlined,
                color: const Color(0xFFF39C12),
                suffix: profile != null && profile.rating > 0 ? '★' : '',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingSection(AsyncValue<List<Booking>> upcomingAsync, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "TODAY'S ORDERS",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/schedule'),
              child: Text(
                'Full Schedule',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        upcomingAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return _EmptyUpcoming();
            }
            return Column(
              children: orders
                  .map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: OrderCard(
                          booking: b,
                          onTap: () => context.push('/order-detail/${b.id}'),
                        ),
                      ))
                  .toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => Center(
            child: Text('Failed to load orders', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
        ),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String suffix;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value + suffix,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyUpcoming extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_outlined,
              size: 48, color: AppColors.accent.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text(
            'No upcoming orders',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'New orders will appear here',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
