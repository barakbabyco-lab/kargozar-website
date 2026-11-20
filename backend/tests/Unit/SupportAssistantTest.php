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
            'keywords' => ['ثبت برند'],
            'answer' => 'برای ثبت برند، نام و زمینه فعالیت باید بررسی شود.',
        ]]);
        Config::set('support_assistant.confidence_threshold', 0.25);
        Config::set('support_assistant.minimum_score_margin', 0.0);
        Config::set('support_assistant.customer_communication.standard_closing_text', 'اگر مدرکی ندارید، شماره تماس‌تان را ثبت کنید.');

        $reply = app(SupportAssistant::class)->reply('برای ثبت برند راهنمایی می‌خواهم');

        $this->assertStringContainsString('برای ثبت برند', $reply);
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
