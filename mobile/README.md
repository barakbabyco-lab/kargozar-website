# اپلیکیشن اندروید کارگزار

اپلیکیشن مشتری کارگزار با Flutter ساخته می‌شود.

## وضعیت فعلی
- رابط اولیه خانه، فهرست خدمات، درخواست‌ها و حساب کاربری در `lib/main.dart` قرار دارد.
- فرم ثبت درخواست فعلاً نمایشی است و اطلاعات را ذخیره یا ارسال نمی‌کند.
- کلاینت API نسخه `v1` در `lib/core/network/kargozar_api_client.dart` پیاده‌سازی شده و از توکن امن پشتیبانی می‌کند.
- هماهنگ‌کننده نشست مشتری در `lib/features/auth/customer_session.dart` قرار دارد.
- مخزن تایپ‌شده دسته‌بندی‌ها و خدمات در `lib/features/catalog/service_catalog_repository.dart` و مخزن پرونده‌های مشتری در `lib/features/requests/customer_request_repository.dart` اضافه شده‌اند.
- این مخزن‌ها و مدل‌های داده تست واحد دارند؛ رابط نمونه هنوز به آن‌ها متصل نشده است.
- هیچ‌گاه اطلاعات واقعی مشتری یا مدارک هویتی را در نسخه آزمایشی وارد نکنید.

## پیکربندی API
پس از استقرار بک‌اند، نشانی ریشه API را هنگام اجرا یا ساخت تعیین کنید. نشانی باید شامل پیشوند نسخه باشد:

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

برای ساخت APK آزمایشی:

```bash
flutter build apk --debug
```

توکن دسترسی پس از تأیید OTP با `flutter_secure_storage` در فضای امن سیستم‌عامل نگهداری می‌شود. در آغاز برنامه باید `await api.restoreAccessToken()` اجرا شود؛ هماهنگ‌کننده `CustomerSession.restore()` این کار را انجام می‌دهد. سپس درخواست‌های نیازمند ورود می‌توانند از نشست بازیابی‌شده استفاده کنند. متد `verifyOtp` توکن پاسخ را ذخیره و `logout` پس از موفقیت سرور آن را پاک می‌کند. کلید پیامک یا کلید خصوصی هرگز نباید داخل سورس یا فایل‌های قابل انتشار قرار بگیرد.

## مستندات فنی
- معماری: `../docs/mobile-app-architecture.md`
- طرح دیتابیس: `../docs/database-blueprint.md`
- قرارداد API: `../docs/api-contract.md`

## ساخت خودکار
گردش کار GitHub Actions در `../.github/workflows/android-build.yml`، فایل‌های Android را تولید، وابستگی‌ها را نصب، کد برنامه را تحلیل و APK آزمایشی را می‌سازد. خروجی موفق با نام `kargozar-android-debug` به‌صورت Artifact منتشر می‌شود.
