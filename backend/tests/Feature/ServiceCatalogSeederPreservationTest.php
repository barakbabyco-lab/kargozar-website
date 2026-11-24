<?php

namespace Tests\Feature;

use App\Models\Service;
use Database\Seeders\ServiceCatalogSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ServiceCatalogSeederPreservationTest extends TestCase
{
    use RefreshDatabase;

    public function test_reseeding_preserves_staff_pricing_duration_and_verification_timestamps(): void
    {
        $seeder = app(ServiceCatalogSeeder::class);
        $seeder->run();

        $service = Service::query()->where('slug', 'business-license')->firstOrFail();
        $verifiedAt = now()->subDay();

        $service->update([
            'base_price' => 2500000,
            'estimated_days' => 12,
            'price_verified_at' => $verifiedAt,
            'duration_verified_at' => $verifiedAt,
            'requirements' => ['مدرک آزمایشی'],
        ]);

        $seeder->run();

        $service->refresh();
        $this->assertSame('2500000.00', $service->base_price);
        $this->assertSame(12, $service->estimated_days);
        $this->assertSame(['مدرک آزمایشی'], $service->requirements);
        $this->assertEquals($verifiedAt->timestamp, $service->price_verified_at->timestamp);
        $this->assertEquals($verifiedAt->timestamp, $service->duration_verified_at->timestamp);
    }

    public function test_seeder_adds_the_company_and_guild_prerequisite_services(): void
    {
        app(ServiceCatalogSeeder::class)->run();

        $this->assertDatabaseHas('services', ['slug' => 'company-incorporation', 'is_active' => true]);
        $this->assertDatabaseHas('services', ['slug' => 'police-places-approval', 'is_active' => true]);
        $this->assertDatabaseHas('services', ['slug' => 'environment-health-approval', 'is_active' => true]);
        $this->assertDatabaseHas('services', ['slug' => 'trade-rules-certificate', 'is_active' => true]);
        $this->assertDatabaseHas('services', ['slug' => 'technical-vocational-certificate', 'is_active' => true]);
    }
}
