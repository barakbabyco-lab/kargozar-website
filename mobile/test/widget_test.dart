import 'package:flutter_test/flutter_test.dart';
import 'package:kargozar_mobile/main.dart';

void main() {
  testWidgets('starts the API-backed Kargozar customer app', (tester) async {
    await tester.pumpWidget(const KargozarApp());

    // Secure-storage is not available in the widget-test host; the app must
    // recover from that and render its normal shell rather than remain stuck.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('کارگزار'), findsOneWidget);
    expect(find.text('خدمات پرکاربرد'), findsOneWidget);
    expect(find.text('همه خدمات'), findsNothing);
  });
}
