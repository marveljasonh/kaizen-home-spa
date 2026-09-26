import 'package:equatable/equatable.dart';

class Therapist extends Equatable {
  final String id;
  final String name;
  final String? bio;
  final String? avatarUrl;
  final double rating;
  final int reviewCount;
  final List<String> specialties;
  final int bookingCount;
  final String? status;
  final bool isAvailable;

  const Therapist({
    required this.id,
    required this.name,
    this.bio,
    this.avatarUrl,
    required this.rating,
    required this.reviewCount,
    this.specialties = const [],
    this.bookingCount = 0,
    this.status,
    this.isAvailable = true,
  });

  @override
  List<Object?> get props =>
      [id, name, bio, avatarUrl, rating, reviewCount, specialties, bookingCount, status, isAvailable];
}
