import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/app.dart';

void main() {
  testWidgets('JugaadKit app renders JSON Jugaad', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const JugaadKitApp());

    expect(find.text('JugaadKit'), findsOneWidget);
    expect(find.text('JSON Jugaad'), findsOneWidget);
    expect(find.text('Input'), findsOneWidget);
    expect(find.text('Output'), findsOneWidget);
  });
}
