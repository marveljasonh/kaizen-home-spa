import '../../../../core/api/api_client.dart';
import '../../../../core/api/auth_session.dart';
import '../../domain/entities/availability_slot.dart';
import '../../domain/entities/booking_detail_data.dart';
import '../../domain/entities/booking_record.dart';
import '../../domain/entities/booking_request.dart';
import '../../domain/entities/order_summary.dart';
import '../../domain/entities/therapist.dart';
import '../../domain/entities/voucher.dart';

abstract interface class BookingRemoteDataSource {
  /// Therapists who have treated this customer (from completed bookings).
  Future<List<Therapist>> getTherapists();
  Future<Voucher> validateVoucher(String code);
  Future<String> createBooking(BookingRequest request);
  Future<List<BookingRecord>> getBookingHistory();
  Future<List<OrderSummary>> getOrderSummaries();
  Future<List<AvailabilitySlot>> getAvailability({
    required String packageId,
    required String date, // YYYY-MM-DD (WIB calendar day)
    double? lat,
    double? lng,
  });
  Future<BookingDetailData> getBookingDetail(String bookingId);
  Future<void> submitReview(
    String bookingId, {
    required int score,
    String? comment,
  });
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final ApiClient _api;
  BookingRemoteDataSourceImpl(this._api);

  List<Map<String, dynamic>>? _branches;

  String _customerId() {
    final session = AuthSession.current;
    if (session == null) throw const ApiException('Not signed in', 401);
    return session.customerId;
  }

