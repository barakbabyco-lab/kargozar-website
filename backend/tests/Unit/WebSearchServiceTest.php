<?php

namespace Tests\Unit;

use App\Services\Support\WebSearchService;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class WebSearchServiceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config([
            'support_assistant.web_search.endpoint' => 'http://127.0.0.1:8888/search',
            'support_assistant.web_search.timeout' => 8,
            'support_assistant.web_search.max_results' => 5,
            'support_assistant.web_search.official_context_terms' => ['قانون'],
            'support_assistant.web_search.official_domains' => ['gov.ir', 'mojavez.ir'],
        ]);

        Cache::flush();
    }

    public function test_it_searches_searxng_and_returns_only_https_sources(): void
    {
        Http::fake([
            '127.0.0.1:8888/search*' => Http::response([
                'results' => [
                    [
                        'title' => 'منبع رسمی',
                        'url' => 'https://example.gov.ir/guide',
                        'content' => 'خلاصه نتیجه جست‌وجو',
                    ],
                    [
                        'title' => 'نشانی ناامن',
                        'url' => 'http://example.com/page',
                        'content' => 'این نتیجه نباید نمایش داده شود',
                    ],
                ],
            ], 200),
        ]);

        $result = app(WebSearchService::class)->search('راهنمای ثبت درخواست');

        $this->assertSame('', $result['answer']);
        $this->assertCount(1, $result['sources']);
        $this->assertSame('https://example.gov.ir/guide', $result['sources'][0]['url']);
        $this->assertSame('خلاصه نتیجه جست‌وجو', $result['sources'][0]['snippet']);

        Http::assertSent(function (Request $request): bool {
            $query = [];
            parse_str((string) parse_url($request->url(), PHP_URL_QUERY), $query);

            return $request->method() === 'GET'
                && ($query['format'] ?? null) === 'json'
                && ($query['language'] ?? null) === 'fa-IR'
                && ($query['safesearch'] ?? null) === '1'
                && ($query['q'] ?? null) === 'راهنمای ثبت درخواست';
        });
    }

    public function test_it_removes_email_and_mobile_number_before_searching(): void
    {
        Http::fake([
            '127.0.0.1:8888/search*' => Http::response([
                'results' => [[
                    'title' => 'نتیجه',
                    'url' => 'https://example.com/result',
                    'content' => 'محتوای عمومی',
                ]],
            ], 200),
        ]);

        app(WebSearchService::class)->search('قانون ثبت کسب‌وکار، تماس ۰۹۱۲۳۴۵۶۷۸۹ و user@example.com');

        Http::assertSent(function (Request $request): bool {
            $query = [];
            parse_str((string) parse_url($request->url(), PHP_URL_QUERY), $query);
            $searched = (string) ($query['q'] ?? '');

            return ! str_contains($searched, '09123456789')
                && ! str_contains($searched, 'user@example.com')
                && str_contains($searched, 'قانون ثبت کسب‌وکار، تماس');
        });
    }

    public function test_official_context_adds_configured_site_restrictions(): void
    {
        Http::fake([
            '127.0.0.1:8888/search*' => Http::response([
                'results' => [[
                    'title' => 'قانون',
                    'url' => 'https://gov.ir/law',
                    'content' => 'اطلاعات رسمی',
                ]],
            ], 200),
        ]);

        app(WebSearchService::class)->search('قانون مجوز کسب');

        Http::assertSent(function (Request $request): bool {
            $query = [];
            parse_str((string) parse_url($request->url(), PHP_URL_QUERY), $query);
            $searched = (string) ($query['q'] ?? '');

            return str_contains($searched, 'site:gov.ir')
                && str_contains($searched, 'site:mojavez.ir');
        });
    }

    public function test_remote_https_endpoint_requires_a_bearer_token(): void
    {
        config(['support_assistant.web_search.endpoint' => 'https://search.example.com/search']);
        config(['support_assistant.web_search.token' => '']);
        Http::fake();

        $this->assertNull(app(WebSearchService::class)->search('پرسش عمومی'));
        Http::assertNothingSent();
    }

    public function test_remote_https_endpoint_sends_the_configured_bearer_token(): void
    {
        config(['support_assistant.web_search.endpoint' => 'https://search.example.com/search']);
        config(['support_assistant.web_search.token' => 'test-secret-token']);
        Http::fake([
            'search.example.com/search*' => Http::response([
                'results' => [[
                    'title' => 'نتیجه',
                    'url' => 'https://example.com/result',
                    'content' => 'محتوا',
                ]],
            ], 200),
        ]);

        $result = app(WebSearchService::class)->search('پرسش عمومی');

        $this->assertCount(1, $result['sources']);
        Http::assertSent(function (Request $request): bool {
            $query = [];
            parse_str((string) parse_url($request->url(), PHP_URL_QUERY), $query);

            return $request->method() === 'GET'
                && parse_url($request->url(), PHP_URL_HOST) === 'search.example.com'
                && ($query['format'] ?? null) === 'json'
                && $request->hasHeader('Authorization', 'Bearer test-secret-token');
        });
    }

    public function test_it_rejects_non_https_remote_endpoints(): void
    {
        config(['support_assistant.web_search.endpoint' => 'http://search.example.com/search']);
        Http::fake();

        $this->assertNull(app(WebSearchService::class)->search('پرسش عمومی'));
        Http::assertNothingSent();
    }

    public function test_it_caches_repeated_searches_for_the_same_query(): void
    {
        Http::fake([
            '127.0.0.1:8888/search*' => Http::response([
                'results' => [[
                    'title' => 'نتیجه',
                    'url' => 'https://example.com/result',
                    'content' => 'محتوا',
                ]],
            ], 200),
        ]);

        $service = app(WebSearchService::class);
        $service->search('پرسش تکراری');
        $service->search('پرسش تکراری');

        Http::assertSentCount(1);
    }
    public function test_service_key_routes_search_to_its_registered_official_portal(): void
    {
        config([
            'knowledge_sources.services.guild-business-license' => [
                'mode' => 'live',
                'source' => 'iran_national_license_portal',
            ],
            'knowledge_sources.sources.iran_national_license_portal' => [
                'base_url' => 'https://mojavez.ir/',
                'search_url' => null,
            ],
            'support_assistant.web_search.official_context_terms' => [],
        ]);

        Http::fake([
            '127.0.0.1:8888/search*' => Http::response([
                'results' => [[
                    'title' => 'درگاه ملی مجوزها',
                    'url' => 'https://mojavez.ir/',
                    'content' => 'نتیجه رسمی',
                ]],
            ], 200),
        ]);

        app(WebSearchService::class)->search('فروشگاه پوشاک', ['guild-business-license']);

        Http::assertSent(function (Request $request): bool {
            $query = [];
            parse_str((string) parse_url($request->url(), PHP_URL_QUERY), $query);

            return str_contains((string) ($query['q'] ?? ''), 'site:mojavez.ir')
                && ! str_contains((string) ($query['q'] ?? ''), 'site:gov.ir');
        });
    }


}
