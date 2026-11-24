<?php

namespace Tests\Feature;

use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\StaffUser;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class StaffCatalogQuoteVerificationTest extends TestCase
{
    use RefreshDatabase;

    private function staffAdmin(): StaffUser
    {
        $staff = StaffUser::create([
            'name' => 'Catalog Admin',
            'email' => 'catalog-admin@example.test',
            'password' => 'test-password',
            'role' => 'admin',
            'is_active' => true,
        ]);

        Sanctum::actingAs($staff);

        return $staff;
    }

    private function service(): Service
    {
        $category = ServiceCategory::create([
            'name' => 'مجوزها',
            'slug' => 'licenses',
            'is_active' => true,
            'sort_order' => 1,
        ]);

        return Service::create([
            'category_id' => $category->id,
            'title' => 'جواز کسب',
            'slug' => 'business-license',
            'description' => 'خدمت آزمایشی',
            'requirements' => [],
            'estimated_days' => null,
            'base_price' => null,
            'is_active' => true,
            'sort_order' => 1,
        ]);
    }

    public function test_changing_price_or_duration_clears_old_verification_timestamps(): void
    {
        $service = $this->service();
        $service->update([
            'base_price' => 100000,
            'estimated_days' => 3,
            'price_verified_at' => now()->subDay(),
            'duration_verified_at' => now()->subDay(),
        ]);

        $this->staffAdmin();

        $this->patchJson('/api/v1/staff/catalog/services/'.$service->id, [
            'base_price' => 150000,
            'estimated_days' => 5,
        ])->assertOk();

        $this->assertDatabaseHas('services', [
            'id' => $service->id,
            'base_price' => 150000,
            'estimated_days' => 5,
            'price_verified_at' => null,
            'duration_verified_at' => null,
        ]);
    }

    public function test_staff_can_explicitly_mark_current_price_and_duration_as_verified(): void
    {
        $service = $this->service();
        $this->staffAdmin();

        $verifiedAt = now()->toIso8601String();

        $this->patchJson('/api/v1/staff/catalog/services/'.$service->id, [
            'base_price' => 150000,
            'estimated_days' => 5,
            'price_verified_at' => $verifiedAt,
            'duration_verified_at' => $verifiedAt,
        ])->assertOk()
            ->assertJsonPath('data.price_verified_at', fn ($value) => is_string($value))
            ->assertJsonPath('data.duration_verified_at', fn ($value) => is_string($value));

        $service->refresh();
        $this->assertNotNull($service->price_verified_at);
        $this->assertNotNull($service->duration_verified_at);
    }

    public function test_staff_cannot_mark_future_quote_verification_timestamps(): void
    {
        $service = $this->service();
        $this->staffAdmin();

        $this->patchJson('/api/v1/staff/catalog/services/'.$service->id, [
            'base_price' => 150000,
            'price_verified_at' => now()->addDay()->toIso8601String(),
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('price_verified_at');
    }
}
