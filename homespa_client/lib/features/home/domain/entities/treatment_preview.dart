import 'package:equatable/equatable.dart';

class TreatmentPreview extends Equatable {
  final String id;
  final String name;
  final String category;
  final int durationMinutes;
  final double price;
  final double rating;
  final int reviewCount;
  final String? imageUrl;

  const TreatmentPreview({
    required this.id,
    required this.name,
    required this.category,
    required this.durationMinutes,
    required this.price,
    required this.rating,
    required this.reviewCount,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        durationMinutes,
        price,
        rating,
        reviewCount,
        imageUrl,
      ];
}
