import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kargozar_mobile/main.dart';

void main() {
  testWidgets('preserves the approved Kargozar customer UI and navigation', (tester) async {
    await tester.pumpWidget(const KargozarApp());
    await tester.pumpAndSettle();

    expect(find.text('کارگزار'), findsOneWidget);
    expect(find.text('خدمات پرکاربرد'), findsOneWidget);
    expect(find.text('شروع یک کسب‌وکار،\nبا مسیر روشن‌تر'), findsOneWidget);
    expect(find.text('خانه'), findsOneWidget);
    expect(find.text('خدمات'), findsOneWidget);
    expect(find.text('درخواست‌ها'), findsOneWidget);
    expect(find.text('حساب من'), findsOneWidget);

    await tester.tap(find.text('خدمات'));
    await tester.pumpAndSettle();

    expect(find.text('همه خدمات'), findsOneWidget);
    expect(find.text('جست‌وجوی خدمات...'), findsOneWidget);
    expect(find.text('دریافت جواز کسب'), findsOneWidget);
  });

  testWidgets('does not report a successful login when API is not configured', (tester) async {
    await tester.pumpWidget(const KargozarApp());
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
