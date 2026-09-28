import 'package:equatable/equatable.dart';

/// One line of a past booking, from `booking_items` + its `treatment_snapshot`.
class OrderSummaryItem extends Equatable {
  final String? treatmentDurationId;
  final String? treatmentId;
  final String treatmentName;
  final int? durationMinutes;
  final int quantity;

  const OrderSummaryItem({
    required this.treatmentDurationId,
    required this.treatmentId,
    required this.treatmentName,
    required this.durationMinutes,
    required this.quantity,
  });

  @override
  List<Object?> get props => [
    treatmentDurationId,
    treatmentId,
    treatmentName,
    durationMinutes,
    quantity,
  ];
}

/// A booking summarised for order cards (Home "Recent Orders" and the
/// Order History page).
class OrderSummary extends Equatable {
  final String id;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final String status;
  final List<OrderSummaryItem> items;
  final String address;
  final double total;

  const OrderSummary({
    required this.id,
    required this.scheduledAt,
    required this.createdAt,
    required this.status,
    required this.items,
    required this.address,
    required this.total,
  });

  static const upcomingStatuses = {
    'pending',
    'accepted',
    'confirmed',
    'therapist_assigned',
    'rider_assigned',
    'on_the_way',
    'arrived',
    'in_progress',
  };

  bool get isUpcoming => upcomingStatuses.contains(status);
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  /// Past orders can be booked again; upcoming ones are still in progress.
  bool get canReorder => isCompleted || isCancelled;

  /// First 8 characters of the booking id, upper-cased (e.g. "C49832B3").
  String get code => (id.length >= 8 ? id.substring(0, 8) : id).toUpperCase();

  /// First treatment's name.
  String get firstTreatmentName =>
      items.isEmpty ? 'Kaizen Spa Service' : items.first.treatmentName;

  /// How many treatments beyond the first (0 for a single-treatment order).
  int get additionalCount => items.isEmpty ? 0 : items.length - 1;

  /// "Full Body Massage" or "Full Body Massage +1".
  String get title => additionalCount > 0
      ? '$firstTreatmentName +$additionalCount'
      : firstTreatmentName;

  String get statusLabel => switch (status) {
    'pending' => 'Pending',
    'accepted' => 'Accepted',
    'confirmed' => 'Confirmed',
    'therapist_assigned' => 'Therapist Assigned',
    'rider_assigned' => 'Rider Assigned',
    'on_the_way' => 'On the Way',
    'arrived' => 'Arrived',
    'in_progress' => 'In Progress',
    'completed' => 'Completed',
    'cancelled' => 'Cancelled',
    _ =>
      status.isEmpty
          ? ''
          : status[0].toUpperCase() + status.substring(1).replaceAll('_', ' '),
  };

  @override
  List<Object?> get props => [
    id,
    scheduledAt,
    createdAt,
    status,
    items,
    address,
    total,
  ];
}
