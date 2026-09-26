import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dashboard_repository.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/therapist_profile.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/providers/auth_provider.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(supabaseClientProvider));
});

final dashboardStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final profile = await ref.watch(therapistProfileProvider.future);
  if (profile == null) return {'today': 0, 'week': 0};

  return ref.read(dashboardRepositoryProvider).getOrderStats(profile.userId);
});

final todayBookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) async {
  final profile = await ref.watch(therapistProfileProvider.future);
  if (profile == null) return [];

  return ref.read(dashboardRepositoryProvider).getTodayBookings(profile.userId);
});

final upcomingOrdersProvider = FutureProvider.autoDispose<List<Booking>>((ref) async {
  final profile = await ref.watch(therapistProfileProvider.future);
  if (profile == null) return [];

  return ref.read(dashboardRepositoryProvider).getUpcomingOrders(profile.userId);
});

class AvailabilityNotifier extends StateNotifier<AsyncValue<bool>> {
  final DashboardRepository _repo;
  final TherapistProfile _profile;

  AvailabilityNotifier(this._repo, this._profile)
      : super(AsyncValue.data(_profile.isAvailable));

  Future<void> setAvailable() async {
    if (_profile.userId.isEmpty) return;
    state = const AsyncValue.data(true);
    try {
      await _repo.updateAvailability(_profile.userId, true, 'available');
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.data(_profile.isAvailable);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setUnavailable(String status) async {
    if (_profile.userId.isEmpty) return;
    state = const AsyncValue.data(false);
    try {
      await _repo.updateAvailability(_profile.userId, false, status);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.data(_profile.isAvailable);
      state = AsyncValue.error(e, st);
    }
  }
}

final availabilityProvider =
    StateNotifierProvider.autoDispose<AvailabilityNotifier, AsyncValue<bool>>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  final profileAsync = ref.watch(therapistProfileProvider);

  return AvailabilityNotifier(
    repo,
    profileAsync.value ?? TherapistProfile(
      id: '', userId: '', name: '', email: '',
      isAvailable: false, specialties: [], rating: 0, totalReviews: 0,
    ),
  );
});
