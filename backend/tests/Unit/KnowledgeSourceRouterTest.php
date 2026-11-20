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
        $this->assertSame('company_registration_knowledge.json', $route['knowledge_file']);
        $this->assertSame('local_knowledge_configured', $route['status']);
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
