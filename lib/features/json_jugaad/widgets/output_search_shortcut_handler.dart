import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:jugaadkit/core/keyboard/find_shortcut.dart';

import 'output_json_search_focus.dart';

/// Listens for Cmd+F / Ctrl+F and focuses the output JSON search field.
class OutputSearchShortcutHandler {
  OutputSearchShortcutHandler({
    required OutputJsonSearchFocus focusTarget,
    required bool Function() isEnabled,
  })  : _focusTarget = focusTarget,
        _isEnabled = isEnabled;

  final OutputJsonSearchFocus _focusTarget;
  final bool Function() _isEnabled;
  FindShortcutUnbinder? _unbindWebShortcut;
  bool _installed = false;

  void install() {
    if (_installed) {
      return;
    }
    _installed = true;

    if (kIsWeb) {
      _unbindWebShortcut = bindFindShortcut(
        isEnabled: _isEnabled,
        onTrigger: _triggerFocus,
      );
    }

    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  void dispose() {
    if (!_installed) {
      return;
    }
    _installed = false;

    _unbindWebShortcut?.call();
    _unbindWebShortcut = null;

    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || !_isEnabled()) {
      return false;
    }

    if (event.logicalKey != LogicalKeyboardKey.keyF) {
      return false;
    }

    if (!HardwareKeyboard.instance.isMetaPressed &&
        !HardwareKeyboard.instance.isControlPressed) {
      return false;
    }

    _triggerFocus();
    return true;
  }

  void _triggerFocus() {
    _focusTarget.requestFocus();
  }
}
