<?php

namespace App\Services\Support;

/**
 * Adds the provider-independent guided-flow layer ahead of the legacy
 * assistant. Existing reviewed answers remain available when no flow matches.
 */
class GuidedSupportAssistant extends SupportAssistant
{
    public function reply(string $message, ?int $conversationId = null): string
    {
        $guidedReply = app(GuidedServiceFlowEngine::class)->handle($message, $conversationId);
        if ($guidedReply !== null) {
            app(UnansweredQuestionTracker::class)->record($message, 'guided_service_flow', $conversationId);

            return $guidedReply;
        }

        return parent::reply($message, $conversationId);
    }
}
