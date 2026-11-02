import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/api/auth_session.dart';
import 'core/services/notification_service.dart';
import 'core/storage/app_prefs.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background FCM message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Saved appearance / language (defaults: dark, English) + locale data.
  await AppPrefs.init();
  await initializeDateFormatting();

  // Push is best-effort: on iOS, Firebase throws until the iOS app is
  // registered (GoogleService-Info.plist) — the app must still launch.
  var firebaseReady = false;
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      firebaseReady = true;
    } catch (e) {
      debugPrint('Firebase unavailable, push disabled: $e');
    }
  }

  await AuthSession.load();

  if (firebaseReady && AuthSession.current != null) {
    await NotificationService.init();
  }

  runApp(const ProviderScope(child: App()));
}
