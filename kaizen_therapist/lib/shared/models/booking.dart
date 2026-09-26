import 'dart:convert';
import '../../core/utils/timezone_helper.dart';

class Booking {
  final String id;
  final String bookingNumber;
  final String status;
  final DateTime scheduledTime;
  final String address;
  final String clientId;
  final String? clientName;
  final String? clientPhone;
  final String? therapistId;
  final List<BookingTreatment> treatments;
  final List<BookingAddon> addons;
  final String? notes;
  final double? totalPrice;
  final double? subtotal;
  final double? discountAmount;
  final double? totalAmount;
  final String? paymentMethod;
  final String? riderName;
  final String? riderPhone;

  Booking({
    required this.id,
    required this.bookingNumber,
    required this.status,
    required this.scheduledTime,
    required this.address,
    required this.clientId,
    this.clientName,
    this.clientPhone,
    this.therapistId,
    required this.treatments,
    this.addons = const [],
    this.notes,
    this.totalPrice,
    this.subtotal,
    this.discountAmount,
    this.totalAmount,
    this.paymentMethod,
    this.riderName,
    this.riderPhone,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final clientProfile = json['profiles'] as Map<String, dynamic>? ??
        json['client'] as Map<String, dynamic>? ??
        {};

    List<BookingTreatment> treatments = [];
    final rawTreatments = json['booking_items'] ?? json['booking_treatments'] ?? json['treatments_list'];
    if (rawTreatments is List) {
      treatments = rawTreatments
          .map((t) => BookingTreatment.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    List<BookingAddon> addons = [];
    final rawAddons = json['booking_addons'];
    if (rawAddons is List) {
      addons = rawAddons
          .map((a) => BookingAddon.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    final rawTime = json['scheduled_at'] as String? ?? json['scheduled_time'] as String?;
    final id = json['id'] as String;

    return Booking(
      id: id,
      bookingNumber: '#${id.substring(0, 8).toUpperCase()}',
      status: json['status'] as String? ?? 'pending',
      scheduledTime: WIB.toWIB(DateTime.parse(rawTime!)),
      address: _parseAddress(json['address_snapshot']) ?? json['address'] as String? ?? '',
      clientId: json['client_id'] as String? ?? '',
      clientName: clientProfile['full_name'] as String? ??
          clientProfile['name'] as String? ??
          (json['client_id'] != null
              ? 'Customer ${(json['client_id'] as String).substring(0, 6).toUpperCase()}'
              : null),
      clientPhone: clientProfile['phone'] as String?,
      therapistId: json['therapist_id'] as String?,
      treatments: treatments,
      addons: addons,
      notes: json['notes'] as String?,
      totalPrice: (json['total_price'] as num?)?.toDouble(),
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble(),
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      paymentMethod: json['payment_method'] as String?,
      riderName: json['__rider_name'] as String? ??
          (json['rider'] as Map<String, dynamic>?)?['full_name'] as String?,
      riderPhone: json['__rider_phone'] as String? ??
          (json['rider'] as Map<String, dynamic>?)?['phone'] as String?,
    );
  }

  // Parses address_snapshot which can be a Map (JSONB) or raw string (coordinates/text).
  static String? _parseAddress(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      return raw['address_line'] as String? ??
          raw['full_address'] as String? ??
          raw['address'] as String?;
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return decoded['address_line'] as String? ??
            decoded['full_address'] as String? ??
            decoded['address'] as String? ??
            raw;
      } catch (_) {
        return raw; // coordinates string or plain text
      }
    }
    return null;
  }

  static const List<String> activeStatuses = [
    'therapist_assigned',
    'on_the_way',
    'arrived',
    'in_progress',
  ];

  static const List<String> historyStatuses = [
    'completed',
    'cancelled',
  ];

  bool get isActive => activeStatuses.contains(status);
  bool get isHistory => historyStatuses.contains(status);
  bool get hasAction => activeStatuses.contains(status);

  String get nextStatus {
    switch (status) {
      case 'therapist_assigned':
        return 'on_the_way';
      case 'on_the_way':
        return 'arrived';
      case 'arrived':
        return 'in_progress';
      case 'in_progress':
        return 'completed';
      default:
        return status;
    }
  }

  String get actionButtonLabel {
    switch (status) {
      case 'therapist_assigned':
        return 'Start Journey';
      case 'on_the_way':
        return "I've Arrived";
      case 'arrived':
        return 'Start Treatment';
      case 'in_progress':
        return 'Complete Treatment';
      default:
        return '';
    }
  }

  String get treatmentNames {
    if (treatments.isEmpty) return 'No treatments';
    return treatments.map((t) => t.name).join(', ');
  }

  String get totalPriceText {
    if (totalPrice == null) return '';
    return _formatRp(totalPrice!);
  }

  String get subtotalText => subtotal != null ? _formatRp(subtotal!) : '';
  String get discountText => (discountAmount != null && discountAmount! > 0)
      ? '-${_formatRp(discountAmount!)}'
      : '';
  String get totalAmountText {
    final amount = totalAmount ?? totalPrice;
    return amount != null ? _formatRp(amount) : '';
  }

  String get paymentMethodLabel {
    switch (paymentMethod?.toLowerCase()) {
      case 'bank_transfer':
      case 'transfer':
        return 'Bank Transfer';
      case 'cash':
        return 'Cash';
      default:
        return paymentMethod ?? 'Cash';
    }
  }

  static String _formatRp(double amount) {
    final s = amount.toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'Rp $s';
  }
}

class BookingTreatment {
  final String id;
  final String name;
  final int? duration;
  final double? price;

  BookingTreatment({
    required this.id,
    required this.name,
    this.duration,
    this.price,
  });

  factory BookingTreatment.fromJson(Map<String, dynamic> json) {
    // treatment_snapshot is a JSONB column on booking_items
    final snapshot = json['treatment_snapshot'] as Map<String, dynamic>? ??
        json['treatments'] as Map<String, dynamic>? ??
        json;

    return BookingTreatment(
      id: json['id'] as String? ?? '',
      name: snapshot['treatment_name'] as String? ??
          snapshot['name'] as String? ??
          json['treatment_name'] as String? ??
          'Treatment',
      duration: (snapshot['duration_minutes'] as num?)?.toInt() ??
          (snapshot['duration'] as num?)?.toInt(),
      price: (snapshot['price'] as num?)?.toDouble(),
    );
  }

  String get durationText => duration != null ? '$duration min' : '';
  String get priceText => price != null ? Booking._formatRp(price!) : '';
}

class BookingAddon {
  final String id;
  final String name;
  final double? unitPrice;
  final int quantity;

  BookingAddon({
    required this.id,
    required this.name,
    this.unitPrice,
    this.quantity = 1,
  });

  factory BookingAddon.fromJson(Map<String, dynamic> json) {
    final snapshot = json['addon_snapshot'] as Map<String, dynamic>? ?? {};
    return BookingAddon(
      id: json['id'] as String? ?? '',
      name: snapshot['addon_name'] as String? ??
          snapshot['name'] as String? ??
          json['addon_name'] as String? ??
          'Add-on',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ??
          (snapshot['price'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  String get priceText => unitPrice != null ? Booking._formatRp(unitPrice!) : '';
}
