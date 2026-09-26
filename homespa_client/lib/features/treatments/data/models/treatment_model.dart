import '../../domain/entities/treatment.dart';
import 'treatment_duration_model.dart';

class TreatmentModel extends Treatment {
  const TreatmentModel({
    required super.id,
    required super.name,
    required super.description,
    required super.categoryId,
    required super.categoryName,
    super.imageUrl,
    required super.basePrice,
    required super.rating,
    required super.reviewCount,
    super.isAvailable,
    super.durations,
  });

  factory TreatmentModel.fromFlat({
    required Map<String, dynamic> row,
    required String categoryName,
    required List<Map<String, dynamic>> durationsData,
  }) {
    return TreatmentModel(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String? ?? '',
      categoryId: row['category_id'] as String,
      categoryName: categoryName,
      imageUrl: row['image_url'] as String?,
      basePrice: (row['base_price'] as num?)?.toDouble() ?? 0.0,
      rating: (row['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: row['review_count'] as int? ?? 0,
      isAvailable: row['is_active'] as bool? ?? true,
      durations: durationsData
          .map((d) => TreatmentDurationModel.fromJson(d))
          .toList(),
    );
  }
}
