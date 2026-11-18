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

        $categories = [];
        foreach ($tree as $position => $node) {
            $categories = array_merge(
                $categories,
                $this->storeNode($node, null, $position + 1),
            );
        }

        // Preserve all existing service records and their identifiers while
        // assigning known catalog entries to their new leaf categories.
        $serviceCategoryMap = [
            'business-license' => 'trade-business-license',
            'commercial-card' => 'commercial-card',
            'health-card' => 'health-card',
            'standard-mark' => 'standard-mark',
            'sib-salamat' => 'sib-salamat',
            'trademark-registration' => 'trademark',
            'industrial-design-registration' => 'industrial-design',
            'enamad-online-store' => 'internet-business-setup',
            'payment-gateway' => 'ecommerce-sales',
            'internet-phone' => 'internet-telephony',
            'bulk-sms-panel' => 'sms-services',
            'tax-file' => 'tax-tracking-code',
            'lease-tracking-code' => 'lease-tracking',
            'current-account-opening' => 'current-account',
            'employment-contract' => 'employment-contract',
            'contractor-agreement' => 'contractor-contract',
            'advertising-video' => 'other-specialized-services',
        ];

        foreach ($serviceCategoryMap as $serviceSlug => $categorySlug) {
            $category = ServiceCategory::query()->where('slug', $categorySlug)->first();
            if ($category) {
                Service::query()->where('slug', $serviceSlug)->update([
                    'category_id' => $category->id,
                ]);
            }
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
