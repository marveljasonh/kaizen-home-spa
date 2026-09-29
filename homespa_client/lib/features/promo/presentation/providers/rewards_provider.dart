import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final clientTotalPointsProvider = FutureProvider<int>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return 0;

  final data = await client
      .from('client_points')
      .select('points_earned')
      .eq('client_id', userId);

  return (data as List).fold<int>(
    0,
    (sum, row) => sum + (row['points_earned'] as int),
  );
});

/// Adds `reward_treatment_image_url` (the free treatment's `image_url`) to
/// each reward map. Flat query + inFilter, assembled in Dart.
Future<void> _attachTreatmentImages(
  SupabaseClient client,
  Iterable<Map<String, dynamic>> rewards,
) async {
  final ids = {
    for (final r in rewards)
      if (r['reward_treatment_id'] is String)
        r['reward_treatment_id'] as String,
  }.toList();
  if (ids.isEmpty) return;
  try {
    final rows = await client
        .from('treatments')
        .select('id, image_url')
        .inFilter('id', ids);
    final images = {
      for (final row in rows as List<dynamic>)
        (row as Map<String, dynamic>)['id'] as String: row['image_url'],
    };
    for (final r in rewards) {
      r['reward_treatment_image_url'] = images[r['reward_treatment_id']];
    }
  } catch (e) {
    // Cards fall back to the reward image or the bundled default.
    debugPrint('[Rewards] treatment images ERROR: $e');
  }
}

final rewardsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('rewards')
      .select(
        '*,'
        'reward_treatment:treatments!rewards_reward_treatment_id_fkey(name),'
        'reward_duration:treatment_durations!rewards_reward_treatment_duration_id_fkey(duration_minutes)',
      )
      .eq('is_active', true)
      .order('points_required', ascending: true);
  // `*` includes rewards.image_url.
  final rewards = List<Map<String, dynamic>>.from(data);
  await _attachTreatmentImages(Supabase.instance.client, rewards);
  return rewards;
});

final myRedemptionsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  debugPrint('myRedemptionsProvider userId: $userId');
  if (userId == null) return [];

  final data = await Supabase.instance.client
      .from('reward_redemptions')
      .select(
        '*, rewards(title, description, reward_type, reward_value, image_url, '
        'reward_treatment_id, reward_treatment_duration_id, '
        'reward_treatment:treatments!rewards_reward_treatment_id_fkey(name), '
        'reward_duration:treatment_durations!rewards_reward_treatment_duration_id_fkey(duration_minutes, price))',
      )
      .eq('client_id', userId)
      .eq('is_used', false)
      .order('created_at', ascending: false);

  debugPrint('myRedemptionsProvider data: ${data.length} items');
  final redemptions = List<Map<String, dynamic>>.from(data);
  await _attachTreatmentImages(Supabase.instance.client, [
    for (final r in redemptions)
      if (r['rewards'] is Map<String, dynamic>)
        r['rewards'] as Map<String, dynamic>,
  ]);
  debugPrint(
    'myRedemptionsProvider first: ${data.isNotEmpty ? data.first : 'empty'}',
  );

  return redemptions;
});

final clientVouchersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  final data = await Supabase.instance.client
      .from('client_vouchers')
      .select('*, voucher:vouchers(*)')
      .eq('client_id', userId)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data);
});

final unusedVouchersProvider = FutureProvider<int>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return 0;

  final data = await Supabase.instance.client
      .from('reward_redemptions')
      .select('id')
      .eq('client_id', userId)
      .eq('is_used', false);

  return (data as List).length;
});
