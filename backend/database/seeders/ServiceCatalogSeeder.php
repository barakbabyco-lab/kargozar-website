<?php

namespace Database\Seeders;

use App\Models\Service;
use App\Models\ServiceCategory;
use Illuminate\Database\Seeder;

class ServiceCatalogSeeder extends Seeder
{
    public function run(): void
    {
        // Existing root slugs are intentionally reused where possible so
        // category IDs referenced by existing records remain stable.
        $tree = [
            [
                'slug' => 'licenses',
                'name' => 'مجوزهای کسب‌وکار',
                'children' => [
                    [
                        'slug' => 'home-business-permits',
                        'name' => 'جواز کسب‌وکار مشاغل خانگی',
                        'children' => [
                            ['slug' => 'home-production', 'name' => 'تولیدی و صنعتی'],
                            ['slug' => 'home-food-processing', 'name' => 'غذایی و فرآوری محصولات'],
                            ['slug' => 'home-arts-crafts', 'name' => 'هنری و صنایع دستی'],
                            ['slug' => 'home-traditional-weaving', 'name' => 'فرش و بافته‌های سنتی'],
                            ['slug' => 'home-agriculture', 'name' => 'کشاورزی، دامپروری و شیلات'],
                            ['slug' => 'home-digital', 'name' => 'اداری، رایانه‌ای و دیجیتال'],
                            ['slug' => 'home-technical', 'name' => 'فنی و تخصصی'],
                            ['slug' => 'home-education', 'name' => 'آموزشی و پژوهشی'],
                            ['slug' => 'home-services', 'name' => 'خدماتی و خانگی'],
                        ],
                    ],
                    ['slug' => 'trade-business-license', 'name' => 'جواز کسب‌وکار صنفی'],
                    ['slug' => 'device-business-license', 'name' => 'جواز کسب‌وکار دستگاهی'],
                    ['slug' => 'commercial-card', 'name' => 'کارت بازرگانی'],
                ],
            ],
            [
                'slug' => 'company-registration',
                'name' => 'ثبت شرکت',
                'children' => [
                    ['slug' => 'company-incorporation', 'name' => 'ثبت و تأسیس شرکت'],
                    ['slug' => 'noncommercial-institutions', 'name' => 'ثبت مؤسسات غیرتجاری'],
                    ['slug' => 'company-amendments', 'name' => 'تغییرات شرکت‌ها و مؤسسات'],
                    ['slug' => 'company-dissolution', 'name' => 'انحلال و تصفیه شرکت'],
                    ['slug' => 'company-branches', 'name' => 'ثبت شعبه و نمایندگی'],
                    ['slug' => 'legal-ledgers', 'name' => 'دریافت دفاتر قانونی و پلمپ دفاتر'],
                    ['slug' => 'other-company-registration', 'name' => 'سایر امور ثبتی شرکت‌ها'],
                ],
            ],
            [
                'slug' => 'registration',
                'name' => 'ثبت برند و مالکیت فکری',
                'children' => [
                    ['slug' => 'trademark', 'name' => 'ثبت علامت تجاری (برند)'],
                    ['slug' => 'trademark-renewal', 'name' => 'تمدید و تجدید ثبت برند'],
                    ['slug' => 'trademark-transfer', 'name' => 'انتقال و تغییرات برند'],
                    ['slug' => 'industrial-design', 'name' => 'ثبت طرح صنعتی'],
                    ['slug' => 'patent-registration', 'name' => 'ثبت اختراع'],
                    ['slug' => 'copyright-registration', 'name' => 'ثبت آثار ادبی و هنری'],
                    ['slug' => 'ip-search', 'name' => 'جست‌وجو و استعلام مالکیت فکری'],
                    ['slug' => 'ip-legal-services', 'name' => 'خدمات حقوقی و پیگیری مالکیت فکری'],
                    ['slug' => 'other-ip-services', 'name' => 'سایر خدمات مالکیت فکری'],
                ],
            ],
            [
                'slug' => 'finance-admin',
                'name' => 'مدارک و تأییدیه‌های مکمل',
                'children' => [
                    ['slug' => 'health-card', 'name' => 'کارت بهداشت'],
                    ['slug' => 'environment-health-approval', 'name' => 'تأییدیه بهداشت محیط'],
                    ['slug' => 'police-places-approval', 'name' => 'تأییدیه پلیس اماکن'],
                    ['slug' => 'trade-rules-certificate', 'name' => 'گواهی احکام تجارت'],
                    ['slug' => 'technical-vocational-certificate', 'name' => 'گواهینامه فنی و حرفه‌ای'],
                    ['slug' => 'standard-mark', 'name' => 'نشان استاندارد'],
                    ['slug' => 'sib-salamat', 'name' => 'سیب سلامت'],
                    ['slug' => 'tax-tracking-code', 'name' => 'تشکیل پرونده و دریافت کد رهگیری مالیاتی'],
                ],
            ],
            [
                'slug' => 'banking-services',
                'name' => 'خدمات بانکی',
                'children' => [
                    ['slug' => 'current-account', 'name' => 'افتتاح حساب جاری و دریافت دسته‌چک'],
                    ['slug' => 'bank-loans', 'name' => 'دریافت تسهیلات بانکی'],
                    ['slug' => 'pos-terminal', 'name' => 'دریافت دستگاه کارت‌خوان (POS)'],
                    ['slug' => 'cashless-terminal', 'name' => 'دریافت دستگاه کش‌لس (Cashless)'],
                ],
            ],
            [
                'slug' => 'contracts',
                'name' => 'خدمات حقوقی و قراردادی',
                'children' => [
                    ['slug' => 'employment-contract', 'name' => 'تنظیم قراردادهای کاری'],
                    ['slug' => 'contractor-contract', 'name' => 'تنظیم قراردادهای پیمانکاری'],
                    ['slug' => 'commercial-contracts', 'name' => 'قراردادهای تجاری و بازرگانی'],
                    ['slug' => 'partnership-contracts', 'name' => 'قراردادهای مشارکت'],
                    ['slug' => 'legal-consulting', 'name' => 'امور حقوقی و مشاوره'],
                    ['slug' => 'tax-insurance-legal', 'name' => 'امور مالیاتی و بیمه‌ای مرتبط'],
                    ['slug' => 'documents-agreements', 'name' => 'تنظیم اسناد و توافق‌نامه‌ها'],
                    ['slug' => 'other-legal-contractual', 'name' => 'سایر خدمات حقوقی و قراردادی'],
                ],
            ],
            [
                'slug' => 'digital-services',
                'name' => 'خدمات اینترنتی و تجاری',
                'children' => [
                    ['slug' => 'internet-business-setup', 'name' => 'ثبت و راه‌اندازی کسب‌وکار اینترنتی'],
                    ['slug' => 'website-design', 'name' => 'طراحی و راه‌اندازی وب‌سایت'],
                    ['slug' => 'domain-hosting', 'name' => 'خدمات دامنه و میزبانی'],
                    ['slug' => 'internet-telephony', 'name' => 'خدمات تلفن و ارتباطات اینترنتی'],
                    ['slug' => 'sms-services', 'name' => 'خدمات پیامکی'],
                    ['slug' => 'ecommerce-sales', 'name' => 'خدمات فروش و تجارت الکترونیک'],
                    ['slug' => 'other-internet-commercial', 'name' => 'سایر خدمات اینترنتی و تجاری'],
                ],
            ],
            [
                'slug' => 'real-estate-services',
                'name' => 'خدمات ملکی و قراردادها',
                'children' => [
                    ['slug' => 'lease-tracking', 'name' => 'تنظیم اجاره‌نامه دارای کد رهگیری'],
                    ['slug' => 'property-sale-agreement', 'name' => 'تنظیم مبایعه‌نامه املاک'],
                    ['slug' => 'lease-renewal-tracking', 'name' => 'تمدید اجاره‌نامه و دریافت کد رهگیری جدید'],
                    ['slug' => 'construction-partnership', 'name' => 'تنظیم قرارداد مشارکت در ساخت'],
                    ['slug' => 'pre-sale-property', 'name' => 'تنظیم قرارداد پیش‌فروش ملک'],
                    ['slug' => 'property-contract-amendment', 'name' => 'تنظیم الحاقیه و اصلاح قراردادهای ملکی'],
                    ['slug' => 'property-contract-termination', 'name' => 'فسخ و اقاله قراردادهای ملکی'],
                    ['slug' => 'property-legal-review', 'name' => 'بررسی و مشاوره حقوقی قراردادهای ملکی'],
                ],
            ],
            [
                'slug' => 'business-development',
                'name' => 'خدمات توسعه کسب‌وکار',
                'children' => [
                    ['slug' => 'accounting-software', 'name' => 'نرم‌افزار حسابداری و مالی'],
                    ['slug' => 'invoicing-sales-management', 'name' => 'صدور فاکتور و مدیریت فروش'],
                    ['slug' => 'payroll-management', 'name' => 'حقوق و دستمزد و مدیریت پرسنل'],
                    ['slug' => 'human-resources', 'name' => 'مدیریت منابع انسانی'],
                    ['slug' => 'contract-management', 'name' => 'مدیریت قراردادها'],
                    ['slug' => 'crm', 'name' => 'مدیریت ارتباط با مشتریان (CRM)'],
                    ['slug' => 'inventory-management', 'name' => 'مدیریت انبار و موجودی کالا'],
                    ['slug' => 'order-purchasing-management', 'name' => 'مدیریت سفارش‌ها و خرید'],
                    ['slug' => 'business-management-reporting', 'name' => 'سیستم مدیریت کسب‌وکار و گزارش‌گیری'],
                    ['slug' => 'other-management-tools', 'name' => 'سایر ابزارها و نرم‌افزارهای مدیریتی'],
                ],
            ],
            [
                'slug' => 'advertising',
                'name' => 'سایر خدمات تخصصی',
                'children' => [
                    ['slug' => 'business-consulting', 'name' => 'مشاوره تخصصی کسب‌وکار'],
                    ['slug' => 'feasibility-study', 'name' => 'تدوین طرح توجیهی و امکان‌سنجی'],
                    ['slug' => 'business-plan', 'name' => 'تهیه طرح کسب‌وکار (Business Plan)'],
                    ['slug' => 'business-valuation', 'name' => 'ارزش‌گذاری کسب‌وکار'],
                    ['slug' => 'investment-services', 'name' => 'خدمات تأمین سرمایه و جذب سرمایه‌گذار'],
                    ['slug' => 'import-export-consulting', 'name' => 'خدمات صادرات و واردات تخصصی'],
                    ['slug' => 'vocational-training', 'name' => 'آموزش و مشاوره تخصصی مشاغل'],
                    ['slug' => 'other-specialized-services', 'name' => 'سایر خدمات قابل ارائه توسط کارگزار'],
                ],
            ],
        ];

        foreach ($tree as $position => $node) {
            $this->storeNode($node, null, $position + 1);
        }

        // Keep the original seeded service offerings and their stable slugs.
        // Existing rows are updated in place, never deleted or recreated.
        $serviceDefinitions = [
            ['جواز کسب', 'business-license', 'راهنمایی و پیگیری فرایند دریافت مجوز کسب‌وکار.', 'trade-business-license'],
            ['کارت بازرگانی', 'commercial-card', 'بررسی شرایط و پیگیری تشکیل پرونده کارت بازرگانی.', 'commercial-card'],
            ['کارت بهداشت', 'health-card', 'راهنمایی درباره مدارک و مراحل دریافت کارت بهداشت.', 'health-card'],
            ['نشان استاندارد', 'standard-mark', 'راهنمایی و پیگیری درخواست نشان استاندارد.', 'standard-mark'],
            ['سیب سلامت', 'sib-salamat', 'راهنمایی و پیگیری فرایندهای مرتبط با سیب سلامت.', 'sib-salamat'],
            ['ثبت برند و علامت تجاری', 'trademark-registration', 'بررسی اولیه و پیگیری مراحل ثبت علامت تجاری.', 'trademark'],
            ['ثبت طرح صنعتی', 'industrial-design-registration', 'راهنمایی درباره ثبت طرح صنعتی و مدارک موردنیاز.', 'industrial-design'],
            ['اینماد و راه‌اندازی فروشگاه اینترنتی', 'enamad-online-store', 'راهنمایی برای اینماد، وب‌سایت و آماده‌سازی فروشگاه اینترنتی.', 'internet-business-setup'],
            ['راه‌اندازی درگاه پرداخت', 'payment-gateway', 'پیگیری مراحل آماده‌سازی درگاه پرداخت متناسب با شرایط کسب‌وکار.', 'ecommerce-sales'],
            ['تلفن اینترنتی', 'internet-phone', 'راهنمایی و پیگیری راه‌اندازی خط تلفن اینترنتی.', 'internet-telephony'],
            ['پنل پیامک انبوه', 'bulk-sms-panel', 'راهنمایی برای تهیه و راه‌اندازی پنل پیامک کسب‌وکار.', 'sms-services'],
            ['تشکیل پرونده مالیاتی', 'tax-file', 'راهنمایی و پیگیری تشکیل پرونده و دریافت کدهای مالیاتی.', 'tax-tracking-code'],
            ['کد رهگیری اجاره‌نامه', 'lease-tracking-code', 'راهنمایی درباره ثبت قرارداد اجاره و دریافت کد رهگیری.', 'lease-tracking'],
            ['افتتاح حساب جاری', 'current-account-opening', 'بررسی شرایط و مدارک افتتاح حساب جاری کسب‌وکار.', 'current-account'],
            ['قرارداد استخدام', 'employment-contract', 'تهیه پیش‌نویس قرارداد استخدام متناسب با اطلاعات طرفین.', 'employment-contract'],
            ['قرارداد پیمانکاری', 'contractor-agreement', 'تهیه پیش‌نویس قرارداد پیمانکاری بر اساس شرح کار و توافق طرفین.', 'contractor-contract'],
            ['ساخت تیزر تبلیغاتی', 'advertising-video', 'طراحی و تولید تیزر معرفی محصول یا کسب‌وکار.', 'other-specialized-services'],
            ['ثبت و تأسیس شرکت', 'company-incorporation', 'بررسی قالب حقوقی و پیگیری فرایند ثبت و تأسیس شرکت.', 'company-incorporation'],
            ['تأییدیه پلیس اماکن', 'police-places-approval', 'بررسی شرایط و پیگیری تأییدیه پلیس نظارت بر اماکن عمومی.', 'police-places-approval'],
            ['تأییدیه بهداشت محیط', 'environment-health-approval', 'بررسی الزامات و پیگیری تأییدیه بهداشت محیط متناسب با فعالیت.', 'environment-health-approval'],
            ['گواهی احکام تجارت', 'trade-rules-certificate', 'راهنمایی و پیگیری دوره و گواهی احکام تجارت در صورت شمول.', 'trade-rules-certificate'],
            ['گواهینامه فنی و حرفه‌ای', 'technical-vocational-certificate', 'راهنمایی و پیگیری مسیر دریافت گواهینامه مهارتی مرتبط با فعالیت.', 'technical-vocational-certificate'],
        ];

        foreach ($serviceDefinitions as $position => [$title, $slug, $description, $categorySlug]) {
            $category = ServiceCategory::query()->where('slug', $categorySlug)->firstOrFail();
            $service = Service::query()->firstOrNew(['slug' => $slug]);
            $isNewService = ! $service->exists;

            $service->category_id = $category->id;
            $service->title = $title;
            $service->description = $description;
            $service->is_active = true;
            $service->sort_order = $position + 1;

            if ($isNewService) {
                $service->requirements = [];
                $service->estimated_days = null;
                $service->base_price = null;
            }

            // Existing staff-entered requirements, prices, durations and their
            // verification timestamps must survive every catalogue seed run.
            $service->save();
        }

    }


    /**
     * @param array<string, mixed> $node
     * @return array<string, ServiceCategory>
     */
    private function storeNode(array $node, ?int $parentId, int $sortOrder): array
    {
        $category = ServiceCategory::updateOrCreate(
            ['slug' => $node['slug']],
            [
                'parent_id' => $parentId,
                'name' => $node['name'],
                'description' => $node['description'] ?? null,
                'is_active' => true,
                'sort_order' => $sortOrder,
            ],
        );

        $stored = [$category->slug => $category];
        foreach (($node['children'] ?? []) as $position => $child) {
            $stored += $this->storeNode($child, (int) $category->id, $position + 1);
        }

        return $stored;
    }
}
