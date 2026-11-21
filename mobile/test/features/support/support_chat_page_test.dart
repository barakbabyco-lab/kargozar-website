import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kargozar_mobile/core/network/access_token_store.dart';
import 'package:kargozar_mobile/core/network/kargozar_api_client.dart';
import 'package:kargozar_mobile/features/support/support_chat_page.dart';

void main() {
  testWidgets('starts a guest conversation and renders the assistant reply',
      (tester) async {
    final store = _FakeGuestSupportTokenStore();
    final client = KargozarApiClient(
      baseUrl: 'https://api.example.test/api/v1',
      guestTokenStore: store,
      httpClient: MockClient((request) async {
        expect(request.headers['X-Support-Guest-Token'], isNotEmpty);
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/guest/support-conversations');
        return http.Response(
          jsonEncode({
            'data': {
              'id': 41,
              'status': 'open',
              'messages': [
                {
                  'id': 1,
                  'sender_type': 'customer',
                  'body': 'سلام',
                  'created_at': '2026-11-21T10:00:00Z',
                },
                {
                  'id': 2,
                  'sender_type': 'assistant',
                  'body': 'سلام، چطور می‌توانم راهنمایی‌تان کنم؟',
                  'created_at': '2026-11-21T10:00:01Z',
                },
              ],
            },
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: SupportChatPage(api: client),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'سلام');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(await store.readConversationId(), 41);
    expect(find.text('سلام'), findsOneWidget);
    expect(find.text('سلام، چطور می‌توانم راهنمایی‌تان کنم؟'), findsOneWidget);
    expect(find.text('دستیار کارگزار'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    client.close();
  });

  testWidgets('restores a saved guest conversation on page open',
      (tester) async {
    final store = _FakeGuestSupportTokenStore()
      ..value = 'a' * 64
      ..conversationId = 73;
    final client = KargozarApiClient(
      baseUrl: 'https://api.example.test/api/v1',
      guestTokenStore: store,
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          '/api/v1/guest/support-conversations/73/messages',
        );
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 5,
                'sender_type': 'customer',
                'body': 'پیام قبلی',
                'created_at': '2026-11-21T10:00:00Z',
              },
              {
                'id': 6,
                'sender_type': 'assistant',
                'body': 'پاسخ قبلی',
                'created_at': '2026-11-21T10:00:01Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: SupportChatPage(api: client),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('پیام قبلی'), findsOneWidget);
    expect(find.text('پاسخ قبلی'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    client.close();
  });
}

class _FakeGuestSupportTokenStore extends SecureGuestSupportTokenStore {
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
