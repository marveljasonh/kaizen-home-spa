import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    if (kIsWeb) return;

    // Request permission (Android 13+ / iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Get token and persist to Supabase
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }

    // Refresh token whenever FCM rotates it
    _messaging.onTokenRefresh.listen(_saveToken);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        'FCM foreground: ${message.notification?.title} — ${message.notification?.body}',
      );
    });
  }

  static Future<void> _saveToken(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);
      debugPrint('FCM token saved for $userId');
    } catch (e) {
      debugPrint('FCM token save failed: $e');
    }
  }
}
