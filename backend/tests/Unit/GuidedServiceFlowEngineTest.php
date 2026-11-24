<?php

namespace Tests\Unit;

use App\Models\SupportConversation;
use App\Services\Support\GuidedServiceFlowEngine;
use App\Services\Support\SupportAssistant;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class GuidedServiceFlowEngineTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_starts_a_guild_license_flow_for_a_supported_service_intent(): void
    {
        $conversation = SupportConversation::query()->create(['status' => 'open']);

        $reply = app(GuidedServiceFlowEngine::class)->handle(
            'می‌خوام جواز کسب خرازی بگیرم',
            (int) $conversation->id
        );

        $this->assertStringContainsString('چند سؤال کوتاه', $reply);
        $this->assertStringContainsString('محل فعالیت در کدوم شهره؟', $reply);
        $this->assertSame('guild-business-license', $conversation->fresh()->assistant_context['guided_flow']['flow_key']);
        $this->assertSame('retail', $conversation->fresh()->assistant_context['guided_flow']['answers']['activity_group']);
        $this->assertSame('خرازی', $conversation->fresh()->assistant_context['guided_flow']['answers']['activity_detail']);
    }

    public function test_it_accepts_persian_numeric_choices_and_advances_the_flow(): void
    {
        $conversation = SupportConversation::query()->create(['status' => 'open']);
        $engine = app(GuidedServiceFlowEngine::class);

        $engine->handle('ثبت برند می‌خوام', (int) $conversation->id);
        $conversation->messages()->create([
            'sender_type' => 'customer',
            'sender_id' => null,
            'body' => '۲',
        ]);

        $reply = $engine->handle('۲', (int) $conversation->id);

        $this->assertStringContainsString('برند برای چه کالا یا خدماتی استفاده می‌شه؟', $reply);
        $this->assertSame('logo', $conversation->fresh()->assistant_context['guided_flow']['answers']['mark_type']);
    }

    public function test_conditional_questions_are_skipped_when_their_activity_group_does_not_apply(): void
    {
        $conversation = SupportConversation::query()->create(['status' => 'open']);
        $engine = app(GuidedServiceFlowEngine::class);

        $engine->handle('برای جواز کسب راهنمایی می‌خوام', (int) $conversation->id);
        $answers = ['1', 'خرازی', 'تهران', '1', '2', '2'];
        $reply = '';

        foreach ($answers as $answer) {
            $conversation->messages()->create([
                'sender_type' => 'customer',
                'sender_id' => null,
                'body' => $answer,
            ]);
            $reply = $engine->handle($answer, (int) $conversation->id) ?? '';
        }

        $this->assertStringContainsString('گواهی دوره احکام تجارت', $reply);
        $this->assertStringNotContainsString('گواهینامه فنی‌وحرفه‌ای مرتبط با این فعالیت رو دارید؟', $reply);
    }
    public function test_the_registered_support_assistant_uses_guided_flows_without_a_model_provider(): void
    {
        config(['assistant_ai.enabled' => false]);
        $conversation = SupportConversation::query()->create(['status' => 'open']);

        $reply = app(SupportAssistant::class)->reply(
            'برای ثبت برند راهنمایی می‌خوام',
            (int) $conversation->id
        );

        $this->assertStringContainsString('چه چیزی رو می‌خواید ثبت کنید؟', $reply);
        $this->assertSame('trademark-registration', $conversation->fresh()->assistant_context['guided_flow']['flow_key']);
    }

    public function test_accounting_software_request_starts_a_bounded_requirements_interview(): void
    {
        $conversation = SupportConversation::query()->create(['status' => 'open']);

        $reply = app(GuidedServiceFlowEngine::class)->handle(
            'برای کسب و کارم نرم افزار حسابداری می‌خوام',
            (int) $conversation->id
        );

        $this->assertStringContainsString('نوع فعالیت کسب‌وکارتون چیه؟', $reply);
        $this->assertStringContainsString('فروشگاهی و خرده‌فروشی', $reply);
        $this->assertSame('accounting-software', $conversation->fresh()->assistant_context['guided_flow']['flow_key']);
    }
}
