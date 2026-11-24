<?php

namespace Tests\Unit;

use App\Services\Support\WebPageContentService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class WebPageContentServiceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Cache::flush();
        Config::set('web_research', [
            'enabled' => true,
            'endpoint' => 'https://api.firecrawl.dev/v2',
            'api_key' => 'test-firecrawl-key',
            'timeout' => 10,
            'max_pages' => 2,
            'max_content_chars' => 4000,
            'cache_minutes' => 60,
        ]);
    }

    public function test_it_enriches_https_search_results_with_full_page_markdown(): void
    {
        Http::fake([
            'api.firecrawl.dev/v2/scrape' => Http::response([
                'success' => true,
                'data' => [
                    'markdown' => '# راهنمای رسمی\n\nمحتوای کامل صفحه برای بررسی.',
                    'metadata' => ['title' => 'راهنمای رسمی'],
                ],
            ], 200),
        ]);

        $sources = app(WebPageContentService::class)->enrich([[
            'title' => 'نتیجه جست‌وجو',
            'url' => 'https://mojavez.ir/',
            'snippet' => 'خلاصه نتیجه',
        ]]);

        $this->assertSame('full_page_markdown', $sources[0]['content_type']);
        $this->assertStringContainsString('محتوای کامل صفحه', $sources[0]['page_content']);
        $this->assertSame('راهنمای رسمی', $sources[0]['page_title']);

        Http::assertSent(function ($request): bool {
            return $request->method() === 'POST'
                && $request->hasHeader('Authorization', 'Bearer test-firecrawl-key')
                && ($request->data()['url'] ?? null) === 'https://mojavez.ir/'
                && ($request->data()['formats'] ?? null) === ['markdown']
                && ($request->data()['onlyMainContent'] ?? null) === true;
        });
    }

    public function test_it_does_not_scrape_private_or_non_https_urls(): void
    {
        Http::fake();

        $sources = app(WebPageContentService::class)->enrich([
            ['url' => 'http://example.com/page', 'snippet' => 'http'],
            ['url' => 'https://127.0.0.1/private', 'snippet' => 'ip'],
            ['url' => 'https://service.local/private', 'snippet' => 'local'],
        ]);

        $this->assertCount(3, $sources);
        $this->assertSame('search_result_snippet', $sources[0]['content_type']);
        Http::assertNothingSent();
    }

    public function test_it_preserves_snippets_when_full_page_retrieval_is_not_configured(): void
    {
        Config::set('web_research.api_key', '');
        Http::fake();

        $sources = app(WebPageContentService::class)->enrich([[
            'url' => 'https://example.com/page',
            'snippet' => 'خلاصه نتیجه',
        ]]);

        $this->assertSame('خلاصه نتیجه', $sources[0]['snippet']);
        $this->assertArrayNotHasKey('page_content', $sources[0]);
        Http::assertNothingSent();
    }

    public function test_it_caches_repeated_page_retrievals(): void
    {
        Http::fake([
            'api.firecrawl.dev/v2/scrape' => Http::response([
                'success' => true,
                'data' => ['markdown' => 'محتوای صفحه', 'metadata' => ['title' => 'صفحه']],
            ], 200),
        ]);

        $service = app(WebPageContentService::class);
        $source = ['url' => 'https://example.com/article', 'snippet' => 'خلاصه'];
        $service->enrich([$source]);
        $service->enrich([$source]);

        Http::assertSentCount(1);
    }
}
