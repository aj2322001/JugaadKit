import 'dart:convert';

import 'package:jugaadkit/features/json_jugaad/constants/json_jugaad_constants.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_error.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_result.dart';
import 'package:jugaadkit/features/json_jugaad/models/processing_mode.dart';
import 'package:jugaadkit/features/json_jugaad/models/transformation_step.dart';

import 'base64_codec.dart';
import 'confidence.dart';
import 'detected_format.dart';
import 'format_codecs.dart';
import 'hex_codec.dart';
import 'html_entity_codec.dart';
import 'jwt_codec.dart';
import 'jugaad_validator.dart';
import 'processing_mode_suggestions.dart';
import 'text_preview.dart';

class _TransformCandidate {
  const _TransformCandidate({
    required this.output,
    required this.step,
    required this.format,
    required this.confidence,
  });

  final String output;
  final TransformationStep step;
  final DetectedFormat format;
  final Confidence confidence;
}

/// Deterministic client-side data inspection and transformation engine.
class JugaadEngine {
  const JugaadEngine({
    CompressedPayloadDecoder compressedDecoder =
        const UnsupportedCompressedPayloadDecoder(),
  }) : _compressedDecoder = compressedDecoder;

  final CompressedPayloadDecoder _compressedDecoder;

  JsonJugaadResult processAuto(String rawInput) {
    try {
      return process(
        rawInput,
        processingMode: ProcessingMode.auto,
        isAutomatic: true,
      );
    } on JsonJugaadError catch (error) {
      if (!error.isAutomatic || error.isAmbiguousAutoFailure) {
        rethrow;
      }
      if (!_shouldWrapAsAmbiguousAutoFailure(error)) {
        rethrow;
      }
      throw JsonJugaadError(
        message: "Couldn't confidently identify this input.",
        detail: error.detail,
        partialSteps: error.partialSteps,
        lastAttempt: error.lastAttempt,
        originalInput: error.originalInput ?? rawInput,
        detectedFormat: error.detectedFormat,
        confidence: error.confidence,
        processingMode: ProcessingMode.auto,
        isAutomatic: true,
        isAmbiguousAutoFailure: true,
        suggestedModes: ProcessingModeSuggestions.forInput(rawInput),
      );
    }
  }

