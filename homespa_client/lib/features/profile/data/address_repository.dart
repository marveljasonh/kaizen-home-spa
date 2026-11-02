import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_session.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../domain/entities/saved_address.dart';

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => AddressRepository(apiClient),
);

final savedAddressesProvider = FutureProvider<List<SavedAddress>>((ref) {
  ref.watch(authNotifierProvider); // re-run on sign-in / sign-out
  if (AuthSession.current == null) return Future.value([]);
  return ref.watch(addressRepositoryProvider).getAddresses();
});

/// Saved addresses on the platform: GET/POST /customers/{id}/addresses,
/// PATCH/DELETE /customers/{id}/addresses/{addressId}.
class AddressRepository {
  final ApiClient _api;
  const AddressRepository(this._api);

  String get _base {
    final session = AuthSession.current;
    if (session == null) throw const ApiException('Not signed in', 401);
    return '/customers/${session.customerId}/addresses';
  }

  /// The API wants a city; take the tail of a comma-separated address.
  static String _cityOf(String fullAddress) {
    final parts = fullAddress.split(',');
    final tail = parts.length > 1 ? parts.last.trim() : '';
    return tail.isNotEmpty ? tail : '-';
  }

  Future<List<SavedAddress>> getAddresses() async {
    final json = await _api.get(_base) as Map<String, dynamic>;
    return (json['addresses'] as List)
        .cast<Map<String, dynamic>>()
        .map(SavedAddress.fromJson)
        .toList();
  }

  Future<void> addAddress({
    required String label,
    required String fullAddress,
    String? notes,
    bool isDefault = false,
    double? lat,
    double? lng,
  }) async {
    await _api.post(
      _base,
      body: {
        'label': label,
        'line': fullAddress,
        'city': _cityOf(fullAddress),
        // Jakarta fallback — dispatch needs some coordinate to route from.
        'lat': lat ?? -6.2088,
        'lng': lng ?? 106.8456,
        if (notes != null && notes.isNotEmpty) 'entranceNotes': notes,
        if (isDefault) 'isDefault': true,
      },
    );
  }

  Future<void> updateAddress({
    required String id,
    required String label,
    required String fullAddress,
    String? notes,
    bool isDefault = false,
    double? lat,
    double? lng,
  }) async {
    await _api.patch(
      '$_base/$id',
      body: {
        'label': label,
        'line': fullAddress,
        'city': _cityOf(fullAddress),
        'entranceNotes': notes,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'isDefault': isDefault,
      },
    );
  }

  Future<void> deleteAddress(String id) async {
    await _api.delete('$_base/$id');
  }

  Future<void> setDefault(String id) async {
    await _api.patch('$_base/$id', body: {'isDefault': true});
  }
}
