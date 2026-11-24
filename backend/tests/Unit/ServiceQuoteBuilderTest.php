<?php

namespace Tests\Unit;

use App\Models\Service;
use App\Models\ServiceCategory;
use App\Services\Support\ServiceQuoteBuilder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ServiceQuoteBuilderTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Config::set('assistant_ai.quote_currency', 'IRT');
    }

    private function createService(string $slug, ?float $price, ?int $days, array $timestamps = []): Service
    {
        $category = ServiceCategory::query()->firstOrCreate(
            ['slug' => 'licenses'],
            ['name' => 'مجوزهای کسب‌وکار', 'is_active' => true, 'sort_order' => 1]
        );

        return Service::query()->create(array_merge([
            'category_id' => $category->id,
            'title' => 'جواز کسب',
            'slug' => $slug,
            'description' => 'خدمت آزمایشی',
            'requirements' => [],
            'estimated_days' => $days,
            'base_price' => $price,
            'is_active' => true,
            'sort_order' => 1,
        ], $timestamps));
    }

    public function test_it_does_not_quote_unverified_catalog_values(): void
    {
        $this->createService('business-license', 1500000, 7);

        $quote = app(ServiceQuoteBuilder::class)->build(['guild-business-license']);

        $this->assertSame('requires_review_or_missing_values', $quote['quote_status']);
        $this->assertNull($quote['service_fee_subtotal']);
        $this->assertSame('verification_missing_or_stale', $quote['line_items'][0]['price_status']);
        $this->assertNull($quote['line_items'][0]['price_amount']);
        $this->assertNull($quote['line_items'][0]['estimated_days']);
    }

    public function test_it_sums_only_currently_verified_service_fees_and_durations(): void
    {
        $this->createService('business-license', 1500000, 7, [
            'price_verified_at' => now(),
            'duration_verified_at' => now(),
        ]);

        $quote = app(ServiceQuoteBuilder::class)->build(['guild-business-license']);

        $this->assertSame('ready_for_confirmation', $quote['quote_status']);
        $this->assertSame(1500000.0, $quote['service_fee_subtotal']);
        $this->assertSame(1500000.0, $quote['line_items'][0]['price_amount']);
        $this->assertSame(7, $quote['line_items'][0]['estimated_days']);
        $this->assertSame('IRT', $quote['currency']);
        $this->assertNull($quote['official_and_third_party_fees']['amount']);
    }

    public function test_it_marks_services_without_an_orderable_catalogue_row_as_unavailable(): void
    {
        $quote = app(ServiceQuoteBuilder::class)->build(['company-changes']);

        $this->assertSame('requires_review_or_missing_values', $quote['quote_status']);
        $this->assertFalse($quote['line_items'][0]['orderable']);
        $this->assertSame('pending_service_row', $quote['line_items'][0]['catalog_status']);
    }

    public function test_it_rejects_stale_price_verification_even_when_duration_is_current(): void
    {
        $this->createService('business-license', 1500000, 7, [
            'price_verified_at' => now()->subDays(45),
            'duration_verified_at' => now(),
        ]);

        $quote = app(ServiceQuoteBuilder::class)->build(['guild-business-license']);

        $this->assertNull($quote['line_items'][0]['price_amount']);
        $this->assertSame('verification_missing_or_stale', $quote['line_items'][0]['price_status']);
        $this->assertSame(7, $quote['line_items'][0]['estimated_days']);
        $this->assertSame('verified_current', $quote['line_items'][0]['duration_status']);
    }
    public function test_it_does_not_quote_verified_price_when_currency_is_not_configured(): void
    {
        Config::set('assistant_ai.quote_currency', null);
        $this->createService('business-license', 1500000, 7, [
            'price_verified_at' => now(),
            'duration_verified_at' => now(),
        ]);

        $quote = app(ServiceQuoteBuilder::class)->build(['guild-business-license']);

        $this->assertNull($quote['currency']);
        $this->assertSame('not_configured_owner_confirmation_required', $quote['currency_status']);
        $this->assertNull($quote['line_items'][0]['price_amount']);
        $this->assertSame('currency_not_configured', $quote['line_items'][0]['price_status']);
        $this->assertNull($quote['service_fee_subtotal']);
    }


}
