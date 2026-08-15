import '../models/json_repair_highlight.dart';
import '../utils/json_path.dart';
import 'jugaad_validator.dart';

class JsonRepairAttempt {
  const JsonRepairAttempt({
    required this.repaired,
    required this.description,
    required this.highlights,
    required this.kind,
  });

  final String repaired;
  final String description;
  final List<JsonRepairHighlight> highlights;
  final JsonRepairKind kind;
}

abstract final class JsonRepairEngine {
  static JsonRepairAttempt? tryRepair(String input) {
    if (JugaadValidator.tryParseJson(input) != null) {
      return null;
    }

    if (!JugaadValidator.looksLikeJsonRepairCandidate(input)) {
      return null;
    }

    final withoutComments = _removeComments(input);
    if (withoutComments != input) {
      if (JugaadValidator.tryParseJson(withoutComments) != null) {
        return JsonRepairAttempt(
          repaired: withoutComments,
          description: 'JSON comment removed',
          highlights: const [],
          kind: JsonRepairKind.comment,
        );
      }
    }

    final withoutTrailingComma = _removeTrailingCommas(withoutComments);
    if (withoutTrailingComma != withoutComments &&
        JugaadValidator.tryParseJson(withoutTrailingComma) != null) {
      return JsonRepairAttempt(
        repaired: withoutTrailingComma,
        description: 'Trailing comma removed',
        highlights: const [],
        kind: JsonRepairKind.trailingComma,
      );
    }

    final base = withoutComments;

    return _repairSingleQuotedStrings(base) ??
        _repairUnquotedKeys(base) ??
        _repairPythonPrimitives(base) ??
        _repairMissingClosing(base);
  }

  static String _removeComments(String input) {
    return input
        .replaceAll(RegExp(r'//.*$', multiLine: true), '')
        .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  }

  static String _removeTrailingCommas(String input) {
    return input.replaceAllMapped(
      RegExp(r',(\s*[}\]])'),
      (match) => match.group(1)!,
    );
  }

  static JsonRepairAttempt? _repairSingleQuotedStrings(String input) {
    final highlights = <JsonRepairHighlight>[];
    final scanner = _ScannerState(input);
    final buffer = StringBuffer();
    var changed = false;
    var repairedOne = false;

    while (!scanner.isAtEnd) {
      if (scanner.inDoubleString) {
        buffer.write(scanner.readChar());
        continue;
      }

      if (scanner.currentChar == "'" && !repairedOne) {
        final isKey = scanner.expectingObjectKey;
        scanner.readChar();
        final content = StringBuffer();
        while (!scanner.isAtEnd) {
          final current = scanner.currentChar;
          if (current == '\\' && scanner.peekNext() != null) {
            content.write(scanner.readChar());
            content.write(scanner.readChar());
            continue;
          }
          if (current == "'") {
            scanner.readChar();
            break;
          }
          content.write(scanner.readChar());
        }
        final text = content.toString();

        buffer.write('"');
        buffer.write(_escapeForJsonString(text));
        buffer.write('"');
        highlights.add(
          JsonRepairHighlight(
            path: isKey
                ? JsonPath.childPath(scanner.currentContainerPath, text)
                : scanner.currentValuePath,
            target: isKey ? JsonRepairTarget.key : JsonRepairTarget.value,
            kind: JsonRepairKind.singleQuotedString,
            originalText: "'$text'",
            repairedText: '"$text"',
          ),
        );
        if (isKey) {
          scanner.registerKey(text);
        } else {
          scanner.afterValue();
        }
        changed = true;
        repairedOne = true;
        continue;
      }

      buffer.write(scanner.readStructuralChar());
    }

    return _attempt(
      input: input,
      repaired: buffer.toString(),
      changed: changed,
      description: 'Repaired single-quoted strings',
      highlights: highlights,
      kind: JsonRepairKind.singleQuotedString,
    );
  }

