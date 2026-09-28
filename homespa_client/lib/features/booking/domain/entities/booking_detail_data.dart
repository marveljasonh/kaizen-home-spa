import 'booking_record.dart';

class TreatmentLineItem {
  final String name;
  final double price;
  final int durationMinutes;
  final int quantity;

  const TreatmentLineItem({
    required this.name,
    required this.price,
    this.durationMinutes = 0,
    this.quantity = 1,
  });
}

class AddonLineItem {
  final String name;
  final double price;
  final int quantity;

  const AddonLineItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });
}

class BookingDetailData {
  final String bookingId;
  final BookingStatus status;
  final DateTime scheduledAt;
  final String addressText;
  final String paymentMethod;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String? therapistId;
  final String? therapistName;
  final double? therapistRating;
  final String? therapistAvatarUrl;
  final String? therapistPhone;
  final List<TreatmentLineItem> treatments;
  final List<AddonLineItem> addons;
  final bool hasExistingReview;
  final double? existingRating;
  final String? existingReviewText;

  const BookingDetailData({
    required this.bookingId,
    required this.status,
    required this.scheduledAt,
    required this.addressText,
    required this.paymentMethod,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    this.therapistId,
    this.therapistName,
    this.therapistRating,
    this.therapistAvatarUrl,
    this.therapistPhone,
    this.treatments = const [],
    this.addons = const [],
    this.hasExistingReview = false,
    this.existingRating,
    this.existingReviewText,
  });

  BookingDetailData copyWith({
    BookingStatus? status,
    DateTime? scheduledAt,
    String? addressText,
    String? paymentMethod,
    double? subtotal,
    double? discountAmount,
    double? taxAmount,
    double? totalAmount,
    String? therapistId,
    String? therapistName,
    double? therapistRating,
    String? therapistAvatarUrl,
    String? therapistPhone,
    List<TreatmentLineItem>? treatments,
    List<AddonLineItem>? addons,
    bool? hasExistingReview,
    double? existingRating,
    String? existingReviewText,
  }) => BookingDetailData(
    bookingId: bookingId,
    status: status ?? this.status,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    addressText: addressText ?? this.addressText,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    subtotal: subtotal ?? this.subtotal,
    discountAmount: discountAmount ?? this.discountAmount,
    taxAmount: taxAmount ?? this.taxAmount,
    totalAmount: totalAmount ?? this.totalAmount,
    therapistId: therapistId ?? this.therapistId,
    therapistName: therapistName ?? this.therapistName,
    therapistRating: therapistRating ?? this.therapistRating,
    therapistAvatarUrl: therapistAvatarUrl ?? this.therapistAvatarUrl,
    therapistPhone: therapistPhone ?? this.therapistPhone,
    treatments: treatments ?? this.treatments,
    addons: addons ?? this.addons,
    hasExistingReview: hasExistingReview ?? this.hasExistingReview,
    existingRating: existingRating ?? this.existingRating,
    existingReviewText: existingReviewText ?? this.existingReviewText,
  );
}
