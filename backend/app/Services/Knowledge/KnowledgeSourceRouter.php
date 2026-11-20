<?php

namespace App\Services\Knowledge;

class KnowledgeSourceRouter
{
    /**
     * Resolve the configured retrieval strategy for a Kargozar service.
     *
     * Unknown services deliberately return an explicit unsupported result;
     * they are never silently routed to an unrelated knowledge source.
     */
    public function resolve(string $serviceKey): array
    {
        $service = config("knowledge_sources.services.{$serviceKey}");

        if (! is_array($service) || ! in_array($service['mode'] ?? null, ['local', 'live', 'hybrid'], true)) {
            return [
                'service_key' => $serviceKey,
                'mode' => 'unsupported',
                'status' => 'service_source_not_configured',
                'source' => null,
                'knowledge_file' => null,
                'live_verification_source' => null,
            ];
        }

        $sourceKey = $service['source'] ?? null;
        $source = $sourceKey ? config("knowledge_sources.sources.{$sourceKey}") : null;

        return [
            'service_key' => $serviceKey,
            'mode' => $service['mode'],
            'status' => $this->statusFor($service, $source),
            'source' => $sourceKey,
            'source_name' => is_array($source) ? ($source['name'] ?? null) : null,
            'source_url' => is_array($source) ? ($source['base_url'] ?? null) : null,
            'knowledge_file' => $service['knowledge_file'] ?? null,
            'live_verification_source' => $service['live_verification_source'] ?? null,
        ];
    }

    private function statusFor(array $service, mixed $source): string
    {
        if ($service['mode'] === 'local') {
            return 'local_knowledge_configured';
        }

        if (! is_array($source)) {
            return 'source_definition_missing';
        }

        return $source['status'] ?? 'source_status_unknown';
    }
}
