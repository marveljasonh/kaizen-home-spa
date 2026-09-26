import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/timezone_helper.dart';
import '../../auth/presentation/login_provider.dart';
import '../../../shared/models/rider_assignment.dart';
import '../../../shared/widgets/status_badge.dart';
import 'rider_history_page.dart';
import 'rider_provider.dart';

const _bg = Color(0xFFFAF7F2);
const _card = Color(0xFFF5F0E8);
const _primary = Color(0xFF4E523B);
const _primaryLight = Color(0xFF6B7057);
const _divider = Color(0xFFE0D9CE);
const _textPrimary = Color(0xFF1A1A14);
const _textSecondary = Color(0xFF7A7565);

class RiderDashboardPage extends ConsumerStatefulWidget {
  const RiderDashboardPage({super.key});

  @override
  ConsumerState<RiderDashboardPage> createState() => _RiderDashboardPageState();
}

class _RiderDashboardPageState extends ConsumerState<RiderDashboardPage> {
  int _selectedIndex = 0;

  String get _greeting {
    final hour = WIB.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(riderProfileProvider);
    final upcomingAsync = ref.watch(riderUpcomingAssignmentsProvider);
    final isAvailable = ref.watch(riderAvailabilityProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: _selectedIndex == 0
          ? _buildDashboardBody(profileAsync, upcomingAsync, isAvailable)
          : _selectedIndex == 1
              ? const RiderHistoryPage()
              : _buildProfileBody(profileAsync),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardBody(
    AsyncValue<dynamic> profileAsync,
    AsyncValue<List<RiderAssignment>> upcomingAsync,
    bool isAvailable,
  ) {
    return RefreshIndicator(
      color: _primary,
      backgroundColor: _card,
      onRefresh: () async {
        ref.invalidate(riderProfileProvider);
        ref.invalidate(riderUpcomingAssignmentsProvider);
      },
      child: CustomScrollView(
        slivers: [
          _buildAppBar(profileAsync, isAvailable),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildUpcomingSection(upcomingAsync),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBody(AsyncValue<dynamic> profileAsync) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(
              'Profile',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            profileAsync.when(
              data: (profile) {
                final name = profile?.name as String? ?? 'Rider';
                final email = profile?.email as String? ?? '';
                final initial = name.isNotEmpty ? name[0].toUpperCase() : 'R';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                );
              },
              loading: () =>
                  const CircularProgressIndicator(color: _primary),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _primary),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AsyncValue<dynamic> profileAsync, bool isAvailable) {
    return SliverAppBar(
      expandedHeight: 195,
      pinned: true,
      backgroundColor: _primary,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primary, _primaryLight],
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
                        color: Colors.white.withOpacity(0.80),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile?.name as String? ?? 'Rider',
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
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildAvailabilityToggle(isAvailable),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityToggle(bool isAvailable) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAvailable
                ? const Color(0xFF2ECC71)
                : Colors.white.withOpacity(0.35),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isAvailable ? 'Available for assignments' : 'Not available',
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
            onChanged: (_) =>
                ref.read(riderAvailabilityProvider.notifier).toggle(),
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF2ECC71),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingSection(AsyncValue<List<RiderAssignment>> upcomingAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UPCOMING ORDERS',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        upcomingAsync.when(
          data: (assignments) {
            if (assignments.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _divider),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.delivery_dining_outlined,
                      size: 52,
                      color: _primary.withOpacity(0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No active assignments',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'New assignments will appear here',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: _textSecondary),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: assignments
                  .map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AssignmentCard(
                          assignment: a,
                          onTap: () =>
                              context.push('/rider-assignment/${a.id}'),
                        ),
                      ))
                  .toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: _primary),
            ),
          ),
          error: (_, __) => Center(
            child: Text(
              'Failed to load assignments',
              style: GoogleFonts.inter(color: _textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final RiderAssignment assignment;
  final VoidCallback onTap;

  const _AssignmentCard({required this.assignment, required this.onTap});

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: _divider),
            _buildDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.shortId,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
                if (assignment.clientName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    assignment.clientName!,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          StatusBadge(status: assignment.status),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (assignment.scheduledAt != null)
            _infoRow(
              Icons.schedule_outlined,
              DateFormat('EEE, dd MMM yyyy • HH:mm')
                  .format(assignment.scheduledAt!),
            ),
          if (assignment.address != null) ...[
            const SizedBox(height: 8),
            _infoRow(
              Icons.location_on_outlined,
              assignment.address!,
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment:
          maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: _textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _textSecondary,
              height: 1.4,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

