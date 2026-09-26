import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../../shared/providers/supabase_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

class LoginNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;

  LoginNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    final error = await _repo.signIn(email, password);
    if (!mounted) return;
    if (error != null) {
      state = AsyncValue.error(error, StackTrace.current);
    } else {
      state = const AsyncValue.data(null);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final loginProvider =
    StateNotifierProvider.autoDispose<LoginNotifier, AsyncValue<void>>((ref) {
  return LoginNotifier(ref.watch(authRepositoryProvider));
});
