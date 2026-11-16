import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kargozar_mobile/core/network/access_token_store.dart';
import 'package:kargozar_mobile/core/network/kargozar_api_client.dart';
import 'package:kargozar_mobile/features/auth/customer_session.dart';

void main() {
  test('restores a previously persisted customer session', () async {
    final store = _MemoryTokenStore()..token = 'persisted-token';
    final api = KargozarApiClient(
      baseUrl: 'https://api.example.test/api/v1',
      tokenStore: store,
      httpClient: MockClient((request) async => http.Response(
        jsonEncode({'data': <dynamic>[]}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      )),
    );
    const session = CustomerSessionPlaceholder();

    final customerSession = CustomerSession(api);
    expect(customerSession.isAuthenticated, isFalse);
    expect(await customerSession.restore(), isTrue);
    expect(customerSession.isAuthenticated, isTrue);
    api.close();
  });
}

class _MemoryTokenStore implements AccessTokenStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}

class CustomerSessionPlaceholder {
  const CustomerSessionPlaceholder();
}
