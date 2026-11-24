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
    public function test_ai_receives_the_guild_permit_context_for_a_natural_shop_opening_request(): void
    {
        Http::fake([
            'api.example.test/v1/chat/completions' => Http::response([
                'choices' => [[
                    'message' => ['content' => 'برای راه‌اندازی فروشگاه پوشاک باید ابتدا نوع دقیق فعالیت و شهر را مشخص کنیم.'],
                ]],
            ], 200),
        ]);

        $answer = app(SupportAssistant::class)->reply('می‌خوام مغازه لباس‌فروشی راه بندازم');

        $this->assertStringContainsString('نوع دقیق فعالیت', $answer);
        Http::assertSent(function ($request): bool {
            $messages = $request->data()['messages'] ?? [];
            $payload = json_decode((string) ($messages[1]['content'] ?? ''), true);
            $context = $payload['service_knowledge'] ?? [];
            $keys = array_column($context, 'service_key');
            $preflight = collect($context)->first(fn ($item) => isset($item['guild_activity_preflight']));
            $mapping = collect($context)->first(fn ($item) => isset($item['prerequisite_fulfillment_map']));
            $healthCard = collect($mapping['prerequisite_fulfillment_map'] ?? [])
                ->firstWhere('requirement_key', 'health_card');

            return in_array('guild-business-license', $keys, true)
                && in_array('retail_sales', array_column($preflight['guild_activity_preflight']['groups'] ?? [], 'key'), true)
                && ($healthCard['fulfillment']['service_key'] ?? null) === 'health-card'
                && ($healthCard['fulfillment']['status'] ?? null) === 'available_in_catalog';
        });
    }

    public function test_default_guild_classifier_recognizes_woodworking_as_a_skilled_activity(): void
    {
        $result = app(SupportAssistant::class)->classifyGuildActivity('جواز نجاری و کارگاه ساخت کابینت');

        $this->assertContains('technical_vocational', array_column($result['groups'], 'key'));
        $this->assertContains('vocational_skill_certificate', $result['requirements']);
    }

    public function test_case_specific_tax_debt_questions_still_require_human_review(): void
    {
        Http::fake();

        $answer = app(SupportAssistant::class)->reply('برای بدهی مالیاتی من چه کار کنم؟');

        $this->assertStringContainsString('بررسی دقیق‌تر', $answer);
        Http::assertNothingSent();
    }

}
