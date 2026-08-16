import 'package:flutter/material.dart';

/// Output scrollbars stay visible but ignore drag/tap gestures.
class OutputScrollBehavior extends MaterialScrollBehavior {
  const OutputScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (axisDirectionToAxis(details.direction) != Axis.vertical) {
      return child;
    }

    final controller = details.controller;
    if (controller == null) {
      return child;
    }

    return Scrollbar(
      controller: controller,
      thumbVisibility: true,
      interactive: false,
      child: child,
    );
  }
}
