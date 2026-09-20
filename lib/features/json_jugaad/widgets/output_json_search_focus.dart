import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jugaadkit/core/keyboard/dom_focus.dart';

/// Registers the active output JSON search field for global focus shortcuts.
class OutputJsonSearchFocus {
  FocusNode? focusNode;
  TextEditingController? controller;

  bool get isAvailable => focusNode != null && controller != null;

  void register({
    required FocusNode focusNode,
    required TextEditingController controller,
  }) {
    this.focusNode = focusNode;
    this.controller = controller;
  }

  void unregister() {
    focusNode = null;
    controller = null;
  }

  void requestFocus() {
    final node = focusNode;
    final fieldController = controller;
    if (node == null || fieldController == null) {
      return;
    }

    _focusSearchField(node, fieldController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!node.hasFocus) {
        _focusSearchField(node, fieldController);
      }
    });
  }

  void _focusSearchField(FocusNode node, TextEditingController fieldController) {
    releaseActiveDomFocus();
    FocusManager.instance.primaryFocus?.unfocus();
    node.requestFocus();
    final text = fieldController.text;
    if (text.isNotEmpty) {
      fieldController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: text.length,
      );
    }
  }
}

class FocusOutputJsonSearchIntent extends Intent {
  const FocusOutputJsonSearchIntent();
}

class OutputJsonSearchShortcuts extends StatelessWidget {
  const OutputJsonSearchShortcuts({
    super.key,
    required this.focusTarget,
    required this.enabled,
    required this.child,
  });

  final OutputJsonSearchFocus focusTarget;
  final bool enabled;
  final Widget child;

  static const Map<ShortcutActivator, Intent> shortcuts = {
    SingleActivator(LogicalKeyboardKey.keyF, meta: true):
        FocusOutputJsonSearchIntent(),
    SingleActivator(LogicalKeyboardKey.keyF, control: true):
        FocusOutputJsonSearchIntent(),
  };

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          FocusOutputJsonSearchIntent: CallbackAction<FocusOutputJsonSearchIntent>(
            onInvoke: (_) {
              focusTarget.requestFocus();
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}
