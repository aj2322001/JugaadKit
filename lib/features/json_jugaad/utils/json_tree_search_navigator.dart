import 'package:flutter/foundation.dart';

/// Shared search-navigation state for a single JSON tree output surface.
class JsonTreeSearchSession extends ChangeNotifier {
  int _matchCount = 0;
  int _activeIndex = 0;

  bool get canNavigate => _matchCount > 0;
  int get matchCount => _matchCount;
  int get activeIndex => _activeIndex;
  int get activeMatchNumber => _matchCount == 0 ? 0 : _activeIndex + 1;

  void setMatches(int matchCount, {bool resetIndex = true}) {
    _matchCount = matchCount;
    if (resetIndex || _activeIndex >= matchCount) {
      _activeIndex = 0;
    } else {
      _activeIndex = _activeIndex.clamp(0, matchCount > 0 ? matchCount - 1 : 0);
    }
    notifyListeners();
  }

  void goToPrevious() {
    if (_matchCount <= 0) {
      return;
    }
    _activeIndex = (_activeIndex - 1 + _matchCount) % _matchCount;
    notifyListeners();
  }

  void goToNext() {
    if (_matchCount <= 0) {
      return;
    }
    _activeIndex = (_activeIndex + 1) % _matchCount;
    notifyListeners();
  }

  void clear() {
    _matchCount = 0;
    _activeIndex = 0;
    notifyListeners();
  }
}

/// Backwards-compatible alias used by older call sites.
typedef JsonTreeSearchNavigator = JsonTreeSearchSession;
