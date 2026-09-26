import 'package:equatable/equatable.dart';

class Addon extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool isActive;

  const Addon({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, description, price, isActive];
}
