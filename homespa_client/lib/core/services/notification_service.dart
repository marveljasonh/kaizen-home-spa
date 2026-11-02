import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

import '../api/api_client.dart';
import '../api/auth_session.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;

  // Set via --dart-define=SCREENSHOT_MODE=true for store-screenshot drives:
  // skips the permission request so no native dialog covers the UI.
  static const _screenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

  static Future<void> init() async {
    // No-op until Firebase is configured for this platform (iOS needs
    // GoogleService-Info.plist) — push is best-effort, never a crash.
    if (kIsWeb || Firebase.apps.isEmpty || _screenshotMode) return;

    // Request permission (Android 13+ / iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Get token and register it with the platform API
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
    if (AuthSession.current == null) return;

    try {
      await apiClient.post(
        '/push-token',
        body: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      );
      debugPrint('FCM token registered');
    } catch (e) {
      debugPrint('FCM token save failed: $e');
    }
  }
}
