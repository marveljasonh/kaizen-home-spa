import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/orders_repository.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/supabase_provider.dart';
import 'orders_provider.dart';

final orderDetailProvider =
    StreamProvider.autoDispose.family<Booking, String>((ref, bookingId) {
  final client = ref.watch(supabaseClientProvider);
  final repo = ref.read(ordersRepositoryProvider);

  // Re-fetch full booking (with profiles + addons) on every realtime event.
  return client
      .from('bookings')
      .stream(primaryKey: ['id'])
      .eq('id', bookingId)
      .asyncMap((_) => repo.getOrderById(bookingId));
});

class OrderActionNotifier extends StateNotifier<AsyncValue<void>> {
  final OrdersRepository _repo;
  final String _userId;
  final Ref _ref;

  OrderActionNotifier(this._repo, this._userId, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> updateStatus(String bookingId, String newStatus) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateStatus(bookingId, newStatus, _userId);
      if (!mounted) return false;
      state = const AsyncValue.data(null);
      _ref.invalidate(activeOrdersProvider);
      _ref.invalidate(historyOrdersProvider);
      _ref.invalidate(orderDetailProvider(bookingId));
      return true;
    } catch (e, st) {
      if (!mounted) return false;
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final orderActionProvider = StateNotifierProvider.autoDispose
    .family<OrderActionNotifier, AsyncValue<void>, String>((ref, bookingId) {
  final user = ref.watch(currentUserProvider);
  return OrderActionNotifier(
    ref.watch(ordersRepositoryProvider),
    user?.id ?? '',
    ref,
  );
});
