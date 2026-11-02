import 'package:equatable/equatable.dart';

/// One bookable start time from GET /availability — the same slot engine the
/// WhatsApp bot uses, so a listed slot is genuinely free (the database has an
/// exclusion constraint on therapist time ranges).
class AvailabilitySlot extends Equatable {
  final DateTime startUtc;
  final String therapistId;
  final String therapistName;
  final String label;

  const AvailabilitySlot({
    required this.startUtc,
    required this.therapistId,
    required this.therapistName,
    required this.label,
  });

  @override
  List<Object?> get props => [startUtc, therapistId];
}
