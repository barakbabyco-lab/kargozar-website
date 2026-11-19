import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kargozar_mobile/core/network/access_token_store.dart';
import 'package:kargozar_mobile/core/network/kargozar_api_client.dart';
import 'package:kargozar_mobile/main.dart';

void main() {
  testWidgets('swiping between main pages reveals support and profile actions', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(PageView), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);

    final shellPager = find.byType(PageView).first;
    await tester.drag(shellPager, const Offset(-620, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.drag(shellPager, const Offset(-620, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('تماس تلفنی'), findsOneWidget);
    expect(find.text('ارتباط از طریق ایمیل'), findsOneWidget);
    expect(find.text('ثبت و پیگیری تیکت'), findsOneWidget);
    expect(find.text('دستیار هوشمند کارگزار'), findsOneWidget);

    await tester.drag(shellPager, const Offset(620, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.drag(shellPager, const Offset(620, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('درخواست‌های من'), findsOneWidget);
    expect(find.text('احراز هویت'), findsOneWidget);
    expect(find.text('پشتیبانی و تماس با ما'), findsNothing);
  });

  testWidgets('request history requires customer authentication', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    await tester.drag(find.byType(PageView).first, const Offset(620, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.tap(find.text('درخواست‌های من'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('ورود به کارگزار'), findsOneWidget);
    expect(find.text('دریافت کد'), findsOneWidget);
  });

  testWidgets('does not report a successful login when API is not configured', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    await tester.tap(find.text('حساب کاربری من'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.drag(find.byType(PageView).first, const Offset(620, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.ensureVisible(find.text('ورود / ثبت‌نام'));
    await tester.tap(find.text('ورود / ثبت‌نام'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    await tester.enterText(
      find.byWidgetPredicate((widget) => widget is TextField && widget.decoration?.labelText == 'شماره موبایل'),
      '09120000000',
    );
    await tester.tap(find.text('دریافت کد'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

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
