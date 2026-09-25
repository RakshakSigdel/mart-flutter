import 'package:dio/dio.dart';

/// Public image search used by the category form. This request goes directly
/// from the app to Wikimedia Commons; the mart API only receives the chosen URL.
class CategoryImageSearchService {
  CategoryImageSearchService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://commons.wikimedia.org',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  final Dio _dio;

  Future<List<CategorySearchImage>> search(String query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/w/api.php',
      queryParameters: {
        'action': 'query',
        'format': 'json',
        'formatversion': 2,
        'origin': '*', // Required for requests from Flutter web.
        'generator': 'search',
        'gsrsearch': query.trim(),
        'gsrnamespace': 6, // File pages only.
        'gsrlimit': 24,
        'prop': 'imageinfo',
        'iiprop': 'url|mime|extmetadata',
        'iiurlwidth': 480,
      },
    );

    final pages = (response.data?['query'] as Map<String, dynamic>?)?['pages'];
    if (pages is! List) return [];

    final images = <CategorySearchImage>[];
    for (final page in pages) {
      if (page is! Map) continue;
      final infos = page['imageinfo'];
      if (infos is! List || infos.isEmpty || infos.first is! Map) continue;
      final info = infos.first as Map;
      final mime = info['mime'];
      if (mime != 'image/jpeg' && mime != 'image/png' && mime != 'image/webp') {
        continue;
      }
      final imageUrl = info['thumburl'] ?? info['url'];
      if (imageUrl is! String || !imageUrl.startsWith('https://')) continue;
      final metadata = info['extmetadata'];
      final license = metadata is Map && metadata['LicenseShortName'] is Map
          ? (metadata['LicenseShortName'] as Map)['value'] as String?
          : null;
      images.add(
        CategorySearchImage(
          title: (page['title'] as String? ?? 'Image').replaceFirst(
            'File:',
            '',
          ),
          imageUrl: imageUrl,
          license: license,
          sourceUrl: info['descriptionurl'] as String?,
        ),
      );
    }
    return images;
  }

  void dispose() => _dio.close(force: true);
}

class CategorySearchImage {
  const CategorySearchImage({
    required this.title,
    required this.imageUrl,
    this.license,
    this.sourceUrl,
  });

  final String title;
  final String imageUrl;
  final String? license;
  final String? sourceUrl;
}
