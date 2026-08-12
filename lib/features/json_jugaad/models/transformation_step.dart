enum TransformationType {
  normalized,
  removedWrapper,
  decodedEscaped,
  urlDecoded,
  base64Decoded,
  hexDecoded,
  htmlEntitiesDecoded,
  jsonExtracted,
  jsonpExtracted,
  trailingCommaRemoved,
  commentRemoved,
  compressedDecoded,
  parsedJson,
  parsedNdjson,
  parsedQueryString,
  detectedJwt,
  extractedNestedJson,
  parsedCurl,
  parsedHttpHeaders,
  parsedUrl,
  parsedCsv,
  parsedYaml,
  formattedXml,
  parsedHttpResponse,
}

class TransformationStep {
  const TransformationStep({
    required this.type,
    required this.description,
    this.detail,
  });

  final TransformationType type;
  final String description;
  final String? detail;

  @override
  String toString() => description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransformationStep &&
          type == other.type &&
          description == other.description &&
          detail == other.detail;

  @override
  int get hashCode => Object.hash(type, description, detail);
}
