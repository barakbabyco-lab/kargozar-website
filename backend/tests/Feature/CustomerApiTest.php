<?php

namespace Tests\\Feature;

use App\\Models\\Customer;
use App\\Models\\IdempotencyKey;
use App\\Models\\RequestEvent;
use App\\Models\\Service;
use App\\Models\\ServiceCategory;
use App\\Models\\ServiceRequest;
use App\\Models\\StaffUser;
use App\\Services\\OtpDelivery;
use Illuminate\\Foundation\\Testing\\RefreshDatabase;
use Tests\\TestCase;

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
            'public_id' => (string) \\Illuminate\\Support\\Str::uuid(),
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
            ->assertDontSee('PRIVATE INTERNAL NOTE');
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

    public function test_public_categories_include_parent_ids_for_multilevel_navigation(): void
    {
        $root = ServiceCategory::create([
            'name' => 'مجوزهای کسب‌وکار',
            'slug' => 'business-permits',
            'is_active' => true,
        ]);
        $child = ServiceCategory::create([
            'parent_id' => $root->id,
            'name' => 'مشاغل خانگی',
            'slug' => 'home-businesses',
            'is_active' => true,
        ]);
        ServiceCategory::create([
            'parent_id' => $child->id,
            'name' => 'تولیدی و صنعتی',
            'slug' => 'home-production',
            'is_active' => true,
        ]);

        $response = $this->getJson('/api/v1/service-categories')->assertOk();

        $this->assertSame((string) $root->id, $response->json('data.0.id'));
        $this->assertNull($response->json('data.0.parent_id'));
        $this->assertTrue($response->json('data.0.has_children'));

        $childNode = collect($response->json('data'))->firstWhere('slug', 'home-businesses');
        $this->assertNotNull($childNode);
        $this->assertSame((string) $root->id, $childNode['parent_id']);
        $this->assertTrue($childNode['has_children']);
    }

    public function test_public_catalog_hides_entire_branch_when_any_ancestor_is_inactive(): void
    {
        $root = ServiceCategory::create([
            'name' => 'مجوزهای کسب‌وکار',
            'slug' => 'inactive-root',
            'is_active' => false,
        ]);
        $child = ServiceCategory::create([
            'parent_id' => $root->id,
            'name' => 'مشاغل خانگی',
            'slug' => 'inactive-child',
            'is_active' => true,
        ]);
        $leaf = ServiceCategory::create([
            'parent_id' => $child->id,
            'name' => 'تولیدی و صنعتی',
            'slug' => 'inactive-leaf',
            'is_active' => true,
        ]);
        $service = Service::create([
            'category_id' => $leaf->id,
            'title' => 'مجوز تولیدی خانگی',
            'slug' => 'hidden-by-inactive-ancestor',
            'description' => 'این خدمت نباید در کاتالوگ عمومی دیده شود.',
            'requirements' => [],
            'is_active' => true,
        ]);

        $this->getJson('/api/v1/service-categories')
            ->assertOk()
            ->assertJsonMissing(['slug' => 'inactive-root'])
            ->assertJsonMissing(['slug' => 'inactive-child'])
            ->assertJsonMissing(['slug' => 'inactive-leaf']);

        $this->getJson('/api/v1/services')
            ->assertOk()
            ->assertJsonMissing(['slug' => $service->slug]);

        $this->getJson('/api/v1/services/'.$service->slug)
            ->assertNotFound();
    }

    public function test_api_authentication_and_not_found_errors_follow_the_contract(): void
    {
        $this->getJson('/api/v1/me/service-requests')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'UNAUTHENTICATED');

        $this->getJson('/api/v1/services/not-a-real-service')
            ->assertNotFound()
            ->assertJsonPath('error.code', 'NOT_FOUND');
    }

    public function test_staff_login_role_protection_assignment_and_internal_events(): void
    {
        $supervisor = StaffUser::create([
            'name' => 'Supervisor',
            'email' => 'supervisor@example.test',
            'password' => 'strong-test-password',
            'role' => 'supervisor',
            'is_active' => true,
        ]);
        $expert = StaffUser::create([
            'name' => 'Expert',
            'email' => 'expert@example.test',
            'password' => 'strong-test-password',
            'role' => 'expert',
            'is_active' => true,
        ]);

        $login = $this->postJson('/api/v1/staff/auth/login', [
            'email' => 'supervisor@example.test',
            'password' => 'strong-test-password',
        ])->assertOk()
            ->assertJsonPath('data.staff.role', 'supervisor');

        $token = $login->json('data.access_token');
        $customer = Customer::create([
            'mobile' => '09120000006',
            'status' => 'active',
        ]);
        $service = $this->makeService();
        $serviceRequest = ServiceRequest::create([
            'public_id' => (string) \\Illuminate\\Support\\Str::uuid(),
            'customer_id' => $customer->id,
            'service_id' => $service->id,
            'tracking_code' => 'KG-STAFF-REQUEST-001',
            'status' => 'submitted',
        ]);

        $headers = ['Authorization' => 'Bearer '.$token];

        $this->withHeaders($headers)
            ->patchJson('/api/v1/staff/service-requests/'.$serviceRequest->tracking_code.'/assignment', [
                'assigned_staff_id' => $expert->id,
            ])
            ->assertOk()
            ->assertJsonPath('data.assigned_staff.id', (string) $expert->id);

        $this->withHeaders($headers)
            ->postJson('/api/v1/staff/service-requests/'.$serviceRequest->tracking_code.'/events', [
                'status' => 'reviewing',
                'public_message' => 'پرونده در حال بررسی است.',
                'internal_note' => 'یادداشت داخلی کارشناسی',
            ])
            ->assertOk()
            ->assertJsonPath('data.status', 'reviewing')
            ->assertJsonPath('data.events.0.internal_note', 'یادداشت داخلی کارشناسی');

        $this->withHeaders($headers)
            ->getJson('/api/v1/staff/service-requests/'.$serviceRequest->tracking_code)
            ->assertOk()
            ->assertJsonPath('data.events.0.internal_note', 'یادداشت داخلی کارشناسی');

        $this->assertDatabaseHas('audit_logs', [
            'action' => 'staff.auth.login',
            'subject_id' => $supervisor->id,
        ]);
        $this->assertDatabaseHas('audit_logs', [
            'action' => 'service_request.viewed',
            'subject_id' => $serviceRequest->id,
        ]);
        $this->assertDatabaseHas('audit_logs', [
            'action' => 'service_request.assigned',
            'subject_id' => $serviceRequest->id,
        ]);
        $this->assertDatabaseHas('audit_logs', [
            'action' => 'service_request.event_recorded',
            'subject_id' => $serviceRequest->id,
        ]);

        $this->actingAs($customer, 'sanctum')
            ->getJson('/api/v1/staff/service-requests')
            ->assertForbidden();
    }

    public function test_expired_idempotency_key_can_be_reused(): void
    {
        $customer = Customer::create([
            'mobile' => '09120000008',
            'status' => 'active',
        ]);
        $service = $this->makeService();
        $key = 'expired-request-key-001';
        $requestHash = hash('sha256', json_encode([
            'service_id' => (int) $service->id,
            'customer_note' => null,
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));

        IdempotencyKey::create([
            'customer_id' => $customer->id,
            'key_hash' => hash('sha256', $key),
            'request_hash' => $requestHash,
            'response_json' => ['data' => ['tracking_code' => 'KG-OLD']],
            'response_status' => 201,
            'expires_at' => now()->subMinute(),
        ]);

        $token = $customer->createToken('test')->plainTextToken;
        $this->withToken($token)
            ->withHeader('Idempotency-Key', $key)
            ->postJson('/api/v1/service-requests', [
                'service_id' => $service->id,
            ])
            ->assertCreated()
            ->assertJsonMissing(['tracking_code' => 'KG-OLD']);

        $this->assertDatabaseCount('service_requests', 1);
        $this->assertDatabaseHas('idempotency_keys', [
            'customer_id' => $customer->id,
            'key_hash' => hash('sha256', $key),
        ]);
    }

    public function test_supervisor_can_manage_service_catalog_but_expert_cannot(): void
    {
        $supervisor = StaffUser::create([
            'name' => 'Catalog Supervisor',
            'email' => 'catalog-supervisor@example.test',
            'password' => 'strong-test-password',
            'role' => 'supervisor',
            'is_active' => true,
        ]);
        $expert = StaffUser::create([
            'name' => 'Catalog Expert',
            'email' => 'catalog-expert@example.test',
            'password' => 'strong-test-password',
            'role' => 'expert',
            'is_active' => true,
        ]);
        $supervisorToken = $supervisor->createToken('staff')->plainTextToken;

        $category = $this->withToken($supervisorToken)
            ->postJson('/api/v1/staff/catalog/categories', [
                'name' => 'خدمات آزمایشی',
                'slug' => 'test-services',
                'is_active' => true,
            ])
            ->assertCreated()
            ->json('data');

        $childCategory = $this->withToken($supervisorToken)
            ->postJson('/api/v1/staff/catalog/categories', [
                'parent_id' => (int) $category['id'],
                'name' => 'زیرشاخه آزمایشی',
                'slug' => 'test-services-child',
                'is_active' => true,
            ])
            ->assertCreated()
            ->assertJsonPath('data.parent_id', (string) $category['id'])
            ->json('data');

        $this->withToken($supervisorToken)
            ->patchJson('/api/v1/staff/catalog/categories/'.$category['id'], [
                'parent_id' => (int) $childCategory['id'],
            ])
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR');

        $service = $this->withToken($supervisorToken)
            ->postJson('/api/v1/staff/catalog/services', [
                'category_id' => (int) $childCategory['id'],
                'title' => 'خدمت آزمایشی',
                'slug' => 'test-service-item',
                'description' => 'توضیحات آزمایشی خدمت',
                'requirements' => ['مدرک نمونه'],
                'is_active' => true,
            ])
            ->assertCreated()
            ->assertJsonPath('data.slug', 'test-service-item');

        $serviceId = (int) $service->json('data.id');
        $this->withToken($supervisorToken)
            ->patchJson('/api/v1/staff/catalog/services/'.$serviceId, [
                'is_active' => false,
            ])
            ->assertOk()
            ->assertJsonPath('data.is_active', false);

        $this->actingAs($expert, 'sanctum')
            ->postJson('/api/v1/staff/catalog/categories', [
                'name' => 'نباید ساخته شود',
                'slug' => 'forbidden-category',
            ])
            ->assertForbidden();

        $this->getJson('/api/v1/services/test-service-item')
            ->assertNotFound()
            ->assertJsonPath('error.code', 'NOT_FOUND');

        $this->assertDatabaseHas('audit_logs', [
            'action' => 'catalog.category_created',
        ]);
        $this->assertDatabaseHas('audit_logs', [
            'action' => 'catalog.service_created',
        ]);
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
