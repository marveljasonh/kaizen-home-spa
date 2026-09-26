class BookingAddonRequest {
  final String addonId;
  final String addonName;
  final double unitPrice;
  final int quantity;

  const BookingAddonRequest({
    required this.addonId,
    required this.addonName,
    required this.unitPrice,
    this.quantity = 1,
  });

  @override
  String toString() =>
      'BookingAddonRequest(name: $addonName, unitPrice: $unitPrice, qty: $quantity, id: $addonId)';
}

class BookingItemRequest {
  final String? treatmentDurationId;
  final String treatmentName;
  final int durationMinutes;
  final double unitPrice;
  final int quantity;

  const BookingItemRequest({
    this.treatmentDurationId,
    required this.treatmentName,
    required this.durationMinutes,
    required this.unitPrice,
    this.quantity = 1,
  });

  @override
  String toString() =>
      'BookingItemRequest(name: $treatmentName, duration: ${durationMinutes}min, '
      'unitPrice: $unitPrice, qty: $quantity, durationId: $treatmentDurationId)';
}

class BookingRequest {
  final String treatmentId;
  final String? treatmentDurationId;
  final String? therapistId;
  final DateTime scheduledAt;
  final String addressText;
  final double latitude;
  final double longitude;
  final String? addressNotes;
  final String? voucherCode;
  final String paymentMethodId;
  final double subtotal;
  final double discountAmount;
  final double total;
  final List<BookingItemRequest> items;
  final List<BookingAddonRequest> addons;
  final String? freeRewardId;
  final String? freeRewardTreatmentId;
  final int? freeRewardDurationMinutes;
  final String? rewardRedemptionId; // ID of a discount reward redemption

  const BookingRequest({
    required this.treatmentId,
    this.treatmentDurationId,
    this.therapistId,
    required this.scheduledAt,
    required this.addressText,
    required this.latitude,
    required this.longitude,
    this.addressNotes,
    this.voucherCode,
    required this.paymentMethodId,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    this.items = const [],
    this.addons = const [],
    this.freeRewardId,
    this.freeRewardTreatmentId,
    this.freeRewardDurationMinutes,
    this.rewardRedemptionId,
  });

  Map<String, dynamic> toJson() => {
        'treatment_id': treatmentId,
        'treatment_duration_id': treatmentDurationId,
        'therapist_id': therapistId,
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'address_text': addressText,
        'latitude': latitude,
        'longitude': longitude,
        'address_notes': addressNotes,
        'voucher_code': voucherCode,
        'payment_method': paymentMethodId,
        'subtotal': subtotal,
        'discount': discountAmount,
        'total': total,
        'status': 'pending',
      };
}
