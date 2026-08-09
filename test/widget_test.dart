import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/app.dart';

void main() {
  testWidgets('JugaadKit home lists JSON Jugaad tool', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const JugaadKitApp());
    await tester.pumpAndSettle();

    expect(find.text('JugaadKit'), findsOneWidget);
    expect(find.text('JSON Jugaad'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
  });

  testWidgets('JSON Jugaad renders at /jsonParser', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const JugaadKitApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('JSON Jugaad'));
    await tester.pumpAndSettle();

    expect(find.text('Input'), findsOneWidget);
    expect(find.text('Output'), findsOneWidget);
  });
}
