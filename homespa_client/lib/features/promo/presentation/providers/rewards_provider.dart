import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/auth_session.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'promo_providers.dart';

String? _customerId() => AuthSession.current?.customerId;

/// Loyalty points balance from the platform profile.
final clientTotalPointsProvider = FutureProvider<int>((ref) async {
  ref.watch(authNotifierProvider);
  final customerId = _customerId();
  if (customerId == null) return 0;
  final json =
      await apiClient.get('/customers/$customerId/profile')
          as Map<String, dynamic>;
  final profile = json['profile'] as Map<String, dynamic>;
  return (profile['loyaltyPoints'] as num?)?.toInt() ?? 0;
});

Map<String, dynamic> _rewardShape(Map<String, dynamic> r) => {
  'id': r['id'],
  'title': r['title'],
  'description': r['description'],
  // Platform reward types → the labels the page renders.
  'reward_type': (r['rewardType'] as String?) == 'free_package'
      ? 'free_treatment'
      : 'discount_flat',
  'reward_value': r['discountIdr'],
  'points_required': r['pointsRequired'],
  // The reward's platform package id — createBooking books exactly this.
  'reward_treatment_id': r['packageId'],
  'reward_treatment': {'name': r['packageName']},
  'reward_duration': {
    'duration_minutes': (r['packageDurationMin'] as num?)?.toInt(),
  },
};

/// Points-priced rewards catalog (GET /rewards), shaped for the page.
final rewardsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final json = await apiClient.get('/rewards') as Map<String, dynamic>;
  return [
    for (final r in (json['rewards'] as List).cast<Map<String, dynamic>>())
      _rewardShape(r),
  ];
});

/// The customer's unused redemptions (GET /customers/{id}/reward-redemptions).
final myRedemptionsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  ref.watch(authNotifierProvider);
  final customerId = _customerId();
  if (customerId == null) return [];
  final json =
      await apiClient.get('/customers/$customerId/reward-redemptions')
          as Map<String, dynamic>;
  return [
    for (final r
        in (json['redemptions'] as List).cast<Map<String, dynamic>>())
      if (r['isUsed'] != true)
        {
          'id': r['id'],
          'is_used': r['isUsed'],
          'created_at': r['createdAt'],
          'rewards': _rewardShape({
            'id': r['id'],
            'title': r['rewardTitle'],
            'description': null,
            'rewardType': r['rewardType'],
            'discountIdr': r['discountIdr'],
            'pointsRequired': r['pointsSpent'],
            'packageId': r['packageId'],
            'packageName': r['packageName'],
            'packageDurationMin': r['packageDurationMin'],
          }),
        },
  ];
});

/// Redeems a reward with points on the platform (atomic balance check).
Future<void> redeemReward(String rewardId) async {
  final customerId = _customerId();
  if (customerId == null) {
    throw const ApiException('Not signed in', 401);
  }
  await apiClient.post(
    '/customers/$customerId/reward-redemptions',
    body: {'rewardId': rewardId},
  );
}

/// Active platform promo codes, shaped like the old saved-voucher rows.
final clientVouchersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.read(promoDataSourceProvider).getPromos();
});

final unusedVouchersProvider = FutureProvider<int>((ref) async {
  final redemptions = await ref.watch(myRedemptionsProvider.future);
  return redemptions.length;
});
