import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kargozar_mobile/core/network/access_token_store.dart';
import 'package:kargozar_mobile/core/network/kargozar_api_client.dart';

void main() {
  group('KargozarApiClient', () {
    test('rejects remote HTTP API URLs before sending customer data', () async {
      final client = KargozarApiClient(
        baseUrl: 'http://api.example.test/api/v1',
        httpClient: MockClient((request) async {
          fail('An insecure remote URL must never receive a request.');
        }),
      );

      await expectLater(
        client.requestOtp('09120000000'),
        throwsA(
          isA<KargozarApiException>()
              .having((error) => error.code, 'code', 'API_INSECURE_URL'),
        ),
      );
      client.close();
    });

    test('allows local emulator HTTP URLs for development', () async {
      final client = KargozarApiClient(
        baseUrl: 'http://10.0.2.2:8000/api/v1',
        httpClient: MockClient((request) async => http.Response(
          jsonEncode({'data': <dynamic>[]}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        )),
      );

      await client.getServices();
      client.close();
    });

    test('normalizes a host-only API URL to the versioned API path', () async {
      late http.Request captured;
      final client = KargozarApiClient(
        baseUrl: 'https://api.example.test',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({'data': <dynamic>[]}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      await client.getServices();

      expect(captured.url.path, '/api/v1/services');
      client.close();
    });

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

    test('stores the access token returned by OTP verification', () async {
      final tokenStore = FakeAccessTokenStore();
      late http.Request authenticatedRequest;
      final client = KargozarApiClient(
        baseUrl: 'https://api.example.test/api/v1',
        tokenStore: tokenStore,
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/auth/otp/verify')) {
            return http.Response(
              jsonEncode({
                'data': {
                  'access_token': 'issued-token',
                  'token_type': 'Bearer',
                  'expires_at': '2026-12-01T00:00:00Z',
                  'customer': {'id': 'cust-1', 'mobile': '09120000000'},
                },
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          authenticatedRequest = request;
          return http.Response(
            jsonEncode({'data': <dynamic>[]}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      await client.verifyOtp(mobile: '09120000000', code: '123456');
      expect(tokenStore.value, 'issued-token');
      await client.getMyRequests();
      expect(authenticatedRequest.headers['Authorization'], 'Bearer issued-token');
      client.close();
    });

    test('uses authenticated endpoints for support chat messages', () async {
      final requests = <http.Request>[];
      final client = KargozarApiClient(
        baseUrl: 'https://api.example.test/api/v1',
        accessToken: 'chat-token',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({'data': {'id': 41, 'sender_type': 'customer', 'body': 'سلام'}}),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      await client.startSupportConversation('سلام');
      await client.sendSupportMessage(41, 'پیام دوم');
      await client.getSupportMessages(41);

      expect(requests[0].method, 'POST');
      expect(requests[0].url.path, '/api/v1/support-conversations');
      expect(requests[0].headers['Authorization'], 'Bearer chat-token');
      expect(jsonDecode(requests[0].body)['body'], 'سلام');
      expect(requests[1].url.path, '/api/v1/me/support-conversations/41/messages');
      expect(requests[2].method, 'GET');
      client.close();
    });

    test('persists and reuses the installation guest token for support chat', () async {
      final guestTokenStore = FakeGuestSupportTokenStore();
      final requests = <http.Request>[];
      final client = KargozarApiClient(
        baseUrl: 'https://api.example.test/api/v1',
        guestTokenStore: guestTokenStore,
        httpClient: MockClient((request) async {
          requests.add(request);
          final payload = request.method == 'GET'
              ? {'data': <dynamic>[]}
              : request.url.path.endsWith('/guest/support-conversations')
                  ? {'data': {'id': 41, 'messages': <dynamic>[]}}
                  : {'data': {'id': 42, 'sender_type': 'customer', 'body': 'پیام دوم'}};
          return http.Response(
            jsonEncode(payload),
            request.method == 'GET' ? 200 : 201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      await client.startGuestSupportConversation('سلام');
      expect(await client.restoreGuestSupportConversationId(), 41);
      await client.sendGuestSupportMessage(41, 'پیام دوم');
      await client.getGuestSupportMessages(41);

      expect(guestTokenStore.value, matches(RegExp(r'^[a-f0-9]{64}$')));
      expect(requests, hasLength(3));
      expect(requests[0].url.path, '/api/v1/guest/support-conversations');
      expect(requests[1].url.path, '/api/v1/guest/support-conversations/41/messages');
      expect(requests[2].url.path, '/api/v1/guest/support-conversations/41/messages');
      for (final request in requests) {
        expect(request.headers['X-Support-Guest-Token'], guestTokenStore.value);
      }
      client.close();
    });

    test('restores a saved token and clears it after logout', () async {
      final tokenStore = FakeAccessTokenStore()..value = 'saved-token';
      late http.Request logoutRequest;
      final client = KargozarApiClient(
        baseUrl: 'https://api.example.test/api/v1',
        tokenStore: tokenStore,
        httpClient: MockClient((request) async {
          logoutRequest = request;
          return http.Response('', 204);
        }),
      );

      await client.restoreAccessToken();
      await client.logout();

      expect(logoutRequest.headers['Authorization'], 'Bearer saved-token');
      expect(tokenStore.value, isNull);
      client.close();
    });
  });
}

class FakeAccessTokenStore implements AccessTokenStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async {
    value = token;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class FakeGuestSupportTokenStore extends SecureGuestSupportTokenStore {
  String? value;
  int? conversationId;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async {
    value = token;
  }

  @override
  Future<int?> readConversationId() async => conversationId;

  @override
  Future<void> writeConversationId(int id) async {
    conversationId = id;
  }

  @override
  Future<void> clearConversationId() async {
    conversationId = null;
  }

  @override
  Future<void> clear() async {
    value = null;
    conversationId = null;
  }
}
