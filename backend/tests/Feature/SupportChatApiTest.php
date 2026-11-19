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
            ->assertJsonCount(2, 'data');
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
