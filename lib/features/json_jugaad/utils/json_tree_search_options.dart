class JsonTreeSearchOptions {
  const JsonTreeSearchOptions({
    this.matchCase = false,
    this.wholeWord = false,
  });

  final bool matchCase;
  final bool wholeWord;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is JsonTreeSearchOptions &&
            matchCase == other.matchCase &&
            wholeWord == other.wholeWord;
  }

  @override
  int get hashCode => Object.hash(matchCase, wholeWord);

  bool matches(String text, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty || text.isEmpty) {
      return false;
    }

    if (wholeWord) {
      return _containsWholeWord(text, trimmed, matchCase);
    }

    if (matchCase) {
      return text.contains(trimmed);
    }

    return text.toLowerCase().contains(trimmed.toLowerCase());
  }

  List<({int start, int end})> matchRanges(String text, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty || text.isEmpty) {
      return const [];
    }

    final ranges = <({int start, int end})>[];
    final needleLength = trimmed.length;
    var start = 0;

    while (start <= text.length - needleLength) {
      final index = _indexOf(text, trimmed, start, matchCase);
      if (index < 0) {
        break;
      }

      if (!wholeWord || _isWholeWordMatch(text, index, needleLength)) {
        ranges.add((start: index, end: index + needleLength));
      }

      start = index + 1;
    }

    return ranges;
  }

  static int _indexOf(
    String text,
    String query,
    int start,
    bool matchCase,
  ) {
    if (matchCase) {
      return text.indexOf(query, start);
    }
    return text.toLowerCase().indexOf(query.toLowerCase(), start);
  }

  static bool _containsWholeWord(String text, String query, bool matchCase) {
    final needleLength = query.length;
    var start = 0;

    while (start <= text.length - needleLength) {
      final index = _indexOf(text, query, start, matchCase);
      if (index < 0) {
        return false;
      }

      if (_isWholeWordMatch(text, index, needleLength)) {
        return true;
      }

      start = index + 1;
    }

    return false;
  }

  static bool _isWholeWordMatch(String text, int index, int length) {
    final beforeOk = index == 0 || !_isWordChar(text[index - 1]);
    final afterIndex = index + length;
    final afterOk =
        afterIndex == text.length || !_isWordChar(text[afterIndex]);
    return beforeOk && afterOk;
  }

  static bool _isWordChar(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 48 && code <= 57) ||
        (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        code == 95;
  }
}
