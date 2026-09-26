import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/rider_assignment.dart';
import '../../../shared/models/rider_profile.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../data/rider_repository.dart';

final riderRepositoryProvider = Provider<RiderRepository>((ref) {
  return RiderRepository(ref.watch(supabaseClientProvider));
});

final riderProfileProvider = FutureProvider<RiderProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(riderRepositoryProvider).getRiderProfile(user.id);
});

final riderAssignmentsProvider = FutureProvider<List<RiderAssignment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(riderRepositoryProvider).getTodayAssignments(user.id);
});

// Availability toggle — initialised from profile; persists locally only.
// The admin dashboard determines availability from active assignment count.
class RiderAvailabilityNotifier extends StateNotifier<bool> {
  RiderAvailabilityNotifier(bool initial) : super(initial);
  void toggle() => state = !state;
}

final riderAvailabilityProvider =
    StateNotifierProvider<RiderAvailabilityNotifier, bool>((ref) {
  final profile = ref.watch(riderProfileProvider).value;
  return RiderAvailabilityNotifier(profile?.isAvailable ?? true);
});

// Assignment detail loader
final assignmentDetailProvider =
    FutureProvider.family<RiderAssignment?, String>((ref, id) async {
  return ref.watch(riderRepositoryProvider).getAssignment(id);
});

// Upcoming assignments (status = assigned)
final riderUpcomingAssignmentsProvider = FutureProvider<List<RiderAssignment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(riderRepositoryProvider).getUpcomingAssignments(user.id);
});

// Active assignments for history Active tab (assigned / on_the_way / arrived)
final riderActiveHistoryProvider = FutureProvider<List<RiderAssignment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(riderRepositoryProvider).getActiveAssignments(user.id);
});

// Completed assignments for history Completed tab
final riderCompletedHistoryProvider = FutureProvider<List<RiderAssignment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(riderRepositoryProvider).getCompletedAssignments(user.id);
});

// Past assignments (completed / arrived)
final riderPastAssignmentsProvider = FutureProvider<List<RiderAssignment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(riderRepositoryProvider).getPastAssignments(user.id);
});

// Assignment detail with therapist info (for history detail page)
final assignmentDetailWithTherapistProvider =
    FutureProvider.family<RiderAssignment?, String>((ref, id) async {
  return ref.watch(riderRepositoryProvider).getAssignmentWithTherapist(id);
});

