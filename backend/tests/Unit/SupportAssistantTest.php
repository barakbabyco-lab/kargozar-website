<?php

namespace Tests\Unit;

use App\Services\Support\SupportAssistant;
use Illuminate\Support\Facades\Config;
use Tests\TestCase;

class SupportAssistantTest extends TestCase
{
    public function test_missing_requirement_is_routed_to_human_without_explaining_workarounds(): void
    {
        Config::set('support_assistant.missing_requirement_phrases', ['مغازه ندارم']);
        Config::set('support_assistant.missing_requirement_response', 'نگران نباشید، راه‌های رسیدن به خدا زیاده! شماره تماس‌تون رو ثبت کنید.');

        $reply = app(SupportAssistant::class)->reply('برای جواز کسب مغازه ندارم');

        $this->assertStringContainsString('راه‌های رسیدن به خدا زیاده!', $reply);
        $this->assertStringContainsString('شماره تماس', $reply);
        $this->assertStringNotContainsString('روش اجرایی', $reply);
    }

    public function test_service_faq_uses_the_separate_customer_reassurance_closing(): void
    {
        Config::set('support_assistant.escalation_terms', []);
        Config::set('support_assistant.faqs', [[
            'key' => 'test_service',
            'service_assurance' => true,
            'keywords' => ['خدمات آزمایشی'],
            'answer' => 'برای خدمات آزمایشی، اطلاعات اولیه بررسی می‌شود.',
        ]]);
        Config::set('support_assistant.confidence_threshold', 0.25);
        Config::set('support_assistant.minimum_score_margin', 0.0);
        Config::set('support_assistant.customer_communication.standard_closing_text', 'اگر مدرکی ندارید، شماره تماس‌تان را ثبت کنید.');

        $reply = app(SupportAssistant::class)->reply('برای خدمات آزمایشی راهنمایی می‌خواهم');

        $this->assertStringContainsString('برای خدمات آزمایشی', $reply);
        $this->assertStringContainsString("\n\nاگر مدرکی ندارید", $reply);
    }

    public function test_structured_service_bank_answers_document_questions(): void
    {
        Config::set('support_assistant.missing_requirement_phrases', []);
        Config::set('support_assistant.escalation_terms', []);
        Config::set('support_assistant.customer_communication.standard_closing_text', 'برای پیگیری، شماره تماس‌تان را ثبت کنید.');

        $reply = app(SupportAssistant::class)->reply('مدارک ثبت شرکت چیست؟');

        $this->assertStringContainsString('ثبت شرکت', $reply);
        $this->assertStringContainsString('مدارک قابل بررسی', $reply);
        $this->assertStringContainsString('شماره تماس‌تان را ثبت کنید', $reply);
    }

    public function test_guild_license_document_question_uses_shared_and_activity_specific_checklists(): void
    {
        Config::set('support_assistant.missing_requirement_phrases', []);
        Config::set('support_assistant.escalation_terms', []);
        Config::set('support_assistant.customer_communication.standard_closing_text', 'برای پیگیری، شماره تماس‌تان را ثبت کنید.');

        $reply = app(SupportAssistant::class)->reply('مدارک جواز کسب برای آرایشگاه چیست؟');

        $this->assertStringContainsString('چک‌لیست اولیه', $reply);
        $this->assertStringContainsString('کارت بهداشت', $reply);
        $this->assertStringContainsString('تأییدیه بهداشت', $reply);
        $this->assertStringContainsString('شماره تماس‌تان را ثبت کنید', $reply);
    }

    public function test_unknown_question_uses_safe_fallback(): void
    {
        Config::set('support_assistant.missing_requirement_phrases', []);
        Config::set('support_assistant.escalation_terms', []);
        Config::set('support_assistant.faqs', []);
        Config::set('support_assistant.fallback', 'برای بررسی دقیق‌تر با کارشناس تماس بگیرید.');

        $this->assertSame(
            'برای بررسی دقیق‌تر با کارشناس تماس بگیرید.',
            app(SupportAssistant::class)->reply('سؤال نامرتبط و ناشناخته')
        );
    }

    public function test_unknown_question_uses_public_web_search_when_configured(): void
    {
        Config::set('support_assistant.missing_requirement_phrases', []);
        Config::set('support_assistant.escalation_terms', []);
        Config::set('support_assistant.faqs', []);
        Config::set('support_assistant.web_search.enabled', true);
        Config::set('support_assistant.web_search.api_key', 'test-key');
        Config::set('support_assistant.web_search.endpoint', 'https://api.tavily.com/search');
        Http::fake([
            'api.tavily.com/search' => Http::response([
                'answer' => 'این یک پاسخ عمومی آزمایشی است.',
                'results' => [[
                    'title' => 'منبع آزمایشی',
                    'url' => 'https://example.com/reference',
                    'content' => 'خلاصه منبع',
                ]],
            ], 200),
        ]);

        $reply = app(SupportAssistant::class)->reply('یک پرسش عمومی ناشناخته درباره موضوعی خارج از خدمات');

        $this->assertStringContainsString('پاسخ عمومی آزمایشی', $reply);
        $this->assertStringContainsString('https://example.com/reference', $reply);
    }

    public function test_current_date_and_time_is_reported_in_tehran_jalali_calendar(): void
    {
        Config::set('support_assistant.timezone', 'Asia/Tehran');

        $reply = app(SupportAssistant::class)->reply('الان تاریخ و ساعت چنده؟');

        $this->assertStringContainsString('تاریخ و ساعت فعلی تهران:', $reply);
        $this->assertStringContainsString('Asia/Tehran', $reply);
        $this->assertMatchesRegularExpression('/\\d{4}/u', $reply);
    }

    public function test_guild_activity_classifier_supports_multiple_specialist_groups(): void
    {
        Config::set('support_assistant.guild_job_classification', [
            'common_preflight' => ['identity_and_contact'],
            'groups' => [
                'food_health_hygiene' => [
                    'title' => 'غذایی و بهداشتی',
                    'keywords' => ['بسته بندی مواد غذایی'],
                    'requirements' => ['health_card', 'environmental_health_approval'],
                ],
                'technical_vocational' => [
                    'title' => 'فنی و مهارتی',
                    'keywords' => ['دستگاه بسته بندی'],
                    'requirements' => ['vocational_skill_certificate'],
                ],
            ],
            'official_worksheet_overrides_classifier' => true,
        ]);

        $result = app(SupportAssistant::class)->classifyGuildActivity('بسته بندی مواد غذایی با دستگاه بسته بندی');

        $this->assertCount(2, $result['groups']);
        $this->assertContains('health_card', $result['requirements']);
        $this->assertContains('vocational_skill_certificate', $result['requirements']);
    }
}
