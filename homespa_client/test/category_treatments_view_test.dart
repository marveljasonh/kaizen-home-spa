import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homespa_client/features/treatments/domain/entities/treatment.dart';
import 'package:homespa_client/features/treatments/domain/entities/treatment_category.dart';
import 'package:homespa_client/features/treatments/domain/entities/treatment_duration.dart';
import 'package:homespa_client/features/treatments/presentation/providers/treatments_providers.dart';
import 'package:homespa_client/features/treatments/presentation/widgets/category_treatments_view.dart';

Treatment _t(String name, String description, double price) => Treatment(
  id: name,
  name: name,
  description: description,
  categoryId: 'massage',
  categoryName: 'Massage',
  basePrice: price,
  rating: 5,
  reviewCount: 0,
  durations: [
    TreatmentDuration(
      id: '$name-60',
      treatmentId: name,
      durationMinutes: 60,
      price: price,
    ),
  ],
);

final _treatments = [
  _t(
    'Full Body Massage',
    'A relaxing treatment to relieve muscle tension and refresh your body '
        'from head to toe.',
    175000,
  ),
  _t(
    'Back & Shoulder Massage',
    'Focused massage on back and shoulder areas.',
    120000,
  ),
  _t(
    'Traditional Balinese Deep Tissue Aromatherapy Massage',
    'An extra long description that keeps going to make sure the text '
        'is clamped to two lines instead of spilling out of the card area.',
    1250000,
  ),
];

void main() {
  // No network in tests: fonts fall back instead of being downloaded.
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final width in [320.0, 360.0, 402.0]) {
    testWidgets('treatment cards fit at ${width.toInt()}px wide', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            treatmentsProvider.overrideWith((ref, _) async => _treatments),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CategoryTreatmentsView(
                category: const TreatmentCategory(
                  id: 'massage',
                  name: 'Massage',
                ),
                categoryId: 'massage',
                onBack: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Any RenderFlex/Text overflow is reported as a test exception.
      expect(tester.takeException(), isNull);
      for (final t in _treatments) {
        expect(find.text(t.name), findsOneWidget);
        final text = tester.getRect(find.text(t.name));
        final card = tester.getRect(
          find
              .ancestor(of: find.text(t.name), matching: find.byType(Stack))
              .first,
        );
        // Name stays inside the card with at least 16px on both sides.
        expect(text.left - card.left, greaterThanOrEqualTo(16));
        expect(card.right - text.right, greaterThanOrEqualTo(16));
      }
    });
  }
}
