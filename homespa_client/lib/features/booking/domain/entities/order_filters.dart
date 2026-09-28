import 'package:equatable/equatable.dart';

/// History page filters (Filter sheet): a `scheduled_at` date range and a set
/// of treatment categories. Empty filters match every order.
class OrderFilters extends Equatable {
  /// Inclusive, local calendar days.
  final DateTime? from;
  final DateTime? to;
  final Set<String> categoryIds;

  const OrderFilters({this.from, this.to, this.categoryIds = const {}});

  static const none = OrderFilters();

  bool get isEmpty => from == null && to == null && categoryIds.isEmpty;

  /// Shown as the Filter button's badge.
  int get activeCount =>
      (from != null || to != null ? 1 : 0) + (categoryIds.isNotEmpty ? 1 : 0);

  bool matchesDate(DateTime scheduledAt) {
    final local = scheduledAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    if (from != null && day.isBefore(from!)) return false;
    if (to != null && day.isAfter(to!)) return false;
    return true;
  }

  @override
  List<Object?> get props => [from, to, categoryIds.toList()..sort()];
}
