import 'package:equatable/equatable.dart';

import 'treatment_duration.dart';

class Treatment extends Equatable {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String categoryName;
  final String? imageUrl;
  final double basePrice;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final List<TreatmentDuration> durations;

  const Treatment({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    this.imageUrl,
    required this.basePrice,
    required this.rating,
    required this.reviewCount,
    this.isAvailable = true,
    this.durations = const [],
  });

  TreatmentDuration? get defaultDuration {
    if (durations.isEmpty) return null;
    try {
      return durations.firstWhere((d) => d.isDefault);
    } catch (_) {
      return durations.first;
    }
  }

  double get displayPrice => defaultDuration?.price ?? basePrice;

  /// Lowest price across durations ("Starting from …"), else the base price.
  double get startingPrice => durations.isEmpty
      ? basePrice
      : durations.map((d) => d.price).reduce((a, b) => a < b ? a : b);

  int get displayDurationMinutes => defaultDuration?.durationMinutes ?? 60;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    categoryId,
    categoryName,
    imageUrl,
    basePrice,
    rating,
    reviewCount,
    isAvailable,
    durations,
  ];
}
