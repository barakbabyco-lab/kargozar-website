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

    public function test_company_registration_intent_receives_official_portal_context(): void
    {
        $assistant = app(SupportAssistant::class);
        $method = new \ReflectionMethod(SupportAssistant::class, 'assistantServiceContext');
        $method->setAccessible(true);
        $context = $method->invoke($assistant, 'می‌خوام یک شرکت با مسئولیت محدود ثبت کنم');

        $company = collect($context)->firstWhere('service_key', 'company-registration');

        $this->assertIsArray($company);
        $this->assertSame('https://irsherkat.ssaa.ir/', $company['source_url'] ?? null);
        $this->assertSame('سامانه رسمی ثبت شرکت‌ها', $company['official_source'] ?? null);
    }

    public function test_ai_receives_tax_file_service_intent_and_official_portal(): void
    {
        Http::fake([
            'api.example.test/v1/chat/completions' => Http::response([
                'choices' => [[
                    'message' => ['content' => 'برای تشکیل پرونده مالیاتی، اول مشخص کنیم شخص حقیقی هستید یا حقوقی؟'],
                ]],
            ], 200),
        ]);

        $answer = app(SupportAssistant::class)->reply('برای تشکیل پرونده مالیاتی راهنمایی می‌خوام');

        $this->assertStringContainsString('حقیقی هستید یا حقوقی', $answer);
        Http::assertSent(function ($request): bool {
            $messages = $request->data()['messages'] ?? [];
            $payload = json_decode((string) ($messages[1]['content'] ?? ''), true);
            $tax = collect($payload['service_knowledge'] ?? [])
                ->firstWhere('service_key', 'tax-file-and-tracking');

            return ($tax['source_url'] ?? null) === 'https://my.tax.gov.ir/';
        });
    }

    public function test_structured_service_analysis_builds_a_customer_specific_quote_context(): void
    {
        app(\Database\Seeders\ServiceCatalogSeeder::class)->run();

        $analysis = json_encode([
            'requested_outcome' => 'دریافت جواز کسب فروشگاه پوشاک',
            'matched_service_keys' => ['guild-business-license'],
            'required_service_keys' => ['health-card'],
            'missing_prerequisite_keys' => ['health_card'],
            'customer_state' => [
                ['requirement_key' => 'health_card', 'status' => 'missing'],
            ],
            'known_facts' => ['activity' => 'فروشگاه پوشاک'],
            'missing_facts' => [],
            'clarifying_question' => null,
            'confidence' => 0.94,
            'needs_human' => false,
        ], JSON_UNESCAPED_UNICODE);

        Http::fakeSequence()
            ->push(['choices' => [['message' => ['content' => $analysis]]]], 200)
            ->push(['choices' => [['message' => ['content' => 'برای تکمیل درخواست، خدمات موردنیاز را به شما اعلام می‌کنم.']]]], 200);

        $answer = app(SupportAssistant::class)->reply('برای جواز کسب فروشگاه پوشاک راهنمایی می‌خواهم');

        $this->assertStringContainsString('خدمات موردنیاز', $answer);
        Http::assertSent(function ($request): bool {
            $messages = $request->data()['messages'] ?? [];
            $payload = json_decode((string) ($messages[1]['content'] ?? ''), true);
            $analysis = collect($payload['service_knowledge'] ?? [])
                ->firstWhere('service_need_analysis');
            $quote = collect($payload['service_knowledge'] ?? [])
                ->firstWhere('service_quote_context');
            $lineItems = $quote['service_quote_context']['line_items'] ?? [];

            return is_array($analysis)
                && count($lineItems) === 2
                && count(array_filter($lineItems, fn ($item) => ($item['orderable'] ?? false) === true)) === 2
                && ($quote['service_quote_context']['service_fee_subtotal'] ?? null) === null;
        });
    }

}