  JsonJugaadResult process(
    String rawInput, {
    ProcessingMode processingMode = ProcessingMode.auto,
    bool isAutomatic = true,
  }) {
    final originalInput = rawInput;
    final steps = <TransformationStep>[];
    var current = rawInput;
    var transformCount = 0;
    var detectedFormat = DetectedFormat.unknown;
    var confidence = Confidence.none;

    if (current.trim().isEmpty) {
      throw JsonJugaadError(
        message: 'Input is empty.',
        processingMode: processingMode,
        isAutomatic: isAutomatic,
      );
    }

    final normalized = current.trim();
    if (normalized != current) {
      steps.add(
        const TransformationStep(
          type: TransformationType.normalized,
          description: 'Trimmed leading and trailing whitespace',
        ),
      );
      current = normalized;
      transformCount++;
    }

    final jwt = JwtCodec.tryDecode(current);
    if (jwt != null) {
      steps.add(
        const TransformationStep(
          type: TransformationType.detectedJwt,
          description: 'Detected JWT and decoded header/payload',
          detail: 'Signature was not verified',
        ),
      );
      return JsonJugaadResult.fromValue(
        value: JwtCodec.toDisplayMap(jwt),
        steps: steps,
        transformCount: transformCount + 1,
        originalInput: originalInput,
        detectedFormat: DetectedFormat.jwt,
        confidence: jwt.confidence,
        processingMode: processingMode,
        isAutomatic: isAutomatic,
      );
    }

    if (JugaadValidator.looksLikeNdjsonAttempt(current) &&
        NdjsonCodec.tryParse(current) == null) {
      throw JsonJugaadError(
        message: 'Input looks like JSON Lines / NDJSON but contains invalid lines.',
        detail: 'Each non-empty line must be valid JSON.',
        partialSteps: List.unmodifiable(steps),
        lastAttempt: previewText(current),
        originalInput: originalInput,
        detectedFormat: DetectedFormat.ndjson,
        confidence: Confidence.medium,
        processingMode: processingMode,
        isAutomatic: isAutomatic,
      );
    }

    final ndjson = NdjsonCodec.tryParse(current);
    if (ndjson != null) {
      steps.add(
        TransformationStep(
          type: TransformationType.parsedNdjson,
          description:
              'Recognized JSON Lines / NDJSON (${ndjson.lines.length} lines)',
        ),
      );
      return JsonJugaadResult.fromValue(
        value: ndjson.lines,
        steps: steps,
        transformCount: transformCount + 1,
        originalInput: originalInput,
        detectedFormat: DetectedFormat.ndjson,
        confidence: Confidence.high,
        processingMode: processingMode,
        isAutomatic: isAutomatic,
      );
    }

    final queryString = QueryStringCodec.tryParse(current);
    if (queryString != null) {
      steps.add(
        const TransformationStep(
          type: TransformationType.parsedQueryString,
          description: 'Parsed query-string / form data',
        ),
      );
      final value = QueryStringCodec.toDisplayMap(queryString);
      return JsonJugaadResult.fromValue(
        value: value,
        steps: steps,
        transformCount: transformCount + 1,
        originalInput: originalInput,
        detectedFormat: DetectedFormat.queryString,
        confidence: Confidence.high,
        processingMode: processingMode,
        isAutomatic: isAutomatic,
      );
    }

    for (var i = 0; i < JsonJugaadConstants.maxTransformIterations; i++) {
      final parsed = JugaadValidator.tryParseJson(current);
      if (parsed != null) {
        final nested = _extractNestedJson(parsed.value, steps);
        if (nested.changed) {
          transformCount += nested.transformCount;
          detectedFormat = DetectedFormat.nestedJson;
          confidence = Confidence.high;
          return _buildJsonResult(
            value: nested.value,
            steps: steps,
            transformCount: transformCount,
            originalInput: originalInput,
            detectedFormat:
                detectedFormat == DetectedFormat.unknown ? DetectedFormat.json : detectedFormat,
            confidence: confidence == Confidence.none ? Confidence.high : confidence,
            hadPriorTransforms: transformCount > 0,
            processingMode: processingMode,
            isAutomatic: isAutomatic,
          );
        }

        detectedFormat = _resolveDetectedFormat(detectedFormat, steps);
        confidence = Confidence.high;
        return _buildJsonResult(
          value: parsed.value,
          steps: steps,
          transformCount: transformCount + 1,
          originalInput: originalInput,
          detectedFormat:
              detectedFormat == DetectedFormat.unknown ? DetectedFormat.json : detectedFormat,
          confidence: confidence,
          hadPriorTransforms: transformCount > 0,
          processingMode: processingMode,
          isAutomatic: isAutomatic,
        );
      }

      final candidate = _nextTransform(current);
      if (candidate == null) {
        break;
      }

      steps.add(candidate.step);
      current = candidate.output;
      transformCount++;
      if (detectedFormat == DetectedFormat.unknown) {
        detectedFormat = candidate.format;
        confidence = candidate.confidence;
      }
    }

    final lowConfidence = _detectLowConfidenceFormat(current);
    if (lowConfidence != null) {
      throw JsonJugaadError(
        message: 'Input looks like ${lowConfidence.label}, but could not be safely transformed.',
        detail: 'Confidence: ${Confidence.low.label}. No changes were applied.',
        partialSteps: List.unmodifiable(steps),
        lastAttempt: previewText(current),
        originalInput: originalInput,
        detectedFormat: lowConfidence,
        confidence: Confidence.low,
        processingMode: processingMode,
        isAutomatic: isAutomatic,
      );
    }

    throw JsonJugaadError(
      message: 'Unable to parse input as JSON.',
      detail: 'The input could not be transformed into valid JSON.',
      partialSteps: List.unmodifiable(steps),
      lastAttempt: previewText(current),
      originalInput: originalInput,
      detectedFormat: detectedFormat,
      confidence: confidence,
      processingMode: processingMode,
      isAutomatic: isAutomatic,
    );
  }

