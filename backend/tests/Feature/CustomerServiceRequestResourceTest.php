<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Service;
use App\Models\ServiceCategory;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CustomerServiceRequestResourceTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_request_responses_include_the_related_service_title(): void
    {
        $customer = Customer::create([
            'mobile' => '09120000091',
            'status' => 'active',
        ]);
        $category = ServiceCategory::create([
            'name' => 'مجوزها',
            'slug' => 'licenses-resource-test',
            'is_active' => true,
        ]);
        $service = Service::create([
            'category_id' => $category->id,
            'title' => 'دریافت جواز کسب',
            'slug' => 'business-license-resource-test',
            'description' => 'توضیحات آزمایشی',
            'requirements' => [],
            'is_active' => true,
        ]);
        $token = $customer->createToken('test')->plainTextToken;
        $headers = ['Authorization' => 'Bearer '.$token];

        $created = $this->withHeaders($headers)
            ->withHeader('Idempotency-Key', 'resource-test-request-001')
            ->postJson('/api/v1/service-requests', [
                'service_id' => $service->id,
            ])
            ->assertCreated()
            ->assertJsonPath('data.service.title', 'دریافت جواز کسب');

        $trackingCode = $created->json('data.tracking_code');

        $this->withHeaders($headers)
            ->getJson('/api/v1/me/service-requests')
            ->assertOk()
            ->assertJsonPath('data.0.service.title', 'دریافت جواز کسب');

        $this->withHeaders($headers)
            ->getJson('/api/v1/me/service-requests/'.$trackingCode)
            ->assertOk()
            ->assertJsonPath('data.service.title', 'دریافت جواز کسب');
    }
}
