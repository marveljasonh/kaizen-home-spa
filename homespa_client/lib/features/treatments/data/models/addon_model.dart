import '../../domain/entities/addon.dart';

class AddonModel extends Addon {
  const AddonModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    super.isActive,
  });

  factory AddonModel.fromJson(Map<String, dynamic> json) => AddonModel(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    isActive: json['is_active'] as bool? ?? true,
  );
}
