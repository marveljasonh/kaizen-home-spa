import 'package:equatable/equatable.dart';

class PromoBanner extends Equatable {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;

  const PromoBanner({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, title, subtitle, imageUrl];
}
