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
          return http.Response.bytes(
            utf8.encode(jsonEncode({
              'data': [
                {
                  'id': 4,
                  'parent_id': null,
                  'name': 'مجوزها',
                  'slug': 'licenses',
                  'has_children': true,
                  'is_active': true
                },
                {
                  'id': 5,
                  'parent_id': 4,
                  'name': 'مشاغل خانگی',
                  'slug': 'home-businesses',
                  'has_children': true,
                  'is_active': true
                },
                {
                  'id': 6,
                  'parent_id': 5,
                  'name': 'تولیدی و صنعتی',
                  'slug': 'home-production',
                  'has_children': false,
                  'is_active': true
                }
              ]
            })),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'data': [
              {
                'id': 12,
                'title': 'جواز کسب',
                'slug': 'business-license',
                'requirements': ['کارت ملی'],
                'estimated_days': '7',
                'base_price': 1200000.75,
                'category': {'name': 'مجوزها', 'slug': 'licenses'}
              }
            ],
            'meta': {'current_page': 1}
          })),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final repository = ServiceCatalogRepository(api);
    final categories = await repository.getCategories();
    final tree = await repository.getCategoryTree();
    final services = await repository.getServices();

    expect(categories.singleWhere((item) => item.slug == 'licenses').hasChildren,
        isTrue);
    expect(tree.single.slug, 'licenses');
    expect(tree.single.children.single.slug, 'home-businesses');
    expect(
      tree.single.children.single.children.single.slug,
      'home-production',
    );
    expect(services.single.id, '12');
    expect(services.single.estimatedDays, 7);
    expect(services.single.requirements, ['کارت ملی']);
    expect(services.single.basePrice, 1200000.75);
    expect(services.single.categoryName, 'مجوزها');
    api.close();
  });
}
