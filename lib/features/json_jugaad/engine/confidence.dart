enum Confidence {
  none,
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case Confidence.none:
        return 'None';
      case Confidence.low:
        return 'Low';
      case Confidence.medium:
        return 'Medium';
      case Confidence.high:
        return 'High';
    }
  }
}
