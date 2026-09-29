import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Therapist shown in the chat header, plus the booking's status.
class ChatBookingInfo {
  final String? therapistId;
  final String therapistName;
  final String? therapistAvatarUrl;
  final String status;

  const ChatBookingInfo({
    required this.therapistId,
    required this.therapistName,
    required this.therapistAvatarUrl,
    required this.status,
  });
}

/// Booking status + therapist profile (flat queries, assembled in Dart).
final chatBookingInfoProvider = FutureProvider.autoDispose
    .family<ChatBookingInfo, String>((ref, bookingId) async {
      final client = Supabase.instance.client;
      final booking = await client
          .from('bookings')
          .select('status, therapist_id')
          .eq('id', bookingId)
          .single();
      final therapistId = booking['therapist_id'] as String?;

      String name = 'Therapist';
      String? avatarUrl;
      if (therapistId != null) {
        final profile = await client
            .from('profiles')
            .select('full_name, avatar_url')
            .eq('id', therapistId)
            .maybeSingle();
        name = (profile?['full_name'] as String?)?.trim().isNotEmpty == true
            ? profile!['full_name'] as String
            : name;
        avatarUrl = profile?['avatar_url'] as String?;
      }
      return ChatBookingInfo(
        therapistId: therapistId,
        therapistName: name,
        therapistAvatarUrl: avatarUrl,
        status: booking['status'] as String? ?? 'pending',
      );
    });

/// Messages from the therapist the client hasn't read yet, for the badge on
/// the booking's chat button. Live via Supabase Realtime (inserts and the
/// read_at updates the chat page makes).
final chatUnreadCountProvider = StreamProvider.autoDispose.family<int, String>((
  ref,
  bookingId,
) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Stream.value(0);
  return Supabase.instance.client
      .from('chat_messages')
      .stream(primaryKey: ['id'])
      .eq('booking_id', bookingId)
      .map((rows) {
        final unread = rows
            .where((r) => r['sender_id'] != userId && r['read_at'] == null)
            .length;
        debugPrint('[Chat] $bookingId unread: $unread');
        return unread;
      });
});
