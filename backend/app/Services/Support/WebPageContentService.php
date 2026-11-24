<?php

namespace App\Services\Support;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Throwable;

class WebPageContentService
{
    /**
     * Enrich search results with full-page Markdown when Firecrawl is configured.
     * If retrieval is disabled or fails, preserve the original snippets unchanged.
     */
    public function enrich(array $sources): array
    {
        $config = config('web_research', []);
        $apiKey = trim((string) ($config['api_key'] ?? ''));
        $endpoint = rtrim(trim((string) ($config['endpoint'] ?? 'https://api.firecrawl.dev/v2')), '/');

        if (($config['enabled'] ?? false) !== true || $apiKey === '' || $endpoint !== 'https://api.firecrawl.dev/v2') {
            return $sources;
        }

        $maxPages = max(0, min(5, (int) ($config['max_pages'] ?? 3)));
        $enriched = [];

        foreach ($sources as $source) {
            if (! is_array($source)) {
                continue;
            }

            $source['content_type'] = $source['content_type'] ?? 'search_result_snippet';
            if (count($enriched) >= $maxPages) {
                $enriched[] = $source;
                continue;
            }

            $url = trim((string) ($source['url'] ?? ''));
            if (! $this->isSafePublicUrl($url)) {
                $enriched[] = $source;
                continue;
            }

            $page = $this->scrape($url, $apiKey, $config);
            if (is_array($page) && ($page['markdown'] ?? '') !== '') {
                $source['page_content'] = $page['markdown'];
                $source['content_type'] = 'full_page_markdown';
                $source['page_title'] = $page['title'] ?? ($source['title'] ?? null);
                $source['retrieved_at'] = now()->toIso8601String();
            } else {
                $source['content_type'] = 'search_result_snippet';
            }

            $enriched[] = $source;
        }

        return $enriched;
    }

    private function scrape(string $url, string $apiKey, array $config): ?array
    {
        $cacheKey = 'assistant-page:'.hash('sha256', $url);

        return Cache::remember($cacheKey, now()->addMinutes(max(1, (int) ($config['cache_minutes'] ?? 60))), function () use ($url, $apiKey, $config) {
            try {
                $response = Http::acceptJson()
                    ->withToken($apiKey)
                    ->timeout((int) ($config['timeout'] ?? 20))
                    ->retry(1, 250)
                    ->post('https://api.firecrawl.dev/v2/scrape', [
                        'url' => $url,
                        'formats' => ['markdown'],
                        'onlyMainContent' => true,
                        'maxAge' => 3600000,
                        'timeout' => max(5000, (int) ($config['timeout'] ?? 20) * 1000),
                    ]);

                if (! $response->successful() || $response->json('success') !== true) {
                    return null;
                }

                $markdown = trim((string) $response->json('data.markdown', ''));
                if ($markdown === '') {
                    return null;
                }

                return [
                    'markdown' => mb_substr(
                        $markdown,
                        0,
                        max(1000, (int) ($config['max_content_chars'] ?? 6000)),
                        'UTF-8'
                    ),
                    'title' => trim((string) $response->json('data.metadata.title', '')),
                ];
            } catch (Throwable) {
                return null;
            }
        });
    }

    private function isSafePublicUrl(string $url): bool
    {
        if (! filter_var($url, FILTER_VALIDATE_URL)) {
            return false;
        }

        $parts = parse_url($url);
        if (! is_array($parts)
            || strtolower((string) ($parts['scheme'] ?? '')) !== 'https'
            || empty($parts['host'])
            || isset($parts['user'])
            || isset($parts['pass'])
            || isset($parts['fragment'])
            || isset($parts['port'])) {
            return false;
        }

        $host = strtolower((string) $parts['host']);
        if ($host === 'localhost'
            || str_ends_with($host, '.localhost')
            || str_ends_with($host, '.local')
            || str_ends_with($host, '.internal')
            || str_ends_with($host, '.test')
            || filter_var($host, FILTER_VALIDATE_IP) !== false) {
            return false;
        }

        return preg_match('/^[a-z0-9.-]+$/', $host) === 1;
    }
}
