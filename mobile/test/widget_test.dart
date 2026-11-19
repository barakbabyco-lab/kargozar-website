import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kargozar_mobile/core/network/access_token_store.dart';
import 'package:kargozar_mobile/core/network/kargozar_api_client.dart';
import 'package:kargozar_mobile/main.dart';

void main() {
  testWidgets('renders the approved four-tab structure and compact navigation', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_testApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('دسته‌بندی خدمات'), findsOneWidget);
    expect(find.text('همه خدمات'), findsNothing);
    expect(find.text('حساب کاربری'), findsOneWidget);
    expect(find.text('خدمات'), findsOneWidget);
    expect(find.text('همراه کسب‌وکار'), findsOneWidget);
    expect(find.text('تماس و پشتیبانی'), findsNWidgets(2));

    await tester.tap(find.text('همراه کسب‌وکار'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('پکیج‌های کارگزار'), findsOneWidget);
    expect(find.text('استودیو طراحی'), findsOneWidget);
    expect(find.text('راهکارهای کسب‌وکار'), findsNothing);

    await tester.tap(find.text('تماس و پشتیبانی'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('ارسال پیام به پشتیبانی و ثبت تیکت'), findsOneWidget);
    expect(find.text('ارتباط آنلاین با پشتیبانی'), findsOneWidget);
    expect(find.text('دستیار هوشمند'), findsOneWidget);
    expect(find.text('وبلاگ و مقالات کارگزار'), findsOneWidget);
    expect(find.text('پشتیبانی کارگزار'), findsNothing);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('request history requires customer authentication', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('حساب کاربری'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('درخواست‌های من'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('ورود به کارگزار'), findsOneWidget);
    expect(find.text('دریافت کد'), findsOneWidget);
  });

  testWidgets('does not report a successful login when API is not configured', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('حساب کاربری'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('ورود / ثبت‌نام'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byWidgetPredicate((widget) => widget is TextField && widget.decoration?.labelText == 'شماره موبایل'),'09120000000');
    await tester.tap(find.text('دریافت کد'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('نشانی سرور هنوز تنظیم نشده است.'), findsOneWidget);
    expect(find.text('حساب شما فعال است'), findsNothing);
  });
}

Widget _testApp() => KargozarApp(apiClient: KargozarApiClient(tokenStore: _MemoryTokenStore()));
class _MemoryTokenStore implements AccessTokenStore {
 String? _token;
 @override Future<String?> read() async=>_token;
 @override Future<void> write(String token) async{_token=token;}
 @override Future<void> clear() async{_token=null;}
}
