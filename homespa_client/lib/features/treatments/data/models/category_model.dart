import '../../domain/entities/treatment_category.dart';

class CategoryModel extends TreatmentCategory {
  const CategoryModel({
    required super.id,
    required super.name,
    super.iconUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        iconUrl: json['icon_url'] as String?,
      );
}