  JsonJugaadResult processManual(String rawInput, ProcessingMode mode) {
    if (mode == ProcessingMode.auto) {
      return processAuto(rawInput);
    }

    final originalInput = rawInput;
    final steps = <TransformationStep>[];
    var current = rawInput;
    var transformCount = 0;
    const isAutomatic = false;

    if (current.trim().isEmpty) {
      throw JsonJugaadError(
        message: 'Input is empty.',
        processingMode: mode,
        isAutomatic: isAutomatic,
      );
    }

    final normalized = current.trim();
    if (normalized != current) {
      steps.add(
        const TransformationStep(
          type: TransformationType.normalized,
          description: 'Trimmed leading and trailing whitespace',
        ),
      );
      current = normalized;
      transformCount++;
    }

    switch (mode) {
      case ProcessingMode.auto:
        return processAuto(rawInput);
      case ProcessingMode.jwt:
        return _processManualJwt(
          current: current,
          steps: steps,
          transformCount: transformCount,
          originalInput: originalInput,
          mode: mode,
        );
      case ProcessingMode.ndjson:
        return _processManualNdjson(
          current: current,
          steps: steps,
          transformCount: transformCount,
          originalInput: originalInput,
          mode: mode,
        );
      case ProcessingMode.json:
        return _finishManualJsonPipeline(
          current: current,
          steps: steps,
          transformCount: transformCount,
          originalInput: originalInput,
          processingMode: mode,
          primaryFormat: DetectedFormat.json,
        );
      case ProcessingMode.urlDecode:
        return _applyManualCodecTransform(
          current: current,
          steps: steps,
          transformCount: transformCount,
          originalInput: originalInput,
          mode: mode,
          candidate: _tryUrlDecode(current),
          primaryFormat: DetectedFormat.urlEncoded,
        );
      case ProcessingMode.base64:
        return _applyManualCodecTransform(
          current: current,
          steps: steps,
          transformCount: transformCount,
          originalInput: originalInput,
          mode: mode,
          candidate: _tryBase64(current),
          primaryFormat: DetectedFormat.base64,
        );
      case ProcessingMode.hex:
        return _applyManualCodecTransform(
          current: current,
          steps: steps,
          transformCount: transformCount,
          originalInput: originalInput,
          mode: mode,
          candidate: _tryHex(current),
          primaryFormat: DetectedFormat.hex,
        );
      case ProcessingMode.unicode:
        return _applyManualCodecTransform(
          current: current,
          steps: steps,
          transformCount: transformCount,
          originalInput: originalInput,
          mode: mode,
          candidate: _tryUnescapeJsonString(current),
          primaryFormat: DetectedFormat.escapedJson,
        );
      case ProcessingMode.htmlDecode:
        return _applyManualCodecTransform(
          current: current,
          steps: steps,
          transformCount: transformCount,
          originalInput: originalInput,
          mode: mode,
          candidate: _tryHtmlEntities(current),
          primaryFormat: DetectedFormat.htmlEntities,
        );
    }
  }

  JsonJugaadResult _processManualJwt({
    required String current,
    required List<TransformationStep> steps,
    required int transformCount,
    required String originalInput,
    required ProcessingMode mode,
  }) {
    final jwt = JwtCodec.tryDecode(current);
    if (jwt == null) {
      throw _manualFailure(
        mode: mode,
        originalInput: originalInput,
        steps: steps,
        lastAttempt: previewText(current),
      );
    }

    steps.add(
      const TransformationStep(
        type: TransformationType.detectedJwt,
        description: 'Decoded JWT header/payload',
        detail: 'Signature was not verified',
      ),
    );

    return JsonJugaadResult.fromValue(
      value: JwtCodec.toDisplayMap(jwt),
      steps: steps,
      transformCount: transformCount + 1,
      originalInput: originalInput,
      detectedFormat: DetectedFormat.jwt,
      confidence: jwt.confidence,
      processingMode: mode,
      isAutomatic: false,
    );
  }

