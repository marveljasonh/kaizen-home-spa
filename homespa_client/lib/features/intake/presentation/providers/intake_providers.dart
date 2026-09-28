import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../domain/entities/client_intake.dart';

/// The signed-in client's intake answers, or null when they haven't filled
/// the form yet. Cached (not auto-disposed) and re-fetched only when the
/// signed-in user changes, so the router can read it on every redirect
/// without looping. Invalidate after saving.
final clientIntakeProvider = FutureProvider<ClientIntake?>((ref) async {
  final userId = ref.watch(
    authNotifierProvider.select(
      (s) => s is AuthAuthenticated ? s.user.id : null,
    ),
  );
  if (userId == null) return null;

  final row = await Supabase.instance.client
      .from('client_intake')
      .select('health_conditions, focus_areas, pressure, avoid_areas')
      .eq('client_id', userId)
      .maybeSingle();
  debugPrint('[Intake] $userId has intake: ${row != null}');
  return row == null ? null : ClientIntake.fromJson(row);
});
