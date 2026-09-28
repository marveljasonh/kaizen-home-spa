import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/utils/timezone_helper.dart';

import '../../data/datasources/booking_remote_datasource.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/entities/booking_detail_data.dart';
import '../../domain/entities/booking_record.dart';
import '../../domain/entities/therapist.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/usecases/get_booking_history_usecase.dart';
import '../../domain/usecases/get_therapists_usecase.dart';
import '../../domain/usecases/validate_voucher_usecase.dart';

// ── DI chain ──────────────────────────────────────────────────────────────────

final _bookingDataSourceProvider = Provider<BookingRemoteDataSource>(
  (ref) => BookingRemoteDataSourceImpl(Supabase.instance.client),
);

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepositoryImpl(ref.watch(_bookingDataSourceProvider)),
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

final therapistsProvider = FutureProvider.autoDispose<List<Therapist>>((
  ref,
) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  // Only therapists who have already treated this client: distinct
  // therapist_id from their completed bookings. New clients get none and
  // can only pick "Any Available Therapist".
  final bookingRows = await client
      .from('bookings')
      .select('therapist_id')
      .eq('client_id', userId)
      .eq('status', 'completed')
      .not('therapist_id', 'is', null);
  final treatedIds = {
    for (final r in bookingRows as List<dynamic>)
      if ((r as Map<String, dynamic>)['therapist_id'] != null)
        r['therapist_id'] as String,
  }.toList();
  if (treatedIds.isEmpty) return [];

  // Those therapists from therapist_profiles, available ones first
  final tProfileRows = List<Map<String, dynamic>>.from(
    await client
        .from('therapist_profiles')
        .select(
          'profile_id, rating_avg, bio, specialties, status, is_available',
        )
        .inFilter('profile_id', treatedIds)
        .order('is_available', ascending: false),
  );

  if (tProfileRows.isEmpty) return [];

  final ids = tProfileRows.map((r) => r['profile_id'] as String).toList();

  // Flat fetch of display info from profiles
  final profileRows = await client
      .from('profiles')
      .select('id, full_name, avatar_url')
      .inFilter('id', ids);

  final profileMap = {
    for (final r in profileRows as List<dynamic>)
      (r as Map<String, dynamic>)['id'] as String: r,
  };

  return tProfileRows.map((tp) {
    final pid = tp['profile_id'] as String;
    final profile = profileMap[pid] ?? {};
    final specs = tp['specialties'] as List<dynamic>? ?? [];
    return Therapist(
      id: pid,
      name: profile['full_name'] as String? ?? 'Therapist',
      avatarUrl: profile['avatar_url'] as String?,
      rating: (tp['rating_avg'] as num?)?.toDouble() ?? 0.0,
      reviewCount: 0,
      bio: tp['bio'] as String?,
      specialties: specs.map((e) => e.toString()).toList(),
      status: tp['status'] as String?,
      isAvailable: tp['is_available'] as bool? ?? true,
    );
  }).toList();
});

/// A therapist's existing booking, as a UTC time range.
class BusyWindow {
  final DateTime startUtc;
  final int durationMinutes;
  const BusyWindow(this.startUtc, this.durationMinutes);

  DateTime get endUtc => startUtc.add(Duration(minutes: durationMinutes));
}

/// Used when a booking's items carry no duration.
const int kDefaultBookingMinutes = 60;

