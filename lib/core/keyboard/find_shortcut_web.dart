// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

typedef FindShortcutUnbinder = void Function();

FindShortcutUnbinder bindFindShortcut({
  required bool Function() isEnabled,
  required void Function() onTrigger,
}) {
  void listener(html.Event event) {
    final keyEvent = event as html.KeyboardEvent;
    final key = keyEvent.key?.toLowerCase();
    final isFindKey = key == 'f' || keyEvent.code == 'KeyF';
    if (!isFindKey || !(keyEvent.metaKey || keyEvent.ctrlKey)) {
      return;
    }

    if (!isEnabled()) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();
    onTrigger();
  }

  // Capture phase on document + window so Cmd+F works regardless of focus target.
  final targets = <html.EventTarget>[html.document, html.window];
  for (final target in targets) {
    target.addEventListener('keydown', listener, true);
  }

  return () {
    for (final target in targets) {
      target.removeEventListener('keydown', listener, true);
    }
  };
}
