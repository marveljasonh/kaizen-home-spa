import 'package:equatable/equatable.dart';

class TreatmentCategory extends Equatable {
  final String id;
  final String name;
  final String? iconUrl;

  const TreatmentCategory({required this.id, required this.name, this.iconUrl});

  @override
  List<Object?> get props => [id, name, iconUrl];
}
