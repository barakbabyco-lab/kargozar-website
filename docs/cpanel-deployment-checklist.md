# راهنمای ارزیابی و استقرار بک‌اند کارگزار روی هاست cPanel باراک‌مد

این راهنما برای بررسی امکان میزبانی موقت/اولیه API کارگزار روی همان هاست باراک‌مد است. تا پیش از تأیید همه پیش‌نیازها، هیچ فایل عملیاتی یا دیتابیس production ایجاد نکنید.

## معماری پیشنهادی

- نشانی API: یک زیردامنه مستقل مانند `api.barakmod.ir` (پس از تأیید مالکیت و تنظیم DNS).
- ریشه پروژه Laravel: خارج از web root، برای مثال `/home/CPANEL_USER/apps/kargozar-api`.
- Document Root زیردامنه: فقط `/home/CPANEL_USER/apps/kargozar-api/public`.
- دیتابیس: یک MySQL database و user مستقل مخصوص کارگزار؛ هرگز از دیتابیس‌های وردپرس باراک‌مد استفاده نشود.
- ارتباط اپ و وب‌سایت با بک‌اند فقط از HTTPS و API نسخه‌بندی‌شده `/api/v1` انجام شود.

## دروازه‌های فنی پیش از نصب

همه موارد باید روی همان زیردامنه و همان محیطی که PHP اجرا می‌شود تأیید شوند:

1. PHP نسخه 8.3 یا بالاتر؛ هم در MultiPHP Manager برای دامنه و هم در CLI/SSH.
2. Composer نسخه 2 و امکان اجرای `composer install --no-dev --prefer-dist --optimize-autoloader`.
3. افزونه‌های PHP: ctype, curl, dom, fileinfo, filter, hash, mbstring, openssl, pcre, pdo, pdo_mysql, session, tokenizer, xml.
4. MySQL نسخه 8.0 یا بالاتر، یا نسخه سازگار تأییدشده؛ دیتابیس و کاربر جداگانه با حداقل دسترسی لازم.
5. SSH/Terminal برای اجرای Composer و Artisan؛ یا روش deploy قابل اتکا که همان دستورات را اجرا کند.
6. امکان تنظیم Document Root روی پوشه `public` و نگهداری `.env`، `vendor`، `storage` و سورس خارج از public.
7. SSL معتبر، امکان تعریف متغیرهای محیطی و مجوز نوشتن امن برای `storage` و `bootstrap/cache`.
8. امکان تعریف cron هر دقیقه برای `php artisan schedule:run` و منابع کافی CPU/RAM/Process.

اگر PHP CLI با نسخه دامنه متفاوت باشد، Composer در محیط ناسازگار اجرا شود، یا امکان جداسازی public root وجود نداشته باشد، استقرار production روی آن هاست متوقف شود.

## اطلاعاتی که باید از cPanel جمع‌آوری شود

- تصویر صفحه MultiPHP Manager که نسخه PHP دامنه/زیردامنه را نشان دهد.
- تصویر یا خروجی Terminal از دستورات زیر:
  ```bash
  php -v
  composer --version
  php -m
  mysql --version
  ```
- تأیید وجود SSH Access / Terminal.
- تأیید اینکه می‌توان Document Root زیردامنه را روی مسیر `backend/public` قرار داد.
- نسخه MySQL که در بخش MySQL Databases یا اطلاعات سرور نمایش داده می‌شود.

در تصاویر و خروجی‌ها نام کاربری cPanel، آدرس‌های حساس، رمزها، کلید API و هر مقدار محرمانه را بپوشانید. هیچ رمز، API Key یا محتوای فایل `.env` را در چت یا GitHub ارسال نکنید.

## ترتیب استقرار پس از تأیید

1. ایجاد زیردامنه مستقل و فعال‌سازی SSL.
2. ایجاد دیتابیس و کاربر مستقل؛ نگهداری اطلاعات اتصال فقط در فایل `.env` خارج از public.
3. بارگذاری نسخه release از بک‌اند در مسیر خصوصی خارج از web root.
4. نصب وابستگی‌های production با Composer.
5. ساخت `.env` امن و تولید APP_KEY روی سرور؛ تنظیم APP_ENV=production و APP_DEBUG=false.
6. اجرای migrations با `php artisan migrate --force` پس از backup و تأیید مقصد دیتابیس.
7. اجرای `php artisan config:cache`، `route:cache` و `view:cache`.
8. تنظیم cron زمان‌بندی Laravel و بررسی logها/health endpoint.
9. آزمون HTTPS، CORS، rate limit، احراز هویت، دسترسی نقش‌ها و جداسازی داده مشتریان در محیط staging.
10. اتصال اپ Flutter به URL نهایی فقط پس از موفقیت آزمون‌ها.

