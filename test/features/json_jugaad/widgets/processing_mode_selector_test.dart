import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/models/processing_mode.dart';
import 'package:jugaadkit/features/json_jugaad/widgets/processing_mode_selector.dart';

void main() {
  group('ProcessingMode search', () {
    test('matches label and keywords', () {
      expect(ProcessingMode.cookie.matchesSearch('cookie'), isTrue);
      expect(ProcessingMode.authorization.matchesSearch('bearer'), isTrue);
      expect(ProcessingMode.httpError.matchesSearch('dio'), isTrue);
      expect(ProcessingMode.json.matchesSearch('yaml'), isFalse);
    });

    test('empty query matches all modes', () {
      for (final mode in ProcessingModeLabel.selectableModes) {
        expect(mode.matchesSearch(''), isTrue);
      }
    });
  });

  group('ProcessingModeSelector', () {
    testWidgets('opens searchable picker and filters modes', (tester) async {
      var selected = ProcessingMode.auto;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProcessingModeSelector(
              selectedMode: selected,
              onModeChanged: (mode) => selected = mode,
            ),
          ),
        ),
      );

      await tester.tap(find.text('✨ Auto'));
      await tester.pumpAndSettle();

      expect(find.text('Search modes...'), findsOneWidget);
      expect(find.text('✨ Auto'), findsWidgets);
      expect(find.text('JSON'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'cookie');
      await tester.pump();

      expect(find.text('Cookie'), findsOneWidget);
      expect(find.text('JSON'), findsNothing);

      await tester.tap(find.text('Cookie'));
      await tester.pumpAndSettle();

      expect(selected, ProcessingMode.cookie);
      expect(find.text('Search modes...'), findsNothing);
    });
  });
}