  // ── Branch resolution ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _getBranches() async {
    final cached = _branches;
    if (cached != null) return cached;
    final json = await _api.get('/branches') as Map<String, dynamic>;
    _branches = (json['branches'] as List).cast<Map<String, dynamic>>();
    return _branches!;
  }

  /// Nearest active branch to the coordinates, else the first one.
  Future<String> _resolveBranchId({double? lat, double? lng}) async {
    final branches = await _getBranches();
    if (branches.isEmpty) {
      throw const ApiException('No active branch', 500);
    }
    if (lat == null || lng == null) return branches.first['id'] as String;
    Map<String, dynamic>? best;
    double bestD = double.infinity;
    for (final b in branches) {
      final bLat = (b['lat'] as num?)?.toDouble();
      final bLng = (b['lng'] as num?)?.toDouble();
      if (bLat == null || bLng == null) continue;
      final d = (bLat - lat) * (bLat - lat) + (bLng - lng) * (bLng - lng);
      if (d < bestD) {
        bestD = d;
        best = b;
      }
    }
    return (best ?? branches.first)['id'] as String;
  }

  // ── Bookings ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _fetchBookings() async {
    final json =
        await _api.get('/customers/${_customerId()}/bookings')
            as Map<String, dynamic>;
    return (json['bookings'] as List).cast<Map<String, dynamic>>();
  }

  /// Platform statuses → the labels the app's order UI understands.
  static String mapStatus(String platform) => switch (platform) {
    'assigned' => 'therapist_assigned',
    'en_route' => 'on_the_way',
    'at_customer' => 'arrived',
    _ => platform,
  };

  static BookingStatus recordStatus(String platform) => switch (platform) {
    'pending' => BookingStatus.pending,
    'assigned' => BookingStatus.confirmed,
    'en_route' || 'at_customer' || 'in_progress' => BookingStatus.inProgress,
    'completed' => BookingStatus.completed,
    'cancelled' => BookingStatus.cancelled,
    _ => BookingStatus.pending,
  };

  @override
  Future<List<Therapist>> getTherapists() async {
    final rows = await _fetchBookings();
    final seen = <String>{};
    final result = <Therapist>[];
    for (final r in rows) {
      if (r['status'] != 'completed') continue;
      final id = r['therapistId'] as String?;
      final name = r['therapistName'] as String?;
      if (id == null || name == null || !seen.add(id)) continue;
      result.add(Therapist(id: id, name: name, rating: 0, reviewCount: 0));
    }
    return result;
  }

  @override
  Future<Voucher> validateVoucher(String code) async {
    final json =
        await _api.post(
              '/promos/validate',
              body: {'code': code.trim().toUpperCase(), 'customerId': _customerId()},
            )
            as Map<String, dynamic>;
    if (json['valid'] != true) {
      throw ApiException(
        (json['reason'] as String?) ?? 'Invalid or expired voucher',
        400,
      );
    }
    final grants = (json['grants'] as Map<String, dynamic>?) ?? const {};
    return Voucher(
      code: code.trim().toUpperCase(),
      discountType: DiscountType.fixed,
      discountValue: 0,
      freeAddonName: grants['name'] as String?,
      freeAddonDurationMinutes: (grants['durationMin'] as num?)?.toInt(),
      freeAddonValueIdr: (grants['valueIdr'] as num?)?.toDouble(),
    );
  }

  @override
  Future<String> createBooking(BookingRequest request) async {
    final customerId = _customerId();

    final distinctTreatments = request.items
        .map((i) => i.treatmentDurationId)
        .whereType<String>()
        .toSet();
    if (distinctTreatments.length > 1) {
      throw const ApiException(
        'One booking covers one treatment — please book the second treatment separately.',
        400,
      );
    }

    // The platform books one package; the package id IS the app's
    // treatment-duration id. A rewards-only booking carries the reward's
    // package in freeRewardTreatmentId.
    final packageId =
        request.treatmentDurationId ?? request.freeRewardTreatmentId;
    if (packageId == null) {
      throw const ApiException('Pick a treatment duration first', 400);
    }

    var addressId = request.addressId;
    if (addressId == null) {
      final created =
          await _api.post(
                '/customers/$customerId/addresses',
                body: {
                  'label': 'Booking address',
                  'line': request.addressText,
                  'city': (request.addressText.split(',').lastOrNull ?? '-')
                      .trim(),
                  'lat': request.latitude,
                  'lng': request.longitude,
                  if (request.addressNotes?.isNotEmpty ?? false)
                    'entranceNotes': request.addressNotes,
                },
              )
              as Map<String, dynamic>;
      addressId =
          (created['address'] as Map<String, dynamic>)['id'] as String;
    }

    final branchId = await _resolveBranchId(
      lat: request.latitude,
      lng: request.longitude,
    );

    final addonIds = request.addons.map((a) => a.addonId).toSet().toList();
    final redemptionId = request.freeRewardId ?? request.rewardRedemptionId;

    final json =
        await _api.post(
              '/bookings',
              body: {
                'customerId': customerId,
                'addressId': addressId,
                'packageId': packageId,
                'branchId': branchId,
                'startISO': request.scheduledAt.toUtc().toIso8601String(),
                if (request.therapistId != null)
                  'therapistId': request.therapistId,
                'paymentMethod': 'cash',
                if (request.addressNotes?.isNotEmpty ?? false)
                  'notes': request.addressNotes,
                if (request.voucherCode != null)
                  'promoCode': request.voucherCode,
                if (redemptionId != null) 'redemptionId': redemptionId,
                if (addonIds.isNotEmpty) 'addonIds': addonIds,
              },
            )
            as Map<String, dynamic>;
    return (json['booking'] as Map<String, dynamic>)['id'] as String;
  }

  @override
  Future<List<BookingRecord>> getBookingHistory() async {
    final rows = await _fetchBookings();
    return rows.map((r) {
      final scheduled = DateTime.parse(r['scheduledStart'] as String).toUtc();
      return BookingRecord(
        id: r['id'] as String,
        treatmentId: (r['packageId'] as String?) ?? '',
        treatmentName: (r['packageName'] as String?) ?? 'Kaizen Spa Service',
        therapistName: r['therapistName'] as String?,
        scheduledAt: scheduled,
        addressText: [
          r['addressLabel'],
          r['addressLine'],
        ].whereType<String>().join(' — '),
        paymentMethod: 'cash',
        subtotal: (r['totalAmountIdr'] as num?)?.toDouble() ?? 0,
        discount: 0,
        total: (r['totalAmountIdr'] as num?)?.toDouble() ?? 0,
        status: recordStatus((r['status'] as String?) ?? 'pending'),
        createdAt:
            DateTime.tryParse('${r['createdAt']}')?.toUtc() ?? scheduled,
      );
    }).toList();
  }

  @override
  Future<List<OrderSummary>> getOrderSummaries() async {
    final rows = await _fetchBookings();
    final summaries = rows.map((r) {
      final scheduled = DateTime.parse(r['scheduledStart'] as String).toUtc();
      final created =
          DateTime.tryParse('${r['createdAt']}')?.toUtc() ?? scheduled;
      return OrderSummary(
        id: r['id'] as String,
        scheduledAt: scheduled,
        createdAt: created,
        status: mapStatus((r['status'] as String?) ?? 'pending'),
        items: [
          OrderSummaryItem(
            treatmentDurationId: r['packageId'] as String?,
            treatmentId: null,
            treatmentName:
                (r['packageName'] as String?) ?? 'Kaizen Spa Service',
            durationMinutes: (r['packageDurationMin'] as num?)?.toInt(),
            quantity: 1,
          ),
        ],
        address: [
          r['addressLabel'],
          r['addressLine'],
        ].whereType<String>().join(' — '),
        total: (r['totalAmountIdr'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
    summaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return summaries;
  }

  @override
  Future<List<AvailabilitySlot>> getAvailability({
    required String packageId,
    required String date,
    double? lat,
    double? lng,
  }) async {
    final branchId = await _resolveBranchId(lat: lat, lng: lng);
    final json =
        await _api.get(
              '/availability',
              query: {
                'packageId': packageId,
                'branchId': branchId,
                'date': date,
              },
            )
            as Map<String, dynamic>;
    return (json['slots'] as List)
        .cast<Map<String, dynamic>>()
        .map(
          (s) => AvailabilitySlot(
            startUtc: DateTime.parse(s['startISO'] as String).toUtc(),
            therapistId: s['therapistId'] as String,
            therapistName: s['therapistName'] as String,
            label: (s['label'] as String?) ?? '',
          ),
        )
        .toList();
  }

  @override
  Future<BookingDetailData> getBookingDetail(String bookingId) async {
    final json =
        await _api.get('/bookings/$bookingId') as Map<String, dynamic>;
    final b = json['booking'] as Map<String, dynamic>;

    final addonRows =
        (b['addons'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final review = b['review'] as Map<String, dynamic>?;
    final total = (b['totalAmountIdr'] as num?)?.toDouble() ?? 0;
    final discount = (b['discountIdr'] as num?)?.toDouble() ?? 0;
    final packagePrice = (b['packagePriceIdr'] as num?)?.toDouble() ?? 0;

    return BookingDetailData(
      bookingId: b['id'] as String,
      status: recordStatus((b['status'] as String?) ?? 'pending'),
      statusRaw: mapStatus((b['status'] as String?) ?? 'pending'),
      scheduledAt: DateTime.parse(b['scheduledStart'] as String).toUtc(),
      addressText: [
        b['addressLabel'],
        b['addressLine'],
      ].whereType<String>().join(' — '),
      paymentMethod: (b['paymentMethod'] as String?) ?? 'cash',
      subtotal: packagePrice +
          addonRows.fold<double>(
            0,
            (s, a) => s + ((a['priceIdr'] as num?)?.toDouble() ?? 0),
          ),
      discountAmount: discount,
      taxAmount: 0,
      totalAmount: total,
      therapistId: b['therapistId'] as String?,
      therapistName: b['therapistName'] as String?,
      therapistRating: (b['therapistRating'] as num?)?.toDouble(),
      therapistAvatarUrl: b['therapistAvatarUrl'] as String?,
      therapistPhone: b['therapistPhone'] as String?,
      treatments: [
        TreatmentLineItem(
          name: (b['packageName'] as String?) ?? 'Kaizen Spa Service',
          price: packagePrice,
          durationMinutes: (b['packageDurationMin'] as num?)?.toInt() ?? 0,
        ),
      ],
      addons: [
        for (final a in addonRows)
          AddonLineItem(
            name: (a['name'] as String?) ?? 'Add-on',
            price: (a['priceIdr'] as num?)?.toDouble() ?? 0,
          ),
      ],
      hasExistingReview: review != null,
      existingRating: (review?['score'] as num?)?.toDouble(),
      existingReviewText: review?['comment'] as String?,
    );
  }

  @override
  Future<void> submitReview(
    String bookingId, {
    required int score,
    String? comment,
  }) async {
    await _api.post(
      '/bookings/$bookingId/review',
      body: {
        'score': score,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
  }
}
