import '../../domain/entities/booking_record.dart';

class BookingRecordModel extends BookingRecord {
  const BookingRecordModel({
    required super.id,
    required super.treatmentId,
    required super.treatmentName,
    super.therapistName,
    required super.scheduledAt,
    required super.addressText,
    required super.paymentMethod,
    required super.subtotal,
    required super.discount,
    required super.total,
    required super.status,
    required super.createdAt,
  });

  factory BookingRecordModel.fromJson(
    Map<String, dynamic> json, {
    required String treatmentName,
    String? therapistName,
  }) =>
      BookingRecordModel(
        id: json['id'] as String,
        treatmentId: '',
        treatmentName: treatmentName,
        therapistName: therapistName,
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        addressText: json['address_snapshot'] as String? ?? '',
        paymentMethod: json['payment_method'] as String? ?? '',
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
        discount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
        total: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
        status: _parseStatus(json['status'] as String? ?? 'pending'),
        createdAt: DateTime.parse(
            json['created_at'] as String? ?? json['scheduled_at'] as String),
      );

  static BookingStatus _parseStatus(String s) => switch (s) {
        'confirmed' => BookingStatus.confirmed,
        'in_progress' => BookingStatus.inProgress,
        'completed' => BookingStatus.completed,
        'cancelled' => BookingStatus.cancelled,
        _ => BookingStatus.pending,
      };
}
