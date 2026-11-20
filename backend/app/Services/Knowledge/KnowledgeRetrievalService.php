<?php

namespace App\Services\Knowledge;

class KnowledgeRetrievalService
{
    public function __construct(
        private readonly KnowledgeSourceRouter $router,
        private readonly KnowledgeDocumentRepository $documents,
    ) {
    }

    /**
     * Return source instructions and approved local knowledge, if available.
     * Live retrieval is intentionally reported as pending until a verified
     * source adapter is registered for that official portal.
     */
    public function retrieve(string $serviceKey): array
    {
        $route = $this->router->resolve($serviceKey);

        if ($route['mode'] === 'unsupported') {
            return [
                'status' => 'unsupported_service',
                'route' => $route,
                'knowledge' => null,
                'live_lookup' => null,
            ];
        }

        $knowledge = null;
        if (! empty($route['knowledge_file'])) {
            $knowledge = $this->documents->find($route['knowledge_file']);
        }

        $localUsable = is_array($knowledge) && ($knowledge['usable'] ?? false) === true;
        $needsLive = in_array($route['mode'], ['live', 'hybrid'], true);
        $liveReady = $this->isLiveSourceReady($route);

        if ($route['mode'] === 'local') {
            $status = $localUsable ? 'local_knowledge_available' : 'local_knowledge_requires_review';
        } elseif ($route['mode'] === 'hybrid') {
            $status = $localUsable && $liveReady
                ? 'local_and_live_sources_ready'
                : 'hybrid_sources_not_fully_ready';
        } else {
            $status = $liveReady ? 'live_source_ready' : 'live_source_not_ready';
        }

        return [
            'status' => $status,
            'route' => $route,
            'knowledge' => $localUsable ? $knowledge['document'] : null,
            'knowledge_review' => $localUsable ? null : ($knowledge['reason'] ?? 'knowledge_document_missing'),
            'live_lookup' => $needsLive ? [
                'source' => $route['source'],
                'ready' => $liveReady,
                'status' => $liveReady ? 'adapter_configured' : 'adapter_pending_verification',
            ] : null,
        ];
    }

    private function isLiveSourceReady(array $route): bool
    {
        $sourceKey = $route['mode'] === 'hybrid'
            ? ($route['live_verification_source'] ?? null)
            : ($route['source'] ?? null);

        if (! $sourceKey) {
            return false;
        }

        $source = config("knowledge_sources.sources.{$sourceKey}");

        return is_array($source)
            && ($source['status'] ?? null) === 'operational'
            && ! empty($source['search_url']);
    }
}
