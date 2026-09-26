import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? phone;

  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.phone,
  });

  @override
  List<Object?> get props => [id, email, name, avatarUrl, phone];
}
