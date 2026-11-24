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
        Http::fake([
            'api.example.test/v1/chat/completions' => Http::response([
                'choices' => [[
                    'message' => ['content' => 'متوجه شدم.'],
                ]],
            ], 200),
        ]);

        app(AssistantLanguageModel::class)->answer(
            'شماره ۰۹۱۲۳۴۵۶۷۸۹ و ایمیل person@example.com برای پیگیری من است.'
        );

        Http::assertSent(function (Request $request): bool {
            $body = json_encode($request->data(), JSON_UNESCAPED_UNICODE);
            return ! str_contains($body, '09123456789')
                && ! str_contains($body, 'person@example.com')
                && str_contains($body, '[حذف شماره تماس]')
                && str_contains($body, '[حذف ایمیل]');
        });
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
}
