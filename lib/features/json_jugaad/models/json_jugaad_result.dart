import 'dart:convert';

import '../engine/confidence.dart';
import '../engine/detected_format.dart';
import '../engine/detection_summary.dart';
import 'jugaad_output_type.dart';
import 'jugaad_structured_output.dart';
import 'processing_mode.dart';
import 'transformation_step.dart';

class JsonJugaadResult {
  const JsonJugaadResult({
    required this.parsedValue,
    required this.formattedJson,
    required this.steps,
    required this.transformCount,
    required this.originalInput,
    required this.detectedFormat,
    required this.confidence,
    required this.processingMode,
    required this.isAutomatic,
    required this.detectionSummary,
    required this.outputType,
    this.structuredOutput,
  });

  final Object? parsedValue;
  final String formattedJson;
  final List<TransformationStep> steps;
  final int transformCount;
  final String originalInput;
  final DetectedFormat detectedFormat;
  final Confidence confidence;
  final ProcessingMode processingMode;
  final bool isAutomatic;
  final String detectionSummary;
  final JugaadOutputType outputType;
  final JugaadStructuredOutput? structuredOutput;

  bool get isJsonOutput => outputType == JugaadOutputType.json;

  bool get hasStructuredOutput => structuredOutput != null;

  factory JsonJugaadResult.fromValue({
    required Object? value,
    required List<TransformationStep> steps,
    required int transformCount,
    required String originalInput,
    required DetectedFormat detectedFormat,
    required Confidence confidence,
    required ProcessingMode processingMode,
    required bool isAutomatic,
  }) {
    final summary = DetectionSummary.build(
      steps: steps,
      detectedFormat: detectedFormat,
      processingMode: processingMode,
      isAutomatic: isAutomatic,
    );

    return JsonJugaadResult(
      parsedValue: value,
      formattedJson: const JsonEncoder.withIndent('  ').convert(value),
      steps: List.unmodifiable(steps),
      transformCount: transformCount,
      originalInput: originalInput,
      detectedFormat: detectedFormat,
      confidence: confidence,
      processingMode: processingMode,
      isAutomatic: isAutomatic,
      detectionSummary: summary,
      outputType: JugaadOutputType.json,
    );
  }

  factory JsonJugaadResult.fromStructured({
    required String text,
    required JugaadStructuredOutput structuredOutput,
    required List<TransformationStep> steps,
    required int transformCount,
    required String originalInput,
    required DetectedFormat detectedFormat,
    required Confidence confidence,
    required ProcessingMode processingMode,
    required bool isAutomatic,
  }) {
    final summary = DetectionSummary.build(
      steps: steps,
      detectedFormat: detectedFormat,
      processingMode: processingMode,
      isAutomatic: isAutomatic,
    );

    return JsonJugaadResult(
      parsedValue: null,
      formattedJson: text,
      steps: List.unmodifiable(steps),
      transformCount: transformCount,
      originalInput: originalInput,
      detectedFormat: detectedFormat,
      confidence: confidence,
      processingMode: processingMode,
      isAutomatic: isAutomatic,
      detectionSummary: summary,
      outputType: JugaadOutputType.text,
      structuredOutput: structuredOutput,
    );
  }

  factory JsonJugaadResult.fromText({
    required String text,
    required List<TransformationStep> steps,
    required int transformCount,
    required String originalInput,
    required DetectedFormat detectedFormat,
    required Confidence confidence,
    required ProcessingMode processingMode,
    required bool isAutomatic,
  }) {
    final summary = DetectionSummary.build(
      steps: steps,
      detectedFormat: detectedFormat,
      processingMode: processingMode,
      isAutomatic: isAutomatic,
    );

    return JsonJugaadResult(
      parsedValue: null,
      formattedJson: text,
      steps: List.unmodifiable(steps),
      transformCount: transformCount,
      originalInput: originalInput,
      detectedFormat: detectedFormat,
      confidence: confidence,
      processingMode: processingMode,
      isAutomatic: isAutomatic,
      detectionSummary: summary,
      outputType: JugaadOutputType.text,
    );
  }
}
