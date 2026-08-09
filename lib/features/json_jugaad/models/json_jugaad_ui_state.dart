import 'json_jugaad_error.dart';
import 'json_jugaad_result.dart';

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
    this.result,
    this.error,
  });

  final JsonJugaadStatus status;
  final String input;
  final JsonJugaadResult? result;
  final JsonJugaadError? error;

  JsonJugaadViewState copyWith({
    JsonJugaadStatus? status,
    String? input,
    JsonJugaadResult? result,
    JsonJugaadError? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return JsonJugaadViewState(
      status: status ?? this.status,
      input: input ?? this.input,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
