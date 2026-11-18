import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kargozar_mobile/core/network/access_token_store.dart';
import 'package:kargozar_mobile/core/network/kargozar_api_client.dart';
import 'package:kargozar_mobile/main.dart';

void main() {
  testWidgets('preserves the approved Kargozar customer UI and navigation', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('کارگزار'), findsOneWidget);
    expect(find.text('خدمات پرکاربرد'), findsOneWidget);
    expect(find.text('شروع یک کسب‌وکار،\nبا مسیر روشن‌تر'), findsOneWidget);
    expect(find.text('خانه'), findsOneWidget);
    expect(find.text('خدمات'), findsOneWidget);
    expect(find.text('درخواست‌ها'), findsOneWidget);
    expect(find.text('حساب من'), findsOneWidget);

    // The home-page call to action must navigate to the service catalogue,
    // rather than implying that a consultation request was already created.
    await tester.tap(find.text('مشاهده خدمات'));
    await tester.pumpAndSettle();
    expect(find.text('همه خدمات'), findsOneWidget);

    await tester.tap(find.text('خدمات'));
    await tester.pumpAndSettle();

    expect(find.text('همه خدمات'), findsOneWidget);
    expect(find.text('جست‌وجوی خدمات...'), findsOneWidget);
    expect(find.text('دریافت جواز کسب'), findsOneWidget);
  });

  testWidgets('requests tab offers a working login entry point', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('درخواست‌ها'));
    await tester.pumpAndSettle();

    expect(find.text('برای مشاهده درخواست‌ها وارد شو'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'ورود / ثبت‌نام'));
    await tester.pumpAndSettle();

    expect(find.text('ورود به کارگزار'), findsOneWidget);
  });

  testWidgets('does not report a successful login when API is not configured', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('حساب من'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ورود / ثبت‌نام'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '09120000000');
    await tester.tap(find.text('دریافت کد'));
    await tester.pumpAndSettle();

    expect(find.text('نشانی سرور هنوز تنظیم نشده است.'), findsOneWidget);
    expect(find.text('حساب شما فعال است'), findsNothing);
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
