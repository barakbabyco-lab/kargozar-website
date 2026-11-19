import 'package:flutter_test/flutter_test.dart';
import 'package:kargozar_mobile/features/content/app_content.dart';

void main() {
 test('bundled service categories include ten approved illustrations',(){
  expect(serviceCategoryImages.length,10);
  expect(serviceCategoryImages.values.every((v)=>v.endsWith('.svg')),isTrue);
 });
 test('business companion contains nine image-backed modules',(){
  expect(companionModules.length,9);
  expect(companionModules.every((m)=>m.image.endsWith('.svg')),isTrue);
 });
 test('banner carousel has five full-width slides',(){
  expect(AppBannerStrip.banners.length,5);
  expect(AppBannerStrip.banners.every((b)=>b.$1.endsWith('.svg')),isTrue);
 });
}
