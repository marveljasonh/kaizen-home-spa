import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/booking/domain/entities/voucher.dart';
import '../../data/datasources/promo_remote_datasource.dart';
import '../../domain/entities/promo_banner.dart';

final _promoDataSourceProvider = Provider<PromoRemoteDataSource>(
  (ref) => PromoRemoteDataSourceImpl(Supabase.instance.client),
);

final bannersProvider = FutureProvider<List<PromoBanner>>((ref) async {
  return ref.read(_promoDataSourceProvider).getBanners();
});

final availableVouchersProvider = FutureProvider<List<Voucher>>((ref) async {
  return ref.read(_promoDataSourceProvider).getAvailableVouchers();
});

// ── Loyalty ───────────────────────────────────────────────────────────────────

class LoyaltyData {
  static const int target = 10;

  final int completedOrders;
  const LoyaltyData(this.completedOrders);

  double get progress => (completedOrders / target).clamp(0.0, 1.0);
  bool get hasReward => completedOrders >= target;
  int get remaining => (target - completedOrders).clamp(0, target);
}

final loyaltyDataProvider = FutureProvider<LoyaltyData>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return const LoyaltyData(0);

  // Query both sources in parallel; use whichever gives a higher count.
  // The client_profiles counter is updated by a DB trigger on booking completion,
  // but the trigger may not have fired yet or the row may not exist.
  final results = await Future.wait([
    client
        .from('client_profiles')
        .select('completed_orders_count')
        .eq('profile_id', userId)
        .maybeSingle()
        .then((data) {
          debugPrint('[Loyalty] client_profiles row: $data');
          return data?['completed_orders_count'] as int? ?? 0;
        })
        .catchError((e) {
          debugPrint('[Loyalty] client_profiles error: $e');
          return 0;
        }),
    client
        .from('bookings')
        .select('id')
        .eq('client_id', userId)
        .eq('status', 'completed')
        .then((rows) {
          debugPrint('[Loyalty] completed bookings count: ${rows.length}');
          return rows.length;
        })
        .catchError((e) {
          debugPrint('[Loyalty] bookings count error: $e');
          return 0;
        }),
  ]);

  final count = results.reduce((a, b) => a > b ? a : b);
  debugPrint('[Loyalty] using count: $count');
  return LoyaltyData(count);
});
