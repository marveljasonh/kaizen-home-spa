import '../../core/utils/timezone_helper.dart';

class RiderAssignment {
  final String id;
  final String riderId;
  final String bookingId;
  final String status;
  final DateTime assignedAt;
  final String? address;
  final DateTime? scheduledAt;
  final String? notes;
  final String? clientName;
  final String? therapistName;
  final String? therapistPhone;
  final String? bookingStatus;

  RiderAssignment({
    required this.id,
    required this.riderId,
    required this.bookingId,
    required this.status,
    required this.assignedAt,
    this.address,
    this.scheduledAt,
    this.notes,
    this.clientName,
    this.therapistName,
    this.therapistPhone,
    this.bookingStatus,
  });

  factory RiderAssignment.fromJson(Map<String, dynamic> json) {
    final booking = json['bookings'] as Map<String, dynamic>? ?? {};
    final clientProfile = booking['profiles'] as Map<String, dynamic>? ?? {};
    final therapistProfileData =
        booking['therapist_profiles'] as Map<String, dynamic>?;
    final therapistProfilesMap =
        therapistProfileData?['profiles'] as Map<String, dynamic>?;

    return RiderAssignment(
      id: json['id'] as String,
      riderId: json['rider_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? booking['id'] as String? ?? '',
      status: json['status'] as String? ?? 'assigned',
      assignedAt: WIB.toWIB(DateTime.parse(json['assigned_at'] as String)),
      address: _parseAddress(booking['address_snapshot']),
      scheduledAt: booking['scheduled_at'] != null
          ? WIB.toWIB(DateTime.parse(booking['scheduled_at'] as String))
          : null,
      notes: booking['notes'] as String? ?? json['notes'] as String?,
      clientName: clientProfile['full_name'] as String?,
      therapistName: json['__therapist_name'] as String? ??
          therapistProfilesMap?['full_name'] as String?,
      therapistPhone: json['__therapist_phone'] as String? ??
          therapistProfilesMap?['phone'] as String?,
      bookingStatus: booking['status'] as String?,
    );
  }

  static String? _parseAddress(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      return raw['address_line'] as String? ??
          raw['full_address'] as String? ??
          raw['address'] as String?;
    }
    if (raw is String && raw.isNotEmpty) return raw;
    return null;
  }

  // Rider is locked (cannot receive new assignments) when on_the_way
  bool get isLocked => status == 'on_the_way';
  bool get isCompleted => status == 'completed';
  bool get hasAction => status != 'completed';

  String get nextStatus {
    switch (status) {
      case 'assigned':
        return 'on_the_way';
      case 'on_the_way':
        return 'arrived';
      case 'arrived':
        return 'completed';
      default:
        return status;
    }
  }

  String get actionLabel {
    switch (status) {
      case 'assigned':
        return 'Start Journey';
      case 'on_the_way':
        return "I've Arrived";
      case 'arrived':
        return 'Mark Completed';
      default:
        return '';
    }
  }

  String get shortId => '#${bookingId.substring(0, 8).toUpperCase()}';
}
