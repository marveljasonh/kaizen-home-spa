import '../../domain/entities/treatment_duration.dart';

class TreatmentDurationModel extends TreatmentDuration {
  const TreatmentDurationModel({
    required super.id,
    required super.treatmentId,
    required super.durationMinutes,
    required super.price,
    super.isDefault,
  });

  factory TreatmentDurationModel.fromJson(Map<String, dynamic> json) =>
      TreatmentDurationModel(
        id: json['id'] as String,
        treatmentId: json['treatment_id'] as String,
        durationMinutes: json['duration_minutes'] as int,
        price: (json['price'] as num).toDouble(),
        isDefault: json['is_default'] as bool? ?? false,
      );
}
