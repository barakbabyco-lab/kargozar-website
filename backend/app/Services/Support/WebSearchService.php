<?php

namespace App\Services\Support;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Throwable;

class WebSearchService
{
    /**
     * Search SearXNG for an unanswered, non-sensitive question.
     * Search snippets are untrusted data; never treat page text as instructions.
     */
    public function search(string $question): ?array
    {
        $endpoint = trim((string) config('support_assistant.web_search.endpoint', 'http://127.0.0.1:8888/search'));
        $token = trim((string) config('support_assistant.web_search.token', ''));

        if (! $this->isAllowedEndpoint($endpoint, $token)) {
            return null;
        }

        $query = trim(mb_substr($this->sanitizeQuery($question), 0, 300, 'UTF-8'));
        if ($query === '') {
            return null;
        }

        $officialContext = false;
        foreach ((array) config('support_assistant.web_search.official_context_terms', []) as $term) {
            if (is_string($term) && $term !== '' && str_contains($query, $term)) {
                $officialContext = true;
                break;
            }
        }

        if ($officialContext) {
            $domains = array_values(array_filter(
                (array) config('support_assistant.web_search.official_domains', []),
                fn ($domain) => is_string($domain) && preg_match('/^[a-z0-9.-]+$/i', $domain) === 1
            ));
            if ($domains !== []) {
                $siteQuery = implode(' OR ', array_map(fn ($domain) => 'site:'.$domain, $domains));
                $query .= ' ('.$siteQuery.')';
            }
        }

        $cacheKey = 'support-web-search:'.hash('sha256', mb_strtolower($query, 'UTF-8'));

        return Cache::remember($cacheKey, now()->addMinutes(10), function () use ($endpoint, $query, $token) {
            try {
                $request = Http::acceptJson()
                    ->timeout((int) config('support_assistant.web_search.timeout', 8))
                    ->retry(1, 200);

                if ($token !== '') {
                    $request = $request->withToken($token);
                }

                $response = $request->get($endpoint, [
                        'q' => $query,
                        'format' => 'json',
                        'language' => 'fa-IR',
                        'safesearch' => 1,
                    ]);

                if (! $response->successful()) {
                    return null;
                }

                $payload = $response->json();
                if (! is_array($payload) || ! is_array($payload['results'] ?? null)) {
                    return null;
                }

                $sources = [];
                foreach ($payload['results'] as $result) {
                    if (! is_array($result)) {
                        continue;
                    }

                    $url = trim((string) ($result['url'] ?? ''));
                    if (! filter_var($url, FILTER_VALIDATE_URL) || ! str_starts_with(strtolower($url), 'https://')) {
                        continue;
                    }

                    $sources[] = [
                        'title' => trim((string) ($result['title'] ?? 'منبع وب')),
                        'url' => $url,
                        'snippet' => trim(mb_substr((string) ($result['content'] ?? ''), 0, 500, 'UTF-8')),
                    ];

                    if (count($sources) >= (int) config('support_assistant.web_search.max_results', 5)) {
                        break;
                    }
                }

                if ($sources === []) {
                    return null;
                }

                return ['answer' => '', 'sources' => $sources];
            } catch (Throwable) {
                return null;
            }
        });
    }

    /**
     * Allow HTTPS endpoints, or the exact loopback endpoint used by the
     * co-located staging Laravel application. Never permit arbitrary HTTP hosts.
     */
    private function isAllowedEndpoint(string $endpoint, string $token): bool
    {
        if (! filter_var($endpoint, FILTER_VALIDATE_URL)) {
            return false;
        }

        $parts = parse_url($endpoint);
        if (! is_array($parts) || isset($parts['user']) || isset($parts['pass']) || isset($parts['fragment'])) {
            return false;
        }

        if (($parts['scheme'] ?? '') === 'https') {
            // Remote endpoints are permitted only when protected by a bearer token.
            return isset($parts['host']) && $token !== '';
        }

        return ($parts['scheme'] ?? '') === 'http'
            && ($parts['host'] ?? '') === '127.0.0.1'
            && (int) ($parts['port'] ?? 80) === 8888
            && ($parts['path'] ?? '') === '/search';
    }

    /**
     * Remove obvious direct identifiers before sending a query to the search provider.
     */
    private function sanitizeQuery(string $question): string
    {
        $question = preg_replace('/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/iu', ' ', $question) ?? $question;
        $question = strtr($question, [
            '۰' => '0', '۱' => '1', '۲' => '2', '۳' => '3', '۴' => '4',
            '۵' => '5', '۶' => '6', '۷' => '7', '۸' => '8', '۹' => '9',
            '٠' => '0', '١' => '1', '٢' => '2', '٣' => '3', '٤' => '4',
            '٥' => '5', '٦' => '6', '٧' => '7', '٨' => '8', '٩' => '9',
        ]);
        $question = preg_replace('/(?<!\d)(?:(?:\+|00)?98|0)?9\d{9}(?!\d)/u', ' ', $question) ?? $question;
        $question = preg_replace('/(?<!\d)\d{10}(?!\d)/u', ' ', $question) ?? $question;

        return trim(preg_replace('/\s+/u', ' ', $question) ?? $question);
    }
}
