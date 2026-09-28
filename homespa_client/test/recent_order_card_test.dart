import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homespa_client/features/booking/domain/entities/order_summary.dart';
import 'package:homespa_client/features/home/presentation/pages/home_page.dart';
import 'package:homespa_client/features/home/presentation/providers/home_providers.dart';

final _order = OrderSummary(
  id: 'c49832b3-0000-0000-0000-000000000000',
  scheduledAt: DateTime.utc(2026, 7, 2, 15),
  createdAt: DateTime.utc(2026, 7, 1),
  status: 'completed',
  items: const [
    OrderSummaryItem(
      treatmentDurationId: null,
      treatmentId: null,
      treatmentName: 'Full Body Massage',
      durationMinutes: 60,
      quantity: 1,
    ),
    OrderSummaryItem(
      treatmentDurationId: null,
      treatmentId: null,
      treatmentName: 'Reflexology',
      durationMinutes: 60,
      quantity: 1,
    ),
  ],
  address: 'Jl. Kemang Raya',
  total: 175000,
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late List<String> visited;

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(402, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    visited = [];

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        GoRoute(
          path: '/bookings/:id',
          builder: (_, state) {
            visited.add(state.uri.path);
            return const Scaffold(body: Text('booking detail'));
          },
        ),
        GoRoute(
          path: '/booking/cart',
          builder: (_, state) {
            visited.add(state.uri.path);
            return const Scaffold(body: Text('cart'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          popularTreatmentsProvider.overrideWith((ref) async => []),
          recentOrdersProvider.overrideWith((ref) async => [_order]),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('title uses "+N" in the text, not a separate badge', (
    tester,
  ) async {
    await pumpHome(tester);
    expect(find.text('Full Body Massage +1'), findsOneWidget);
    expect(find.text('# C49832B3'), findsOneWidget);
    expect(find.text('Total Price'), findsOneWidget);
    expect(find.text('IDR 175K'), findsOneWidget);
    expect(find.text('View Details'), findsNothing);
  });

  testWidgets('tapping the card opens booking detail', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('Full Body Massage +1'));
    await tester.pumpAndSettle();
    expect(visited, ['/bookings/${_order.id}']);
  });

  testWidgets('⋮ opens the support sheet without navigating', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.bySemanticsLabel('Order options'));
    await tester.pumpAndSettle();
    expect(find.text('Request Help'), findsOneWidget);
    expect(find.text('Report an Issue'), findsOneWidget);
    expect(visited, isEmpty);
  });

  testWidgets('Re-Order does not open booking detail', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('Re-Order'));
    await tester.pumpAndSettle();
    expect(visited.where((p) => p.startsWith('/bookings/')), isEmpty);
  });
}
