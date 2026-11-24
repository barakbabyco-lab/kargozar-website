<?php

return [
    // Optional full-page retrieval layer. Search snippets remain available without it.
    'enabled' => (bool) env('ASSISTANT_WEB_PAGE_RETRIEVAL_ENABLED', false),
    'endpoint' => env('FIRECRAWL_API_URL', 'https://api.firecrawl.dev/v2'),
    'api_key' => env('FIRECRAWL_API_KEY', ''),
    'timeout' => (int) env('ASSISTANT_WEB_PAGE_TIMEOUT', 20),
    'max_pages' => (int) env('ASSISTANT_WEB_PAGE_MAX_PAGES', 3),
    'max_content_chars' => (int) env('ASSISTANT_WEB_PAGE_MAX_CONTENT_CHARS', 6000),
    'cache_minutes' => (int) env('ASSISTANT_WEB_PAGE_CACHE_MINUTES', 60),
];
