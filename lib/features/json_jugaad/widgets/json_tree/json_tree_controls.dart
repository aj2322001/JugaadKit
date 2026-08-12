import 'package:flutter/material.dart';

abstract final class JsonTreeLayout {
  static const double trailingActionsWidth = 22;
  static const double scrollbarGutter = 14;
  static const double expandIconSize = 16;
  static const double expandControlWidth = 20;
  static const double expandLeadingWidth = expandControlWidth + 4;
}

class SearchMatchHighlight extends StatelessWidget {
  const SearchMatchHighlight({
    super.key,
    required this.isActive,
    required this.child,
  });

  final bool isActive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return child;
    }

    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}

class JsonTreeExpandIcon extends StatelessWidget {
  const JsonTreeExpandIcon({
    super.key,
    required this.isExpanded,
    required this.color,
  });

  final bool isExpanded;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: JsonTreeLayout.expandIconSize,
      height: JsonTreeLayout.expandIconSize,
      child: AnimatedRotation(
        turns: isExpanded ? 0.25 : 0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Icon(
          Icons.chevron_right_rounded,
          size: JsonTreeLayout.expandIconSize,
          color: color,
        ),
      ),
    );
  }
}

class JsonTreeIconButton extends StatelessWidget {
  const JsonTreeIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 12),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
    );
  }
}

/// Fixed-width trailing slot for the hover copy-path button.
class JsonTreeTrailingActions extends StatelessWidget {
  const JsonTreeTrailingActions({
    super.key,
    required this.visible,
    required this.onCopyPath,
  });

  final bool visible;
  final VoidCallback onCopyPath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: JsonTreeLayout.trailingActionsWidth,
      child: Opacity(
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: Align(
            alignment: Alignment.centerRight,
            child: JsonTreeIconButton(
              tooltip: 'Copy path',
              icon: Icons.route_outlined,
              onPressed: onCopyPath,
            ),
          ),
        ),
      ),
    );
  }
}
