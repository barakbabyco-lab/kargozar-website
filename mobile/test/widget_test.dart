import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kargozar_mobile/core/network/access_token_store.dart';
import 'package:kargozar_mobile/core/network/kargozar_api_client.dart';
import 'package:kargozar_mobile/main.dart';

void main() {
  testWidgets('starts the API-backed Kargozar customer app', (tester) async {
    String? requestedCategory;
    final api = KargozarApiClient(
      baseUrl: 'https://api.example.test/api/v1',
      tokenStore: _MemoryTokenStore(),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/service-categories')) {
          return _jsonResponse({
            'data': [
              {
                'id': 4,
                'parent_id': null,
                'name': 'مجوزها',
                'slug': 'licenses',
                'has_children': true,
                'is_active': true,
              },
              {
                'id': 5,
                'parent_id': 4,
                'name': 'مشاغل خانگی',
                'slug': 'home-businesses',
                'has_children': true,
                'is_active': true,
              },
              {
                'id': 6,
                'parent_id': 5,
                'name': 'تولیدی و صنعتی',
                'slug': 'home-production',
                'has_children': false,
                'is_active': true,
              },
            ],
          });
        }

        requestedCategory = request.url.queryParameters['category'];
        return _jsonResponse({
          'data': requestedCategory == 'home-production'
              ? [
                  {
                    'id': 12,
                    'title': 'مجوز تولیدی خانگی',
                    'slug': 'home-production-license',
                    'description': 'خدمت آزمایشی زیرشاخه',
                    'requirements': [],
                    'category': {
                      'name': 'تولیدی و صنعتی',
                      'slug': 'home-production',
                    },
                  },
                ]
              : [],
        });
      }),
    );

    await tester.pumpWidget(KargozarApp(apiClient: api));
    await tester.pumpAndSettle();

    expect(find.text('کارگزار'), findsOneWidget);
    expect(find.text('خدمات پرکاربرد'), findsOneWidget);

    await tester.tap(find.text('خدمات'));
    await tester.pumpAndSettle();

    expect(find.text('همه خدمات'), findsOneWidget);
    expect(find.text('دسته‌بندی خدمات'), findsOneWidget);

    await tester.tap(find.text('مجوزها'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مشاغل خانگی'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تولیدی و صنعتی'));
    await tester.pumpAndSettle();

    expect(requestedCategory, 'home-production');
    expect(find.text('مجوز تولیدی خانگی'), findsOneWidget);
  });
}

http.Response _jsonResponse(Map<String, dynamic> body) => http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

class _MemoryTokenStore implements AccessTokenStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async {
    token = value;
  }

  @override
  Future<void> clear() async {
    token = null;
  }
}
