import '../../domain/entities/promo_banner.dart';

class PromoBannerModel extends PromoBanner {
  const PromoBannerModel({
    required super.id,
    required super.title,
    super.subtitle,
    super.imageUrl,
  });

  factory PromoBannerModel.fromJson(Map<String, dynamic> json) =>
      PromoBannerModel(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String?,
        imageUrl: json['image_url'] as String?,
      );
}
