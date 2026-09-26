class TherapistProfile {
  final String id;
  final String userId;
  final String name;
  final String email;
  final bool isAvailable;
  final String? bio;
  final List<String> specialties;
  final double rating;
  final int totalReviews;

  TherapistProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.isAvailable,
    this.bio,
    required this.specialties,
    required this.rating,
    required this.totalReviews,
  });

  factory TherapistProfile.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? {};

    List<String> specs = [];
    final rawSpecs = json['specialties'];
    if (rawSpecs is List) {
      specs = rawSpecs.map((e) => e.toString()).toList();
    } else if (rawSpecs is String && rawSpecs.isNotEmpty) {
      specs = rawSpecs.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    return TherapistProfile(
      id: json['id'] as String,
      userId: json['profile_id'] as String? ?? json['user_id'] as String? ?? '',
      name: profile['full_name'] as String? ?? profile['name'] as String? ?? json['name'] as String? ?? 'Therapist',
      email: profile['email'] as String? ?? json['email'] as String? ?? '',
      isAvailable: json['is_available'] as bool? ?? false,
      bio: json['bio'] as String?,
      specialties: specs,
      rating: (json['rating_avg'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
    );
  }

  TherapistProfile copyWith({
    bool? isAvailable,
    String? bio,
    List<String>? specialties,
  }) {
    return TherapistProfile(
      id: id,
      userId: userId,
      name: name,
      email: email,
      isAvailable: isAvailable ?? this.isAvailable,
      bio: bio ?? this.bio,
      specialties: specialties ?? this.specialties,
      rating: rating,
      totalReviews: totalReviews,
    );
  }

  String get displayRating => rating.toStringAsFixed(1);

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'T';
  }
}
