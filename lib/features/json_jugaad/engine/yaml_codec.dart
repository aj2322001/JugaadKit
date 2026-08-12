import 'package:yaml/yaml.dart';

import 'jugaad_validator.dart';

abstract final class YamlCodec {
  static Object? tryParse(String input) {
    if (!JugaadValidator.looksLikeYaml(input)) {
      return null;
    }

    try {
      final document = loadYaml(input);
      return _yamlToJson(document);
    } on YamlException {
      return null;
    }
  }

  static Object? _yamlToJson(Object? value) {
    if (value is YamlMap) {
      return value.map(
        (key, entryValue) => MapEntry(
          key.toString(),
          _yamlToJson(entryValue),
        ),
      );
    }

    if (value is YamlList) {
      return value.map(_yamlToJson).toList();
    }

    return value;
  }
}
