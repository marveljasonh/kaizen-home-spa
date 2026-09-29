import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The signed-in identity: bearer token + ids from /auth/login|register.
/// Persisted in secure storage; [current] is loaded once at app start so the
/// router and ApiClient can read it synchronously.
class AuthSession {
  final String token;
  final String userId;
  final String customerId;
  final String name;
  final String phone;

  const AuthSession({
    required this.token,
    required this.userId,
    required this.customerId,
    required this.name,
    required this.phone,
  });

  static const _storage = FlutterSecureStorage();
  static const _key = 'kaizen_session_v1';

  static AuthSession? current;

  factory AuthSession.fromAuthResponse(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String,
      userId: json['userId'] as String,
      customerId: json['profileId'] as String,
      name: (json['name'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
    );
  }

  static Future<AuthSession?> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      current = AuthSession(
        token: m['token'] as String,
        userId: m['userId'] as String,
        customerId: m['customerId'] as String,
        name: (m['name'] as String?) ?? '',
        phone: (m['phone'] as String?) ?? '',
      );
    } catch (_) {
      current = null;
    }
    return current;
  }

  Future<void> save() async {
    current = this;
    await _storage.write(
      key: _key,
      value: jsonEncode({
        'token': token,
        'userId': userId,
        'customerId': customerId,
        'name': name,
        'phone': phone,
      }),
    );
  }

  static Future<void> clear() async {
    current = null;
    await _storage.delete(key: _key);
  }
}
