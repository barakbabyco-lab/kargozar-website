# Kargozar API Backend

Laravel 13 REST API for the Kargozar customer application and staff portal.

## Runtime

- PHP 8.3+
- Composer 2
- MySQL 8.0+ for staging/production
- SQLite is used only in automated tests
- Laravel Sanctum for customer and staff bearer tokens

## Local setup

```bash
composer install
cp .env.example .env
php artisan key:generate
```

Configure the database in `.env`, then run:

```bash
php artisan migrate --seed
php artisan serve
```

The API base path is `/api/v1`.

## Implemented API areas

### Customer
- OTP request and verification
- Token revocation
- Active service categories and service catalog
- Idempotent service request creation
- Customer-owned request list and detail

### Staff
- Email/password staff login
- Role-protected request queue and detail
- Request assignment
- Staff-managed service category and service catalog CRUD with soft deactivation
- Status changes, public updates and internal notes
- Audit logging for staff login, detail access, assignment and events

Staff roles:
- `admin`, `supervisor`: assign requests
- `admin`, `supervisor`, `expert`: record request events and status changes
- `finance`, `support`: read-only access in the current MVP

Create the first staff account through a trusted terminal. The password is entered interactively and is never passed as a command-line argument:

```bash
php artisan kargozar:staff-create --name="Administrator" --email="admin@example.com" --role=admin
```

## OTP delivery

The `OtpDelivery` interface isolates the SMS provider. The default binding is deliberately disabled and returns HTTP 503; no OTP is logged or returned to the client. Select and configure a real SMS provider, implement the adapter, and test delivery before enabling production login.

OTP codes are stored only as password hashes, expire after five minutes, and are limited to five verification attempts. Customer tokens expire after 30 days; staff tokens expire after 12 hours.

## Scheduled cleanup

The daily `kargozar:cleanup-expired` task removes old OTP challenges and expired idempotency records. On the production host, configure Laravel's scheduler by running this command every minute:

```cron
* * * * * cd /path/to/backend && php artisan schedule:run >> /dev/null 2>&1
```

## Tests

```bash
php artisan test
php artisan migrate:fresh --seed
```

GitHub Actions runs Composer validation, command registration checks, migrations and seeders on both SQLite and MySQL 8, plus feature tests on PHP 8.3.

## Production readiness gates

Do not expose this API publicly until:
1. The destination host is confirmed to support PHP 8.3+, Composer 2, required extensions and CLI/cron.
2. MySQL 8, HTTPS, document root, private storage and backup/restore are configured.
3. A real SMS provider is selected and the OTP adapter is tested.
4. Staff accounts are provisioned securely.
5. Rate limits, monitoring, logging retention and backup recovery are verified.

Never commit `.env`, API keys, SMS credentials, production data, or staff passwords. Customer documents, payments and e-signatures are not enabled in this MVP.


## پیامک ورود یک‌بارمصرف

راهنمای تنظیم امن IPPanel و آزمایش انتهابه‌انتها در [SMS_SETUP.md](SMS_SETUP.md) قرار دارد. مقادیر واقعی API فقط باید در محیط امن سرور نگهداری شوند.
