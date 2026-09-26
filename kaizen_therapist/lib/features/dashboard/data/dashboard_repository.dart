import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/timezone_helper.dart';
import '../../../shared/models/booking.dart';

class DashboardRepository {
  final SupabaseClient _client;

  DashboardRepository(this._client);

  Future<Map<String, int>> getOrderStats(String therapistId) async {
    debugPrint('[OrderStats] therapistId: $therapistId');
    final wib = WIB.now();
    final todayStart = WIB.startOfTodayUTC();
    final todayEnd = WIB.endOfTodayUTC();
    final weekStart = todayStart.subtract(Duration(days: wib.weekday - 1));

    final todayOrders = await _client
        .from('bookings')
        .select('id')
        .eq('therapist_id', therapistId)
        .gte('scheduled_at', todayStart.toIso8601String())
        .lt('scheduled_at', todayEnd.toIso8601String())
        .not('status', 'in', '("completed","cancelled")');

    final weekOrders = await _client
        .from('bookings')
        .select('id')
        .eq('therapist_id', therapistId)
        .neq('status', 'cancelled')
        .gte('scheduled_at', weekStart.toIso8601String())
        .lt('scheduled_at', todayEnd.toIso8601String());

    return {
      'today': todayOrders.length,
      'week': weekOrders.length,
    };
  }

  Future<List<Booking>> getUpcomingOrders(String therapistId) async {
    final startOfDay = WIB.startOfTodayUTC();
    final endOfToday = WIB.endOfTodayUTC();

    List<Map<String, dynamic>> rows;
    try {
      rows = await _client
          .from('bookings')
          .select('*, booking_items(id, quantity, treatment_snapshot)')
          .eq('therapist_id', therapistId)
          .filter('status', 'in', '(therapist_assigned,on_the_way,arrived,in_progress)')
          .gte('scheduled_at', startOfDay.toIso8601String())
          .lt('scheduled_at', endOfToday.toIso8601String())
          .order('scheduled_at')
          .limit(5);
    } catch (_) {
      rows = await _client
          .from('bookings')
          .select('*')
          .eq('therapist_id', therapistId)
          .filter('status', 'in', '(therapist_assigned,on_the_way,arrived,in_progress)')
          .gte('scheduled_at', startOfDay.toIso8601String())
          .lt('scheduled_at', endOfToday.toIso8601String())
          .order('scheduled_at')
          .limit(5);
    }

    await _embedClientProfiles(rows);
    return rows.map((json) => Booking.fromJson(json)).toList();
  }

  Future<List<Booking>> getScheduleBookings(String therapistId) async {
    final startOfDay = WIB.startOfTodayUTC();

    List<Map<String, dynamic>> rows;
    try {
      rows = await _client
          .from('bookings')
          .select('*, booking_items(id, quantity, treatment_snapshot)')
          .eq('therapist_id', therapistId)
          .gte('scheduled_at', startOfDay.toIso8601String())
          .not('status', 'in', '("completed","cancelled")')
          .order('scheduled_at', ascending: true);
    } catch (_) {
      rows = await _client
          .from('bookings')
          .select('*')
          .eq('therapist_id', therapistId)
          .gte('scheduled_at', startOfDay.toIso8601String())
          .not('status', 'in', '("completed","cancelled")')
          .order('scheduled_at', ascending: true);
    }

    await _embedClientProfiles(rows);
    return rows.map((json) => Booking.fromJson(json)).toList();
  }

  Future<int> getUpcomingCount(String therapistId) async {
    final startOfDay = WIB.startOfTodayUTC();

    final rows = await _client
        .from('bookings')
        .select('id')
        .eq('therapist_id', therapistId)
        .gte('scheduled_at', startOfDay.toIso8601String())
        .not('status', 'in', '("completed","cancelled")');

    return rows.length;
  }

  // Fetches profiles for all client_ids in the list and inlines them as 'profiles'.
  Future<void> _embedClientProfiles(List<Map<String, dynamic>> rows) async {
    final ids = rows
        .map((r) => r['client_id'] as String?)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (ids.isEmpty) return;

    try {
      final profiles = await _client
          .from('profiles')
          .select('id, full_name, phone')
          .filter('id', 'in', '(${ids.join(',')})');

      final byId = <String, Map<String, dynamic>>{
        for (final p in profiles) p['id'] as String: p,
      };

      for (final row in rows) {
        final cid = row['client_id'] as String?;
        if (cid != null) row['profiles'] = byId[cid];
      }
    } catch (_) {}
  }

  Future<List<Booking>> getTodayBookings(String therapistId) async {
    final startOfDay = WIB.startOfTodayUTC();
    final endOfDay = WIB.endOfTodayUTC();

    debugPrint('[TodayBookings] therapistId: $therapistId');
    debugPrint('[TodayBookings] startOfDay (WIB→UTC): ${startOfDay.toIso8601String()}');
    debugPrint('[TodayBookings] endOfDay   (WIB→UTC): ${endOfDay.toIso8601String()}');

    final rows = await _client
        .from('bookings')
        .select('*')
        .eq('therapist_id', therapistId)
        .gte('scheduled_at', startOfDay.toIso8601String())
        .lt('scheduled_at', endOfDay.toIso8601String())
        .not('status', 'in', '("completed","cancelled")')
        .order('scheduled_at');

    debugPrint('[TodayBookings] raw rows returned: ${rows.length}');
    for (final r in rows) {
      debugPrint('[TodayBookings] row → id: ${r['id']}, status: ${r['status']}, scheduled_at: ${r['scheduled_at']}');
    }

    await _embedClientProfiles(rows);
    return rows.map((json) => Booking.fromJson(json)).toList();
  }

  Future<void> updateAvailability(
    String userId,
    bool isAvailable,
    String status,
  ) async {
    if (userId.isEmpty) return;
    await _client
        .from('therapist_profiles')
        .update({'is_available': isAvailable, 'status': status})
        .eq('profile_id', userId);
  }
}
