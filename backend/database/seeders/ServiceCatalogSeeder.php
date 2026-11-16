<?php

namespace Database\Seeders;

use App\Models\Service;
use App\Models\ServiceCategory;
use Illuminate\Database\Seeder;

class ServiceCatalogSeeder extends Seeder
{
    public function run(): void
    {
        $catalog = [
            'licenses' => [
                'name' => 'مجوزها و کارت‌ها',
                'description' => 'خدمات مرتبط با مجوزهای فعالیت و کارت‌های تخصصی.',
                'services' => [
                    ['جواز کسب', 'business-license', 'راهنمایی و پیگیری فرایند دریافت مجوز کسب‌وکار.'],
                    ['کارت بازرگانی', 'commercial-card', 'بررسی شرایط و پیگیری تشکیل پرونده کارت بازرگانی.'],
                    ['کارت بهداشت', 'health-card', 'راهنمایی درباره مدارک و مراحل دریافت کارت بهداشت.'],
                    ['نشان استاندارد', 'standard-mark', 'راهنمایی و پیگیری درخواست نشان استاندارد.'],
                    ['سیب سلامت', 'sib-salamat', 'راهنمایی و پیگیری فرایندهای مرتبط با سیب سلامت.'],
                ],
            ],
            'registration' => [
                'name' => 'ثبت و مالکیت فکری',
                'description' => 'خدمات ثبت علامت تجاری و دارایی‌های فکری.',
                'services' => [
                    ['ثبت برند و علامت تجاری', 'trademark-registration', 'بررسی اولیه و پیگیری مراحل ثبت علامت تجاری.'],
                    ['ثبت طرح صنعتی', 'industrial-design-registration', 'راهنمایی درباره ثبت طرح صنعتی و مدارک موردنیاز.'],
                ],
            ],
            'digital-services' => [
                'name' => 'خدمات آنلاین و زیرساخت دیجیتال',
                'description' => 'راه‌اندازی و تکمیل زیرساخت‌های دیجیتال کسب‌وکار.',
                'services' => [
                    ['اینماد و راه‌اندازی فروشگاه اینترنتی', 'enamad-online-store', 'راهنمایی برای اینماد، وب‌سایت و آماده‌سازی فروشگاه اینترنتی.'],
                    ['راه‌اندازی درگاه پرداخت', 'payment-gateway', 'پیگیری مراحل آماده‌سازی درگاه پرداخت متناسب با شرایط کسب‌وکار.'],
                    ['تلفن اینترنتی', 'internet-phone', 'راهنمایی و پیگیری راه‌اندازی خط تلفن اینترنتی.'],
                    ['پنل پیامک انبوه', 'bulk-sms-panel', 'راهنمایی برای تهیه و راه‌اندازی پنل پیامک کسب‌وکار.'],
                ],
            ],
            'finance-admin' => [
                'name' => 'مالی و امور اداری',
                'description' => 'پیگیری امور مالیاتی، بانکی و کدهای رهگیری.',
                'services' => [
                    ['تشکیل پرونده مالیاتی', 'tax-file', 'راهنمایی و پیگیری تشکیل پرونده و دریافت کدهای مالیاتی.'],
                    ['کد رهگیری اجاره‌نامه', 'lease-tracking-code', 'راهنمایی درباره ثبت قرارداد اجاره و دریافت کد رهگیری.'],
                    ['افتتاح حساب جاری', 'current-account-opening', 'بررسی شرایط و مدارک افتتاح حساب جاری کسب‌وکار.'],
                ],
            ],
            'contracts' => [
                'name' => 'قراردادها و منابع انسانی',
                'description' => 'تهیه و تنظیم اسناد قراردادی کسب‌وکار.',
                'services' => [
                    ['قرارداد استخدام', 'employment-contract', 'تهیه پیش‌نویس قرارداد استخدام متناسب با اطلاعات طرفین.'],
                    ['قرارداد پیمانکاری', 'contractor-agreement', 'تهیه پیش‌نویس قرارداد پیمانکاری بر اساس شرح کار و توافق طرفین.'],
                ],
            ],
            'advertising' => [
                'name' => 'تبلیغات و معرفی کسب‌وکار',
                'description' => 'خدمات محتوایی و تبلیغاتی برای معرفی کسب‌وکار.',
                'services' => [
                    ['ساخت تیزر تبلیغاتی', 'advertising-video', 'طراحی و تولید تیزر معرفی محصول یا کسب‌وکار.'],
                ],
            ],
        ];

        foreach ($catalog as $slug => $categoryData) {
            $category = ServiceCategory::updateOrCreate(
                ['slug' => $slug],
                [
                    'name' => $categoryData['name'],
                    'description' => $categoryData['description'],
                    'is_active' => true,
                ],
            );

            foreach ($categoryData['services'] as [$title, $serviceSlug, $description]) {
                Service::updateOrCreate(
                    ['slug' => $serviceSlug],
                    [
                        'category_id' => $category->id,
                        'title' => $title,
                        'description' => $description,
                        'requirements' => [],
                        'estimated_days' => null,
                        'base_price' => null,
                        'is_active' => true,
                    ],
                );
            }
        }
    }
}
