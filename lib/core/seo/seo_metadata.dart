import 'seo_metadata_stub.dart'
    if (dart.library.html) 'seo_metadata_web.dart' as seo;

abstract final class SeoMetadata {
  static void apply({
    required String title,
    String? description,
  }) {
    seo.applySeoMetadata(title: title, description: description);
  }
}
