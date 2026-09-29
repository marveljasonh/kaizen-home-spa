import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/api/auth_session.dart';
import 'core/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background FCM message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Supabase stays only for features not yet migrated to the platform API;
  // auth/session is the platform's (AuthSession).
  await Supabase.initialize(
    url: 'https://zxiofkulrvjtpusgzoei.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp4aW9ma3VscnZqdHB1c2d6b2VpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExNjQ3ODAsImV4cCI6MjA5Njc0MDc4MH0.7-0OQtBE_Uf3eGIiMYN_baqugLHqwEK0aqIC5uH7cJ0',
  );

  await AuthSession.load();

  if (!kIsWeb && AuthSession.current != null) {
    await NotificationService.init();
  }

  runApp(const ProviderScope(child: App()));
}