  static JsonRepairAttempt? _repairUnquotedKeys(String input) {
    final highlights = <JsonRepairHighlight>[];
    final scanner = _ScannerState(input);
    final buffer = StringBuffer();
    var changed = false;
    var repairedOne = false;

    while (!scanner.isAtEnd) {
      if (scanner.inDoubleString) {
        buffer.write(scanner.readChar());
        continue;
      }

      if (scanner.expectingObjectKey && !repairedOne) {
        scanner.copyWhitespace(buffer);
        if (scanner.isAtEnd) {
          break;
        }

        if (scanner.currentChar == '"' || scanner.currentChar == "'") {
          buffer.write(scanner.readChar());
          continue;
        }

        final key = scanner.readIdentifier();
        if (key != null) {
          scanner.copyWhitespace(buffer);
          if (!scanner.isAtEnd && scanner.currentChar == ':') {
            final keyPath = JsonPath.childPath(scanner.currentContainerPath, key);
            buffer.write('"');
            buffer.write(key);
            buffer.write('"');
            highlights.add(
              JsonRepairHighlight(
                path: keyPath,
                target: JsonRepairTarget.key,
                kind: JsonRepairKind.unquotedKey,
                originalText: key,
                repairedText: '"$key"',
              ),
            );
            scanner.registerKey(key);
            changed = true;
            repairedOne = true;
            continue;
          }

          buffer.write(key);
          continue;
        }
      }

      buffer.write(scanner.readStructuralChar());
    }

    return _attempt(
      input: input,
      repaired: buffer.toString(),
      changed: changed,
      description: 'Repaired unquoted object keys',
      highlights: highlights,
      kind: JsonRepairKind.unquotedKey,
    );
  }

  static JsonRepairAttempt? _repairPythonPrimitives(String input) {
    final highlights = <JsonRepairHighlight>[];
    final scanner = _ScannerState(input);
    final buffer = StringBuffer();
    var changed = false;
    var repairedOne = false;

    while (!scanner.isAtEnd) {
      if (scanner.inDoubleString) {
        buffer.write(scanner.readChar());
        continue;
      }

      if (scanner.expectingValue && !repairedOne) {
        scanner.copyWhitespace(buffer);
        final primitive = scanner.matchPythonPrimitive();
        if (primitive != null) {
          final valuePath = scanner.currentValuePath;
          buffer.write(primitive.replacement);
          highlights.add(
            JsonRepairHighlight(
              path: valuePath,
              target: JsonRepairTarget.value,
              kind: primitive.kind,
              originalText: primitive.token,
              repairedText: primitive.replacement,
            ),
          );
          scanner.afterValue();
          changed = true;
          repairedOne = true;
          continue;
        }
      }

      buffer.write(scanner.readStructuralChar());
    }

    return _attempt(
      input: input,
      repaired: buffer.toString(),
      changed: changed,
      description: 'Repaired Python/JavaScript-style primitives',
      highlights: highlights,
      kind: JsonRepairKind.pythonTrue,
    );
  }

  static JsonRepairAttempt? _repairMissingClosing(String input) {
    final scanner = _StructureScanner.scan(input);
    if (scanner.unclosedStructures.isEmpty) {
      return null;
    }

    final repaired = input + scanner.closingSuffix;
    if (JugaadValidator.tryParseJson(repaired) == null) {
      return null;
    }

    return JsonRepairAttempt(
      repaired: repaired,
      description: 'Added missing closing brackets',
      highlights: [
        for (final unclosed in scanner.unclosedStructures)
          JsonRepairHighlight(
            path: unclosed.path,
            target: JsonRepairTarget.structure,
            kind: JsonRepairKind.missingClosing,
            repairedText: unclosed.addedCloser,
          ),
      ],
      kind: JsonRepairKind.missingClosing,
    );
  }

  static JsonRepairAttempt? _attempt({
    required String input,
    required String repaired,
    required bool changed,
    required String description,
    required List<JsonRepairHighlight> highlights,
    required JsonRepairKind kind,
  }) {
    if (!changed || repaired == input) {
      return null;
    }
    if (!JugaadValidator.looksLikeJsonCandidate(repaired)) {
      return null;
    }
    return JsonRepairAttempt(
      repaired: repaired,
      description: description,
      highlights: highlights,
      kind: kind,
    );
  }

  static String _escapeForJsonString(String value) {
    return value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  }
}

class _UnclosedStructure {
  const _UnclosedStructure(this.path, this.addedCloser);

  final String path;
  final String addedCloser;
}

class _StructureScanner {
  const _StructureScanner(this.unclosedStructures, this.closingSuffix);

