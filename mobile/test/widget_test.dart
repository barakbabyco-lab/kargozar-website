import 'package:flutter_test/flutter_test.dart';
import 'package:kargozar_mobile/main.dart';

void main() {
  testWidgets('renders the Kargozar customer app', (tester) async {
    await tester.pumpWidget(const KargozarApp());
    expect(find.text('کارگزار'), findsWidgets);
    expect(find.text('همه خدمات'), findsOneWidget);
  });
}
