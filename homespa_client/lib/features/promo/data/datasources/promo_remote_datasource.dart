import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/booking/data/models/voucher_model.dart';
import '../../../../features/booking/domain/entities/voucher.dart';
import '../../domain/entities/promo_banner.dart';
import '../models/promo_banner_model.dart';

abstract interface class PromoRemoteDataSource {
  Future<List<PromoBanner>> getBanners();
  Future<List<Voucher>> getAvailableVouchers();
}

class PromoRemoteDataSourceImpl implements PromoRemoteDataSource {
  final SupabaseClient _client;
  const PromoRemoteDataSourceImpl(this._client);

  @override
  Future<List<PromoBanner>> getBanners() async {
    try {
      final data = await _client
          .from('banners')
          .select('id, title, subtitle, image_url, is_active, valid_from, valid_until')
          .eq('is_active', true)
          .order('valid_from', ascending: false);
      return data.map((e) => PromoBannerModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Voucher>> getAvailableVouchers() async {
    try {
      final userId = _client.auth.currentUser?.id;
      final now = DateTime.now().toUtc().toIso8601String();

      final data = await _client
          .from('vouchers')
          .select('id, code, description, discount_type, discount_value, min_purchase, valid_until, is_active, max_uses_per_user')
          .eq('is_active', true)
          .gte('valid_until', now)
          .order('valid_until', ascending: true);

      if (data.isEmpty) return [];

      // Filter out vouchers the current user has already exhausted
      if (userId != null) {
        final voucherIds = data.map((r) => r['id'] as String).toList();

        final usageRows = await _client
            .from('voucher_usages')
            .select('voucher_id')
            .eq('user_id', userId)
            .inFilter('voucher_id', voucherIds);

        final usageCount = <String, int>{};
        for (final row in usageRows) {
          final vid = row['voucher_id'] as String;
          usageCount[vid] = (usageCount[vid] ?? 0) + 1;
        }

        final filtered = data.where((r) {
          final maxUses = (r['max_uses_per_user'] as int?) ?? 1;
          final used = usageCount[r['id'] as String] ?? 0;
          return used < maxUses;
        }).toList();

        return filtered.map((e) => VoucherModel.fromJson(e)).toList();
      }

      return data.map((e) => VoucherModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