  final List<_UnclosedStructure> unclosedStructures;
  final String closingSuffix;

  static _StructureScanner scan(String input) {
    final stack = <_OpenFrame>[];
    var inDoubleString = false;
    var escapeNext = false;
    final pathTracker = _ScannerState(input, trackOnly: true);

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (inDoubleString) {
        if (escapeNext) {
          escapeNext = false;
          continue;
        }
        if (char == '\\') {
          escapeNext = true;
          continue;
        }
        if (char == '"') {
          inDoubleString = false;
        }
        continue;
      }

      if (char == '"') {
        inDoubleString = true;
        pathTracker.consumeChar(char);
        continue;
      }

      if (char == '{') {
        final path = pathTracker.currentValuePath;
        pathTracker.consumeChar(char);
        stack.add(_OpenFrame('{', path));
      } else if (char == '[') {
        final path = pathTracker.currentValuePath;
        pathTracker.consumeChar(char);
        stack.add(_OpenFrame('[', path));
      } else if (char == '}') {
        if (stack.isEmpty || stack.last.token != '{') {
          return const _StructureScanner([], '');
        }
        stack.removeLast();
        pathTracker.consumeChar(char);
      } else if (char == ']') {
        if (stack.isEmpty || stack.last.token != '[') {
          return const _StructureScanner([], '');
        }
        stack.removeLast();
        pathTracker.consumeChar(char);
      } else if (char == "'" && !inDoubleString) {
        var j = i + 1;
        while (j < input.length) {
          if (input[j] == '\\' && j + 1 < input.length) {
            j += 2;
            continue;
          }
          if (input[j] == "'") {
            j++;
            break;
          }
          j++;
        }
        i = j - 1;
      } else {
        pathTracker.consumeChar(char);
      }
    }

    if (stack.isEmpty) {
      return const _StructureScanner([], '');
    }

    final closers = StringBuffer();
    final structures = <_UnclosedStructure>[];
    for (final frame in stack.reversed) {
      final closer = frame.token == '{' ? '}' : ']';
      closers.write(closer);
      structures.add(_UnclosedStructure(frame.path, closer));
    }

    return _StructureScanner(
      structures.reversed.toList(),
      closers.toString(),
    );
  }
}

class _OpenFrame {
  const _OpenFrame(this.token, this.path);

  final String token;
  final String path;
}

class _ScannerState {
  _ScannerState(this.input, {this.trackOnly = false}) : _index = 0;

  final String input;
  final bool trackOnly;
  int _index = 0;

  final List<_Frame> _stack = [_Frame(path: JsonPath.root, isArray: false)];

  bool inDoubleString = false;
  bool _escapeNext = false;
  String? _currentKey;
  int _arrayIndex = 0;

  bool get isAtEnd => _index >= input.length;

  String get currentChar => input[_index];

  String? peekNext() {
    final next = _index + 1;
    if (next >= input.length) {
      return null;
    }
    return input[next];
  }

  String get currentContainerPath => _stack.last.path;

  String get currentValuePath {
    final frame = _stack.last;
    if (frame.isArray) {
      return JsonPath.indexPath(frame.path, _arrayIndex);
    }
    if (_currentKey != null) {
      return JsonPath.childPath(frame.path, _currentKey!);
    }
    return frame.path;
  }

  bool get expectingObjectKey {
    if (inDoubleString) {
      return false;
    }
    final frame = _stack.last;
    return !frame.isArray && frame.expectingKey;
  }

  bool get expectingValue {
    if (inDoubleString) {
      return false;
    }
    return _stack.last.expectingValue;
  }

  void copyWhitespace(StringBuffer buffer) {
    while (!isAtEnd && _isWhitespace(currentChar)) {
      buffer.write(readChar());
    }
  }

  String readChar() {
    final char = input[_index++];
    _consume(char);
    return char;
  }

  String readStructuralChar() {
    final char = input[_index++];
    _consume(char);
    return char;
  }

  void consumeChar(String char) {
    if (_index < input.length && input[_index] == char) {
      _index++;
    }
    _consume(char);
  }

  String? readIdentifier() {
    final match =
        RegExp(r'^[A-Za-z_][A-Za-z0-9_]*').firstMatch(input.substring(_index));
    if (match == null) {
      return null;
    }
    final value = match.group(0)!;
    _index += value.length;
    return value;
  }

