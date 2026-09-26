import '../../domain/entities/therapist.dart';

class TherapistModel extends Therapist {
  const TherapistModel({
    required super.id,
    required super.name,
    super.bio,
    super.avatarUrl,
    required super.rating,
    required super.reviewCount,
    super.specialties,
    super.bookingCount,
    super.status,
    super.isAvailable,
  });

  factory TherapistModel.fromJson(Map<String, dynamic> json) {
    final specs = json['specialties'] as List<dynamic>? ?? [];
    return TherapistModel(
      id: json['id'] as String,
      // preferred_therapist queries return full_name from profiles; fall back to name for legacy use
      name: json['full_name'] as String? ?? json['name'] as String? ?? 'Therapist',
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      rating: (json['rating_avg'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      specialties: specs.map((e) => e.toString()).toList(),
      bookingCount: json['booking_count'] as int? ?? 0,
      status: json['status'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }
}
