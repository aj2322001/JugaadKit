import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jugaadkit/core/utils/app_feedback.dart';

class JsonTreeCopyTarget extends StatelessWidget {
  const JsonTreeCopyTarget({
    super.key,
    required this.text,
    required this.copyType,
    required this.child,
  });

  final String text;
  final CopyFeedbackType copyType;
  final Widget child;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    showCopyFeedback(context, copyType);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _copy(context),
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }
}
