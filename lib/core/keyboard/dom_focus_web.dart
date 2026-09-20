// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

void releaseActiveDomFocus() {
  final active = html.document.activeElement;
  if (active != null && active != html.document.body) {
    active.blur();
  }
}
