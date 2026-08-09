import 'package:flutter/material.dart';

class JsonSyntaxColors extends ThemeExtension<JsonSyntaxColors> {
  const JsonSyntaxColors({
    required this.key,
    required this.string,
    required this.number,
    required this.boolean,
    required this.nullValue,
    required this.structure,
    required this.searchHighlight,
  });

  final Color key;
  final Color string;
  final Color number;
  final Color boolean;
  final Color nullValue;
  final Color structure;
  final Color searchHighlight;

  static const JsonSyntaxColors light = JsonSyntaxColors(
    key: Color(0xFF1B6B93),
    string: Color(0xFF0F766E),
    number: Color(0xFFB45309),
    boolean: Color(0xFF7C3AED),
    nullValue: Color(0xFF64748B),
    structure: Color(0xFF475569),
    searchHighlight: Color(0xFFFEF08A),
  );

  static const JsonSyntaxColors dark = JsonSyntaxColors(
    key: Color(0xFF7DD3FC),
    string: Color(0xFF5EEAD4),
    number: Color(0xFFFCD34D),
    boolean: Color(0xFFC4B5FD),
    nullValue: Color(0xFF94A3B8),
    structure: Color(0xFFCBD5E1),
    searchHighlight: Color(0xFF854D0E),
  );

  static JsonSyntaxColors of(BuildContext context) {
    return Theme.of(context).extension<JsonSyntaxColors>() ?? light;
  }

  @override
  JsonSyntaxColors copyWith({
    Color? key,
    Color? string,
    Color? number,
    Color? boolean,
    Color? nullValue,
    Color? structure,
    Color? searchHighlight,
  }) {
    return JsonSyntaxColors(
      key: key ?? this.key,
      string: string ?? this.string,
      number: number ?? this.number,
      boolean: boolean ?? this.boolean,
      nullValue: nullValue ?? this.nullValue,
      structure: structure ?? this.structure,
      searchHighlight: searchHighlight ?? this.searchHighlight,
    );
  }

  @override
  JsonSyntaxColors lerp(ThemeExtension<JsonSyntaxColors>? other, double t) {
    if (other is! JsonSyntaxColors) {
      return this;
    }

    return JsonSyntaxColors(
      key: Color.lerp(key, other.key, t)!,
      string: Color.lerp(string, other.string, t)!,
      number: Color.lerp(number, other.number, t)!,
      boolean: Color.lerp(boolean, other.boolean, t)!,
      nullValue: Color.lerp(nullValue, other.nullValue, t)!,
      structure: Color.lerp(structure, other.structure, t)!,
      searchHighlight: Color.lerp(searchHighlight, other.searchHighlight, t)!,
    );
  }
}
