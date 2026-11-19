import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kargozar_mobile/core/network/access_token_store.dart';
import 'package:kargozar_mobile/core/network/kargozar_api_client.dart';
import 'package:kargozar_mobile/main.dart';

void main() {
  testWidgets('shows the approved four-tab Kargozar structure', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('کارگزار'), findsOneWidget);
    expect(find.text('همه خدمات'), findsOneWidget);
    expect(find.text('دسته‌بندی خدمات'), findsOneWidget);
    expect(find.text('مجوزهای کسب‌وکار'), findsOneWidget);
    expect(find.text('حساب کاربری من'), findsOneWidget);
    expect(find.text('خدمات'), findsOneWidget);
    expect(find.text('همراه کسب‌وکار'), findsOneWidget);
    expect(find.text('تماس و پشتیبانی'), findsOneWidget);

    await tester.tap(find.text('همراه کسب‌وکار'));
    await tester.pumpAndSettle();
    expect(find.text('پکیج‌های کارگزار'), findsOneWidget);
    expect(find.text('استودیو طراحی'), findsOneWidget);

    await tester.tap(find.text('تماس و پشتیبانی'));
    await tester.pumpAndSettle();
    expect(find.text('پشتیبانی کارگزار'), findsOneWidget);
  });

  testWidgets('request history requires customer authentication', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('حساب کاربری من'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('درخواست‌های من'));
    await tester.pumpAndSettle();

    expect(find.text('ورود به کارگزار'), findsOneWidget);
    expect(find.text('دریافت کد'), findsOneWidget);
  });

  testWidgets('does not report a successful login when API is not configured', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('حساب کاربری من'));
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
