import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/booking_record.dart';
import '../../domain/entities/booking_request.dart';
import '../../domain/entities/therapist.dart';
import '../../domain/entities/voucher.dart';
import '../models/booking_record_model.dart';
import '../models/therapist_model.dart';
import '../models/voucher_model.dart';

abstract interface class BookingRemoteDataSource {
  Future<List<Therapist>> getTherapists();
  Future<Voucher> validateVoucher(String code);
  Future<String> createBooking(BookingRequest request);
  Future<List<BookingRecord>> getBookingHistory();
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final SupabaseClient _client;
  const BookingRemoteDataSourceImpl(this._client);

  @override
  Future<List<Therapist>> getTherapists() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // Step 1: preferred_therapists — therapist_id = profiles.id (auth UID)
      final preferred = await _client
          .from('preferred_therapists')
          .select('therapist_id, booking_count, last_booked_at')
          .eq('client_id', userId)
          .order('booking_count', ascending: false);

      if (preferred.isEmpty) return [];

      final ids = preferred
          .map((r) => r['therapist_id'] as String)
          .toList();

      // Step 2: name + avatar from profiles (keyed by id)
      final profileRows = await _client
          .from('profiles')
          .select('id, full_name, avatar_url')
          .inFilter('id', ids);
      final profileMap = {
        for (final r in profileRows) r['id'] as String: r,
      };

      // Step 3: rating + bio + specialties from therapist_profiles (keyed by profile_id)
      final tProfileRows = await _client
          .from('therapist_profiles')
          .select('profile_id, rating_avg, bio, specialties, status, is_available')
          .inFilter('profile_id', ids);
      final tProfileMap = {
        for (final r in tProfileRows) r['profile_id'] as String: r,
      };

