import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../treatments/domain/entities/addon.dart';
import '../../../treatments/domain/entities/treatment.dart';
import '../../../treatments/domain/entities/treatment_duration.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/service_address.dart';
import '../../domain/entities/therapist.dart';
import '../../domain/entities/voucher.dart';

// ── Add-on selection ──────────────────────────────────────────────────────────

class AddonSelection {
  final Addon addon;
  final int quantity;

  const AddonSelection({required this.addon, required this.quantity});

  double get subtotal => addon.price * quantity;
}

// ── Cart item ─────────────────────────────────────────────────────────────────

class CartItem {
  final Treatment treatment;
  final TreatmentDuration? selectedDuration;
  final List<AddonSelection> addons;

  const CartItem({
    required this.treatment,
    this.selectedDuration,
    this.addons = const [],
  });

  double get basePrice => selectedDuration?.price ?? treatment.displayPrice;
  double get addonsTotal => addons.fold(0.0, (sum, a) => sum + a.subtotal);
  double get price => basePrice + addonsTotal;

  int get durationMinutes =>
      selectedDuration?.durationMinutes ?? treatment.displayDurationMinutes;

  CartItem withDuration(TreatmentDuration duration) => CartItem(
    treatment: treatment,
    selectedDuration: duration,
    addons: addons,
  );
}

// ── State ─────────────────────────────────────────────────────────────────────

class BookingCart {
  final List<CartItem> items;
  final Therapist? therapist;

  /// Chosen start time in UTC. Picked in WIB on the Schedule page.
  final DateTime? scheduledAt;
  final ServiceAddress? address;
  final Voucher? voucher;
  final PaymentMethod? paymentMethod;
  final bool isLoading;
  final String? error;
  final String? freeRewardId;
  final String? freeRewardTitle;
  final String? freeRewardTreatmentId;
  final int? freeRewardDurationMinutes;
  final double? rewardDiscount;
  final String? rewardDiscountType; // 'flat' or 'percentage'
  final String? rewardRedemptionId; // redemption ID for discount rewards

  const BookingCart({
    this.items = const [],
    this.therapist,
    this.scheduledAt,
    this.address,
    this.voucher,
    this.paymentMethod,
    this.isLoading = false,
    this.error,
    this.freeRewardId,
    this.freeRewardTitle,
    this.freeRewardTreatmentId,
    this.freeRewardDurationMinutes,
    this.rewardDiscount,
    this.rewardDiscountType,
    this.rewardRedemptionId,
  });

  int get itemCount => items.length;

  // Backwards-compat accessors used by review/payment pages
  Treatment? get treatment => items.isNotEmpty ? items.first.treatment : null;
  TreatmentDuration? get selectedDuration =>
      items.isNotEmpty ? items.first.selectedDuration : null;

