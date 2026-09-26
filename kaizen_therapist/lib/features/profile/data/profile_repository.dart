import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<void> updateProfile({
    required String therapistProfileId,
    required String bio,
    required List<String> specialties,
    required bool isAvailable,
  }) async {
    await _client
        .from('therapist_profiles')
        .update({
          'bio': bio,
          'specialties': specialties,
          'is_available': isAvailable,
        })
        .eq('id', therapistProfileId);
  }

  Future<void> updateAvailability(String therapistProfileId, bool isAvailable) async {
    await _client
        .from('therapist_profiles')
        .update({'is_available': isAvailable})
        .eq('id', therapistProfileId);
  }
}
