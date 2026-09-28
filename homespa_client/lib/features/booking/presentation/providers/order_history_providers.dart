import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../treatments/domain/entities/treatment.dart';
import '../../../treatments/presentation/providers/treatments_providers.dart';
import '../../domain/entities/order_summary.dart';
import 'booking_cart.dart';
import 'booking_providers.dart';

/// `inFilter` batch size — keeps request URLs short for long histories.
const int _kBatch = 50;

/// Every booking for the signed-in client as [OrderSummary]s, newest first
/// (by `created_at`). Built on the realtime bookings stream, so status changes
/// and new bookings show up without a refresh.
///
/// Flat queries only (no PostgREST embeds, which 400 on this project):
/// bookings (stream) → booking_items → treatment_durations, joined in Dart.
final orderHistoryProvider = FutureProvider.autoDispose<List<OrderSummary>>((
  ref,
) async {
  ref.watch(authNotifierProvider); // re-run on sign-in / sign-out
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final rows = await ref.watch(bookingHistoryStreamProvider(userId).future);
  if (rows.isEmpty) return [];

  DateTime created(Map<String, dynamic> r) =>
      DateTime.tryParse('${r['created_at']}') ??
      DateTime.tryParse('${r['scheduled_at']}') ??
      DateTime.fromMillisecondsSinceEpoch(0);

  final bookings = [...rows]..sort((a, b) => created(b).compareTo(created(a)));
  final bookingIds = bookings.map((b) => b['id'] as String).toList();

  final itemRows = <Map<String, dynamic>>[];
  for (var i = 0; i < bookingIds.length; i += _kBatch) {
    itemRows.addAll(
      await client
          .from('booking_items')
          .select(
            'booking_id, treatment_duration_id, treatment_snapshot, quantity',
          )
          .inFilter('booking_id', bookingIds.skip(i).take(_kBatch).toList()),
    );
  }

  final durationIds = itemRows
      .map((i) => i['treatment_duration_id'] as String?)
      .whereType<String>()
      .toSet()
      .toList();
  final treatmentIdByDuration = <String, String>{};
  for (var i = 0; i < durationIds.length; i += _kBatch) {
    final durationRows = await client
        .from('treatment_durations')
        .select('id, treatment_id')
        .inFilter('id', durationIds.skip(i).take(_kBatch).toList());
    for (final d in durationRows) {
      treatmentIdByDuration[d['id'] as String] = d['treatment_id'] as String;
    }
  }

  final itemsByBooking = <String, List<OrderSummaryItem>>{};
  for (final i in itemRows) {
    final snapshot = (i['treatment_snapshot'] as Map?) ?? const {};
    final durationId = i['treatment_duration_id'] as String?;
    itemsByBooking
        .putIfAbsent(i['booking_id'] as String, () => [])
        .add(
          OrderSummaryItem(
            treatmentDurationId: durationId,
            treatmentId: treatmentIdByDuration[durationId],
            treatmentName:
                (snapshot['treatment_name'] as String?) ?? 'Kaizen Spa Service',
            durationMinutes: (snapshot['duration_minutes'] as num?)?.toInt(),
            quantity: (i['quantity'] as num?)?.toInt() ?? 1,
          ),
        );
  }

  return bookings.map((b) {
    return OrderSummary(
      id: b['id'] as String,
      scheduledAt: DateTime.tryParse('${b['scheduled_at']}') ?? created(b),
      createdAt: created(b),
      status: (b['status'] as String?) ?? '',
      items: itemsByBooking[b['id']] ?? const [],
      address: (b['address_snapshot'] as String?) ?? '—',
      total: (b['total_amount'] as num?)?.toDouble() ?? 0,
    );
  }).toList();
});

/// Puts the same treatments (and durations) from [order] back in the cart.
/// Returns how many cart lines were added; treatments that no longer exist
/// are skipped. Add-ons from the original booking are not re-added.
Future<int> reorderIntoCart(WidgetRef ref, OrderSummary order) async {
  final repo = ref.read(treatmentsRepositoryProvider);
  final cart = ref.read(bookingCartProvider.notifier);
  final cache = <String, Treatment?>{};
  var added = 0;

  for (final item in order.items) {
    final treatmentId = item.treatmentId;
    if (treatmentId == null) continue;
    final treatment = cache.containsKey(treatmentId)
        ? cache[treatmentId]
        : cache[treatmentId] = (await repo.getTreatmentDetail(
            treatmentId,
          )).fold((_) => null, (t) => t);
    if (treatment == null || !treatment.isAvailable) continue;

    final duration =
        treatment.durations
            .where((d) => d.id == item.treatmentDurationId)
            .firstOrNull ??
        treatment.durations
            .where((d) => d.durationMinutes == item.durationMinutes)
            .firstOrNull ??
        treatment.defaultDuration;
    for (var q = 0; q < item.quantity; q++) {
      cart.addItem(treatment, duration);
      added++;
    }
  }
  return added;
}

/// Treatment ids in the given categories (Filter sheet), keyed by the
/// category ids sorted and comma-joined so equal selections share a cache.
/// Flat query on `treatments`; orders are matched through
/// booking_items → treatment_durations → treatment_id in Dart.
final categoryTreatmentIdsProvider = FutureProvider.autoDispose
    .family<Set<String>, String>((ref, categoryKey) async {
      if (categoryKey.isEmpty) return const {};
      final rows = await Supabase.instance.client
          .from('treatments')
          .select('id')
          .inFilter('category_id', categoryKey.split(','));
      return rows.map((r) => r['id'] as String).toSet();
    });

String categoryKeyOf(Set<String> categoryIds) =>
    (categoryIds.toList()..sort()).join(',');