      // Step 4: assemble flat map per therapist and parse
      return preferred.map((pt) {
        final tid = pt['therapist_id'] as String;
        final profile = profileMap[tid] ?? {};
        final tProfile = tProfileMap[tid] ?? {};
        return TherapistModel.fromJson({
          'id': tid,
          'full_name': profile['full_name'],
          'avatar_url': profile['avatar_url'],
          'rating_avg': tProfile['rating_avg'],
          'bio': tProfile['bio'],
          'specialties': tProfile['specialties'],
          'booking_count': pt['booking_count'],
          'review_count': 0,
          'status': tProfile['status'],
          'is_available': tProfile['is_available'],
        });
      }).toList();
    } catch (e) {
      debugPrint('[getTherapists] ERROR: $e');
      return [];
    }
  }

  @override
  Future<Voucher> validateVoucher(String code) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final data = await _client
        .from('vouchers')
        .select()
        .eq('code', code.toUpperCase())
        .eq('is_active', true)
        .or('valid_until.is.null,valid_until.gte.$now')
        .single();
    return VoucherModel.fromJson(data);
  }

  @override
  Future<String> createBooking(BookingRequest request) async {
    final userId = _client.auth.currentUser!.id;

    // Snapshot reward fields immediately — request is immutable, but be explicit.
    final freeRewardId = request.freeRewardId;
    final freeRewardTreatmentId = request.freeRewardTreatmentId;
    final discountRedemptionId = request.rewardRedemptionId;

    debugPrint('[FreeReward] freeRewardId: $freeRewardId');
    debugPrint('[FreeReward] freeRewardTreatmentId: $freeRewardTreatmentId');
    debugPrint('[FreeReward] request.paymentMethodId: ${request.paymentMethodId}');
    debugPrint('[FreeReward] request.total: ${request.total}');
    debugPrint('[FreeReward] request.items.length: ${request.items.length}');

    // Resolve voucher UUID from code if provided
    String? voucherId;
    if (request.voucherCode != null) {
      try {
        final row = await _client
            .from('vouchers')
            .select('id')
            .eq('code', request.voucherCode!.toUpperCase())
            .maybeSingle();
        voucherId = row?['id'] as String?;
      } catch (_) {
        // proceed without voucher_id if lookup fails
      }
    }

    final branch = await _client
        .from('branches')
        .select('id')
        .eq('is_active', true)
        .limit(1)
        .single();

    final isFreeReward = request.total == 0 && request.paymentMethodId == 'reward';

    final bookingData = {
      'client_id': userId,
      'branch_id': branch['id'] as String,
      'therapist_id': request.therapistId,
      'scheduled_at': request.scheduledAt.toIso8601String(),
      'address_snapshot': request.addressText,
      'payment_method': isFreeReward ? 'reward' : request.paymentMethodId,
      'payment_status': isFreeReward ? 'paid' : 'pending',
      'status': 'pending',
      'subtotal': request.subtotal,
      'discount_amount': request.discountAmount,
      'tax_amount': 0,
      'total_amount': request.total,
      'notes': request.addressNotes,
      'voucher_id': voucherId,
    };

    debugPrint('payment_status being sent: ${bookingData['payment_status']}');
    debugPrint('payment_method being sent: ${bookingData['payment_method']}');
    debugPrint('full booking data: $bookingData');

    final booking = await _client
        .from('bookings')
        .insert(bookingData)
        .select('id')
        .single();

    debugPrint('[CreateBooking] booking created: ${booking['id']}');
    debugPrint('[CreateBooking] cart items count: ${request.items.length}');

    if (request.items.isNotEmpty) {
      debugPrint('[CreateBooking] first item: ${request.items.first}');

      final itemsToInsert = request.items.map((item) => {
        'booking_id': booking['id'],
        'treatment_duration_id': item.treatmentDurationId,
        'treatment_snapshot': {
          'treatment_name': item.treatmentName,
          'duration_minutes': item.durationMinutes,
          'price': item.unitPrice,
        },
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'subtotal': item.unitPrice * item.quantity,
      }).toList();

      debugPrint('[CreateBooking] items to insert: $itemsToInsert');

      try {
        await _client.from('booking_items').insert(itemsToInsert);
        debugPrint('[CreateBooking] items insert done');
      } catch (e) {
        debugPrint('[CreateBooking] booking_items insert ERROR: $e');
      }
    } else {
      debugPrint('[CreateBooking] WARNING: no items in request, skipping booking_items insert');
    }

    // Insert booking_addons
    debugPrint('[CreateBooking] cart addons count: ${request.addons.length}');

    if (request.addons.isNotEmpty) {
      final addonsToInsert = request.addons.map((addon) => {
        'booking_id': booking['id'],
        'addon_id': addon.addonId,
        'addon_snapshot': {
          'addon_name': addon.addonName,
          'price': addon.unitPrice,
        },
        'quantity': addon.quantity,
        'unit_price': addon.unitPrice,
        'subtotal': addon.unitPrice * addon.quantity,
      }).toList();

      debugPrint('[CreateBooking] addons to insert: $addonsToInsert');

      try {
        await _client.from('booking_addons').insert(addonsToInsert);
        debugPrint('[CreateBooking] addons insert done');
      } catch (e) {
        debugPrint('[CreateBooking] booking_addons insert ERROR: $e');
      }
    }

    // Handle free reward: insert free treatment as a booking_item and mark redemption used
    debugPrint('[FreeReward] reached free reward block — freeRewardId: $freeRewardId');
    if (freeRewardId != null) {
      debugPrint('[FreeReward] freeRewardId is NOT null — proceeding with insert');

      // Look up the real treatment name from Supabase
      String treatmentName = 'Free Treatment';
      if (freeRewardTreatmentId != null) {
        try {
          final treatment = await _client
              .from('treatments')
              .select('name')
              .eq('id', freeRewardTreatmentId)
              .single();
          treatmentName = (treatment['name'] as String?) ?? treatmentName;
          debugPrint('[FreeReward] treatment name resolved: $treatmentName');
        } catch (e) {
          debugPrint('[FreeReward] treatment name lookup ERROR: $e');
        }
      } else {
        debugPrint('[FreeReward] freeRewardTreatmentId is null — using fallback name');
      }

      // Insert free treatment as a booking_item with price 0
      final freeDurationMinutes = request.freeRewardDurationMinutes ?? 0;
      debugPrint('[FreeReward] inserting booking_item for: $treatmentName ($freeDurationMinutes min)');
      try {
        final insertResult = await _client.from('booking_items').insert({
          'booking_id': booking['id'],
          'treatment_duration_id': null,
          'treatment_snapshot': {
            'treatment_name': treatmentName,
            'duration_minutes': freeDurationMinutes,
            'price': 0,
          },
          'quantity': 1,
          'unit_price': 0,
          'subtotal': 0,
        }).select();
        debugPrint('[FreeReward] insert result: $insertResult');
      } catch (e) {
        debugPrint('[FreeReward] booking_item insert ERROR: $e');
      }

      // Mark reward redemption as used
      try {
        await _client
            .from('reward_redemptions')
            .update({
              'is_used': true,
              'used_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', freeRewardId);
        debugPrint('[FreeReward] reward_redemption $freeRewardId marked used');
      } catch (e) {
        debugPrint('[FreeReward] reward_redemption update ERROR: $e');
      }
    } else {
      debugPrint('[FreeReward] freeRewardId IS null — skipping free item insert');
    }

    // Mark discount reward redemption as used after booking is confirmed.
    if (discountRedemptionId != null) {
      try {
        await _client
            .from('reward_redemptions')
            .update({
              'is_used': true,
              'used_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', discountRedemptionId);
        debugPrint('[DiscountReward] redemption $discountRedemptionId marked used');
      } catch (e) {
        debugPrint('[DiscountReward] redemption update ERROR: $e');
      }
    }

    return booking['id'] as String;
  }

  @override
  Future<List<BookingRecord>> getBookingHistory() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // 1. Fetch all bookings for this user
    final rows = await _client
        .from('bookings')
        .select()
        .eq('client_id', userId)
        .order('scheduled_at', ascending: false);

    if (rows.isEmpty) return [];

    // 2. Resolve therapist names (flat query, only if any booking has one)
    final therapistIds = rows
        .where((r) => r['therapist_id'] != null)
        .map((r) => r['therapist_id'] as String)
        .toSet()
        .toList();
    final Map<String, String> therapistMap = {};
    if (therapistIds.isNotEmpty) {
      final therapistRows = await _client
          .from('therapist_profiles')
          .select('id, name')
          .inFilter('id', therapistIds);
      for (final t in therapistRows) {
        therapistMap[t['id'] as String] = t['name'] as String;
      }
    }

    // 3. Assemble (bookings table has no treatment_id; use generic name)
    return rows.map((r) {
      final tid = r['therapist_id'] as String?;
      return BookingRecordModel.fromJson(
        r,
        treatmentName: 'Kaizen Spa Service',
        therapistName: tid != null ? therapistMap[tid] : null,
      );
    }).toList();
  }
}
