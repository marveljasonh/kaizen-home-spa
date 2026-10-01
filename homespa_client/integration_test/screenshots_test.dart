// Captures App Store screenshots by driving the real app against production
// with the reviewer demo account. Run:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshots_test.dart -d <simulator> \
//     --dart-define=DEMO_PASSWORD=...
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:homespa_client/main.dart' as app;

/// Signals the host to take a native `simctl io screenshot` by dropping a
/// marker file in the app sandbox, then holds the UI still while it shoots.
Future<void> hostShot(WidgetTester tester, String name) async {
  File('${Directory.systemTemp.path}/shot-$name.marker').createSync(recursive: true);
  await tester.pump(const Duration(seconds: 5));
}

const _demoPhone = String.fromEnvironment('DEMO_PHONE', defaultValue: '08000000002');
const _demoPassword = String.fromEnvironment('DEMO_PASSWORD');

Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 300));
    if (done()) return;
  }
  throw StateError('timed out');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture store screenshots', (tester) async {
    app.main();
    // Either the login page ("SIGN IN" — KaizenPrimaryButton uppercases its
    // label) or, when a previous session persisted in the keychain, home.
    await pumpUntil(tester, () =>
        find.text('SIGN IN').evaluate().isNotEmpty ||
        find.text('Popular Treatment').evaluate().isNotEmpty);

    if (find.text('SIGN IN').evaluate().isNotEmpty) {
      await tester.enterText(find.byType(TextFormField).first, _demoPhone);
      await tester.enterText(find.byType(TextFormField).last, _demoPassword);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('SIGN IN'));
    }

    // Wait until the login page is gone, then until home content has
    // actually rendered (treatment cards load images from the network).
    await pumpUntil(tester, () => find.text('SIGN IN').evaluate().isEmpty);
    await pumpUntil(tester, () => find.text('Popular Treatment').evaluate().isNotEmpty);
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    await tester.pump(const Duration(seconds: 2));
    await hostShot(tester, '01-home');

    // Bottom nav is icon-only; tap by position. 5 evenly spaced slots.
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    final navY = size.height - 40;
    Future<void> gotoTab(int i) async {
      await tester.tapAt(Offset(size.width * (2 * i + 1) / 10, navY));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
      await tester.pump(const Duration(seconds: 1));
    }

    await gotoTab(1);
    await hostShot(tester, '02-treatments');

    await gotoTab(2);
    await hostShot(tester, '03-bookings');

    await gotoTab(3);
    await hostShot(tester, '04-promo');
  });
}
