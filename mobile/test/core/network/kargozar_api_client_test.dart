import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kargozar_mobile/core/network/kargozar_api_client.dart';

void main() {
  group('KargozarApiClient', () {
    test('requests services with versioned URL and query parameters', () async {
      late http.Request captured;
      final client = KargozarApiClient(
        baseUrl: 'https://api.example.test/api/v1',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({'data': <dynamic>[]}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      await client.getServices(category: 'licenses', query: 'brand', page: 2);

      expect(captured.method, 'GET');
      expect(captured.url.path, '/api/v1/services');
      expect(captured.url.queryParameters['category'], 'licenses');
      expect(captured.url.queryParameters['q'], 'brand');
      expect(captured.url.queryParameters['page'], '2');
      client.close();
    });

    test('sends bearer token and idempotency key for new requests', () async {
      late http.Request captured;
      final client = KargozarApiClient(
        baseUrl: 'https://api.example.test/api/v1',
        accessToken: 'test-token',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({'data': {'tracking_code': 'KG-TEST'}}),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      await client.createServiceRequest(
        serviceId: 'service-123',
        customerNote: 'Test only',
        idempotencyKey: 'request-once-001',
      );

      expect(captured.headers['Authorization'], 'Bearer test-token');
      expect(captured.headers['Idempotency-Key'], 'request-once-001');
      expect(jsonDecode(captured.body)['service_id'], 'service-123');
      client.close();
    });

    test('converts API validation errors to a typed exception', () async {
      final client = KargozarApiClient(
        baseUrl: 'https://api.example.test/api/v1',
        httpClient: MockClient((request) async => http.Response(
          jsonEncode({
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'اطلاعات معتبر نیست.',
              'fields': {'mobile': ['شماره نامعتبر است.']},
            },
          }),
          422,
          headers: {'content-type': 'application/json; charset=utf-8'},
        )),
      );

      await expectLater(
        client.requestOtp('09120000000'),
        throwsA(
          isA<KargozarApiException>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having((error) => error.code, 'code', 'VALIDATION_ERROR'),
        ),
      );
      client.close();
    });
  });
}
