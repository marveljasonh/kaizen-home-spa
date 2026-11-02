import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../features/booking/domain/entities/voucher.dart';
import '../../../booking/presentation/providers/order_history_providers.dart';
import '../../data/datasources/promo_remote_datasource.dart';
import '../../domain/entities/promo_banner.dart';

final promoDataSourceProvider = Provider<PromoRemoteDataSource>(
  (ref) => PromoRemoteDataSourceImpl(apiClient),
);

/// Tab the Promos page should switch to (0 Promos, 1 Rewards), set by other
/// pages before they navigate to /promo (e.g. Profile → Point & Rewards).
/// The page clears it once it has switched.
final promoTabRequestProvider = StateProvider<int?>((ref) => null);

final bannersProvider = FutureProvider<List<PromoBanner>>((ref) async {
  return ref.read(promoDataSourceProvider).getBanners();
});

final availableVouchersProvider = FutureProvider<List<Voucher>>((ref) async {
  return ref.read(promoDataSourceProvider).getAvailableVouchers();
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
  try {
    final orders = await ref.watch(orderHistoryProvider.future);
    return LoyaltyData(orders.where((o) => o.isCompleted).length);
  } catch (_) {
    return const LoyaltyData(0);
  }
});
