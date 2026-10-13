import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../treatments/presentation/providers/treatments_providers.dart';
import '../../domain/entities/order_summary.dart';
import 'booking_cart.dart';
import 'booking_providers.dart';

/// Every booking for the signed-in customer as [OrderSummary]s, newest first,
/// from GET /customers/{id}/bookings. Pages poll/refresh by invalidating this
/// provider (pull-to-refresh) — the booking detail page has its own 15 s poll.
final orderHistoryProvider = FutureProvider.autoDispose<List<OrderSummary>>((
  ref,
) async {
  ref.watch(authNotifierProvider); // re-run on sign-in / sign-out
  final List<OrderSummary> summaries;
  try {
    summaries = await ref.read(bookingDataSourceProvider).getOrderSummaries();
  } catch (_) {
    return [];
  }

  // Resolve each item's treatment (service) id from the catalog — the API
  // returns the package id; the category filter matches on treatment id.
  try {
    final treatments = await ref.watch(treatmentsProvider(null).future);
    final serviceByPackage = {
      for (final t in treatments)
        for (final d in t.durations) d.id: t.id,
    };
    return [
      for (final s in summaries)
        OrderSummary(
          id: s.id,
          scheduledAt: s.scheduledAt,
          createdAt: s.createdAt,
          status: s.status,
          address: s.address,
          total: s.total,
          items: [
            for (final i in s.items)
              OrderSummaryItem(
                treatmentDurationId: i.treatmentDurationId,
                treatmentId: serviceByPackage[i.treatmentDurationId],
                treatmentName: i.treatmentName,
                durationMinutes: i.durationMinutes,
                quantity: i.quantity,
              ),
          ],
        ),
    ];
  } catch (_) {
    return summaries;
  }
});

/// Puts the same treatment (and duration) from [order] back in the cart.
/// Returns how many cart lines were added; treatments that no longer exist
/// are skipped. Add-ons from the original booking are not re-added.
///
/// The order's `treatmentDurationId` is the platform package id, so the
/// matching treatment is the one whose durations contain it.
Future<int> reorderIntoCart(WidgetRef ref, OrderSummary order) async {
  final repo = ref.read(treatmentsRepositoryProvider);
  final cart = ref.read(bookingCartProvider.notifier);

  final treatments = (await repo.getTreatments()).fold(
    (_) => null,
    (list) => list,
  );
  if (treatments == null) return 0;

  var added = 0;
  for (final item in order.items) {
    final packageId = item.treatmentDurationId;
    final treatment = treatments
        .where(
          (t) =>
              (packageId != null &&
                  t.durations.any((d) => d.id == packageId)) ||
              t.name == item.treatmentName,
        )
        .firstOrNull;
    if (treatment == null || !treatment.isAvailable) continue;

    final duration =
        treatment.durations.where((d) => d.id == packageId).firstOrNull ??
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
/// Resolved from the cached catalog.
final categoryTreatmentIdsProvider = FutureProvider.autoDispose
    .family<Set<String>, String>((ref, categoryKey) async {
      if (categoryKey.isEmpty) return const {};
      final categoryIds = categoryKey.split(',').toSet();
      final treatments = await ref.watch(treatmentsProvider(null).future);
      return treatments
          .where((t) => categoryIds.contains(t.categoryId))
          .map((t) => t.id)
          .toSet();
    });

String categoryKeyOf(Set<String> categoryIds) =>
    (categoryIds.toList()..sort()).join(',');
