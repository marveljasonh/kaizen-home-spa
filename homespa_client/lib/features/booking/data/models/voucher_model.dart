import '../../domain/entities/voucher.dart';

class VoucherModel extends Voucher {
  const VoucherModel({
    required super.code,
    required super.discountType,
    required super.discountValue,
    super.minPurchaseAmount,
    super.description,
    super.expiresAt,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['discount_type'] as String? ?? 'fixed';
    // DB column is valid_until; fall back to expires_at for backwards compat
    final expiresRaw =
        (json['valid_until'] ?? json['expires_at']) as String?;
    return VoucherModel(
      code: json['code'] as String,
      discountType: typeStr == 'percentage'
          ? DiscountType.percentage
          : DiscountType.fixed,
      discountValue: (json['discount_value'] as num).toDouble(),
      // DB column is min_purchase; fall back to min_purchase_amount
      minPurchaseAmount:
          ((json['min_purchase'] ?? json['min_purchase_amount']) as num?)
                  ?.toDouble() ??
              0,
      description: json['description'] as String?,
      expiresAt: expiresRaw != null ? DateTime.tryParse(expiresRaw) : null,
    );
  }
}