  JsonJugaadResult _processManualNdjson({
    required String current,
    required List<TransformationStep> steps,
    required int transformCount,
    required String originalInput,
    required ProcessingMode mode,
  }) {
    final ndjson = NdjsonCodec.tryParse(current);
    if (ndjson == null) {
      throw _manualFailure(
        mode: mode,
        originalInput: originalInput,
        steps: steps,
        lastAttempt: previewText(current),
        message: 'Unable to parse this input as NDJSON.',
      );
    }

    steps.add(
      TransformationStep(
        type: TransformationType.parsedNdjson,
        description:
            'Parsed JSON Lines / NDJSON (${ndjson.lines.length} lines)',
      ),
    );

    return JsonJugaadResult.fromValue(
      value: ndjson.lines,
      steps: steps,
      transformCount: transformCount + 1,
      originalInput: originalInput,
      detectedFormat: DetectedFormat.ndjson,
      confidence: Confidence.high,
      processingMode: mode,
      isAutomatic: false,
    );
  }

  JsonJugaadResult _applyManualCodecTransform({
    required String current,
    required List<TransformationStep> steps,
    required int transformCount,
    required String originalInput,
    required ProcessingMode mode,
    required _TransformCandidate? candidate,
    required DetectedFormat primaryFormat,
  }) {
    if (candidate == null) {
      throw _manualFailure(
        mode: mode,
        originalInput: originalInput,
        steps: steps,
        lastAttempt: previewText(current),
      );
    }

    steps.add(candidate.step);
    return _finishManualJsonPipeline(
      current: candidate.output,
      steps: steps,
      transformCount: transformCount + 1,
      originalInput: originalInput,
      processingMode: mode,
      primaryFormat: primaryFormat,
    );
  }

  JsonJugaadResult _finishManualJsonPipeline({
    required String current,
    required List<TransformationStep> steps,
    required int transformCount,
    required String originalInput,
    required ProcessingMode processingMode,
    required DetectedFormat primaryFormat,
  }) {
    var working = current;
    var count = transformCount;
    var detectedFormat = primaryFormat;

    for (var i = 0; i < JsonJugaadConstants.maxTransformIterations; i++) {
      final parsed = JugaadValidator.tryParseJson(working);
      if (parsed != null) {
        final nested = _extractNestedJson(parsed.value, steps);
        if (nested.changed) {
          return _buildJsonResult(
            value: nested.value,
            steps: steps,
            transformCount: count + nested.transformCount,
            originalInput: originalInput,
            detectedFormat: DetectedFormat.nestedJson,
            confidence: Confidence.high,
            hadPriorTransforms: true,
            processingMode: processingMode,
            isAutomatic: false,
          );
        }

        return _buildJsonResult(
          value: parsed.value,
          steps: steps,
          transformCount: count + 1,
          originalInput: originalInput,
          detectedFormat: detectedFormat,
          confidence: Confidence.high,
          hadPriorTransforms: count > 0,
          processingMode: processingMode,
          isAutomatic: false,
        );
      }

      final candidate =
          _tryUnescapeJsonString(working) ?? _tryLooseJsonRepair(working);
      if (candidate == null) {
        break;
      }

      steps.add(candidate.step);
      working = candidate.output;
      count++;
    }

    throw _manualFailure(
      mode: processingMode,
      originalInput: originalInput,
      steps: steps,
      lastAttempt: previewText(working),
    );
  }

  JsonJugaadError _manualFailure({
    required ProcessingMode mode,
    required String originalInput,
    required List<TransformationStep> steps,
    String? lastAttempt,
    String? message,
  }) {
    return JsonJugaadError(
      message: message ?? _manualFailureMessage(mode),
      partialSteps: List.unmodifiable(steps),
      lastAttempt: lastAttempt,
      originalInput: originalInput,
      processingMode: mode,
      isAutomatic: false,
    );
  }

