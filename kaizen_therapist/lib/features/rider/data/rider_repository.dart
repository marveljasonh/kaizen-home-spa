import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/timezone_helper.dart';
import '../../../shared/models/rider_assignment.dart';
import '../../../shared/models/rider_profile.dart';

// Run this in Supabase SQL editor to create the required table:
//
// CREATE TABLE rider_assignments (
//   id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
//   rider_id uuid REFERENCES profiles(id),
//   booking_id uuid REFERENCES bookings(id),
//   status text DEFAULT 'assigned',
//   assigned_at timestamptz DEFAULT now(),
//   updated_at timestamptz DEFAULT now()
// );
// ALTER TABLE rider_assignments ENABLE ROW LEVEL SECURITY;
//
// Suggested RLS policy (riders see only their own rows):
// CREATE POLICY "Riders can view their own assignments"
//   ON rider_assignments FOR SELECT
//   USING (rider_id = auth.uid());
//
// CREATE POLICY "Riders can update their own assignments"
//   ON rider_assignments FOR UPDATE
//   USING (rider_id = auth.uid());

class RiderRepository {
  final SupabaseClient _client;

  RiderRepository(this._client);

  Future<RiderProfile?> getRiderProfile(String userId) async {
    try {
      final profile = await _client
          .from('profiles')
          .select('id, full_name')
          .eq('id', userId)
          .single();

      // Availability: locked when there's a non-completed active assignment
      final active = await _client
          .from('rider_assignments')
          .select('id')
          .eq('rider_id', userId)
          .filter('status', 'in', '(assigned,on_the_way,arrived)')
          .limit(1)
          .maybeSingle();

      return RiderProfile(
        id: profile['id'] as String,
        userId: userId,
        name: profile['full_name'] as String? ?? 'Rider',
        email: _client.auth.currentUser?.email ?? '',
        isAvailable: active == null,
        currentAssignmentId: active?['id'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<RiderAssignment>> getTodayAssignments(String riderId) async {
    try {
      final rows = await _client
          .from('rider_assignments')
          .select('*, bookings(id, scheduled_at, address_snapshot, notes)')
          .eq('rider_id', riderId)
          .gte('assigned_at', WIB.startOfTodayUTC().toIso8601String())
          .lt('assigned_at', WIB.endOfTodayUTC().toIso8601String())
          .order('assigned_at', ascending: false);

      return rows.map((r) => RiderAssignment.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<RiderAssignment?> getAssignment(String assignmentId) async {
    try {
      // Step 1: fetch assignment + booking fields including therapist_id
      final raw = await _client
          .from('rider_assignments')
          .select(
            '*, bookings(id, scheduled_at, address_snapshot, notes, client_id, therapist_id)',
          )
          .eq('id', assignmentId)
          .single();

      final row = Map<String, dynamic>.from(raw);
      final booking = row['bookings'] as Map<String, dynamic>? ?? {};
      final therapistId = booking['therapist_id'] as String?;
      debugPrint('[Rider] therapist_id from booking: $therapistId');

      // Step 2a: try therapist_profiles keyed by profile_id
      if (therapistId != null) {
        try {
          final therapist = await _client
              .from('therapist_profiles')
              .select('profile_id, profiles(full_name, phone)')
              .eq('profile_id', therapistId)
              .maybeSingle();
          debugPrint('[Rider] therapist_profiles result: $therapist');
          if (therapist != null) {
            final profile = therapist['profiles'] as Map<String, dynamic>?;
            row['__therapist_name'] = profile?['full_name'];
            row['__therapist_phone'] = profile?['phone'];
            debugPrint('[Rider] therapist name: ${row['__therapist_name']}');
            debugPrint('[Rider] therapist phone: ${row['__therapist_phone']}');
          }
        } catch (e) {
          debugPrint('[Rider] therapist_profiles error: $e');
        }

        // Step 2b: fallback — therapist_id IS a profiles.id directly
        if (row['__therapist_name'] == null) {
          try {
            final profile = await _client
                .from('profiles')
                .select('full_name, phone')
                .eq('id', therapistId)
                .maybeSingle();
            debugPrint('[Rider] profiles fallback result: $profile');
            if (profile != null) {
              row['__therapist_name'] = profile['full_name'];
              row['__therapist_phone'] = profile['phone'];
              debugPrint('[Rider] therapist name (fallback): ${row['__therapist_name']}');
              debugPrint('[Rider] therapist phone (fallback): ${row['__therapist_phone']}');
            }
          } catch (e) {
            debugPrint('[Rider] profiles fallback error: $e');
          }
        }
      }

      return RiderAssignment.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  Future<List<RiderAssignment>> getUpcomingAssignments(String riderId) async {
    try {
      final rows = await _client
          .from('rider_assignments')
          .select('*, bookings(id, scheduled_at, address_snapshot, notes, status)')
          .eq('rider_id', riderId)
          .not('status', 'in', '("completed","cancelled")')
          .order('assigned_at', ascending: true);
      return rows.map((r) => RiderAssignment.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<RiderAssignment>> getActiveAssignments(String riderId) async {
    try {
      final rows = await _client
          .from('rider_assignments')
          .select('*, bookings(id, scheduled_at, address_snapshot, notes, status)')
          .eq('rider_id', riderId)
          .not('status', 'in', '("completed","cancelled")')
          .order('assigned_at', ascending: true);
      return rows.map((r) => RiderAssignment.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<RiderAssignment>> getCompletedAssignments(String riderId) async {
    try {
      final rows = await _client
          .from('rider_assignments')
          .select('*, bookings(id, scheduled_at, address_snapshot, notes, status)')
          .eq('rider_id', riderId)
          .eq('status', 'completed')
          .order('updated_at', ascending: false);
      return rows.map((r) => RiderAssignment.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<RiderAssignment>> getPastAssignments(String riderId) async {
    try {
      final rows = await _client
          .from('rider_assignments')
          .select('*, bookings(id, scheduled_at, address_snapshot, notes, status)')
          .eq('rider_id', riderId)
          .eq('status', 'completed')
          .order('updated_at', ascending: false);
      return rows.map((r) => RiderAssignment.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<RiderAssignment?> getAssignmentWithTherapist(String assignmentId) async {
    try {
      final raw = await _client
          .from('rider_assignments')
          .select('*, bookings(id, scheduled_at, address_snapshot, notes, therapist_id)')
          .eq('id', assignmentId)
          .single();

      final row = Map<String, dynamic>.from(raw);
      final booking = row['bookings'] as Map<String, dynamic>? ?? {};
      final therapistId = booking['therapist_id'] as String?;

      if (therapistId != null) {
        try {
          final p = await _client
              .from('profiles')
              .select('full_name, phone')
              .eq('id', therapistId)
              .single();
          row['__therapist_name'] = p['full_name'];
          row['__therapist_phone'] = p['phone'];
        } catch (_) {}
      }

      return RiderAssignment.fromJson(row);
    } catch (_) {
      return null;
    }
  }

}
