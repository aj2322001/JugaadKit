import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/app.dart';

void main() {
  testWidgets('JugaadKit home lists Data Jugaad tool', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const JugaadKitApp());
    await tester.pumpAndSettle();

    expect(find.text('JugaadKit'), findsOneWidget);
    expect(find.text('Data Jugaad'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
  });

  testWidgets('Data Jugaad renders at /data_jugaad', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const JugaadKitApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Data Jugaad'));
    await tester.pumpAndSettle();

    expect(find.text('Input'), findsOneWidget);
    expect(find.text('Output'), findsOneWidget);
  });
}
