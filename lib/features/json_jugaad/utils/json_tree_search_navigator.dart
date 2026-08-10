import 'package:flutter/foundation.dart';

class JsonTreeSearchNavigator extends ChangeNotifier {
  int _matchCount = 0;
  int _activeIndex = 0;
  VoidCallback? _onPrevious;
  VoidCallback? _onNext;

  bool get canNavigate => _matchCount > 0;
  int get matchCount => _matchCount;
  int get activeMatchNumber => _matchCount == 0 ? 0 : _activeIndex + 1;

  void goToPrevious() => _onPrevious?.call();
  void goToNext() => _onNext?.call();

  void update({
    required int matchCount,
    required int activeIndex,
    required VoidCallback onPrevious,
    required VoidCallback onNext,
  }) {
    _matchCount = matchCount;
    _activeIndex = activeIndex;
    _onPrevious = onPrevious;
    _onNext = onNext;
    notifyListeners();
  }

  void clear() {
    _matchCount = 0;
    _activeIndex = 0;
    _onPrevious = null;
    _onNext = null;
    notifyListeners();
  }
}