/// Active bookings for [therapistId] around the WIB calendar day [dayWib].
/// The query reaches 12 h either side of the day so bookings that cross
/// midnight still count.
final therapistBusyWindowsProvider = FutureProvider.autoDispose
    .family<List<BusyWindow>, ({String therapistId, DateTime dayWib})>((
      ref,
      args,
    ) async {
      final client = Supabase.instance.client;
      final dayStart = WIB.startOfDayUtc(args.dayWib);
      final rows = List<Map<String, dynamic>>.from(
        await client
            .from('bookings')
            .select('id, scheduled_at')
            .eq('therapist_id', args.therapistId)
            .not('status', 'in', '("completed","cancelled")')
            .gte(
              'scheduled_at',
              dayStart.subtract(const Duration(hours: 12)).toIso8601String(),
            )
            .lt(
              'scheduled_at',
              dayStart.add(const Duration(hours: 36)).toIso8601String(),
            ),
      );
      if (rows.isEmpty) return const [];

      final ids = rows.map((r) => r['id'] as String).toList();
      final itemRows = List<Map<String, dynamic>>.from(
        await client
            .from('booking_items')
            .select('booking_id, treatment_snapshot, quantity')
            .inFilter('booking_id', ids),
      );
      final minutesById = <String, int>{};
      for (final item in itemRows) {
        final snap = item['treatment_snapshot'] as Map<String, dynamic>? ?? {};
        final mins = (snap['duration_minutes'] as num?)?.toInt() ?? 0;
        final qty = (item['quantity'] as num?)?.toInt() ?? 1;
        final id = item['booking_id'] as String;
        minutesById[id] = (minutesById[id] ?? 0) + mins * qty;
      }

      final windows = [
        for (final r in rows)
          BusyWindow(
            DateTime.parse(r['scheduled_at'] as String).toUtc(),
            (minutesById[r['id']] ?? 0) > 0
                ? minutesById[r['id']]!
                : kDefaultBookingMinutes,
          ),
      ];
      debugPrint(
        'Busy windows for ${args.therapistId} on '
        '${WIB.formatDate(dayStart)}: '
        '${windows.map((w) => '${WIB.formatTime(w.startUtc)}–${WIB.formatTime(w.endUtc)}').join(', ')}',
      );
      return windows;
    });

/// Therapist IDs that have an active booking within ±2 hours of [scheduledAt].
final bookedTherapistIdsProvider = FutureProvider.autoDispose
    .family<Set<String>, DateTime?>((ref, scheduledAt) async {
      if (scheduledAt == null) return {};
      final client = Supabase.instance.client;
      const window = Duration(hours: 2);
      final rows = List<Map<String, dynamic>>.from(
        await client
            .from('bookings')
            .select('therapist_id')
            .not('status', 'in', '("completed","cancelled")')
            .gte('scheduled_at', scheduledAt.subtract(window).toIso8601String())
            .lte('scheduled_at', scheduledAt.add(window).toIso8601String()),
      );
      return {
        for (final r in rows)
          if (r['therapist_id'] != null) r['therapist_id'] as String,
      };
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

// ── Realtime stream providers ─────────────────────────────────────────────────

/// Subscribes to the bookings table via Supabase realtime.
/// Automatically updates when admin changes booking status.
final bookingHistoryStreamProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, userId) {
      return Supabase.instance.client
          .from('bookings')
          .stream(primaryKey: ['id'])
          .eq('client_id', userId)
          .order('scheduled_at', ascending: false);
    });

/// Subscribes to a single booking row for realtime status updates.
final bookingDetailStreamProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, bookingId) {
      return Supabase.instance.client
          .from('bookings')
          .stream(primaryKey: ['id'])
          .eq('id', bookingId)
          .map((list) => list.isNotEmpty ? list.first : null);
    });

// ── Booking detail state (issues 1, 2, 3, 6) ────────────────────────────────

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

class BookingDetailNotifier extends StateNotifier<BookingDetailState> {
  final SupabaseClient _client;
  final String _bookingId;
  Timer? _pollingTimer;

  BookingDetailNotifier(this._client, this._bookingId)
    : super(const BookingDetailState()) {
    _init();
  }

  Future<void> _init() async {
    await _load();
    _startPolling();
  }

