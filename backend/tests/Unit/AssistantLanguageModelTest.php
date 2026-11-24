<?php

namespace Tests\Unit;

use App\Services\Support\AssistantLanguageModel;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AssistantLanguageModelTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Config::set('assistant_ai', [
            'enabled' => true,
            'base_url' => 'https://api.example.test/v1',
            'api_key' => 'test-api-key',
            'model' => 'test-model',
            'timeout' => 10,
            'temperature' => 0.2,
            'max_tokens' => 500,
        ]);
    }

    public function test_it_sends_a_grounded_chat_completion_request_and_returns_the_answer(): void
    {
        Http::fake([
            'api.example.test/v1/chat/completions' => Http::response([
                'choices' => [[
                    'message' => ['content' => 'پاسخ آزمایشی دستیار'],
                ]],
            ], 200),
        ]);

        $answer = app(AssistantLanguageModel::class)->answer(
            'برای جواز کسب پوشاک از کجا شروع کنم؟',
            null,
            [[
                'title' => 'درگاه ملی مجوزها',
                'url' => 'https://mojavez.ir/',
                'snippet' => 'اطلاعات اولیه مجوز',
                'page_content' => 'متن کامل کاربرگ رسمی',
                'content_type' => 'full_page_markdown',
                'page_title' => 'کاربرگ رسمی',
            ]],
            [['service_key' => 'guild-license', 'title' => 'پروانه کسب صنفی']],
        );

        $this->assertSame('پاسخ آزمایشی دستیار', $answer);
        Http::assertSent(function (Request $request): bool {
            $payload = $request->data();
            $messages = $payload['messages'] ?? [];
            $userMessage = json_decode((string) ($messages[1]['content'] ?? ''), true);

            return $request->method() === 'POST'
                && $request->hasHeader('Authorization', 'Bearer test-api-key')
                && ($payload['model'] ?? null) === 'test-model'
                && ($userMessage['web_search_results'][0]['url'] ?? null) === 'https://mojavez.ir/'
                && ($userMessage['web_search_results'][0]['page_content'] ?? null) === 'متن کامل کاربرگ رسمی'
                && ($userMessage['web_search_results'][0]['content_type'] ?? null) === 'full_page_markdown'
                && ($userMessage['service_knowledge'][0]['service_key'] ?? null) === 'guild-license';
        });
    }

    public function test_it_does_not_send_personal_contact_details_to_the_model(): void
    {
        $card = str_repeat('6', 16);
        $iban = 'IR'.str_repeat('1', 24);
        $otp = str_repeat('7', 6);

        Http::fake([
            'api.example.test/v1/chat/completions' => Http::response([
                'choices' => [[
                    'message' => ['content' => 'متوجه شدم.'],
                ]],
            ], 200),
        ]);

        app(AssistantLanguageModel::class)->answer(
            'شماره ۰۹۱۲۳۴۵۶۷۸۹ و ایمیل person@example.com، کارت '.$card.'، شبا '.$iban.' و رمز یکبارمصرف '.$otp.' برای پیگیری من است.'
        );

        $sentBody = null;
        Http::assertSent(function (Request $request) use (&$sentBody): bool {
            $sentBody = json_encode($request->data(), JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
            return true;
        });

        $this->assertStringNotContainsString('09123456789', $sentBody);
        $this->assertStringNotContainsString('person@example.com', $sentBody);
        $this->assertStringNotContainsString($card, $sentBody);
        $this->assertStringNotContainsString($iban, $sentBody);
        $this->assertStringNotContainsString($otp, $sentBody);
        $this->assertStringContainsString('[حذف شماره تماس]', $sentBody);
        $this->assertStringContainsString('[حذف ایمیل]', $sentBody);
        $this->assertStringContainsString('[حذف شماره کارت/حساب]', $sentBody);
        $this->assertStringContainsString('[حذف شماره شبا]', $sentBody);
        $this->assertStringContainsString('[حذف کد یک‌بارمصرف]', $sentBody);
    }

    public function test_it_returns_null_when_provider_is_not_configured(): void
    {
        Config::set('assistant_ai.api_key', '');
        Http::fake();

        $this->assertNull(app(AssistantLanguageModel::class)->answer('یک سؤال عمومی'));
        Http::assertNothingSent();
    }

    public function test_it_rejects_non_https_provider_urls(): void
    {
        Config::set('assistant_ai.base_url', 'http://api.example.test/v1');
        Http::fake();

        $this->assertNull(app(AssistantLanguageModel::class)->answer('یک سؤال عمومی'));
        Http::assertNothingSent();
    }

    public function test_provider_errors_fall_back_without_throwing(): void
    {
        Http::fake([
            'api.example.test/v1/chat/completions' => Http::response(['error' => 'provider unavailable'], 503),
        ]);

        $this->assertNull(app(AssistantLanguageModel::class)->answer('یک سؤال عمومی'));
    }
    public function test_service_need_analysis_validates_catalogue_and_prerequisite_keys(): void
    {
        $analysisJson = json_encode([
            'requested_outcome' => 'دریافت جواز کسب',
            'matched_service_keys' => ['guild-business-license', 'made-up-service'],
            'required_service_keys' => ['lease-tracking-code'],
            'missing_prerequisite_keys' => ['health_card', 'made-up-requirement'],
            'customer_state' => [
                ['requirement_key' => 'health_card', 'status' => 'missing'],
                ['requirement_key' => 'trade_law_training', 'status' => 'expired'],
                ['requirement_key' => 'made-up-requirement', 'status' => 'missing'],
            ],
            'known_facts' => ['city' => 'تهران'],
            'missing_facts' => ['نوع دقیق فعالیت'],
            'clarifying_question' => 'نوع دقیق فعالیت شما چیست؟',
            'confidence' => 0.91,
            'needs_human' => false,
        ], JSON_UNESCAPED_UNICODE);

        Http::fake([
            'api.example.test/v1/chat/completions' => Http::response([
                'choices' => [[
                    'message' => ['content' => $analysisJson],
                ]],
            ], 200),
        ]);

        $analysis = app(AssistantLanguageModel::class)->analyzeServiceNeed(
            'برای جواز کسب راهنمایی می‌خواهم',
            null,
            [],
            [['service_key' => 'guild-business-license']]
        );

        $this->assertSame(['guild-business-license'], $analysis['matched_service_keys']);
        $this->assertSame(['lease-tracking-code'], $analysis['required_service_keys']);
        $this->assertSame(['health_card'], $analysis['missing_prerequisite_keys']);
        $this->assertSame('missing', $analysis['customer_state'][0]['status']);
        $this->assertSame('trade_law_training', $analysis['customer_state'][1]['requirement_key']);
        $this->assertSame('expired', $analysis['customer_state'][1]['status']);
        $this->assertSame('نوع دقیق فعالیت شما چیست؟', $analysis['clarifying_question']);
        $this->assertSame(0.91, $analysis['confidence']);

        Http::assertSent(fn (Request $request) =>
            ($request->data()['response_format']['type'] ?? null) === 'json_object'
        );
    }

    public function test_service_need_analysis_falls_back_on_invalid_json(): void
    {
        Http::fake([
            'api.example.test/v1/chat/completions' => Http::response([
                'choices' => [[
                    'message' => ['content' => 'این پاسخ JSON نیست.'],
                ]],
            ], 200),
        ]);

        $this->assertNull(app(AssistantLanguageModel::class)->analyzeServiceNeed(
            'برای جواز کسب راهنمایی می‌خواهم',
            null,
            [],
            [['service_key' => 'guild-business-license']]
        ));
    }


}
