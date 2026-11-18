import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kargozar_mobile/core/network/access_token_store.dart';
import 'package:kargozar_mobile/core/network/kargozar_api_client.dart';
import 'package:kargozar_mobile/main.dart';

void main() {
  testWidgets('starts the API-backed Kargozar customer app', (tester) async {
    final api = KargozarApiClient(
      baseUrl: 'https://api.example.test/api/v1',
      tokenStore: _MemoryTokenStore(),
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({'data': []}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
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
    expect(find.text('نمایش همه خدمات'), findsOneWidget);
  });
}

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
