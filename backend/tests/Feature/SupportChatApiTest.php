<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\StaffUser;
use App\Models\SupportConversation;
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

        $this->assertDatabaseHas('support_unanswered_question_events', [
            'conversation_id' => $conversationId,
            'outcome' => 'human_escalation',
        ]);
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

        $this->actingAs($customer, 'sanctum')
            ->postJson('/api/v1/me/support-conversations/'.$id.'/messages', ['body' => 'مدارک لازم چیست؟'])
            ->assertCreated()
            ->assertJsonPath('data.sender_type', 'customer');

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
        $conversation = SupportConversation::findOrFail($id);
        $this->assertNull($conversation->customer_id);
        $this->assertSame(hash('sha256', $guestToken), $conversation->guest_token_hash);
        $this->assertNotSame($guestToken, $conversation->guest_token_hash);

        $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->postJson('/api/v1/guest/support-conversations/'.$id.'/messages', ['body' => 'مدارک لازم چیست؟'])
            ->assertCreated()
            ->assertJsonPath('data.sender_type', 'customer');

        $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->getJson('/api/v1/guest/support-conversations/'.$id.'/messages')
            ->assertOk()
            ->assertJsonCount(4, 'data');

        $this->withHeader('X-Support-Guest-Token', str_repeat('b2', 32))
            ->getJson('/api/v1/guest/support-conversations/'.$id.'/messages')
            ->assertUnauthorized();
    }

    public function test_guest_missing_requirement_followup_stays_on_human_escalation_path(): void
    {
        $guestToken = str_repeat('d4', 32);

        $started = $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->postJson('/api/v1/guest/support-conversations', ['body' => 'برای جواز کسب مغازه ندارم'])
            ->assertCreated()
            ->assertJsonPath('data.messages.1.sender_type', 'assistant');

        $id = $started->json('data.id');
        $this->assertStringContainsString('این مورد لزوماً به معنی متوقف‌شدن درخواست شما نیست.', $started->json('data.messages.1.body'));

        $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->postJson('/api/v1/guest/support-conversations/'.$id.'/messages', ['body' => 'چطوری؟'])
            ->assertCreated();

        $messages = $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->getJson('/api/v1/guest/support-conversations/'.$id.'/messages')
            ->assertOk()
            ->assertJsonCount(4, 'data')
            ->json('data');

        $this->assertStringContainsString('این مورد لزوماً به معنی متوقف‌شدن درخواست شما نیست.', $messages[3]['body']);
        $this->assertStringContainsString('شماره تماس', $messages[3]['body']);

        $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->postJson('/api/v1/guest/support-conversations/'.$id.'/messages', ['body' => '۰۹۱۲۳۴۵۶۷۸۷'])
            ->assertCreated();

        $this->assertSame('09123456787', SupportConversation::findOrFail($id)->contact_mobile);
    }

    public function test_guest_can_submit_a_callback_mobile_after_requesting_a_human_agent(): void
    {
        $guestToken = str_repeat('c3', 32);

        $started = $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->postJson('/api/v1/guest/support-conversations', ['body' => 'تماس کارشناس'])
            ->assertCreated()
            ->assertJsonPath('data.messages.1.sender_type', 'assistant')
            ->assertJsonPath('data.messages.1.body', fn ($value) => str_contains($value, 'شماره تماس'));

        $id = $started->json('data.id');

        $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->postJson('/api/v1/guest/support-conversations/'.$id.'/messages', ['body' => '۰۹۱۲۳۴۵۶۷۸۹'])
            ->assertCreated();

        $this->assertSame('09123456789', SupportConversation::findOrFail($id)->contact_mobile);

        $this->withHeader('X-Support-Guest-Token', $guestToken)
            ->getJson('/api/v1/guest/support-conversations/'.$id.'/messages')
            ->assertOk()
            ->assertJsonCount(4, 'data')
            ->assertJsonPath('data.3.sender_type', 'assistant');
    }

    public function test_signed_in_customer_can_submit_a_callback_mobile_after_requesting_a_human_agent(): void
    {
        $customer = Customer::create(['mobile' => '09120000115', 'status' => 'active']);

        $started = $this->actingAs($customer, 'sanctum')
            ->postJson('/api/v1/support-conversations', ['body' => 'تماس کارشناس'])
            ->assertCreated()
            ->assertJsonPath('data.messages.1.sender_type', 'assistant')
            ->assertJsonPath('data.messages.1.body', fn ($value) => str_contains($value, 'شماره تماس'));

        $id = $started->json('data.id');

        $this->actingAs($customer, 'sanctum')
            ->postJson('/api/v1/me/support-conversations/'.$id.'/messages', ['body' => '۰۹۱۲۳۴۵۶۷۸۸'])
            ->assertCreated();

        $this->assertSame('09123456788', SupportConversation::findOrFail($id)->contact_mobile);

        $this->actingAs($customer, 'sanctum')
            ->getJson('/api/v1/me/support-conversations/'.$id.'/messages')
            ->assertOk()
            ->assertJsonCount(4, 'data')
            ->assertJsonPath('data.3.sender_type', 'assistant');
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
