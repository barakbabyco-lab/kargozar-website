<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\RequestEvent;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\ServiceRequest;
use App\Services\OtpDelivery;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CustomerApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_otp_login_issues_a_customer_token_and_does_not_return_the_code(): void
    {
        $delivery = new TestOtpDelivery;
        $this->app->instance(OtpDelivery::class, $delivery);

        $this->postJson('/api/v1/auth/otp/request', [
            'mobile' => '09120000001',
        ])->assertStatus(202)
            ->assertJsonMissingPath('data.code');

        $this->assertNotNull($delivery->lastCode);

        $response = $this->postJson('/api/v1/auth/otp/verify', [
            'mobile' => '09120000001',
            'code' => $delivery->lastCode,
        ])->assertOk()
            ->assertJsonPath('data.token_type', 'Bearer')
            ->assertJsonPath('data.customer.mobile', '09120000001');

        $this->assertNotEmpty($response->json('data.access_token'));
        $this->assertDatabaseHas('customers', [
            'mobile' => '09120000001',
        ]);
    }

    public function test_customer_can_create_and_replay_an_idempotent_service_request(): void
    {
        $customer = Customer::create([
            'mobile' => '09120000002',
            'status' => 'active',
        ]);
        $service = $this->makeService();
        $token = $customer->createToken('test')->plainTextToken;
        $headers = [
            'Authorization' => 'Bearer '.$token,
            'Idempotency-Key' => 'customer-request-key-001',
        ];
        $payload = [
            'service_id' => $service->id,
            'customer_note' => 'Test request only',
        ];

        $first = $this->withHeaders($headers)
            ->postJson('/api/v1/service-requests', $payload)
            ->assertCreated()
            ->assertJsonPath('data.status', 'submitted');

        $trackingCode = $first->json('data.tracking_code');

        $this->withHeaders($headers)
            ->postJson('/api/v1/service-requests', $payload)
            ->assertCreated()
            ->assertJsonPath('data.tracking_code', $trackingCode);

        $this->assertDatabaseCount('service_requests', 1);
        $this->assertDatabaseCount('request_events', 1);
    }

    public function test_reusing_an_idempotency_key_with_a_different_payload_is_rejected(): void
    {
        $customer = Customer::create([
            'mobile' => '09120000003',
            'status' => 'active',
        ]);
        $service = $this->makeService();
        $token = $customer->createToken('test')->plainTextToken;
        $headers = [
            'Authorization' => 'Bearer '.$token,
            'Idempotency-Key' => 'customer-request-key-002',
        ];

        $this->withHeaders($headers)->postJson('/api/v1/service-requests', [
            'service_id' => $service->id,
        ])->assertCreated();

        $this->withHeaders($headers)->postJson('/api/v1/service-requests', [
            'service_id' => $service->id,
            'customer_note' => 'Different payload',
        ])->assertStatus(409)
            ->assertJsonPath('error.code', 'IDEMPOTENCY_CONFLICT');

        $this->assertDatabaseCount('service_requests', 1);
    }

    public function test_customer_cannot_read_another_customers_request_or_internal_notes(): void
    {
        $owner = Customer::create([
            'mobile' => '09120000004',
            'status' => 'active',
        ]);
        $other = Customer::create([
            'mobile' => '09120000005',
            'status' => 'active',
        ]);
        $service = $this->makeService();
        $serviceRequest = ServiceRequest::create([
            'public_id' => (string) \Illuminate\Support\Str::uuid(),
            'customer_id' => $owner->id,
            'service_id' => $service->id,
            'tracking_code' => 'KG-OWNED-REQUEST-001',
            'status' => 'submitted',
        ]);
        RequestEvent::create([
            'service_request_id' => $serviceRequest->id,
            'actor_type' => 'staff',
            'status' => 'reviewing',
            'public_message' => 'در حال بررسی',
            'internal_note' => 'PRIVATE INTERNAL NOTE',
        ]);

        $this->actingAs($other, 'sanctum')
            ->getJson('/api/v1/me/service-requests/'.$serviceRequest->tracking_code)
            ->assertNotFound();

        $this->actingAs($owner, 'sanctum')
            ->getJson('/api/v1/me/service-requests/'.$serviceRequest->tracking_code)
            ->assertOk()
            ->assertJsonMissing(['internal_note' => 'PRIVATE INTERNAL NOTE'])
            ->assertJsonMissingText('PRIVATE INTERNAL NOTE');
    }

    public function test_public_catalog_returns_only_active_services(): void
    {
        $category = ServiceCategory::create([
            'name' => 'مجوزها',
            'slug' => 'licenses',
            'is_active' => true,
        ]);
        Service::create([
            'category_id' => $category->id,
            'title' => 'جواز کسب',
            'slug' => 'business-license',
            'description' => 'توضیحات آزمایشی',
            'is_active' => true,
        ]);
        Service::create([
            'category_id' => $category->id,
            'title' => 'خدمت غیرفعال',
            'slug' => 'inactive-service',
            'description' => 'نباید نمایش داده شود',
            'is_active' => false,
        ]);

        $this->getJson('/api/v1/services')
            ->assertOk()
            ->assertJsonPath('data.0.slug', 'business-license')
            ->assertJsonMissing(['slug' => 'inactive-service']);
    }

    private function makeService(): Service
    {
        $category = ServiceCategory::create([
            'name' => 'مجوزها',
            'slug' => 'licenses-'.uniqid(),
            'is_active' => true,
        ]);

        return Service::create([
            'category_id' => $category->id,
            'title' => 'جواز کسب',
            'slug' => 'business-license-'.uniqid(),
            'description' => 'توضیحات آزمایشی',
            'requirements' => [],
            'is_active' => true,
        ]);
    }
}

class TestOtpDelivery implements OtpDelivery
{
    public ?string $lastCode = null;

    public function send(string $mobile, string $code): void
    {
        $this->lastCode = $code;
    }
}
