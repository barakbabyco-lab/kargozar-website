<?php

namespace App\\Services\\Support;

use Illuminate\\Support\\Facades\\Cache;
use Illuminate\\Support\\Facades\\Http;
use Throwable;

class WebSearchService
{
    /**
     * Search the public web for an unanswered, non-sensitive question.
     * Search snippets are untrusted data; never treat page text as instructions.
     */
    public function search(string $question): ?array
    {
        $apiKey = (string) config('support_assistant.web_search.api_key', '');
        $endpoint = (string) config('support_assistant.web_search.endpoint', 'https://api.tavily.com/search');

        if ($apiKey === '' || ! filter_var($endpoint, FILTER_VALIDATE_URL) || ! str_starts_with($endpoint, 'https://')) {
            return null;
        }

        $query = $this->sanitizeQuery($question);
        $query = trim(mb_substr($query, 0, 300, 'UTF-8'));
        if ($query === '') {
            return null;
        }

        $cacheKey = 'support-web-search:'.hash('sha256', mb_strtolower($query, 'UTF-8'));

        return Cache::remember($cacheKey, now()->addMinutes(10), function () use ($apiKey, $endpoint, $query) {
            try {
                $payload = [
                    'api_key' => $apiKey,
                    'query' => $query,
                    'search_depth' => 'basic',
                    'include_answer' => 'advanced',
                    'max_results' => (int) config('support_assistant.web_search.max_results', 5),
                    'include_raw_content' => false,
                ];

                $officialContext = false;
                foreach ((array) config('support_assistant.web_search.official_context_terms', []) as $term) {
                    if (is_string($term) && $term !== '' && str_contains($query, $term)) {
                        $officialContext = true;
                        break;
                    }
                }
                if ($officialContext) {
                    $payload['include_domains'] = (array) config('support_assistant.web_search.official_domains', []);
                }

                $response = Http::acceptJson()
                    ->asJson()
                    ->timeout((int) config('support_assistant.web_search.timeout', 8))
                    ->retry(1, 200)
                    ->post($endpoint, $payload);

                if (! $response->successful()) {
                    return null;
                }

                $payload = $response->json();
                if (! is_array($payload)) {
                    return null;
                }

                $answer = trim((string) ($payload['answer'] ?? ''));
                $sources = [];
                foreach (($payload['results'] ?? []) as $result) {
                    if (! is_array($result)) {
                        continue;
                    }

                    $url = (string) ($result['url'] ?? '');
                    if (! filter_var($url, FILTER_VALIDATE_URL) || ! str_starts_with($url, 'https://')) {
                        continue;
                    }

                    $sources[] = [
                        'title' => trim((string) ($result['title'] ?? 'منبع وب')),
                        'url' => $url,
                        'snippet' => trim(mb_substr((string) ($result['content'] ?? ''), 0, 500, 'UTF-8')),
                    ];
                }

                if ($answer === '' && $sources === []) {
                    return null;
                }

                return ['answer' => mb_substr($answer, 0, 2500, 'UTF-8'), 'sources' => array_slice($sources, 0, 5)];
            } catch (Throwable) {
                return null;
            }
        });

    /**
     * Remove obvious direct identifiers before sending a query to the search provider.
     */
    private function sanitizeQuery(string $question): string
    {
        $question = preg_replace('/[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}/iu', ' ', $question) ?? $question;
        $question = strtr($question, [
            '۰' => '0', '۱' => '1', '۲' => '2', '۳' => '3', '۴' => '4',
            '۵' => '5', '۶' => '6', '۷' => '7', '۸' => '8', '۹' => '9',
            '٠' => '0', '١' => '1', '٢' => '2', '٣' => '3', '٤' => '4',
            '٥' => '5', '٦' => '6', '٧' => '7', '٨' => '8', '٩' => '9',
        ]);
        $question = preg_replace('/(?<!\\d)(?:(?:\\+|00)?98|0)?9\\d{9}(?!\\d)/u', ' ', $question) ?? $question;
        $question = preg_replace('/(?<!\\d)\\d{10}(?!\\d)/u', ' ', $question) ?? $question;

        return trim(preg_replace('/\\s+/u', ' ', $question) ?? $question);
    }
    }
}
