<?php

namespace Tests\Unit;

use App\Services\Knowledge\KnowledgeRetrievalService;
use App\Services\Knowledge\KnowledgeSourceRouter;
use Tests\TestCase;

class KnowledgeSourceRouterTest extends TestCase
{
    public function test_company_registration_uses_local_knowledge_bank(): void
    {
        $route = app(KnowledgeSourceRouter::class)->resolve('company-registration');

        $this->assertSame('local', $route['mode']);
        $this->assertSame('category_02_company_registration.json', $route['knowledge_file']);
        $this->assertSame('local_knowledge_configured', $route['status']);
    }

    public function test_all_ten_service_categories_have_dedicated_knowledge_files(): void
    {
        $registry = json_decode(
            file_get_contents(resource_path('knowledge/service_knowledge_registry.json')),
            true
        );

        $this->assertSame(10, $registry['category_count']);
        $this->assertCount(10, $registry['categories']);
        foreach ($registry['categories'] as $category) {
            $this->assertFileExists(resource_path('knowledge/' . $category['knowledge_file']));
        }
    }

    public function test_police_public_places_approval_is_hybrid_and_uses_category_four_bank(): void
    {
        $route = app(KnowledgeSourceRouter::class)->resolve('police-public-places-approval');

        $this->assertSame('hybrid', $route['mode']);
        $this->assertSame('category_04_complementary_documents_approvals.json', $route['knowledge_file']);
        $this->assertSame('iran_national_license_portal', $route['live_verification_source']);
    }

    public function test_business_license_uses_live_national_portal_without_claiming_it_is_ready(): void
    {
        $result = app(KnowledgeRetrievalService::class)->retrieve('guild-business-license');

        $this->assertSame('live_source_not_ready', $result['status']);
        $this->assertFalse($result['live_lookup']['ready']);
        $this->assertSame('iran_national_license_portal', $result['live_lookup']['source']);
    }

    public function test_trademark_uses_hybrid_mode_and_does_not_expose_unreviewed_draft_as_knowledge(): void
    {
        $result = app(KnowledgeRetrievalService::class)->retrieve('trademark-registration');

        $this->assertSame('hybrid_sources_not_fully_ready', $result['status']);
        $this->assertNull($result['knowledge']);
        $this->assertSame('document_not_approved', $result['knowledge_review']);
        $this->assertFalse($result['live_lookup']['ready']);
    }

    public function test_unknown_service_is_not_routed_to_another_services_source(): void
    {
        $result = app(KnowledgeRetrievalService::class)->retrieve('unknown-service');

        $this->assertSame('unsupported_service', $result['status']);
        $this->assertNull($result['knowledge']);
        $this->assertNull($result['live_lookup']);
    }
}
