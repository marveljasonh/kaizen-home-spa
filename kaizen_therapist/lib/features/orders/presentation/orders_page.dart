import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/widgets/order_card.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final Stream<List<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final therapistId =
        Supabase.instance.client.auth.currentUser?.id ?? '';
    print('[Orders] therapistId: $therapistId');

    _stream = Supabase.instance.client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('therapist_id', therapistId)
        .order('scheduled_at')
        .asyncMap((rows) async {
          // Always work on mutable copies.
          final result =
              rows.map((r) => Map<String, dynamic>.from(r)).toList();

          // 1. Batch-fetch client profiles.
          final profileIds = result
              .map((r) => r['client_id'] as String?)
              .whereType<String>()
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList();

          if (profileIds.isNotEmpty) {
            try {
              final profiles = await Supabase.instance.client
                  .from('profiles')
                  .select('id, full_name, phone')
                  .filter('id', 'in', '(${profileIds.join(',')})');

              final byId = <String, Map<String, dynamic>>{
                for (final p in profiles) p['id'] as String: p,
              };

              for (final row in result) {
                final cid = row['client_id'] as String?;
                if (cid != null) row['profiles'] = byId[cid];
              }
            } catch (e) {
              print('[Orders] profile embed error: $e');
            }
          }

          // 2. Batch-fetch reviews for completed/cancelled bookings.
          final completedIds = result
              .where((r) =>
                  ['completed', 'cancelled'].contains(r['status']))
              .map((r) => r['id'] as String)
              .toList();

          if (completedIds.isNotEmpty) {
            try {
              final reviews = await Supabase.instance.client
                  .from('therapist_reviews')
                  .select('booking_id, rating, review_text')
                  .inFilter('booking_id', completedIds);

              final reviewMap = <String, Map<String, dynamic>>{
                for (final r in reviews)
                  r['booking_id'] as String:
                      Map<String, dynamic>.from(r),
              };

              for (final row in result) {
                final rev = reviewMap[row['id'] as String?];
                if (rev != null) {
                  row['__review_rating'] = rev['rating'];
                  row['__review_text'] =
                      rev['review_text'] ?? rev['comment'];
                }
              }
            } catch (e) {
              print('[Orders] review embed error: $e');
            }
          }

          return result;
        });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('[Orders] stream error: ${snapshot.error}');
            return _buildError(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final all = snapshot.data!;
          print('[Orders] received ${all.length} bookings');

          final active = all
              .where((b) => [
                    'therapist_assigned',
                    'on_the_way',
                    'arrived',
                    'in_progress',
                  ].contains(b['status']))
              .toList();

          final history = all
              .where((b) =>
                  ['completed', 'cancelled'].contains(b['status']))
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(
                context,
                active,
                'No active orders',
                'Active orders will appear here',
                Icons.assignment_outlined,
              ),
              _buildList(
                context,
                history,
                'No order history',
                'Completed orders will appear here',
                Icons.history_outlined,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Map<String, dynamic>> rows,
    String emptyMessage,
    String emptySubtitle,
    IconData emptyIcon,
  ) {
    if (rows.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF4E523B),
        backgroundColor: const Color(0xFFF5F0E8),
        onRefresh: () async => setState(() {}),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(emptyIcon,
                        size: 64,
                        color: AppColors.accent.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      emptyMessage,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      emptySubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF4E523B),
      backgroundColor: const Color(0xFFF5F0E8),
      onRefresh: () async => setState(() {}),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          return OrderCard(
            booking: Booking.fromJson(row),
            clientRating:
                (row['__review_rating'] as num?)?.toDouble(),
            clientReviewText: row['__review_text'] as String?,
            onTap: () => context.push(
                '/order-detail/${row['id'] as String}'),
          );
        },
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            'Failed to load orders',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
