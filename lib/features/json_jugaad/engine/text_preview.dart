String previewText(String value, {int maxLength = 80}) {
  final singleLine = value.replaceAll(RegExp(r'\s+'), ' ');
  if (singleLine.length <= maxLength) {
    return singleLine;
  }
  return '${singleLine.substring(0, maxLength)}…';
}
