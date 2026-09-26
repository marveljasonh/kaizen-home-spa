import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  Future<String?> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        return 'Login failed. Please try again.';
      }

      // Verify therapist role
      final profile = await _client
          .from('profiles')
          .select('role')
          .eq('id', response.user!.id)
          .maybeSingle();

      final role = profile?['role'] as String?;
      if (role != 'therapist' && role != 'rider') {
        await _client.auth.signOut();
        return 'Access denied. Staff account required.';
      }

      return null; // null = success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