## موارد ممنوع

- قرار دادن کل پروژه Laravel در Document Root.
- استفاده از دیتابیس یا کاربر دیتابیس وردپرس باراک‌مد.
- قراردادن `.env`، کلیدها یا رمزها در GitHub، چت، فایل APK یا پوشه public.
- فعال‌کردن APP_DEBUG در اینترنت.
- دریافت مدارک هویتی یا فایل حساس پیش از آماده‌سازی storage خصوصی و کنترل‌های امنیتی.
- فعال‌کردن پیامک واقعی پیش از تأیید پترن و ثبت secrets فقط روی سرور.
- اعلام production-ready بودن صرفاً به‌دلیل موفقیت Composer یا اجرای migrations.


## مسیر جایگزین برای هاست بدون SSH و Terminal

پشتیبانی هاست اعلام کرده است SSH/Terminal ارائه نمی‌شود، اما PHP CLI نسخه 8.3 از مسیر زیر برای اجرای Artisan در دسترس است و Cron Job نیز قابل استفاده است:

```text
/opt/cpanel/ea-php83/root/usr/bin/php
```

برای حل نبود Composer روی خود هاست، workflow زیر در GitHub Actions وابستگی‌های production را با PHP 8.3 و Composer 2 نصب می‌کند و یک ZIP آماده cPanel می‌سازد:

- Workflow: `.github/workflows/laravel-cpanel-bundle.yml`
- Artifact: `kargozar-laravel-production-bundle`
- خروجی: `kargozar-laravel-production.zip` به‌همراه فایل SHA-256
- فایل ZIP شامل سورس Laravel و `vendor/` است و فایل‌های محیطی، تست‌ها و logها را شامل نمی‌شود.

### روش استفاده پس از موفقیت workflow

1. در GitHub به Actions بروید و اجرای workflow با نام **Build Laravel production bundle for cPanel** را باز کنید.
2. فقط پس از موفقیت کامل، artifact با نام `kargozar-laravel-production-bundle` را دریافت کنید.
3. پیش از استخراج، از پوشه فعلی `/home/CPANEL_USER/apps/kargozar-api` نسخه پشتیبان بگیرید.
4. ZIP را در همان پوشه خصوصی `apps/kargozar-api` بارگذاری و Extract کنید؛ آن را داخل `public_html` یا ریشه وب وردپرس استخراج نکنید.
5. فایل `.env` را جداگانه و فقط روی هاست بسازید؛ آن را از GitHub یا artifact کپی نکنید.
6. Document Root زیردامنه API باید فقط به `/home/CPANEL_USER/apps/kargozar-api/public` اشاره کند.
7. پس از تأیید دیتابیس اختصاصی و تنظیم امن `.env`، فرمان‌های لازم Artisan را با PHP CLI اعلام‌شده از طریق Cron Job اجرا و سپس Cron موقت را حذف کنید.
8. زمان‌بندی دائمی Laravel Scheduler نیز فقط پس از نصب موفق و تأیید فرمان‌ها تنظیم شود.

**محدودیت مهم:** workflow فقط بسته نرم‌افزاری production را آماده می‌کند؛ دیتابیس، فایل `.env`، APP_KEY، مهاجرت‌ها، SSL و تنظیم Document Root را ایجاد یا تغییر نمی‌دهد. تا زمان تأیید نسخه MySQL و Composer build موفق، هیچ مهاجرت production یا اتصال اپ به API انجام نشود.

## وضعیت فعلی

بک‌اند Laravel 13 و تست‌های CI در مخزن آماده‌اند. پشتیبانی هاست نبود SSH/Terminal را تأیید کرده، اما مسیر PHP CLI 8.3، فعال بودن افزونه‌ها، امکان Cron Job و Document Root سفارشی را اعلام کرده است. برای جبران نبود Composer روی هاست، workflow ساخت بسته production به مخزن اضافه شده است؛ اجرای موفق آن و تأیید نسخه MySQL هنوز لازم است. هیچ نصب عملیاتی یا مهاجرت دیتابیس production انجام نشده است.
