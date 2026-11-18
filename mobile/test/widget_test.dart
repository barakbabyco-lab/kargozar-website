import 'package:flutter_test/flutter_test.dart';
import 'package:kargozar_mobile/main.dart';

void main() {
  testWidgets('renders the Kargozar customer services home', (tester) async {
    await tester.pumpWidget(const KargozarApp());

    expect(find.text('کارگزار'), findsWidgets);
    expect(find.text('دسته‌بندی خدمات'), findsOneWidget);
    expect(find.text('مجوزهای کسب‌وکار'), findsOneWidget);
    expect(find.text('پروفایل من'), findsOneWidget);
    expect(find.text('همراه کسب‌وکار'), findsOneWidget);
    expect(find.text('ارتباط و پشتیبانی'), findsOneWidget);
  });
}
