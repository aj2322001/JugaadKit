abstract final class JsonPath {
  static const String root = r'$';

  static final RegExp _identifierPattern = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

  static String childPath(String parentPath, String key) {
    if (_identifierPattern.hasMatch(key)) {
      return '$parentPath.$key';
    }
    return '$parentPath["${_escape(key)}"]';
  }

  static String indexPath(String parentPath, int index) {
    return '$parentPath[$index]';
  }

  static String _escape(String key) {
    return key.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  }
}
