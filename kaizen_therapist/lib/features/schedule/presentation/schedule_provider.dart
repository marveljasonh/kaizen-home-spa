import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/presentation/dashboard_provider.dart';

final scheduleBookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) async {
  final profile = await ref.watch(therapistProfileProvider.future);
  if (profile == null) return [];
  return ref.read(dashboardRepositoryProvider).getScheduleBookings(profile.userId);
});

final upcomingCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final profile = await ref.watch(therapistProfileProvider.future);
  if (profile == null) return 0;
  return ref.read(dashboardRepositoryProvider).getUpcomingCount(profile.userId);
});
