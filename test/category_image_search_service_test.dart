import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sts_retail/presentation/feature_user/inventory_categories/services/category_image_search_service.dart';

void main() {
  test('search requests Commons files and returns usable image URLs', () async {
    RequestOptions? request;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                'query': {
                  'pages': [
                    {
                      'title': 'File:Tea.jpg',
                      'imageinfo': [
                        {
                          'mime': 'image/jpeg',
                          'url': 'https://upload.wikimedia.org/full.jpg',
                          'thumburl': 'https://upload.wikimedia.org/thumb.jpg',
                          'descriptionurl':
                              'https://commons.wikimedia.org/wiki/File:Tea.jpg',
                          'extmetadata': {
                            'LicenseShortName': {'value': 'CC BY-SA 4.0'},
                          },
                        },
                      ],
                    },
                    {
                      'title': 'File:Tea.svg',
                      'imageinfo': [
                        {
                          'mime': 'image/svg+xml',
                          'url': 'https://upload.wikimedia.org/tea.svg',
                        },
                      ],
                    },
                  ],
                },
              },
            ),
          );
        },
      ),
    );

    final service = CategoryImageSearchService(dio: dio);
    final results = await service.search('tea');

    expect(request?.path, '/w/api.php');
    expect(request?.queryParameters['gsrsearch'], 'tea');
    expect(request?.queryParameters['gsrnamespace'], 6);
    expect(request?.queryParameters['origin'], '*');
    expect(results, hasLength(1));
    expect(results.single.imageUrl, 'https://upload.wikimedia.org/thumb.jpg');
    expect(results.single.title, 'Tea.jpg');
    expect(results.single.license, 'CC BY-SA 4.0');
    service.dispose();
  });
}
