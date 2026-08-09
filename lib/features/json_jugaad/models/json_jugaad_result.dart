import 'dart:convert';

import 'transformation_step.dart';

class JsonJugaadResult {
  const JsonJugaadResult({
    required this.parsedValue,
    required this.formattedJson,
    required this.steps,
    required this.transformCount,
  });

  final Object? parsedValue;
  final String formattedJson;
  final List<TransformationStep> steps;
  final int transformCount;

  factory JsonJugaadResult.fromValue({
    required Object? value,
    required List<TransformationStep> steps,
    required int transformCount,
  }) {
    return JsonJugaadResult(
      parsedValue: value,
      formattedJson: const JsonEncoder.withIndent('  ').convert(value),
      steps: List.unmodifiable(steps),
      transformCount: transformCount,
    );
  }
}