  bool get isFree => freeRewardId != null;

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.price);

  double get discountAmount {
    double total = 0;
    if (voucher != null) {
      if (voucher!.discountType == DiscountType.percentage) {
        total += subtotal * (voucher!.discountValue / 100);
      } else {
        total += min(voucher!.discountValue, subtotal);
      }
    }
    if (rewardDiscount != null && rewardDiscountType != null) {
      if (rewardDiscountType == 'percentage') {
        total += subtotal * (rewardDiscount! / 100);
      } else {
        total += rewardDiscount!;
      }
    }
    return total;
  }

  // Free reward lives outside `items` — never added to the items list.
  // Total = sum of all item prices minus discounts. No factors.
  double get total => (subtotal - discountAmount).clamp(0.0, double.infinity);

  // True only when the entire bill is covered by the free reward (no paid items).
  bool get isTotallyFree => total == 0 && freeRewardId != null;

  /// Total treatment time: every paid item plus the free reward treatment.
  int get totalDurationMinutes =>
      items.fold(0, (sum, item) => sum + item.durationMinutes) +
      (freeRewardDurationMinutes ?? 0);

  bool get scheduleReady => scheduledAt != null;
  bool get addressReady => address != null;

  BookingCart _copyCore({
    List<CartItem>? items,
    DateTime? scheduledAt,
    ServiceAddress? address,
    PaymentMethod? paymentMethod,
    bool? isLoading,
    String? error,
  }) => BookingCart(
    items: items ?? this.items,
    therapist: therapist,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    address: address ?? this.address,
    voucher: voucher,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    freeRewardId: freeRewardId,
    freeRewardTitle: freeRewardTitle,
    freeRewardTreatmentId: freeRewardTreatmentId,
    freeRewardDurationMinutes: freeRewardDurationMinutes,
    rewardDiscount: rewardDiscount,
    rewardDiscountType: rewardDiscountType,
    rewardRedemptionId: rewardRedemptionId,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

final bookingCartProvider = NotifierProvider<BookingCartNotifier, BookingCart>(
  BookingCartNotifier.new,
);

class BookingCartNotifier extends Notifier<BookingCart> {
  @override
  BookingCart build() => const BookingCart();

  void addItem(
    Treatment treatment,
    TreatmentDuration? duration, [
    List<AddonSelection> addons = const [],
  ]) {
    final item = CartItem(
      treatment: treatment,
      selectedDuration: duration ?? treatment.defaultDuration,
      addons: addons,
    );
    state = state._copyCore(items: [...state.items, item]);
  }

  void removeItem(int index) {
    final updated = List<CartItem>.from(state.items)..removeAt(index);
    state = state._copyCore(items: updated);
  }

  void removeFreeReward() {
    state = BookingCart(
      items: state.items,
      therapist: state.therapist,
      scheduledAt: state.scheduledAt,
      address: state.address,
      voucher: state.voucher,
      paymentMethod: state.paymentMethod,
      freeRewardId: null,
      freeRewardTitle: null,
      freeRewardTreatmentId: null,
      freeRewardDurationMinutes: null,
      rewardDiscount: state.rewardDiscount,
      rewardDiscountType: state.rewardDiscountType,
      rewardRedemptionId: state.rewardRedemptionId,
    );
  }

  void clearCart() => state = const BookingCart();

  void selectTherapist(Therapist? therapist) {
    state = BookingCart(
      items: state.items,
      therapist: therapist,
      scheduledAt: state.scheduledAt,
      address: state.address,
      voucher: state.voucher,
      paymentMethod: state.paymentMethod,
      freeRewardId: state.freeRewardId,
      freeRewardTitle: state.freeRewardTitle,
      freeRewardTreatmentId: state.freeRewardTreatmentId,
      freeRewardDurationMinutes: state.freeRewardDurationMinutes,
      rewardDiscount: state.rewardDiscount,
      rewardDiscountType: state.rewardDiscountType,
      rewardRedemptionId: state.rewardRedemptionId,
    );
  }

  /// [scheduledAtUtc] must already be converted from WIB (see
  /// [WIB.wibToUtc]).
  void selectSchedule(DateTime scheduledAtUtc) {
    state = state._copyCore(scheduledAt: scheduledAtUtc.toUtc());
  }

  void setAddress(ServiceAddress address) {
    state = state._copyCore(address: address);
  }

  void applyVoucher(Voucher v) {
    state = BookingCart(
      items: state.items,
      therapist: state.therapist,
      scheduledAt: state.scheduledAt,
      address: state.address,
      voucher: v,
      paymentMethod: state.paymentMethod,
      freeRewardId: state.freeRewardId,
      freeRewardTitle: state.freeRewardTitle,
      freeRewardTreatmentId: state.freeRewardTreatmentId,
      freeRewardDurationMinutes: state.freeRewardDurationMinutes,
      rewardDiscount: state.rewardDiscount,
      rewardDiscountType: state.rewardDiscountType,
      rewardRedemptionId: state.rewardRedemptionId,
    );
  }

  void removeVoucher() {
    state = BookingCart(
      items: state.items,
      therapist: state.therapist,
      scheduledAt: state.scheduledAt,
      address: state.address,
      paymentMethod: state.paymentMethod,
      freeRewardId: state.freeRewardId,
      freeRewardTitle: state.freeRewardTitle,
      freeRewardTreatmentId: state.freeRewardTreatmentId,
      freeRewardDurationMinutes: state.freeRewardDurationMinutes,
      rewardDiscount: state.rewardDiscount,
      rewardDiscountType: state.rewardDiscountType,
      rewardRedemptionId: state.rewardRedemptionId,
    );
  }

  void selectPaymentMethod(PaymentMethod method) {
    state = state._copyCore(paymentMethod: method);
  }

  void setLoading(bool loading) {
    state = state._copyCore(isLoading: loading);
  }

  void setError(String? message) {
    state = BookingCart(
      items: state.items,
      therapist: state.therapist,
      scheduledAt: state.scheduledAt,
      address: state.address,
      voucher: state.voucher,
      paymentMethod: state.paymentMethod,
      error: message,
      freeRewardId: state.freeRewardId,
      freeRewardTitle: state.freeRewardTitle,
      freeRewardTreatmentId: state.freeRewardTreatmentId,
      freeRewardDurationMinutes: state.freeRewardDurationMinutes,
      rewardDiscount: state.rewardDiscount,
      rewardDiscountType: state.rewardDiscountType,
      rewardRedemptionId: state.rewardRedemptionId,
    );
  }

  void applyFreeReward(
    String redemptionId,
    String rewardTitle, {
    String? treatmentId,
    int durationMinutes = 0,
  }) {
    // Free reward is exclusive — clear any existing voucher and discount reward.
    state = BookingCart(
      items: state.items,
      therapist: state.therapist,
      scheduledAt: state.scheduledAt,
      address: state.address,
      voucher: null,
      paymentMethod: state.paymentMethod,
      freeRewardId: redemptionId,
      freeRewardTitle: rewardTitle,
      freeRewardTreatmentId: treatmentId,
      freeRewardDurationMinutes: durationMinutes > 0 ? durationMinutes : null,
      rewardDiscount: null,
      rewardDiscountType: null,
      rewardRedemptionId: null,
    );
  }

  void applyDiscountReward(
    String redemptionId,
    int discountAmount,
    String type,
  ) {
    state = BookingCart(
      items: state.items,
      therapist: state.therapist,
      scheduledAt: state.scheduledAt,
      address: state.address,
      voucher: state.voucher,
      paymentMethod: state.paymentMethod,
      freeRewardId: state.freeRewardId,
      freeRewardTitle: state.freeRewardTitle,
      freeRewardTreatmentId: state.freeRewardTreatmentId,
      freeRewardDurationMinutes: state.freeRewardDurationMinutes,
      rewardDiscount: discountAmount.toDouble(),
      rewardDiscountType: type,
      rewardRedemptionId: redemptionId,
    );
  }
}
