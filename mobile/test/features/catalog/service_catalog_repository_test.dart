import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kargozar_mobile/core/network/kargozar_api_client.dart';
import 'package:kargozar_mobile/features/catalog/service_catalog_repository.dart';

void main() {
  test('maps API category and service resources into typed models', () async {
    final api = KargozarApiClient(
      baseUrl: 'https://api.example.test/api/v1',
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/service-categories')) {
          return http.Response(jsonEncode({
            'data': [
              {'id': 4, 'name': 'مجوزها', 'slug': 'licenses', 'is_active': true}
            ]
          }), 200);
        }
        return http.Response(jsonEncode({
          'data': [
            {
              'id': 12,
              'title': 'جواز کسب',
              'slug': 'business-license',
              'requirements': ['کارت ملی'],
              'estimated_days': '7',
              'base_price': 1200000,
              'category': {'name': 'مجوزها', 'slug': 'licenses'}
            }
          ],
          'meta': {'current_page': 1}
        }), 200);
      }),
    );
    final categories = await ServiceCatalogRepository(api).getCategories();
    final services = await ServiceCatalogRepository(api).getServices();

    expect(categories.single.slug, 'licenses');
    expect(services.single.id, '12');
    expect(services.single.estimatedDays, 7);
    expect(services.single.requirements, ['کارت ملی']);
    expect(services.single.categoryName, 'مجوزها');
    api.close();
  });
}