  void _startPolling() {
    debugPrint('[Polling] starting 5s poll for booking $_bookingId');
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      debugPrint('[Polling] refreshing booking detail $_bookingId');
      _load(showLoading: false);
    });
  }

  Future<void> reload() async => _load();

  Future<void> _load({bool showLoading = true}) async {
    print('[BookingDetail] _load called with id: $_bookingId');
    if (!mounted) return;
    if (showLoading) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      // Step 1: check booking exists
      debugPrint('[BookingDetail] Step 1: fetching booking $_bookingId');
      final row = await _client
          .from('bookings')
          .select()
          .eq('id', _bookingId)
          .maybeSingle();
      debugPrint('[BookingDetail] Step 1: booking found=${row != null}');
      if (row == null) {
        debugPrint(
          '[BookingDetail] Step 1: booking NOT found — id=$_bookingId',
        );
        if (!mounted) return;
        state = BookingDetailState(
          isLoading: false,
          error: 'Booking not found (id: $_bookingId)',
        );
        return;
      }
      debugPrint('[BookingDetail] Step 1 data: $row');
      debugPrint('Booking data: ${row.toString()}');

      // Step 2: fetch booking_items
      debugPrint('[BookingDetail] Step 2: fetching booking_items');
      List<Map<String, dynamic>> itemRows = [];
      try {
        final result = await _client
            .from('booking_items')
            .select('*')
            .eq('booking_id', _bookingId);
        itemRows = List<Map<String, dynamic>>.from(result);
        debugPrint(
          '[BookingDetail] Step 2: ${itemRows.length} items — $itemRows',
        );
      } catch (e, st) {
        debugPrint('[BookingDetail] Step 2 ERROR: $e\n$st');
      }

      // Step 3: build TreatmentLineItems from snapshot
      final treatments = itemRows.map((r) {
        final snap = r['treatment_snapshot'] as Map<String, dynamic>? ?? {};
        debugPrint('[BookingDetail] treatment_snapshot: $snap');
        return TreatmentLineItem(
          name: snap['treatment_name'] as String? ?? 'Treatment',
          price: (r['unit_price'] as num?)?.toDouble() ?? 0.0,
          durationMinutes: (snap['duration_minutes'] as num?)?.toInt() ?? 0,
          quantity: r['quantity'] as int? ?? 1,
        );
      }).toList();

      // Step 4: fetch booking_addons
      debugPrint('[BookingDetail] Step 4: fetching booking_addons');
      List<Map<String, dynamic>> addonRows = [];
      try {
        final result = await _client
            .from('booking_addons')
            .select('*')
            .eq('booking_id', _bookingId);
        addonRows = List<Map<String, dynamic>>.from(result);
        debugPrint(
          '[BookingDetail] Step 4: ${addonRows.length} addons — $addonRows',
        );
      } catch (e, st) {
        debugPrint('[BookingDetail] Step 4 ERROR: $e\n$st');
      }

      // Step 5: build AddonLineItems from snapshot
      final addons = addonRows.map((r) {
        final snap = r['addon_snapshot'] as Map<String, dynamic>? ?? {};
        debugPrint('[BookingDetail] addon_snapshot: $snap');
        return AddonLineItem(
          name: snap['addon_name'] as String? ?? 'Add-on',
          price: (r['unit_price'] as num?)?.toDouble() ?? 0.0,
          quantity: r['quantity'] as int? ?? 1,
        );
      }).toList();

      // Step 6: fetch therapist details if assigned
      // therapist_id in bookings = profiles.id (auth user id)
      debugPrint('[BookingDetail] Step 6: therapist_id=${row['therapist_id']}');
      final therapistId = row['therapist_id'] as String?;
      String? therapistName;
      double? therapistRating;
      String? therapistAvatarUrl;
      String? therapistPhone;
      if (therapistId != null) {
        // 6a: name + avatar + phone from profiles (keyed by id = auth uid)
        try {
          final profileRow = await _client
              .from('profiles')
              .select('full_name, avatar_url, phone')
              .eq('id', therapistId)
              .maybeSingle();
          debugPrint('[BookingDetail] Step 6a profiles: $profileRow');
          debugPrint('Therapist data: ${profileRow?.toString()}');
          if (profileRow != null) {
            therapistName = profileRow['full_name'] as String?;
            therapistAvatarUrl = profileRow['avatar_url'] as String?;
            therapistPhone = profileRow['phone'] as String?;
            debugPrint('[BookingDetail] therapistPhone: $therapistPhone');
          }
        } catch (e, st) {
          debugPrint('[BookingDetail] Step 6a ERROR: $e\n$st');
        }

        // 6b: rating from therapist_profiles (keyed by profile_id = auth uid)
        try {
          final detailRow = await _client
              .from('therapist_profiles')
              .select('rating_avg')
              .eq('profile_id', therapistId)
              .maybeSingle();
          debugPrint('[BookingDetail] Step 6b therapist_profiles: $detailRow');
          if (detailRow != null) {
            therapistRating = (detailRow['rating_avg'] as num?)?.toDouble();
          }
        } catch (e, st) {
          debugPrint('[BookingDetail] Step 6b ERROR: $e\n$st');
        }
      }

      // Step 7: check for existing review
      debugPrint('[BookingDetail] Step 7: checking for existing review');
      final userId = _client.auth.currentUser?.id;
      bool hasReview = false;
      double? existingRating;
      String? existingReviewText;
      if (userId != null) {
        try {
          final reviewRow = await _client
              .from('therapist_reviews')
              .select('id, rating, review_text')
              .eq('booking_id', _bookingId)
              .maybeSingle();
          hasReview = reviewRow != null;
          if (reviewRow != null) {
            existingRating = (reviewRow['rating'] as num?)?.toDouble();
            existingReviewText = reviewRow['review_text'] as String?;
          }
          debugPrint(
            '[BookingDetail] Step 7: hasReview=$hasReview rating=$existingRating',
          );
        } catch (e, st) {
          debugPrint('[BookingDetail] Step 7 ERROR: $e\n$st');
        }
      }

      // Step 8: parse scheduledAt
      debugPrint(
        '[BookingDetail] Step 8: parsing scheduled_at=${row['scheduled_at']}',
      );
      final scheduledAt = DateTime.parse(row['scheduled_at'] as String);

      debugPrint('[BookingDetail] All steps done — building state');
      if (!mounted) return;
      state = BookingDetailState(
        isLoading: false,
        detail: BookingDetailData(
          bookingId: _bookingId,
          status: _parseStatus(row['status'] as String? ?? 'pending'),
          scheduledAt: scheduledAt,
          addressText: row['address_snapshot'] as String? ?? '',
          paymentMethod: row['payment_method'] as String? ?? '',
          subtotal: (row['subtotal'] as num?)?.toDouble() ?? 0.0,
          discountAmount: (row['discount_amount'] as num?)?.toDouble() ?? 0.0,
          taxAmount: (row['tax_amount'] as num?)?.toDouble() ?? 0.0,
          totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0.0,
          therapistId: therapistId,
          therapistName: therapistName,
          therapistRating: therapistRating,
          therapistAvatarUrl: therapistAvatarUrl,
          therapistPhone: therapistPhone,
          treatments: treatments,
          addons: addons,
          hasExistingReview: hasReview,
          existingRating: existingRating,
          existingReviewText: existingReviewText,
        ),
      );
      debugPrint('[BookingDetail] state updated successfully');
    } catch (e, st) {
      debugPrint('[BookingDetail] FATAL ERROR: $e');
      debugPrint('[BookingDetail] STACK: $st');
      if (!mounted) return;
      state = BookingDetailState(isLoading: false, error: e.toString());
    }
  }

  /// Submit a therapist review and recalculate their average rating.
  Future<void> submitReview({
    required double rating,
    String? reviewText,
  }) async {
    final detail = state.detail;
    if (detail == null || detail.therapistId == null) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (!mounted) return;
    state = state.copyWith(isSubmittingReview: true);

    try {
      // Insert the review
      await _client.from('therapist_reviews').insert({
        'therapist_id': detail.therapistId,
        'client_id': userId,
        'booking_id': _bookingId,
        'rating': rating.round(),
        if (reviewText != null && reviewText.trim().isNotEmpty)
          'review_text': reviewText.trim(),
      });

      // Recalculate therapist average rating
      final allRatings = await _client
          .from('therapist_reviews')
          .select('rating')
          .eq('therapist_id', detail.therapistId!);

      if (allRatings.isNotEmpty) {
        final avg =
            allRatings.fold<double>(
              0.0,
              (sum, r) => sum + (r['rating'] as num).toDouble(),
            ) /
            allRatings.length;
        await _client
            .from('therapist_profiles')
            .update({'rating_avg': avg})
            .eq('id', detail.therapistId!);
      }

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
    debugPrint('[Polling] booking detail $_bookingId — timer cancelled');
    super.dispose();
  }

  static BookingStatus _parseStatus(String s) => switch (s) {
    'confirmed' => BookingStatus.confirmed,
    'therapist_assigned' => BookingStatus.confirmed,
    'in_progress' => BookingStatus.inProgress,
    'completed' => BookingStatus.completed,
    'cancelled' => BookingStatus.cancelled,
    _ => BookingStatus.pending,
  };
}

final bookingDetailProvider =
    StateNotifierProvider.family<
      BookingDetailNotifier,
      BookingDetailState,
      String
    >(
      (ref, bookingId) =>
          BookingDetailNotifier(Supabase.instance.client, bookingId),
    );