  void registerKey(String key) {
    _currentKey = key;
    _stack.last.expectingKey = false;
    _stack.last.expectingColon = true;
  }

  void afterValue() {
    _currentKey = null;
    _stack.last.expectingValue = false;
    _stack.last.expectingComma = true;
  }

  _PythonPrimitiveMatch? matchPythonPrimitive() {
    final remaining = input.substring(_index);
    for (final candidate in _pythonPrimitives) {
      if (!remaining.startsWith(candidate.token)) {
        continue;
      }
      final nextIndex = candidate.token.length;
      if (nextIndex < remaining.length &&
          _isIdentifierPart(remaining[nextIndex])) {
        continue;
      }
      _index += candidate.token.length;
      return candidate;
    }
    return null;
  }

  void _consume(String char) {
    if (inDoubleString) {
      if (_escapeNext) {
        _escapeNext = false;
        if (_stack.last.expectingKeyString && char != '"') {
          _currentKey = '${_currentKey ?? ''}$char';
        }
        return;
      }
      if (char == '\\') {
        _escapeNext = true;
        return;
      }
      if (char == '"') {
        inDoubleString = false;
        if (_stack.last.expectingKeyString) {
          _stack.last.expectingKeyString = false;
          _stack.last.expectingColon = true;
        } else {
          afterValue();
        }
        return;
      }
      if (_stack.last.expectingKeyString) {
        _currentKey = '${_currentKey ?? ''}$char';
      }
      return;
    }

    switch (char) {
      case '"':
        inDoubleString = true;
        _escapeNext = false;
        if (_stack.last.expectingKey) {
          _stack.last.expectingKey = false;
          _stack.last.expectingKeyString = true;
          _currentKey = '';
        }
      case '{':
        final path = _currentKey == null
            ? currentValuePath
            : JsonPath.childPath(_stack.last.path, _currentKey!);
        _currentKey = null;
        _stack.add(_Frame(path: path, isArray: false)..expectingKey = true);
      case '[':
        final path = _currentKey == null
            ? currentValuePath
            : JsonPath.childPath(_stack.last.path, _currentKey!);
        _currentKey = null;
        _stack.add(_Frame(path: path, isArray: true)..expectingValue = true);
        _arrayIndex = 0;
      case '}':
        if (_stack.length > 1) {
          _stack.removeLast();
        }
        _currentKey = null;
        _stack.last.expectingComma = true;
        _stack.last.expectingValue = false;
      case ']':
        if (_stack.length > 1) {
          _stack.removeLast();
        }
        _currentKey = null;
        _stack.last.expectingComma = true;
        _stack.last.expectingValue = false;
      case ':':
        if (_stack.last.expectingColon) {
          _stack.last.expectingColon = false;
          _stack.last.expectingValue = true;
        }
      case ',':
        final frame = _stack.last;
        frame.expectingComma = false;
        if (frame.isArray) {
          _arrayIndex++;
          frame.expectingValue = true;
        } else {
          frame.expectingKey = true;
          frame.expectingValue = false;
        }
        _currentKey = null;
      default:
        return;
    }
  }

  bool _isWhitespace(String char) {
    return char == ' ' || char == '\t' || char == '\n' || char == '\r';
  }

  bool _isIdentifierPart(String char) {
    return RegExp(r'[A-Za-z0-9_]').hasMatch(char);
  }
}

class _Frame {
  _Frame({
    required this.path,
    required this.isArray,
  });

  final String path;
  final bool isArray;
  bool expectingKey = false;
  bool expectingColon = false;
  bool expectingComma = false;
  bool expectingValue = false;
  bool expectingKeyString = false;
}

class _PythonPrimitiveMatch {
  const _PythonPrimitiveMatch(this.token, this.replacement, this.kind);

  final String token;
  final String replacement;
  final JsonRepairKind kind;
}

const _pythonPrimitives = <_PythonPrimitiveMatch>[
  _PythonPrimitiveMatch('True', 'true', JsonRepairKind.pythonTrue),
  _PythonPrimitiveMatch('False', 'false', JsonRepairKind.pythonFalse),
  _PythonPrimitiveMatch('None', 'null', JsonRepairKind.pythonNone),
];
