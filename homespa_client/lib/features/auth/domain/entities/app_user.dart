import 'package:equatable/equatable.dart';

import '../../../../core/api/auth_session.dart';

class AppUser extends Equatable {
  final String id; // users.id on the platform
  final String customerId; // customers.id — key for /customers/{id}/* calls
  final String name;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String? gender;
  final int loyaltyPoints;
  final String? referralCode;

  const AppUser({
    required this.id,
    required this.customerId,
    required this.name,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.gender,
    this.loyaltyPoints = 0,
    this.referralCode,
  });

  /// Minimal identity from the cached session, before the profile loads.
  factory AppUser.fromSession(AuthSession session) => AppUser(
    id: session.userId,
    customerId: session.customerId,
    name: session.name,
    phone: session.phone,
  );

  /// Full identity from GET /customers/{id}/profile.
  factory AppUser.fromProfileJson(Map<String, dynamic> profile) => AppUser(
    id: profile['userId'] as String,
    customerId: profile['customerId'] as String,
    name: (profile['name'] as String?) ?? '',
    phone: (profile['phone'] as String?) ?? '',
    email: profile['email'] as String?,
    avatarUrl: profile['avatarUrl'] as String?,
    gender: profile['gender'] as String?,
    loyaltyPoints: (profile['loyaltyPoints'] as num?)?.toInt() ?? 0,
    referralCode: profile['referralCode'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    customerId,
    name,
    phone,
    email,
    avatarUrl,
    gender,
    loyaltyPoints,
    referralCode,
  ];
}
