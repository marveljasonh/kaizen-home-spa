import 'package:equatable/equatable.dart';

class ServiceAddress extends Equatable {
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String? notes;

  const ServiceAddress({
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.notes,
  });

  @override
  List<Object?> get props => [fullAddress, latitude, longitude, notes];
}