  String _manualFailureMessage(ProcessingMode mode) {
    return switch (mode) {
      ProcessingMode.base64 => 'Unable to decode this input as Base64.',
      ProcessingMode.urlDecode => 'Unable to decode this input as URL encoded data.',
      ProcessingMode.hex => 'Unable to decode this input as hexadecimal data.',
      ProcessingMode.unicode => 'Unable to decode this input as escaped Unicode/JSON text.',
      ProcessingMode.htmlDecode => 'Unable to decode this input as HTML entities.',
      ProcessingMode.jwt => 'Unable to decode this input as JWT.',
      ProcessingMode.ndjson => 'Unable to parse this input as NDJSON.',
      ProcessingMode.json => 'Unable to parse this input as JSON.',
      ProcessingMode.auto => 'Unable to process this input.',
    };
  }

  bool _shouldWrapAsAmbiguousAutoFailure(JsonJugaadError error) {
    if (error.partialSteps.any(
      (step) => step.type != TransformationType.normalized,
    )) {
      return false;
    }
    if (error.confidence == Confidence.low) {
      return true;
    }
    return error.message == 'Unable to parse input as JSON.' &&
        error.confidence == Confidence.none;
  }

  JsonJugaadResult _buildJsonResult({
    required Object? value,
    required List<TransformationStep> steps,
    required int transformCount,
    required String originalInput,
    required DetectedFormat detectedFormat,
    required Confidence confidence,
    required bool hadPriorTransforms,
    required ProcessingMode processingMode,
    required bool isAutomatic,
  }) {
    if (!steps.any((step) => step.type == TransformationType.parsedJson)) {
      steps.add(
        TransformationStep(
          type: TransformationType.parsedJson,
          description:
              hadPriorTransforms ? 'Parsed JSON successfully' : 'Parsed valid JSON',
        ),
      );
    }

    return JsonJugaadResult.fromValue(
      value: value,
      steps: steps,
      transformCount: transformCount,
      originalInput: originalInput,
      detectedFormat: detectedFormat,
      confidence: confidence,
      processingMode: processingMode,
      isAutomatic: isAutomatic,
    );
  }

  _TransformCandidate? _nextTransform(String input) {
    final candidates = <_TransformCandidate?>[
      _tryJsonp(input),
      _tryExtractFromText(input),
      _tryWrapper(input),
      _tryHtmlEntities(input),
      _tryUrlDecode(input),
      _tryBase64(input),
      _tryHex(input),
      _tryCompressed(input),
      _tryUnescapeJsonString(input),
      _tryLooseJsonRepair(input),
    ];

    for (final candidate in candidates) {
      if (candidate != null) {
        return candidate;
      }
    }
    return null;
  }

  _TransformCandidate? _tryExtractFromText(String input) {
    final extracted = JsonExtractor.extractFromText(input);
    if (extracted == null) {
      return null;
    }
    return _TransformCandidate(
      output: extracted,
      step: const TransformationStep(
        type: TransformationType.jsonExtracted,
        description: 'JSON extracted from surrounding text',
        detail: null,
      ),
      format: DetectedFormat.jsonInText,
      confidence: Confidence.high,
    );
  }

  _TransformCandidate? _tryJsonp(String input) {
    final extracted = JsonpCodec.tryExtract(input);
    if (extracted == null) {
      return null;
    }
    return _TransformCandidate(
      output: extracted,
      step: const TransformationStep(
        type: TransformationType.jsonpExtracted,
        description: 'Extracted JSON from JSONP callback wrapper',
      ),
      format: DetectedFormat.jsonp,
      confidence: Confidence.high,
    );
  }

  _TransformCandidate? _tryWrapper(String input) {
    final match = WrapperCodec.tryUnwrap(input);
    if (match == null) {
      return null;
    }
    return _TransformCandidate(
      output: match.inner,
      step: TransformationStep(
        type: TransformationType.removedWrapper,
        description: match.description,
      ),
      format: DetectedFormat.wrapper,
      confidence: Confidence.high,
    );
  }

