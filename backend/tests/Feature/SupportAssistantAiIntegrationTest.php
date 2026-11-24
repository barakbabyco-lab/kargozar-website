<?php

namespace Tests\Feature;

use App\Services\Support\SupportAssistant;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class SupportAssistantAiIntegrationTest extends TestCase
{
    use RefreshDatabase;

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
        Config::set('support_assistant.web_search.enabled', false);
    }

    public function test_ai_answers_a_general_question_outside_kargozar_services(): void
    {
        Http::fake([
            'api.example.test/v1/chat/completions' => Http::response([
                'choices' => [[
                    'message' => ['content' => 'توکیو پایتخت ژاپن است.'],
                ]],
            ], 200),
        ]);

        $answer = app(SupportAssistant::class)->reply('پایتخت ژاپن کجاست؟');

        $this->assertSame('توکیو پایتخت ژاپن است.', $answer);
        Http::assertSent(fn ($request) => str_contains($request->url(), '/chat/completions'));
    }

    public function test_ai_gets_first_chance_to_analyse_a_missing_service_prerequisite(): void
    {
        Http::fake([
            'api.example.test/v1/chat/completions' => Http::response([
                'choices' => [[
                    'message' => ['content' => 'برای بررسی وضعیت محل کسب، اول بفرمایید ملک را اجاره کرده‌اید یا هنوز انتخاب نکرده‌اید؟'],
                ]],
            ], 200),
        ]);

        $answer = app(SupportAssistant::class)->reply('برای جواز کسب مغازه ندارم');

        $this->assertStringContainsString('ملک را اجاره کرده‌اید', $answer);
        Http::assertSent(fn ($request) => str_contains($request->url(), '/chat/completions'));
    }
}
