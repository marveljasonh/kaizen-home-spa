import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../booking/domain/entities/order_summary.dart';
import '../../../booking/presentation/providers/order_history_providers.dart';
import '../../../treatments/presentation/providers/treatments_providers.dart';
import '../../domain/entities/treatment_preview.dart';

const int _kPopularLimit = 4;

/// Top treatments for the home page — first entries of the platform catalog.
final popularTreatmentsProvider = FutureProvider<List<TreatmentPreview>>((
  ref,
) async {
  try {
    final treatments = await ref.watch(treatmentsProvider(null).future);
    return treatments
        .take(_kPopularLimit)
        .map(
          (t) => TreatmentPreview(
            id: t.id,
            name: t.name,
            category: t.categoryName,
            durationMinutes: t.displayDurationMinutes,
            price: t.displayPrice,
            rating: t.rating,
            reviewCount: t.reviewCount,
            imageUrl: t.imageUrl,
          ),
        )
        .toList();
  } catch (_) {
    return [];
  }
});

// ── Recent orders ─────────────────────────────────────────────────────────────

const int _kRecentOrdersLimit = 3;

/// The signed-in client's latest **completed** bookings (newest first, top 3).
/// Derived from [orderHistoryProvider], so it updates in realtime too.
final recentOrdersProvider = FutureProvider.autoDispose<List<OrderSummary>>((
  ref,
) async {
  final orders = await ref.watch(orderHistoryProvider.future);
  return orders.where((o) => o.isCompleted).take(_kRecentOrdersLimit).toList();
});
