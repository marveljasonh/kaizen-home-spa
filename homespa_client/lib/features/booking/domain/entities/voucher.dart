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

  const Voucher({
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minPurchaseAmount = 0,
    this.description,
    this.expiresAt,
  });

  String get displayDiscount => discountType == DiscountType.percentage
      ? '${discountValue.toStringAsFixed(0)}% off'
      : '${formatRupiah(discountValue)} off';

  @override
  List<Object?> get props => [
    code,
    discountType,
    discountValue,
    minPurchaseAmount,
  ];
}
