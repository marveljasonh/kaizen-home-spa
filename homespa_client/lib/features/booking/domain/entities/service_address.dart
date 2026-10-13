import 'package:equatable/equatable.dart';

class ServiceAddress extends Equatable {
  /// Platform address id when this came from the saved-address list;
  /// null for a fresh map pin (the booking call saves it first).
  final String? id;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String? notes;
  final String? city;

  const ServiceAddress({
    this.id,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.notes,
    this.city,
  });

  @override
  List<Object?> get props => [id, fullAddress, latitude, longitude, notes, city];
}
