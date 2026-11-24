<?php

namespace App\Services\Support;

use App\Models\Service;
use Illuminate\Support\Carbon;

class ServiceQuoteBuilder
{
    /**
     * Build a quote only from active service rows and explicitly verified
     * price/duration values. Missing or stale values never become estimates.
     */
    public function build(array $serviceKeys): array
    {
        $mappingPath = resource_path('knowledge/service_catalog_mapping.json');
        $mappingDocument = is_file($mappingPath)
            ? json_decode((string) file_get_contents($mappingPath), true)
            : [];
        $mapping = collect($mappingDocument['services'] ?? [])->keyBy('service_key');

        $priceValidityDays = max(1, (int) config('assistant_ai.quote_price_validity_days', 30));
        $durationValidityDays = max(1, (int) config('assistant_ai.quote_duration_validity_days', 90));
        $lineItems = [];

        foreach (array_values(array_unique(array_filter($serviceKeys, 'is_string'))) as $serviceKey) {
            $entry = $mapping->get($serviceKey);

            if (! is_array($entry) || empty($entry['catalog_slug'])) {
                $lineItems[] = $this->unavailableLine($serviceKey, $entry['status'] ?? 'missing_mapping');
                continue;
            }

            if (! in_array($entry['status'] ?? null, ['mapped_to_service_row', 'mapped_to_existing_related_service'], true)) {
                $lineItems[] = $this->unavailableLine($serviceKey, $entry['status'] ?? 'not_orderable');
                continue;
            }

            $service = Service::query()
                ->where('slug', $entry['catalog_slug'])
                ->where('is_active', true)
                ->first();

            if (! $service) {
                $lineItems[] = $this->unavailableLine($serviceKey, 'service_row_not_active_or_missing', $entry['catalog_slug']);
                continue;
            }

            $priceVerifiedAt = $service->price_verified_at;
            $durationVerifiedAt = $service->duration_verified_at;
            $priceIsCurrent = $priceVerifiedAt instanceof Carbon
                && $priceVerifiedAt->greaterThanOrEqualTo(now()->subDays($priceValidityDays));
            $durationIsCurrent = $durationVerifiedAt instanceof Carbon
                && $durationVerifiedAt->greaterThanOrEqualTo(now()->subDays($durationValidityDays));

            $priceAmount = $priceIsCurrent && $service->base_price !== null
                ? (float) $service->base_price
                : null;
            $estimatedDays = $durationIsCurrent && $service->estimated_days !== null
                ? (int) $service->estimated_days
                : null;

            $lineItems[] = [
                'service_key' => $serviceKey,
                'catalog_slug' => $service->slug,
                'catalog_title' => $service->title,
                'catalog_match_type' => ($entry['status'] ?? null) === 'mapped_to_existing_related_service' ? 'related_service' : 'direct',
                'orderable' => true,
                'price_amount' => $priceAmount,
                'price_currency' => 'IRR',
                'price_status' => $priceAmount !== null ? 'verified_current' : ($service->base_price === null ? 'not_configured' : 'verification_missing_or_stale'),
                'price_verified_at' => $priceVerifiedAt?->toIso8601String(),
                'estimated_days' => $estimatedDays,
                'duration_status' => $estimatedDays !== null ? 'verified_current' : ($service->estimated_days === null ? 'not_configured' : 'verification_missing_or_stale'),
                'duration_verified_at' => $durationVerifiedAt?->toIso8601String(),
                'official_fee_amount' => null,
                'official_fee_status' => 'not_included_requires_current_official_source',
            ];
        }

        $orderable = array_values(array_filter($lineItems, fn ($item) => ($item['orderable'] ?? false) === true));
        $allPricesVerified = $orderable !== [] && count(array_filter($orderable, fn ($item) => ($item['price_status'] ?? null) === 'verified_current')) === count($orderable);
        $allDurationsVerified = $orderable !== [] && count(array_filter($orderable, fn ($item) => ($item['duration_status'] ?? null) === 'verified_current')) === count($orderable);
        $subtotal = $allPricesVerified
            ? array_sum(array_map(fn ($item) => (float) $item['price_amount'], $orderable))
            : null;

        return [
            'quote_status' => $allPricesVerified && $allDurationsVerified && count($orderable) === count($lineItems)
                ? 'ready_for_confirmation'
                : 'requires_review_or_missing_values',
            'currency' => 'IRR',
            'service_fee_subtotal' => $subtotal,
            'service_fee_subtotal_status' => $allPricesVerified ? 'verified_current_catalog_values' : 'not_complete',
            'estimated_days_status' => $allDurationsVerified ? 'verified_current_catalog_values' : 'not_complete',
            'official_and_third_party_fees' => [
                'amount' => null,
                'status' => 'not_included_requires_current_official_source',
            ],
            'line_items' => $lineItems,
            'checked_at' => now()->toIso8601String(),
            'policy' => 'Only values with current verification timestamps are included. Missing or stale values must be quoted by a human; official/third-party fees are separate.',
        ];
    }

    private function unavailableLine(string $serviceKey, string $status, ?string $catalogSlug = null): array
    {
        return [
            'service_key' => $serviceKey,
            'catalog_slug' => $catalogSlug,
            'orderable' => false,
            'catalog_status' => $status,
            'price_amount' => null,
            'price_status' => 'not_quotable',
            'estimated_days' => null,
            'duration_status' => 'not_quotable',
            'official_fee_amount' => null,
            'official_fee_status' => 'not_included_requires_current_official_source',
        ];
    }
}
