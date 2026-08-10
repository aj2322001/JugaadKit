import 'json_jugaad_error.dart';
import 'json_jugaad_result.dart';
import 'processing_mode.dart';

enum JsonJugaadStatus {
  empty,
  processing,
  success,
  error,
}

class JsonJugaadViewState {
  const JsonJugaadViewState({
    this.status = JsonJugaadStatus.empty,
    this.input = '',
    this.processingMode = ProcessingMode.auto,
    this.result,
    this.error,
  });

  final JsonJugaadStatus status;
  final String input;
  final ProcessingMode processingMode;
  final JsonJugaadResult? result;
  final JsonJugaadError? error;

  JsonJugaadViewState copyWith({
    JsonJugaadStatus? status,
    String? input,
    ProcessingMode? processingMode,
    JsonJugaadResult? result,
    JsonJugaadError? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return JsonJugaadViewState(
      status: status ?? this.status,
      input: input ?? this.input,
      processingMode: processingMode ?? this.processingMode,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
