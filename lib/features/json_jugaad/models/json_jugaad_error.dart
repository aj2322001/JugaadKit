import '../engine/confidence.dart';
import '../engine/detected_format.dart';
import 'processing_mode.dart';
import 'transformation_step.dart';

class JsonJugaadError implements Exception {
  const JsonJugaadError({
    required this.message,
    this.detail,
    this.partialSteps = const [],
    this.lastAttempt,
    this.originalInput,
    this.detectedFormat = DetectedFormat.unknown,
    this.confidence = Confidence.none,
    this.processingMode = ProcessingMode.auto,
    this.isAutomatic = true,
    this.isAmbiguousAutoFailure = false,
    this.suggestedModes = const [],
  });

  final String message;
  final String? detail;
  final List<TransformationStep> partialSteps;
  final String? lastAttempt;
  final String? originalInput;
  final DetectedFormat detectedFormat;
  final Confidence confidence;
  final ProcessingMode processingMode;
  final bool isAutomatic;
  final bool isAmbiguousAutoFailure;
  final List<ProcessingMode> suggestedModes;

  @override
  String toString() => message;
}
