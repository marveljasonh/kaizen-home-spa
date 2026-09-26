import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/saved_address.dart';

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => AddressRepository(Supabase.instance.client),
);

final savedAddressesProvider = FutureProvider<List<SavedAddress>>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Future.value([]);
  return ref.watch(addressRepositoryProvider).getAddresses(userId);
});

class AddressRepository {
  final SupabaseClient _client;
  const AddressRepository(this._client);

  Future<List<SavedAddress>> getAddresses(String userId) async {
    final data = await _client
        .from('saved_addresses')
        .select()
        .eq('client_id', userId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    return (data as List).map((e) => SavedAddress.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addAddress({
    required String userId,
    required String label,
    required String fullAddress,
    String? notes,
    bool isDefault = false,
  }) async {
    if (isDefault) {
      await _client
          .from('saved_addresses')
          .update({'is_default': false})
          .eq('client_id', userId);
    }
    await _client.from('saved_addresses').insert({
      'client_id': userId,
      'label': label,
      'full_address': fullAddress,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'is_default': isDefault,
    });
  }

  Future<void> deleteAddress(String id) async {
    await _client.from('saved_addresses').delete().eq('id', id);
  }

  Future<void> setDefault(String id, String userId) async {
    await _client
        .from('saved_addresses')
        .update({'is_default': false})
        .eq('client_id', userId);
    await _client
        .from('saved_addresses')
        .update({'is_default': true})
        .eq('id', id);
  }
}
