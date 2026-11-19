import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kargozar_mobile/core/network/access_token_store.dart';
import 'package:kargozar_mobile/core/network/kargozar_api_client.dart';
import 'package:kargozar_mobile/main.dart';

void main() {
  testWidgets('renders the main app shell with page navigation and floating support', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('main-tabs')), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('خدمات'), findsOneWidget);
    expect(find.byType(SupportChatLauncher), findsOneWidget);
  });
}

Widget _testApp() => KargozarApp(
  apiClient: KargozarApiClient(tokenStore: _MemoryTokenStore()),
);

class _MemoryTokenStore implements AccessTokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async {
    _token = token;
  }

  @override
  Future<void> clear() async {
    _token = null;
  }
}
