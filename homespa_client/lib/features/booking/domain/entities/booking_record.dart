import 'package:equatable/equatable.dart';

import '../../../../core/utils/currency_formatter.dart';

enum BookingStatus { pending, confirmed, inProgress, completed, cancelled }

class BookingRecord extends Equatable {
  final String id;
  final String treatmentId;
  final String treatmentName;
  final String? therapistName;
  final DateTime scheduledAt;
  final String addressText;
  final String paymentMethod;
  final double subtotal;
  final double discount;
  final double total;
  final BookingStatus status;
  final DateTime createdAt;

  const BookingRecord({
    required this.id,
    required this.treatmentId,
    required this.treatmentName,
    this.therapistName,
    required this.scheduledAt,
    required this.addressText,
    required this.paymentMethod,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  bool get isUpcoming =>
      status == BookingStatus.pending ||
      status == BookingStatus.confirmed ||
      status == BookingStatus.inProgress;

  String get statusLabel => switch (status) {
    BookingStatus.pending => 'Pending',
    BookingStatus.confirmed => 'Confirmed',
    BookingStatus.inProgress => 'In Progress',
    BookingStatus.completed => 'Completed',
    BookingStatus.cancelled => 'Cancelled',
  };

  String get displayTotal => formatRupiah(total);

  @override
  List<Object?> get props => [id, treatmentId, scheduledAt, status];
}
