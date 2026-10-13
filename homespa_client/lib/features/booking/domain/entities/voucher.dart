import 'package:equatable/equatable.dart';

import '../../../../core/utils/currency_formatter.dart';

enum DiscountType { percentage, fixed }

class Voucher extends Equatable {
  final String code;
  final DiscountType discountType;
  final double discountValue;
  final double minPurchaseAmount;
  final String? description;
  final DateTime? expiresAt;

  /// Platform promo codes grant a free add-on (e.g. KAIZENBARU = free 30-min
  /// Body Massage) instead of cutting the bill. [discountValue] stays 0 so
  /// cart math is untouched; the freebie is granted server-side on booking.
  final String? freeAddonName;
  final int? freeAddonDurationMinutes;
  final double? freeAddonValueIdr;

  const Voucher({
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minPurchaseAmount = 0,
    this.description,
    this.expiresAt,
    this.freeAddonName,
    this.freeAddonDurationMinutes,
    this.freeAddonValueIdr,
  });

  bool get grantsFreeAddon => freeAddonName != null;

  String get displayDiscount {
    if (grantsFreeAddon) {
      final min = freeAddonDurationMinutes;
      return min != null && min > 0
          ? 'Free $freeAddonName ($min min)'
          : 'Free $freeAddonName';
    }
    return discountType == DiscountType.percentage
        ? '${discountValue.toStringAsFixed(0)}% off'
        : '${formatRupiah(discountValue)} off';
  }

  @override
  List<Object?> get props => [
    code,
    discountType,
    discountValue,
    minPurchaseAmount,
    freeAddonName,
  ];
}
