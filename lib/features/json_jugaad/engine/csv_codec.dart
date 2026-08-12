import 'jugaad_validator.dart';

class CsvParseResult {
  const CsvParseResult({required this.rows});

  final List<Map<String, Object?>> rows;
}

abstract final class CsvCodec {
  static CsvParseResult? tryParse(String input) {
    if (!JugaadValidator.looksLikeCsv(input)) {
      return null;
    }

    final rows = _parseRows(input);
    if (rows == null || rows.length < 2) {
      return null;
    }

    final headers = rows.first;
    if (headers.isEmpty || headers.any((header) => header.trim().isEmpty)) {
      return null;
    }

    final parsedRows = <Map<String, Object?>>[];
    for (var i = 1; i < rows.length; i++) {
      final values = rows[i];
      if (values.length != headers.length) {
        return null;
      }

      final row = <String, Object?>{};
      for (var j = 0; j < headers.length; j++) {
        row[headers[j]] = _coerceValue(values[j]);
      }
      parsedRows.add(row);
    }

    if (parsedRows.isEmpty) {
      return null;
    }

    return CsvParseResult(rows: parsedRows);
  }

  static List<List<String>>? _parseRows(String input) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];

      if (inQuotes) {
        if (char == '"') {
          final hasEscapedQuote =
              i + 1 < input.length && input[i + 1] == '"';
          if (hasEscapedQuote) {
            buffer.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          buffer.write(char);
        }
        continue;
      }

      if (char == '"') {
        inQuotes = true;
        continue;
      }

      if (char == ',') {
        currentRow.add(buffer.toString());
        buffer.clear();
        continue;
      }

      if (char == '\n') {
        currentRow.add(buffer.toString());
        buffer.clear();
        if (currentRow.any((value) => value.isNotEmpty)) {
          rows.add(List<String>.from(currentRow));
        }
        currentRow.clear();
        continue;
      }

      if (char == '\r') {
        continue;
      }

      buffer.write(char);
    }

    currentRow.add(buffer.toString());
    if (currentRow.any((value) => value.isNotEmpty)) {
      rows.add(currentRow);
    }

    if (rows.isEmpty) {
      return null;
    }

    final columnCount = rows.first.length;
    if (columnCount < 2) {
      return null;
    }

    for (final row in rows) {
      if (row.length != columnCount) {
        return null;
      }
    }

    return rows;
  }

  static Object? _coerceValue(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return '';
    }

    final lower = value.toLowerCase();
    if (lower == 'true') {
      return true;
    }
    if (lower == 'false') {
      return false;
    }
    if (lower == 'null') {
      return null;
    }

    final intValue = int.tryParse(value);
    if (intValue != null) {
      return intValue;
    }

    final doubleValue = double.tryParse(value);
    if (doubleValue != null) {
      return doubleValue;
    }

    return value;
  }
}