  _TransformCandidate? _tryHtmlEntities(String input) {
    final decoded = HtmlEntityCodec.tryDecode(input);
    if (decoded == null) {
      return null;
    }
    return _TransformCandidate(
      output: decoded,
      step: const TransformationStep(
        type: TransformationType.htmlEntitiesDecoded,
        description: 'Decoded HTML entities',
      ),
      format: DetectedFormat.htmlEntities,
      confidence: Confidence.high,
    );
  }

  _TransformCandidate? _tryUrlDecode(String input) {
    if (!JugaadValidator.looksUrlEncoded(input)) {
      return null;
    }
    try {
      final decoded = Uri.decodeComponent(input);
      if (decoded == input || !JugaadValidator.isMeaningfulDecodedString(decoded)) {
        return null;
      }
      return _TransformCandidate(
        output: decoded,
        step: const TransformationStep(
          type: TransformationType.urlDecoded,
          description: 'URL-decoded input',
        ),
        format: DetectedFormat.urlEncoded,
        confidence: Confidence.high,
      );
    } on FormatException {
      return null;
    }
  }

  _TransformCandidate? _tryBase64(String input) {
    final decoded = Base64CodecUtil.tryDecode(input);
    if (decoded == null) {
      return null;
    }
    return _TransformCandidate(
      output: decoded,
      step: TransformationStep(
        type: TransformationType.base64Decoded,
        description: 'Base64-decoded input',
        detail: previewText(decoded),
      ),
      format: DetectedFormat.base64,
      confidence: Confidence.high,
    );
  }

  _TransformCandidate? _tryHex(String input) {
    final decoded = HexCodecUtil.tryDecode(input);
    if (decoded == null) {
      return null;
    }
    return _TransformCandidate(
      output: decoded,
      step: TransformationStep(
        type: TransformationType.hexDecoded,
        description: 'Hexadecimal text decoded',
        detail: previewText(decoded),
      ),
      format: DetectedFormat.hex,
      confidence: Confidence.high,
    );
  }

  _TransformCandidate? _tryCompressed(String input) {
    final decoded = _compressedDecoder.tryDecompress(input);
    if (decoded == null || !JugaadValidator.isMeaningfulDecodedString(decoded)) {
      return null;
    }
    return _TransformCandidate(
      output: decoded,
      step: const TransformationStep(
        type: TransformationType.compressedDecoded,
        description: 'Decompressed payload',
      ),
      format: DetectedFormat.compressed,
      confidence: Confidence.high,
    );
  }

