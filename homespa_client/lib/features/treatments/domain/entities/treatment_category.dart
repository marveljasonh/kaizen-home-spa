import 'package:equatable/equatable.dart';

class TreatmentCategory extends Equatable {
  final String id;
  final String name;
  final String? iconUrl;

  /// Dashboard-editable hero title/description for the category page; the
  /// app falls back to [name] and its built-in copy when unset.
  final String? header;
  final String? subheader;

  const TreatmentCategory({
    required this.id,
    required this.name,
    this.iconUrl,
    this.header,
    this.subheader,
  });

  @override
  List<Object?> get props => [id, name, iconUrl, header, subheader];
}
