import 'package:intl/intl.dart';

import '../../../../core/api/api_client.dart';
import '../../../../features/booking/domain/entities/voucher.dart';
import '../../domain/entities/promo_banner.dart';

abstract interface class PromoRemoteDataSource {
  Future<List<PromoBanner>> getBanners();

  /// Active platform promo codes (raw maps for the "My Vouchers" list —
  /// same key shape the promo page renders).
  Future<List<Map<String, dynamic>>> getPromos();

  Future<List<Voucher>> getAvailableVouchers();
}

class PromoRemoteDataSourceImpl implements PromoRemoteDataSource {
  final ApiClient _api;
  const PromoRemoteDataSourceImpl(this._api);

  @override
  Future<List<PromoBanner>> getBanners() async {
    try {
      final json = await _api.get('/banners') as Map<String, dynamic>;
      return (json['banners'] as List)
          .cast<Map<String, dynamic>>()
          .map(
            (b) => PromoBanner(
              id: b['id'] as String,
              title: (b['title'] as String?) ?? '',
              subtitle: b['subtitle'] as String?,
              imageUrl: b['imageUrl'] as String?,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPromos() async {
    final json = await _api.get('/promos') as Map<String, dynamic>;
    return (json['promos'] as List).cast<Map<String, dynamic>>();
  }

  static String _describe(Map<String, dynamic> p) {
    final type = p['type'] as String?;
    if (type == 'free_addon' && p['addonName'] != null) {
      final dur = (p['addonDurationMin'] as num?)?.toInt() ?? 0;
      final value = (p['addonPriceIdr'] as num?)?.toInt() ?? 0;
      final valueStr = value > 0
          ? ' (worth ${NumberFormat.decimalPattern('id').format(value)} IDR)'
          : '';
      final firstOnly = p['firstTimeOnly'] == true
          ? ' — first app order only'
          : '';
      return dur > 0
          ? 'Free ${p['addonName']} $dur min$valueStr$firstOnly'
          : 'Free ${p['addonName']}$valueStr$firstOnly';
    }
    return 'Promo code';
  }

  @override
  Future<List<Map<String, dynamic>>> getPromos() async {
    try {
      final promos = await _fetchPromos();
      // Shaped like the old client_vouchers rows the promo page renders.
      return [
        for (final p in promos)
          {
            'id': p['id'],
            'is_used': false,
            'voucher': {
              'code': p['code'],
              'description': _describe(p),
              'discount_type': switch (p['type'] as String?) {
                'percent' => 'percentage',
                'fixed' => 'flat',
                _ => null,
              },
              'discount_value': p['amount'],
              'min_order_amount': p['minPurchaseIdr'],
              'valid_until': p['validTo'],
            },
          },
      ];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Voucher>> getAvailableVouchers() async {
    try {
      final promos = await _fetchPromos();
      return [
        for (final p in promos)
          Voucher(
            code: (p['code'] as String?) ?? '',
            discountType: DiscountType.fixed,
            discountValue: 0,
            description: _describe(p),
            expiresAt: DateTime.tryParse('${p['validTo']}'),
            freeAddonName: p['addonName'] as String?,
            freeAddonDurationMinutes: (p['addonDurationMin'] as num?)?.toInt(),
            freeAddonValueIdr: (p['addonPriceIdr'] as num?)?.toDouble(),
          ),
      ];
    } catch (_) {
      return [];
    }
  }
}
