import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../data/datasources/booking_remote_datasource.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/entities/availability_slot.dart';
import '../../domain/entities/booking_detail_data.dart';
import '../../domain/entities/booking_record.dart';
import '../../domain/entities/therapist.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/usecases/get_booking_history_usecase.dart';
import '../../domain/usecases/get_therapists_usecase.dart';
import '../../domain/usecases/validate_voucher_usecase.dart';

// ── DI chain ──────────────────────────────────────────────────────────────────

final bookingDataSourceProvider = Provider<BookingRemoteDataSource>(
  (ref) => BookingRemoteDataSourceImpl(apiClient),
);

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepositoryImpl(ref.watch(bookingDataSourceProvider)),
);

final getTherapistsUseCaseProvider = Provider<GetTherapistsUseCase>(
  (ref) => GetTherapistsUseCase(ref.watch(bookingRepositoryProvider)),
);

final validateVoucherUseCaseProvider = Provider<ValidateVoucherUseCase>(
  (ref) => ValidateVoucherUseCase(ref.watch(bookingRepositoryProvider)),
);

final createBookingUseCaseProvider = Provider<CreateBookingUseCase>(
  (ref) => CreateBookingUseCase(ref.watch(bookingRepositoryProvider)),
);

// ── Async data providers ──────────────────────────────────────────────────────

/// Therapists who have treated this customer (completed platform bookings).
/// New customers get an empty list and can only pick "Any Available Therapist".
final therapistsProvider = FutureProvider.autoDispose<List<Therapist>>((
  ref,
) async {
  final result = await ref.read(getTherapistsUseCaseProvider).call();
  return result.fold((_) => <Therapist>[], (therapists) => therapists);
});

/// Free slots for a package on a WIB calendar day, from the platform's slot
/// engine (shared with the WhatsApp bot — a listed slot is genuinely free).
final availabilityProvider = FutureProvider.autoDispose
    .family<List<AvailabilitySlot>, ({String packageId, String date})>((
      ref,
      args,
    ) async {
      return ref
          .read(bookingDataSourceProvider)
          .getAvailability(packageId: args.packageId, date: args.date);
    });

final getBookingHistoryUseCaseProvider = Provider<GetBookingHistoryUseCase>(
  (ref) => GetBookingHistoryUseCase(ref.watch(bookingRepositoryProvider)),
);

// Legacy one-shot provider (kept for fallback)
final bookingHistoryProvider = FutureProvider<List<BookingRecord>>((ref) async {
  final result = await ref.read(getBookingHistoryUseCaseProvider).call();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (records) => records,
  );
});

// ── Booking detail state ──────────────────────────────────────────────────────

class BookingDetailState {
  final bool isLoading;
  final String? error;
  final BookingDetailData? detail;
  final bool isSubmittingReview;

  const BookingDetailState({
    this.isLoading = true,
    this.error,
    this.detail,
    this.isSubmittingReview = false,
  });

  BookingDetailState copyWith({
    bool? isLoading,
    String? error,
    BookingDetailData? detail,
    bool? isSubmittingReview,
  }) => BookingDetailState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    detail: detail ?? this.detail,
    isSubmittingReview: isSubmittingReview ?? this.isSubmittingReview,
  );
}

/// Loads GET /bookings/{id} and polls it every 15 s so the status timeline
/// (pending → assigned → on the way → … → completed) moves live.
class BookingDetailNotifier extends StateNotifier<BookingDetailState> {
  final BookingRemoteDataSource _dataSource;
  final String _bookingId;
  Timer? _pollingTimer;

  BookingDetailNotifier(this._dataSource, this._bookingId)
    : super(const BookingDetailState()) {
    _load();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _load(showLoading: false);
    });
  }

  Future<void> reload() async => _load();

  Future<void> _load({bool showLoading = true}) async {
    if (!mounted) return;
    if (showLoading) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final detail = await _dataSource.getBookingDetail(_bookingId);
      if (!mounted) return;
      state = BookingDetailState(isLoading: false, detail: detail);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (state.detail == null) {
        state = BookingDetailState(isLoading: false, error: e.message);
      }
    } catch (e) {
      debugPrint('[BookingDetail] load failed: $e');
      if (!mounted) return;
      if (state.detail == null) {
        state = BookingDetailState(isLoading: false, error: e.toString());
      }
    }
  }

  /// Submit a therapist review; the platform rolls the therapist's average.
  Future<void> submitReview({
    required double rating,
    String? reviewText,
  }) async {
    final detail = state.detail;
    if (detail == null || detail.therapistId == null) return;

    if (!mounted) return;
    state = state.copyWith(isSubmittingReview: true);

    try {
      await _dataSource.submitReview(
        _bookingId,
        score: rating.round(),
        comment: reviewText,
      );
      if (!mounted) return;
      state = state.copyWith(
        isSubmittingReview: false,
        detail: detail.copyWith(
          hasExistingReview: true,
          existingRating: rating,
          existingReviewText: reviewText != null && reviewText.trim().isNotEmpty
              ? reviewText.trim()
              : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSubmittingReview: false);
      rethrow;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final bookingDetailProvider =
    StateNotifierProvider.family<
      BookingDetailNotifier,
      BookingDetailState,
      String
    >(
      (ref, bookingId) => BookingDetailNotifier(
        ref.watch(bookingDataSourceProvider),
        bookingId,
      ),
    );
