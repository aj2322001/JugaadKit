import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_result.dart';
import 'package:jugaadkit/features/json_jugaad/models/processing_mode.dart';

import '../engine/jugaad_engine.dart';

/// Thin facade over [JugaadEngine] for the JSON Jugaad feature.
class JsonJugaadService {
  const JsonJugaadService({JugaadEngine? engine})
      : _engine = engine ?? const JugaadEngine();

  final JugaadEngine _engine;

  JsonJugaadResult process(
    String rawInput, {
    ProcessingMode mode = ProcessingMode.auto,
  }) {
    if (mode == ProcessingMode.auto) {
      return _engine.processAuto(rawInput);
    }
    return _engine.processManual(rawInput, mode);
  }
}
