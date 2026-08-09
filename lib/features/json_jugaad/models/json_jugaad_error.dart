import 'transformation_step.dart';

class JsonJugaadError implements Exception {
  const JsonJugaadError({
    required this.message,
    this.detail,
    this.partialSteps = const [],
    this.lastAttempt,
  });

  final String message;
  final String? detail;
  final List<TransformationStep> partialSteps;
  final String? lastAttempt;

  @override
  String toString() => message;
}
