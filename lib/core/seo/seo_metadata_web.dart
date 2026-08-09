// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

void applySeoMetadata({
  required String title,
  String? description,
}) {
  html.document.title = title;

  if (description == null) {
    return;
  }

  final meta = html.document.querySelector('meta[name="description"]');
  meta?.setAttribute('content', description);
}
