# راه‌اندازی استقرار آزمایشی کارگزار روی VPS

وضعیت: فایل‌ها و گردش‌کار اولیه آماده بازبینی‌اند؛ هیچ VPS یا اتصال SSH هنوز پیکربندی نشده است.

## هدف و محدوده

این راهنما فقط برای محیط **staging آزمایشی** است. این گردش‌کار:
- فقط با اجرای دستی از GitHub Actions شروع می‌شود.
- فقط کد پوشه `backend/` را مستقر می‌کند.
- فایل `.env` و پوشه `storage` را از نسخه‌های انتشار جدا نگه می‌دارد.
- قبل از هر استقرار بررسی می‌کند که محیط مقصد صراحتاً `APP_ENV=staging` باشد.
- مهاجرت دیتابیس را فقط وقتی اجرا می‌کند که اپراتور هنگام اجرای workflow گزینه آن را فعال کند.
- به دامنه اصلی، DNS، سایت باراک‌مد یا هاست میهن‌وب‌هاست دست نمی‌زند.

این workflow هنوز تا زمان آماده‌شدن VPS و ثبت Secretهای لازم قابل اجرا نیست.

## ساختار مورد انتظار روی VPS

پس از آماده‌سازی، مسیر نمونه به این شکل خواهد بود:

```text
/var/www/kargozar-staging/
├── current -> releases/<commit-sha>
├── releases/
│   └── <commit-sha>/
│       ├── public/
│       ├── vendor/
│       ├── .env -> ../../shared/.env
│       └── storage -> ../../shared/storage
└── shared/
    ├── .env
    ├── .previous-release
    └── storage/
```

Document Root وب‌سرور باید به `/var/www/kargozar-staging/current/public` اشاره کند. این مسیر نمونه است و فقط پس از انتخاب مسیر نهایی VPS استفاده می‌شود.

## پیش‌نیازهای سرور

- Ubuntu Server LTS؛ نسخه دقیق پس از سفارش VPS انتخاب می‌شود.
- PHP 8.3 یا بالاتر و افزونه‌های موردنیاز Laravel 13.
- Composer 2.
- MySQL 8 با دیتابیس و کاربر اختصاصی staging.
- Nginx یا وب‌سرور منتخب.
- کاربر deploy اختصاصی با دسترسی محدود؛ اجرای برنامه با root ممنوع.
- دسترسی نوشتن برای کاربر وب فقط در storage و bootstrap/cache، با گروه‌بندی صحیح.
- فایروال؛ SSH فقط با کلید عمومی و ترجیحاً محدود به IPهای مدیریتی در صورت امکان.
- هیچ اطلاعات واقعی مشتری در staging قرار نگیرد.

## اتصال GitHub Actions با SSH

پس از خرید VPS، این موارد به ترتیب آماده می‌شوند:

1. کاربر اختصاصی deploy ساخته شود؛ این کاربر نباید دسترسی root یا sudo عمومی داشته باشد.
2. یک کلید SSH اختصاصی Ed25519 برای GitHub Actions ساخته شود. کلید خصوصی فقط در GitHub Actions Secret ذخیره می‌شود؛ کلید عمومی در `authorized_keys` کاربر deploy قرار می‌گیرد.
3. کلید میزبان SSH سرور از کنسول معتبر ارائه‌دهنده دریافت و fingerprint آن مستقلاً بررسی شود. از اعتماد کورکورانه به خروجی `ssh-keyscan` استفاده نشود.
4. کلید عمومی میزبان در Secret با نام `DEPLOY_KNOWN_HOSTS` ثبت شود؛ کلید خصوصی deploy در `DEPLOY_SSH_KEY`.
5. مسیر staging و فایل محیطی آن آماده شود. فایل `.env` باید `APP_ENV=staging` داشته باشد و فقط به دیتابیس آزمایشی اشاره کند.
6. Document Root به پوشه `current/public` متصل شود.

کلید خصوصی، رمز دیتابیس و محتوای `.env` نباید در مخزن، issue، pull request یا گفتگو قرار گیرند.

## GitHub Actions Secrets

در Repository > Settings > Secrets and variables > Actions، این Secrets لازم‌اند:

| نام | مقدار |
|---|---|
| `DEPLOY_HOST` | IP یا hostname سرور آزمایشی |
| `DEPLOY_PORT` | پورت SSH؛ در صورت خالی‌بودن 22 |
| `DEPLOY_USER` | کاربر محدود deploy |
| `DEPLOY_SSH_KEY` | کلید خصوصی SSH اختصاصی |
| `DEPLOY_KNOWN_HOSTS` | خط کلید میزبان تأییدشده SSH |
| `DEPLOY_PATH` | مسیر مطلق مانند `/var/www/kargozar-staging` |
| `STAGING_HEALTHCHECK_URL` | اختیاری؛ نشانی HTTPS برای بررسی سلامت staging |

از GitHub Variables یا Secrets برای اطلاعات عمومی و محرمانه به‌درستی استفاده شود؛ هیچ Secret واقعی در این فایل ثبت نشده است.

## اجرای استقرار

1. پس از merge شدن این workflow به شاخه اصلی، به Actions بروید.
2. گردش‌کار **Deploy Kargozar staging** را انتخاب کنید.
3. `Run workflow` را بزنید.
4. گزینه `run_migrations` به‌طور پیش‌فرض خاموش است. فقط وقتی دیتابیس staging آماده و پشتیبان‌گیری/قابل‌بازیابی است، آن را روشن کنید.
5. اجرای موفق workflow به معنی تأیید نهایی امنیت یا آمادگی production نیست.

## محدودیت‌ها و گام‌های بعد

- این روش یک استقرارکننده staging است، نه عامل تعاملی عمومی برای کنترل همه‌چیز روی VPS.
- اتصال SSH به GitHub Actions اجازه استقرار می‌دهد؛ به‌خودی‌خود دسترسی مستقیم ChatGPT به shell سرور ایجاد نمی‌کند.
- فعلاً rollback خودکار، تنظیم DNS/SSL، نصب سیستم‌عامل، ایجاد دیتابیس، نصب وب‌سرور، تنظیم queue worker و cron توسط workflow انجام نمی‌شود؛ این‌ها در مرحله bootstrap و آزمون سرور تنظیم و مستند خواهند شد.
- پیش از production باید backup/restore، مجوز فایل‌ها، فایروال، rate limiting، log retention، OTP و providerهای واقعی جداگانه بررسی شوند.
- هیچ‌گاه `migrate:fresh` یا `db:seed` به‌صورت خودکار روی محیط عملیاتی اجرا نشود.
