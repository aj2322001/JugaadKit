import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jugaadkit/features/json_jugaad/constants/json_jugaad_constants.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_error.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_ui_state.dart';
import 'package:jugaadkit/features/json_jugaad/models/processing_mode.dart';
import 'package:jugaadkit/features/json_jugaad/services/json_jugaad_service.dart';

class JsonJugaadViewModel extends ChangeNotifier {
  JsonJugaadViewModel({JsonJugaadService? service})
      : _service = service ?? const JsonJugaadService();

  final JsonJugaadService _service;
  Timer? _debounceTimer;

  JsonJugaadViewState _state = const JsonJugaadViewState();

  JsonJugaadViewState get state => _state;

  void updateInput(String value) {
    _state = _state.copyWith(input: value);
    notifyListeners();

    _debounceTimer?.cancel();
    if (value.trim().isEmpty) {
      _state = const JsonJugaadViewState();
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(JsonJugaadConstants.inputDebounce, () {
      _process(value);
    });
  }

  void clearInput() {
    _debounceTimer?.cancel();
    _state = const JsonJugaadViewState();
    notifyListeners();
  }

  void setProcessingMode(ProcessingMode mode) {
    if (_state.processingMode == mode) {
      return;
    }

    _state = _state.copyWith(processingMode: mode);
    notifyListeners();

    if (_state.input.trim().isEmpty) {
      return;
    }

    _debounceTimer?.cancel();
    _process(_state.input);
  }

  void tryAs(ProcessingMode mode) {
    setProcessingMode(mode);
  }

  void processNow() {
    _debounceTimer?.cancel();
    if (_state.input.trim().isEmpty) {
      _state = const JsonJugaadViewState();
      notifyListeners();
      return;
    }
    _process(_state.input);
  }

  void _process(String input) {
    _state = _state.copyWith(
      status: JsonJugaadStatus.processing,
      clearResult: true,
      clearError: true,
    );
    notifyListeners();

    try {
      final result = _service.process(
        input,
        mode: _state.processingMode,
      );
      _state = _state.copyWith(
        status: JsonJugaadStatus.success,
        result: result,
        clearError: true,
      );
    } on JsonJugaadError catch (error) {
      _state = _state.copyWith(
        status: JsonJugaadStatus.error,
        error: error,
        clearResult: true,
      );
    } catch (error) {
      _state = _state.copyWith(
        status: JsonJugaadStatus.error,
        error: JsonJugaadError(
          message: 'An unexpected error occurred.',
          detail: error.toString(),
          processingMode: _state.processingMode,
          isAutomatic: _state.processingMode == ProcessingMode.auto,
        ),
        clearResult: true,
      );
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
