import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jugaadkit/features/json_jugaad/models/processing_mode.dart';

class ProcessingModeSelector extends StatefulWidget {
  const ProcessingModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  final ProcessingMode selectedMode;
  final ValueChanged<ProcessingMode> onModeChanged;

  @override
  State<ProcessingModeSelector> createState() => _ProcessingModeSelectorState();
}

class _ProcessingModeSelectorState extends State<ProcessingModeSelector> {
  final GlobalKey _buttonKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  String _searchQuery = '';

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _closePicker() {
    if (_overlayEntry == null) {
      return;
    }
    _removeOverlay();
    _searchController.clear();
    _searchQuery = '';
    if (mounted) {
      setState(() {});
    }
  }

  void _selectMode(ProcessingMode mode) {
    _closePicker();
    widget.onModeChanged(mode);
  }

  void _togglePicker() {
    if (_overlayEntry != null) {
      _closePicker();
      return;
    }
    _openPicker();
  }

  void _openPicker() {
    final overlay = Overlay.of(context);
    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }

    final buttonOffset = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    final screenSize = MediaQuery.sizeOf(context);
    const menuWidth = 280.0;
    const menuMaxHeight = 360.0;
    const spacing = 4.0;

    var left = buttonOffset.dx + buttonSize.width - menuWidth;
    if (left < 8) {
      left = 8;
    }
    if (left + menuWidth > screenSize.width - 8) {
      left = screenSize.width - menuWidth - 8;
    }

    final spaceBelow =
        screenSize.height - (buttonOffset.dy + buttonSize.height + spacing);
    final spaceAbove = buttonOffset.dy - spacing;
    final openUpward = spaceBelow < 220 && spaceAbove > spaceBelow;
    final availableHeight =
        (openUpward ? spaceAbove : spaceBelow).clamp(160.0, menuMaxHeight);
    final top = openUpward
        ? buttonOffset.dy - availableHeight - spacing
        : buttonOffset.dy + buttonSize.height + spacing;

    _searchController.clear();
    _searchQuery = '';

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final theme = Theme.of(overlayContext);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closePicker,
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: menuWidth,
              child: Material(
                elevation: 8,
                shadowColor: theme.shadowColor.withValues(alpha: 0.25),
                color: theme.colorScheme.surface,
                surfaceTintColor: theme.colorScheme.surfaceTint,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: theme.dividerColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: StatefulBuilder(
                  builder: (context, setOverlayState) {
                    final filteredModes = ProcessingModeLabel.selectableModes
                        .where((mode) => mode.matchesSearch(_searchQuery))
                        .toList();

                    return SizedBox(
                      height: availableHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Search modes...',
                                prefixIcon: const Icon(Icons.search, size: 18),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        tooltip: 'Clear search',
                                        onPressed: () {
                                          _searchController.clear();
                                          setOverlayState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                        icon: const Icon(Icons.clear, size: 16),
                                      )
                                    : null,
                              ),
                              style: theme.textTheme.bodySmall,
                              onChanged: (value) {
                                setOverlayState(() {
                                  _searchQuery = value;
                                });
                              },
                              onSubmitted: (value) {
                                if (filteredModes.isNotEmpty) {
                                  _selectMode(filteredModes.first);
                                }
                              },
                            ),
                          ),
                          Divider(height: 1, color: theme.dividerColor),
                          Expanded(
                            child: filteredModes.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'No matching modes',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color:
                                              theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    itemCount: filteredModes.length,
                                    itemBuilder: (context, index) {
                                      final mode = filteredModes[index];
                                      final isSelected =
                                          mode == widget.selectedMode;

                                      return ListTile(
                                        dense: true,
                                        visualDensity: VisualDensity.compact,
                                        title: Text(mode.menuLabel),
                                        selected: isSelected,
                                        selectedTileColor: theme
                                            .colorScheme.primaryContainer
                                            .withValues(alpha: 0.35),
                                        trailing: isSelected
                                            ? Icon(
                                                Icons.check,
                                                size: 18,
                                                color: theme.colorScheme.primary,
                                              )
                                            : null,
                                        onTap: () => _selectMode(mode),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);
    if (mounted) {
      setState(() {});
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _closePicker();
              return null;
            },
          ),
        },
        child: Tooltip(
          message: 'Processing mode',
          child: OutlinedButton.icon(
            key: _buttonKey,
            onPressed: _togglePicker,
            icon: Icon(
              _overlayEntry == null ? Icons.expand_more : Icons.expand_less,
              size: 18,
            ),
            label: Text(widget.selectedMode.menuLabel),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: theme.colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
