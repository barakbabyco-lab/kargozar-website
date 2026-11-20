<?php

namespace App\Services\Knowledge;

use Illuminate\Support\Facades\File;
use RuntimeException;

class KnowledgeDocumentRepository
{
    /**
     * Read a knowledge document only from the configured local knowledge
     * directory. The filename comes from trusted application configuration,
     * never directly from customer input.
     */
    public function find(string $filename): ?array
    {
        if ($filename === '' || basename($filename) !== $filename || ! str_ends_with($filename, '.json')) {
            throw new RuntimeException('Invalid knowledge document filename.');
        }

        $path = rtrim(config('knowledge_sources.retrieval.local_documents_path'), DIRECTORY_SEPARATOR)
            . DIRECTORY_SEPARATOR . $filename;

        if (! File::exists($path)) {
            return null;
        }

        $document = json_decode(File::get($path), true);

        if (! is_array($document)) {
            throw new RuntimeException("Knowledge document [{$filename}] contains invalid JSON.");
        }

        if (config('knowledge_sources.retrieval.require_approved_document', true)
            && ($document['status'] ?? null) !== 'approved') {
            return [
                'document' => $document,
                'usable' => false,
                'reason' => 'document_not_approved',
            ];
        }

        if (config('knowledge_sources.retrieval.require_review_date', true)
            && empty($document['reviewed_at'])) {
            return [
                'document' => $document,
                'usable' => false,
                'reason' => 'review_date_missing',
            ];
        }

        return [
            'document' => $document,
            'usable' => true,
            'reason' => null,
        ];
    }
}
