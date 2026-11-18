import 'package:flutter_test/flutter_test.dart';
import 'package:kargozar_mobile/main.dart';

void main() {
  testWidgets('preserves the approved Kargozar customer UI and navigation', (tester) async {
    await tester.pumpWidget(const KargozarApp());

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
}
