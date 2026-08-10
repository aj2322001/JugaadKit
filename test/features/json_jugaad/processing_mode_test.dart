import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/engine/confidence.dart';
import 'package:jugaadkit/features/json_jugaad/engine/jugaad_engine.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_error.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_ui_state.dart';
import 'package:jugaadkit/features/json_jugaad/models/processing_mode.dart';
import 'package:jugaadkit/features/json_jugaad/models/transformation_step.dart';
import 'package:jugaadkit/features/json_jugaad/services/json_jugaad_service.dart';
import 'package:jugaadkit/features/json_jugaad/view_models/json_jugaad_view_model.dart';

void main() {
  const engine = JugaadEngine();
  const service = JsonJugaadService();

  group('Processing modes', () {
    test('default mode is Auto', () {
      final viewModel = JsonJugaadViewModel();
      expect(viewModel.state.processingMode, ProcessingMode.auto);
    });

    test('Auto correctly processes valid JSON', () {
      final result = service.process('{"id":1}');
      expect(result.isAutomatic, isTrue);
      expect(result.processingMode, ProcessingMode.auto);
      expect(result.confidence, Confidence.high);
      expect(result.parsedValue, isA<Map>());
    });

    test('Auto correctly detects Base64 JSON', () {
      final result = service.process('eyJ1c2VyIjp7ImlkIjoxMjN9fQ==');
      expect(result.isAutomatic, isTrue);
      expect(
        result.steps.any((s) => s.type == TransformationType.base64Decoded),
        isTrue,
      );
      expect(result.detectionSummary, contains('Base64'));
    });

    test('Auto correctly detects URL encoded JSON', () {
      final result = service.process('%7B%22id%22%3A42%7D');
      expect(result.isAutomatic, isTrue);
      expect(
        result.steps.any((s) => s.type == TransformationType.urlDecoded),
        isTrue,
      );
      expect(result.detectionSummary, contains('URL'));
    });

    test('Auto leaves ambiguous input unchanged on failure', () {
      const input = 'not json at all';
      try {
        service.process(input);
        fail('Expected JsonJugaadError');
      } on JsonJugaadError catch (error) {
        expect(error.originalInput, input);
        expect(error.isAmbiguousAutoFailure, isTrue);
      }
    });

    test('Auto failure shows Try as options', () {
      try {
        service.process('HelloWorld');
      } on JsonJugaadError catch (error) {
        expect(error.isAmbiguousAutoFailure, isTrue);
        expect(error.suggestedModes, isNotEmpty);
        expect(error.suggestedModes, isNot(contains(ProcessingMode.auto)));
        return;
      }
      fail('Expected JsonJugaadError');
    });

    test('Selecting Try as Base64 switches to Base64 mode', () {
      final viewModel = JsonJugaadViewModel();
      viewModel.updateInput('eyJ1c2VyIjp7ImlkIjoxMjN9fQ==');

      viewModel.tryAs(ProcessingMode.base64);

      expect(viewModel.state.processingMode, ProcessingMode.base64);
      expect(viewModel.state.status, JsonJugaadStatus.success);
      expect(viewModel.state.result?.isAutomatic, isFalse);
    });

    test('Manual Base64 bypasses Auto detection', () {
      final result = service.process(
        'eyJ1c2VyIjp7ImlkIjoxMjN9fQ==',
        mode: ProcessingMode.base64,
      );
      expect(result.isAutomatic, isFalse);
      expect(result.processingMode, ProcessingMode.base64);
      expect(
        result.steps.any((s) => s.type == TransformationType.base64Decoded),
        isTrue,
      );
    });

    test('Manual parser failure does not fall back to Auto', () {
      expect(
        () => service.process('not!!!base64', mode: ProcessingMode.base64),
        throwsA(
          predicate<JsonJugaadError>(
            (error) =>
                error.processingMode == ProcessingMode.base64 &&
                error.isAutomatic == false &&
                error.message.contains('Base64'),
          ),
        ),
      );
    });

    test('Switching Manual to Auto processes the original input', () {
      final viewModel = JsonJugaadViewModel();
      const input = '%7B%22id%22%3A42%7D';

      viewModel.updateInput(input);
      viewModel.setProcessingMode(ProcessingMode.base64);
      expect(viewModel.state.status, isNot(JsonJugaadStatus.success));

      viewModel.setProcessingMode(ProcessingMode.auto);
      expect(viewModel.state.processingMode, ProcessingMode.auto);
      expect(viewModel.state.status, JsonJugaadStatus.success);
      expect(viewModel.state.result?.originalInput, input);
      expect(
        viewModel.state.result?.steps.any(
          (step) => step.type == TransformationType.urlDecoded,
        ),
        isTrue,
      );
    });

    test('Switching between manual modes processes the original input', () {
      final viewModel = JsonJugaadViewModel();
      const input = 'eyJ1c2VyIjp7ImlkIjoxMjN9fQ==';

      viewModel.updateInput(input);
      viewModel.setProcessingMode(ProcessingMode.urlDecode);
      expect(viewModel.state.status, JsonJugaadStatus.error);

      viewModel.setProcessingMode(ProcessingMode.base64);
      expect(viewModel.state.status, JsonJugaadStatus.success);
      expect(viewModel.state.result?.originalInput, input);
    });

    test('Reset returns to Auto mode', () {
      final viewModel = JsonJugaadViewModel();
      viewModel.updateInput('{"id":1}');
      viewModel.setProcessingMode(ProcessingMode.base64);
      expect(viewModel.state.processingMode, ProcessingMode.base64);

      viewModel.clearInput();
      expect(viewModel.state.processingMode, ProcessingMode.auto);
      expect(viewModel.state.status, JsonJugaadStatus.empty);
    });

    test('processAuto wraps low-confidence failures as ambiguous', () {
      const input = 'ABCDABCDABCDABCD';
      try {
        engine.processAuto(input);
        fail('Expected JsonJugaadError');
      } on JsonJugaadError catch (error) {
        expect(error.isAmbiguousAutoFailure, isTrue);
        expect(error.message, "Couldn't confidently identify this input.");
        expect(error.suggestedModes, isNotEmpty);
      }
    });

    test('engine.process keeps specific validation failures', () {
      expect(
        () => engine.process('{"id":1}\n{"id":2\n'),
        throwsA(
          predicate<JsonJugaadError>(
            (error) =>
                !error.isAmbiguousAutoFailure &&
                error.message.contains('NDJSON'),
          ),
        ),
      );
    });
  });
}
