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
        $liveSourceKey = $service['live_verification_source'] ?? null;
        $liveSource = $liveSourceKey ? config("knowledge_sources.sources.{$liveSourceKey}") : null;
        $preferredSource = $service['mode'] === 'hybrid' && is_array($liveSource) ? $liveSource : $source;

        return [
            'service_key' => $serviceKey,
            'mode' => $service['mode'],
            'status' => $this->statusFor($service, $source, $liveSource),
            'source' => $sourceKey,
            'source_name' => is_array($source) ? ($source['name'] ?? null) : null,
            'source_url' => is_array($preferredSource) ? ($preferredSource['base_url'] ?? null) : null,
            'knowledge_file' => $service['knowledge_file'] ?? null,
            'live_verification_source' => $liveSourceKey,
            'live_source_name' => is_array($liveSource) ? ($liveSource['name'] ?? null) : null,
            'live_source_url' => is_array($liveSource) ? ($liveSource['base_url'] ?? null) : null,
        ];
    }

    private function statusFor(array $service, mixed $source, mixed $liveSource = null): string
    {
        if ($service['mode'] === 'local') {
            return 'local_knowledge_configured';
        }

        if ($service['mode'] === 'hybrid' && is_array($liveSource)) {
            return $liveSource['status'] ?? 'live_source_status_unknown';
        }

        if (! is_array($source)) {
            return 'source_definition_missing';
        }

        return $source['status'] ?? 'source_status_unknown';
    }
}
