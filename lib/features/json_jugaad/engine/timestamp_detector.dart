import 'confidence.dart';

class TimestampHint {
  const TimestampHint({
    required this.label,
    required this.confidence,
  });

  final String label;
  final Confidence confidence;
}

abstract final class TimestampDetector {
  static TimestampHint? detect(num value) {
    if (value != value.roundToDouble()) {
      return null;
    }

    final intValue = value.toInt();
    if (intValue <= 0) {
      return null;
    }

    final seconds = DateTime.fromMillisecondsSinceEpoch(intValue * 1000, isUtc: true);
    if (_isPlausibleDate(seconds) && intValue >= 946684800 && intValue <= 4102444800) {
      return TimestampHint(
        label: _formatUtc(seconds),
        confidence: Confidence.medium,
      );
    }

    final millis = DateTime.fromMillisecondsSinceEpoch(intValue, isUtc: true);
    if (_isPlausibleDate(millis) &&
        intValue >= 946684800000 &&
        intValue <= 4102444800000) {
      return TimestampHint(
        label: _formatUtc(millis),
        confidence: Confidence.high,
      );
    }

    return null;
  }

  static bool _isPlausibleDate(DateTime date) {
    return date.year >= 2000 && date.year <= 2100;
  }

  static String _formatUtc(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    final s = date.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:$s UTC';
  }
}
