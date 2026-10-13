import '../../../../core/api/api_client.dart';
import '../../../../core/api/auth_session.dart';
import '../../domain/entities/app_user.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthSession> signIn({required String phone, required String password});

  Future<AuthSession> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
  });

  Future<AppUser> fetchProfile(String customerId);

  Future<void> updateProfile(
    String customerId, {
    String? name,
    String? email,
    String? gender,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _api;
  const AuthRemoteDataSourceImpl(this._api);

  @override
  Future<AuthSession> signIn({
    required String phone,
    required String password,
  }) async {
    final json =
        await _api.post(
              '/auth/login',
              body: {'phone': phone, 'password': password},
            )
            as Map<String, dynamic>;
    return AuthSession.fromAuthResponse(json);
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final json =
        await _api.post(
              '/auth/register',
              body: {
                'name': name,
                'phone': phone,
                'email': email,
                'password': password,
                if (referralCode != null && referralCode.isNotEmpty)
                  'referralCode': referralCode,
              },
            )
            as Map<String, dynamic>;
    return AuthSession.fromAuthResponse(json);
  }

  @override
  Future<AppUser> fetchProfile(String customerId) async {
    final json =
        await _api.get('/customers/$customerId/profile')
            as Map<String, dynamic>;
    return AppUser.fromProfileJson(json['profile'] as Map<String, dynamic>);
  }

  @override
  Future<void> updateProfile(
    String customerId, {
    String? name,
    String? email,
    String? gender,
  }) async {
    await _api.patch(
      '/customers/$customerId/profile',
      body: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (gender != null) 'gender': gender,
      },
    );
  }
}
