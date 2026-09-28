import 'package:equatable/equatable.dart';

class TreatmentDuration extends Equatable {
  final String id;
  final String treatmentId;
  final int durationMinutes;
  final double price;
  final bool isDefault;

  const TreatmentDuration({
    required this.id,
    required this.treatmentId,
    required this.durationMinutes,
    required this.price,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [
    id,
    treatmentId,
    durationMinutes,
    price,
    isDefault,
  ];
}
