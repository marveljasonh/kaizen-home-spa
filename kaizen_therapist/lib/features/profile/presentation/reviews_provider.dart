import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/timezone_helper.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/supabase_provider.dart';

class TherapistReview {
  final String id;
  final String clientId;
  final String clientName;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  const TherapistReview({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory TherapistReview.fromRow(
      Map<String, dynamic> row, Map<String, Map<String, dynamic>> profilesById) {
    final cid = row['client_id'] as String? ?? '';
    final profile = profilesById[cid];
    final clientName = profile?['full_name'] as String? ??
        (cid.length >= 6 ? 'Customer ${cid.substring(0, 6).toUpperCase()}' : 'Customer');
    return TherapistReview(
      id: row['id'] as String,
      clientId: cid,
      clientName: clientName,
      rating: (row['rating'] as num?)?.toDouble() ?? 0.0,
      comment: row['comment'] as String? ?? row['review_text'] as String?,
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ?? WIB.now(),
    );
  }
}

final reviewsProvider =
    FutureProvider.autoDispose<List<TherapistReview>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.id.isEmpty) return [];

  final client = ref.watch(supabaseClientProvider);

  final rows = await client
      .from('therapist_reviews')
      .select('*')
      .eq('therapist_id', user.id)
      .order('created_at', ascending: false)
      .limit(5);

  final clientIds = rows
      .map((r) => r['client_id'] as String?)
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  final profilesById = <String, Map<String, dynamic>>{};
  if (clientIds.isNotEmpty) {
    try {
      final profiles = await client
          .from('profiles')
          .select('id, full_name')
          .filter('id', 'in', '(${clientIds.join(',')})');
      for (final p in profiles) {
        profilesById[p['id'] as String] = p;
      }
    } catch (_) {}
  }

  return rows
      .map((r) => TherapistReview.fromRow(r, profilesById))
      .toList();
});

final reviewsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.id.isEmpty) return 0;
  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('therapist_reviews')
      .select('id')
      .eq('therapist_id', user.id);
  return (rows as List).length;
});

final allReviewsProvider =
    FutureProvider.autoDispose<List<TherapistReview>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.id.isEmpty) return [];

  final client = ref.watch(supabaseClientProvider);

  final rows = await client
      .from('therapist_reviews')
      .select('*')
      .eq('therapist_id', user.id)
      .order('created_at', ascending: false);

  final clientIds = rows
      .map((r) => r['client_id'] as String?)
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  final profilesById = <String, Map<String, dynamic>>{};
  if (clientIds.isNotEmpty) {
    try {
      final profiles = await client
          .from('profiles')
          .select('id, full_name')
          .filter('id', 'in', '(${clientIds.join(',')})');
      for (final p in profiles) {
        profilesById[p['id'] as String] = p;
      }
    } catch (_) {}
  }

  return rows.map((r) => TherapistReview.fromRow(r, profilesById)).toList();
});
