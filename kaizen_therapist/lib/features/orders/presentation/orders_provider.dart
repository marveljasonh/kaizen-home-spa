import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/orders_repository.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/providers/auth_provider.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(supabaseClientProvider));
});

final activeOrdersProvider = StreamProvider.autoDispose<List<Booking>>((ref) {
  final user = ref.watch(currentUserProvider);
  final therapistId = user?.id ?? '';

  print('[TherapistOrders] filtering by therapist_id: $therapistId');

  if (therapistId.isEmpty) return Stream.value([]);

  final client = ref.watch(supabaseClientProvider);
  final repo = ref.read(ordersRepositoryProvider);

  return client
      .from('bookings')
      .stream(primaryKey: ['id'])
      .eq('therapist_id', therapistId)
      .order('scheduled_at')
      .asyncMap((data) async {
        print('[TherapistOrders] stream update: ${data.length} bookings');
        return repo.getActiveOrders(therapistId);
      });
});

final historyOrdersProvider = StreamProvider.autoDispose<List<Booking>>((ref) {
  final user = ref.watch(currentUserProvider);
  final therapistId = user?.id ?? '';

  if (therapistId.isEmpty) return Stream.value([]);

  final client = ref.watch(supabaseClientProvider);
  final repo = ref.read(ordersRepositoryProvider);

  return client
      .from('bookings')
      .stream(primaryKey: ['id'])
      .eq('therapist_id', therapistId)
      .order('scheduled_at', ascending: false)
      .asyncMap((data) async {
        print('[TherapistOrders] history stream update: ${data.length} bookings');
        return repo.getHistoryOrders(therapistId);
      });
});
