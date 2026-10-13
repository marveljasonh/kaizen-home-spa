import 'package:equatable/equatable.dart';

class Addon extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;

  /// "immediate" (bookable on the spot) or "advance_only" (needs preparation,
  /// so it must be ordered with the booking, not added during the session).
  final String kind;
  final int durationMinutes;
  final bool isActive;

  const Addon({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.kind = 'immediate',
    this.durationMinutes = 0,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    kind,
    durationMinutes,
    isActive,
  ];
}
