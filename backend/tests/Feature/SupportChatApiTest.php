<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\StaffUser;
use App\Models\SupportConversation;
use App\Http\Controllers\Api\V1\SupportChatController;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SupportChatApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_unanswered_question_is_linked_to_its_conversation(): void
    {
        $guestToken = str_repeat('e5', 32);

        $started = $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->postJson('/api/v1/guest/support-conversations', ['body' => 'هزینه دریافت جواز کسب چقدر است؟'])
            ->assertCreated();

        $conversationId = $started->json('data.id');
        app(SupportChatController::class)->processAssistantReply($conversationId, 'هزینه دریافت جواز کسب چقدر است؟');

        $this->assertDatabaseHas('support_unanswered_question_events', [
            'conversation_id' => $conversationId,
            'outcome' => 'guided_service_flow',
        ]);
    }

    public function test_guest_questions_outside_kargozar_scope_are_redirected(): void
    {
        $guestToken = str_repeat('f6', 32);

        $started = $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->postJson('/api/v1/guest/support-conversations', ['body' => 'فردا هوا چطوره؟'])
            ->assertCreated();

        $conversationId = $started->json('data.id');
        app(SupportChatController::class)->processAssistantReply($conversationId, 'فردا هوا چطوره؟');
        $messages = $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->getJson('/api/v1/guest/support-conversations/'.$conversationId.'/messages')
            ->assertOk()
            ->json('data');
        $this->assertStringContainsString('دستیار تخصصی کارگزارم', $messages[1]['body']);
        $this->assertDatabaseHas('support_unanswered_question_events', [
            'conversation_id' => $conversationId,
            'outcome' => 'out_of_scope',
        ]);
    }

    public function test_guest_small_talk_is_acknowledged_without_leaving_service_scope(): void
    {
        $guestToken = str_repeat('f7', 32);

        $started = $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->postJson('/api/v1/guest/support-conversations', ['body' => 'حالت چطوره؟'])
            ->assertCreated();

        $conversationId = $started->json('data.id');
        app(SupportChatController::class)->processAssistantReply($conversationId, 'حالت چطوره؟');
        $messages = $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->getJson('/api/v1/guest/support-conversations/'.$conversationId.'/messages')
            ->assertOk()
            ->json('data');
        $this->assertStringContainsString('ممنون، آماده‌ام', $messages[1]['body']);
    }

    public function test_customer_can_start_and_continue_a_support_conversation(): void
    {
        $customer = Customer::create(['mobile' => '09120000111', 'status' => 'active']);

        $started = $this->actingAs($customer, 'sanctum')
            ->postJson('/api/v1/support-conversations', ['body' => 'برای دریافت جواز کسب راهنمایی می‌خواهم.'])
            ->assertCreated()
            ->assertJsonPath('data.status', 'open')
            ->assertJsonPath('data.messages.0.sender_type', 'customer');

        $id = $started->json('data.id');
        app(SupportChatController::class)->processAssistantReply($id, 'برای دریافت جواز کسب راهنمایی می‌خواهم.');

        $this->actingAs($customer, 'sanctum')
            ->postJson('/api/v1/me/support-conversations/'.$id.'/messages', ['body' => 'مدارک لازم چیست؟'])
            ->assertCreated()
            ->assertJsonPath('data.sender_type', 'customer');
        app(SupportChatController::class)->processAssistantReply($id, 'مدارک لازم چیست؟');

        $this->actingAs($customer, 'sanctum')
            ->getJson('/api/v1/me/support-conversations/'.$id.'/messages')
            ->assertOk()
            ->assertJsonCount(4, 'data');
    }

    public function test_guest_can_start_and_continue_support_without_customer_login(): void
    {
        $guestToken = str_repeat('a1', 32);

        $started = $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->postJson('/api/v1/guest/support-conversations', ['body' => 'برای دریافت جواز کسب راهنمایی می‌خواهم.'])
            ->assertCreated()
            ->assertJsonPath('data.guest', true)
            ->assertJsonPath('data.messages.0.sender_type', 'customer')
            ->assertJsonPath('data.messages.1.sender_type', 'assistant')
            ->assertJsonPath('data.messages.1.body', fn ($value) => str_contains($value, 'نوع شغل'));

        $id = $started->json('data.id');
        app(SupportChatController::class)->processAssistantReply($id, 'برای دریافت جواز کسب راهنمایی می‌خواهم.');
        $conversation = SupportConversation::findOrFail($id);
        $this->assertNull($conversation->customer_id);
        $this->assertSame(hash('sha256', $guestToken), $conversation->guest_token_hash);
        $this->assertNotSame($guestToken, $conversation->guest_token_hash);

        $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->postJson('/api/v1/guest/support-conversations/'.$id.'/messages', ['body' => 'مدارک لازم چیست؟'])
            ->assertCreated()
            ->assertJsonPath('data.sender_type', 'customer');
        app(SupportChatController::class)->processAssistantReply($id, 'مدارک لازم چیست؟');

        $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->getJson('/api/v1/guest/support-conversations/'.$id.'/messages')
            ->assertOk()
            ->assertJsonCount(4, 'data');

        $this->withHeader('X-Support-Guest-Token', str_repeat('b2', 32))
            ->getJson('/api/v1/guest/support-conversations/'.$id.'/messages')
            ->assertUnauthorized();
    }

    public function test_guest_missing_premises_fact_is_prefilled_and_kept_in_guided_flow(): void
    {
        $guestToken = str_repeat('d4', 32);

        $started = $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->postJson('/api/v1/guest/support-conversations', ['body' => 'برای جواز کسب مغازه ندارم'])
            ->assertCreated();

        $id = $started->json('data.id');
        app(SupportChatController::class)->processAssistantReply($id, 'برای جواز کسب مغازه ندارم');
        $messages = $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->getJson('/api/v1/guest/support-conversations/'.$id.'/messages')
            ->assertOk()
            ->json('data');
        $this->assertStringContainsString('نوع شغل', $messages[1]['body']);

        $conversation = SupportConversation::findOrFail($id);
        $this->assertSame('not_selected', $conversation->assistant_context['guided_flow']['answers']['premises_status']);

        $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->postJson('/api/v1/guest/support-conversations/'.$id.'/messages', ['body' => 'چطوری؟'])
            ->assertCreated();
        app(SupportChatController::class)->processAssistantReply($id, 'چطوری؟');

        $messages = $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->getJson('/api/v1/guest/support-conversations/'.$id.'/messages')
            ->assertOk()
            ->assertJsonCount(4, 'data')
            ->json('data');

        $this->assertStringContainsString('نوع شغل', $messages[3]['body']);
        $this->assertDatabaseMissing('support_unanswered_question_events', [
            'conversation_id' => $id,
            'outcome' => 'human_escalation',
        ]);
    }

    public function test_guest_can_request_internal_review_without_a_callback_number(): void
    {
        $guestToken = str_repeat('c3', 32);

        $started = $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->postJson('/api/v1/guest/support-conversations', ['body' => 'تماس کارشناس'])
            ->assertCreated();

        $conversationId = $started->json('data.id');
        app(SupportChatController::class)->processAssistantReply($conversationId, 'تماس کارشناس');
        $messages = $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->getJson('/api/v1/guest/support-conversations/'.$conversationId.'/messages')
            ->assertOk()
            ->json('data');
        $reply = $messages[1]['body'];
        $this->assertStringContainsString('بررسی داخلی', $reply);
        $this->assertStringContainsString('نیازی به ثبت شماره تماس نیست', $reply);
        $conversation = SupportConversation::findOrFail($started->json('data.id'));
        $this->assertNull($conversation->contact_mobile);
        $this->assertTrue($conversation->assistant_context['internal_review']['required']);
    }

    public function test_signed_in_customer_can_request_internal_review_without_a_callback_number(): void
    {
        $customer = Customer::create(['mobile' => '09120000115', 'status' => 'active']);

        $started = $this->actingAs($customer, 'sanctum')
            ->postJson('/api/v1/support-conversations', ['body' => 'تماس کارشناس'])
            ->assertCreated();

        $conversationId = $started->json('data.id');
        app(SupportChatController::class)->processAssistantReply($conversationId, 'تماس کارشناس');
        $messages = $this->actingAs($customer, 'sanctum')
            ->getJson('/api/v1/me/support-conversations/'.$conversationId.'/messages')
            ->assertOk()
            ->json('data');
        $reply = $messages[1]['body'];
        $this->assertStringContainsString('بررسی داخلی', $reply);
        $this->assertStringContainsString('نیازی به ثبت شماره تماس نیست', $reply);
        $this->assertNull(SupportConversation::findOrFail($started->json('data.id'))->contact_mobile);
    }

    public function test_customer_cannot_read_or_send_messages_to_another_customers_conversation(): void
    {
        $owner = Customer::create(['mobile' => '09120000112', 'status' => 'active']);
        $other = Customer::create(['mobile' => '09120000113', 'status' => 'active']);
        $conversation = SupportConversation::create(['customer_id' => $owner->id, 'status' => 'open']);

        $this->actingAs($other, 'sanctum')
            ->getJson('/api/v1/me/support-conversations/'.$conversation->id.'/messages')
            ->assertNotFound();

        $this->actingAs($other, 'sanctum')
            ->postJson('/api/v1/me/support-conversations/'.$conversation->id.'/messages', ['body' => 'پیام غیرمجاز'])
            ->assertNotFound();
    }

    public function test_support_staff_can_reply_and_close_a_conversation(): void
    {
        $customer = Customer::create(['mobile' => '09120000114', 'status' => 'active']);
        $conversation = SupportConversation::create(['customer_id' => $customer->id, 'status' => 'open']);
        $staff = StaffUser::create([
            'name' => 'Support Agent',
            'email' => 'support@example.test',
            'password' => 'test-password',
            'role' => 'support',
            'is_active' => true,
        ]);

        $this->actingAs($staff, 'sanctum')
            ->postJson('/api/v1/staff/support-conversations/'.$conversation->id.'/messages', ['body' => 'سلام، در خدمت شما هستیم.'])
            ->assertCreated()
            ->assertJsonPath('data.sender_type', 'staff');

        $this->actingAs($staff, 'sanctum')
            ->patchJson('/api/v1/staff/support-conversations/'.$conversation->id.'/status', ['status' => 'closed'])
            ->assertOk()
            ->assertJsonPath('data.status', 'closed');

        $this->actingAs($customer, 'sanctum')
            ->postJson('/api/v1/me/support-conversations/'.$conversation->id.'/messages', ['body' => 'پیام بعد از بسته‌شدن'])
            ->assertStatus(409);
    }
}
