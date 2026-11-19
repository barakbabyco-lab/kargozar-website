import 'package:flutter_test/flutter_test.dart';
import 'package:kargozar_mobile/features/content/app_content.dart';

void main() {
  group('resolveAppContentImageUri', () {
    test('returns null when the asset host is not configured', () {
      expect(resolveAppContentImageUri('banner-01-support.png', baseUrl: ''), isNull);
    });

    test('rejects cleartext HTTP asset hosts', () {
      expect(
        resolveAppContentImageUri(
          'banner-01-support.png',
          baseUrl: 'http://assets.example.ir/images',
        ),
        isNull,
      );
    });

    test('rejects URLs containing credentials, query, or fragment', () {
      for (final value in [
        'https://user:pass@assets.example.ir/images',
        'https://assets.example.ir/images?token=secret',
        'https://assets.example.ir/images#fragment',
      ]) {
        expect(resolveAppContentImageUri('image.png', baseUrl: value), isNull);
      }
    });


    test('rejects path-like or unsafe filenames', () {
      for (final value in ['../secret.png', 'nested/image.png', '']) {
        expect(
          resolveAppContentImageUri(value, baseUrl: 'https://assets.example.ir/images'),
          isNull,
        );
      }
    });

    test('resolves a file beneath the configured HTTPS directory', () {
      expect(
        resolveAppContentImageUri(
          'banner-01-support.png',
          baseUrl: 'https://assets.example.ir/kargozar-assets/final/',
        ),
        Uri.parse('https://assets.example.ir/kargozar-assets/final/banner-01-support.png'),
      );
    });
  });
}
