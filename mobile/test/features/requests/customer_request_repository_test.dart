import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kargozar_mobile/core/network/kargozar_api_client.dart';
import 'package:kargozar_mobile/features/requests/customer_request_repository.dart';

void main() {
  test('creates a request with auth and idempotency headers and parses tracking', () async {
    final api = KargozarApiClient(
      baseUrl: 'https://api.example.test/api/v1',
      accessToken: 'customer-token',
      httpClient: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer customer-token');
        expect(request.headers['Idempotency-Key'], 'idempotency-key-123456');
        expect(jsonDecode(request.body)['service_id'], '12');
        return http.Response(jsonEncode({
          'data': {
            'id': 'public-id-1',
            'tracking_code': 'KG-ABC123',
            'status': 'submitted',
            'created_at': '2026-11-16T05:00:00Z'
          }
        }), 201);
      }),
    );

    final result = await CustomerRequestRepository(api).create(
      serviceId: '12',
      idempotencyKey: 'idempotency-key-123456',
    );

    expect(result.trackingCode, 'KG-ABC123');
    expect(result.status, 'submitted');
    expect(result.id, 'public-id-1');
    api.close();
  });

  test('loads the authenticated customer request list', () async {
    final api = KargozarApiClient(
      baseUrl: 'https://api.example.test/api/v1',
      accessToken: 'customer-token',
      httpClient: MockClient((request) async => http.Response(jsonEncode({
        'data': [
          {'id': 'public-id-2', 'tracking_code': 'KG-XYZ', 'status': 'reviewing'}
        ],
        'meta': {'current_page': 1}
      }), 200)),
    );

    final results = await CustomerRequestRepository(api).getMine();

    expect(results.single.trackingCode, 'KG-XYZ');
    expect(results.single.status, 'reviewing');
    api.close();
  });
}
