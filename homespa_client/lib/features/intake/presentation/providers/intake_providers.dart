import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../domain/entities/client_intake.dart';

/// The signed-in client's intake answers, or null when they haven't filled
/// the form yet. Cached (not auto-disposed) and re-fetched only when the
/// signed-in user changes, so the router can read it on every redirect
/// without looping. Invalidate after saving.
final clientIntakeProvider = FutureProvider<ClientIntake?>((ref) async {
  final customerId = ref.watch(
    authNotifierProvider.select(
      (s) => s is AuthAuthenticated ? s.user.customerId : null,
    ),
  );
  if (customerId == null) return null;

  final json =
      await apiClient.get('/customers/$customerId/intake')
          as Map<String, dynamic>;
  final row = json['intake'] as Map<String, dynamic>?;
  debugPrint('[Intake] $customerId has intake: ${row != null}');
  return row == null ? null : ClientIntake.fromJson(row);
});
