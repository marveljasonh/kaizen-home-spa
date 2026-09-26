import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/booking.dart';

class OrdersRepository {
  final SupabaseClient _client;

  OrdersRepository(this._client);

  Future<List<Booking>> getActiveOrders(String therapistId) async {
    return _fetchOrders(
      therapistId,
      '(therapist_assigned,on_the_way,arrived,in_progress)',
      ascending: true,
    );
  }

  Future<List<Booking>> getHistoryOrders(String therapistId) async {
    return _fetchOrders(
      therapistId,
      '(completed,cancelled)',
      ascending: false,
    );
  }

  Future<List<Booking>> _fetchOrders(
    String therapistId,
    String statusFilter, {
    required bool ascending,
  }) async {
    List<Map<String, dynamic>> rows;

    try {
      rows = await _client
          .from('bookings')
          .select('*, booking_items(id, quantity, treatment_snapshot)')
          .eq('therapist_id', therapistId)
          .filter('status', 'in', statusFilter)
          .order('scheduled_at', ascending: ascending);
    } catch (_) {
      rows = await _client
          .from('bookings')
          .select('*')
          .eq('therapist_id', therapistId)
          .filter('status', 'in', statusFilter)
          .order('scheduled_at', ascending: ascending);
    }

    await _embedClientProfiles(rows);
    return rows.map((json) => Booking.fromJson(json)).toList();
  }

  Future<Booking> getOrderById(String bookingId) async {
    Map<String, dynamic> row;

    try {
      row = await _client
          .from('bookings')
          .select(
            '*, '
            'booking_items(id, quantity, treatment_snapshot), '
            'rider:profiles!bookings_rider_id_fkey(full_name, phone)',
          )
          .eq('id', bookingId)
          .single();
    } catch (_) {
      row = await _client
          .from('bookings')
          .select('*')
          .eq('id', bookingId)
          .single();
    }

    // Fetch client profile
    final clientId = row['client_id'] as String?;
    if (clientId != null && clientId.isNotEmpty) {
      try {
        final profile = await _client
            .from('profiles')
            .select('full_name, phone')
            .eq('id', clientId)
            .maybeSingle();
        row['profiles'] = profile;
      } catch (_) {}
    }

    // Fetch add-ons
    try {
      final addons = await _client
          .from('booking_addons')
          .select('*')
          .eq('booking_id', bookingId);
      row['booking_addons'] = addons;
    } catch (_) {
      row['booking_addons'] = [];
    }

    final riderData = row['rider'] as Map<String, dynamic>?;
    final riderName = riderData?['full_name'];
    final riderPhone = riderData?['phone'];
    debugPrint('[OrderDetail] Rider data: $riderData');
    debugPrint('[OrderDetail] Rider name: $riderName');
    debugPrint('[OrderDetail] Rider phone: $riderPhone');

    return Booking.fromJson(row);
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

  Future<void> updateStatus(
    String bookingId,
    String newStatus,
    String userId,
  ) async {
    await _client
        .from('bookings')
        .update({'status': newStatus})
        .eq('id', bookingId);

    await _client.from('order_status_logs').insert({
      'booking_id': bookingId,
      'status': newStatus,
      'changed_by': userId,
      'note': 'Status updated by therapist',
    });
  }
}
