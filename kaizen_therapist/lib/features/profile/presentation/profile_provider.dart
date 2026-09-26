import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/profile_repository.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/providers/auth_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

class ProfileUpdateNotifier extends StateNotifier<AsyncValue<void>> {
  final ProfileRepository _repo;
  final Ref _ref;

  ProfileUpdateNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> save({
    required String therapistProfileId,
    required String bio,
    required List<String> specialties,
    required bool isAvailable,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateProfile(
        therapistProfileId: therapistProfileId,
        bio: bio,
        specialties: specialties,
        isAvailable: isAvailable,
      );
      if (!mounted) return;
      _ref.invalidate(therapistProfileProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final profileUpdateProvider =
    StateNotifierProvider.autoDispose<ProfileUpdateNotifier, AsyncValue<void>>((ref) {
  return ProfileUpdateNotifier(ref.watch(profileRepositoryProvider), ref);
});
