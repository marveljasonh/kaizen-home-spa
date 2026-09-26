import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/therapist_profile.dart';
import 'supabase_provider.dart';

/// Fetches the authenticated user's role from the profiles table.
/// Used by the router to decide which dashboard to show after login.
final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final client = ref.watch(supabaseClientProvider);
  try {
    final data = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    return data?['role'] as String?;
  } catch (_) {
    return null;
  }
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => Supabase.instance.client.auth.currentUser,
  );
});

final therapistProfileProvider = FutureProvider<TherapistProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.id.isEmpty) return null;

  final client = ref.watch(supabaseClientProvider);

  try {
    // Two separate queries to avoid RLS join restrictions (406 on select('*, profiles(*)'))
    final tpData = await client
        .from('therapist_profiles')
        .select('*')
        .eq('profile_id', user.id)
        .single();

    final profileData = await client
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single();

    final combined = Map<String, dynamic>.from(tpData);
    combined['profiles'] = profileData;

    return TherapistProfile.fromJson(combined);
  } catch (_) {
    return null;
  }
});