  _TransformCandidate? _tryUnescapeJsonString(String input) {
    if (JugaadValidator.tryParseJson(input) != null) {
      return null;
    }

    if (JugaadValidator.isJsonStringLiteral(input)) {
      try {
        final decoded = jsonDecode(input);
        if (decoded is String &&
            decoded != input &&
            (JugaadValidator.looksLikeJsonCandidate(decoded) ||
                JugaadValidator.tryParseJson(decoded) != null)) {
          return _TransformCandidate(
            output: decoded,
            step: TransformationStep(
              type: TransformationType.decodedEscaped,
              description: 'Decoded escaped JSON string',
              detail: previewText(decoded),
            ),
            format: DetectedFormat.escapedJson,
            confidence: Confidence.high,
          );
        }
      } on FormatException {
        // Fall through.
      }
    }

    if (!input.contains(r'\') && !input.contains(r'\"')) {
      return null;
    }

    try {
      final decoded = jsonDecode('"$input"');
      if (decoded is String &&
          decoded != input &&
          (JugaadValidator.looksLikeJsonCandidate(decoded) ||
              JugaadValidator.tryParseJson(decoded) != null)) {
        return _TransformCandidate(
          output: decoded,
          step: TransformationStep(
            type: TransformationType.decodedEscaped,
            description: 'Decoded escaped JSON string',
            detail: previewText(decoded),
          ),
          format: DetectedFormat.escapedJson,
          confidence: Confidence.high,
        );
      }
    } on FormatException {
      return null;
    }

    return null;
  }

  _TransformCandidate? _tryLooseJsonRepair(String input) {
    final repair = LooseJsonRepair.tryRepair(input);
    if (repair == null) {
      return null;
    }
    return _TransformCandidate(
      output: repair.repaired,
      step: TransformationStep(
        type: repair.description.contains('comment')
            ? TransformationType.commentRemoved
            : TransformationType.trailingCommaRemoved,
        description: repair.description,
      ),
      format: DetectedFormat.looseJson,
      confidence: Confidence.medium,
    );
  }

  DetectedFormat? _detectLowConfidenceFormat(String input) {
    if (JugaadValidator.looksLikeBase64(input) &&
        Base64CodecUtil.tryDecode(input) == null) {
      return DetectedFormat.base64;
    }
    if (JugaadValidator.looksLikeHex(input) && HexCodecUtil.tryDecode(input) == null) {
      return DetectedFormat.hex;
    }
    if (JugaadValidator.looksUrlEncoded(input)) {
      return DetectedFormat.urlEncoded;
    }
    return null;
  }

  DetectedFormat _resolveDetectedFormat(
    DetectedFormat current,
    List<TransformationStep> steps,
  ) {
    if (current != DetectedFormat.unknown) {
      return current;
    }
    for (final step in steps.reversed) {
      switch (step.type) {
        case TransformationType.urlDecoded:
          return DetectedFormat.urlEncoded;
        case TransformationType.base64Decoded:
          return DetectedFormat.base64;
        case TransformationType.hexDecoded:
          return DetectedFormat.hex;
        case TransformationType.decodedEscaped:
          return DetectedFormat.escapedJson;
        case TransformationType.htmlEntitiesDecoded:
          return DetectedFormat.htmlEntities;
        case TransformationType.jsonExtracted:
          return DetectedFormat.jsonInText;
        case TransformationType.jsonpExtracted:
          return DetectedFormat.jsonp;
        case TransformationType.removedWrapper:
          return DetectedFormat.wrapper;
        case TransformationType.trailingCommaRemoved:
        case TransformationType.commentRemoved:
          return DetectedFormat.looseJson;
        default:
          continue;
      }
    }
    return DetectedFormat.json;
  }

  _NestedResult _extractNestedJson(
    Object? value,
    List<TransformationStep> steps,
  ) {
    var transformCount = 0;
    final processed = _processValue(value, steps, () => transformCount++);
    return _NestedResult(
      value: processed,
      changed: transformCount > 0,
      transformCount: transformCount,
    );
  }

  Object? _processValue(
    Object? value,
    List<TransformationStep> steps,
    void Function() onTransform,
  ) {
    if (value is String) {
      final nested = _tryParseNestedString(value);
      if (nested != null) {
        steps.add(
          TransformationStep(
            type: TransformationType.extractedNestedJson,
            description: 'Extracted nested JSON from string value',
            detail: previewText(value),
          ),
        );
        onTransform();
        return _processValue(nested, steps, onTransform);
      }
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, entryValue) =>
            MapEntry(key, _processValue(entryValue, steps, onTransform)),
      );
    }

    if (value is List) {
      return value.map((item) => _processValue(item, steps, onTransform)).toList();
    }

    return value;
  }

  Object? _tryParseNestedString(String value) {
    final trimmed = value.trim();
    if (!JugaadValidator.looksLikeJsonCandidate(trimmed)) {
      return null;
    }

    final parsed = JugaadValidator.tryParseJson(trimmed);
    if (parsed != null) {
      return parsed.value;
    }

    final unescaped = _tryUnescapeJsonString(trimmed);
    if (unescaped != null) {
      final reparsed = JugaadValidator.tryParseJson(unescaped.output);
      if (reparsed != null) {
        return reparsed.value;
      }
    }

    return null;
  }
}

class _NestedResult {
  const _NestedResult({
    required this.value,
    required this.changed,
    required this.transformCount,
  });

  final Object? value;
  final bool changed;
  final int transformCount;
}
