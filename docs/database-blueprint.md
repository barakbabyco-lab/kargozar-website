# طرح اولیه پایگاه داده کارگزار

این سند طرح منطقی نسخه اول است؛ هنوز دیتابیس عملیاتی ساخته نشده است.

## جداول اصلی

### customers
- id
- mobile (unique)
- full_name
- email (nullable)
- status
- created_at, updated_at

### staff_users
- id
- name
- mobile (unique)
- email (nullable)
- password_hash
- role (admin, supervisor, expert, finance, support)
- is_active
- created_at, updated_at

### service_categories
- id
- title
- slug (unique)
- sort_order
- is_active

### services
- id
- category_id
- title
- slug (unique)
- short_description
- description
- requirements (JSON)
- estimated_days (nullable)
- base_price (nullable; price must be confirmed before checkout)
- is_active
- sort_order

### service_requests
- id
- tracking_code (unique, non-sequential)
- customer_id
- service_id
- status (submitted, reviewing, awaiting_customer, in_progress, completed, rejected, cancelled)
- customer_note (nullable)
- assigned_staff_id (nullable)
- quoted_price (nullable)
- created_at, updated_at

### request_events
- id
- service_request_id
- actor_type (customer, staff, system)
- actor_id (nullable)
- old_status (nullable)
- new_status (nullable)
- public_message (nullable)
- internal_note (nullable)
- created_at

### request_documents
- id
- service_request_id
- uploaded_by_type
- uploaded_by_id
- original_name
- storage_key
- mime_type
- file_size
- review_status (pending, accepted, rejected)
- created_at

### payments
- id
- service_request_id
- amount
- currency
- provider
- provider_reference (nullable)
- status (pending, paid, failed, refunded)
- paid_at (nullable)
- created_at

### contracts
- id
- service_request_id
- title
- storage_key
- status (draft, sent, signed, void)
- signature_provider (nullable)
- external_reference (nullable)
- created_at, updated_at

### notifications
- id
- customer_id
- service_request_id (nullable)
- channel (in_app, sms, email)
- title
- body
- sent_at (nullable)
- read_at (nullable)
- created_at

## قواعد داده
- حذف فیزیکی پرونده‌ها و اسناد مشتری به‌صورت عادی انجام نمی‌شود؛ چرخه نگهداری و حذف باید مطابق قرارداد و الزامات قانونی تعریف شود.
- شماره موبایل مشتری یکتا است.
- هر درخواست یک کد پیگیری غیرقابل حدس دارد.
- قیمت پایه صرفاً راهنمایی است؛ مبلغ نهایی باید پیش از پرداخت به مشتری اعلام و تأیید شود.
- یادداشت داخلی کارشناسان هرگز در API مشتری ارسال نمی‌شود.
- فایل مدارک با کلید تصادفی و خارج از مسیر عمومی ذخیره می‌شود.
