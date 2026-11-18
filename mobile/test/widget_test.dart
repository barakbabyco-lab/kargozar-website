import 'package:flutter_test/flutter_test.dart';
import 'package:kargozar_mobile/app/kargozar_app.dart';

void main() {
  test('Kargozar application widget is available', () {
    expect(const KargozarApp(), isA<KargozarApp>());
  });
}
