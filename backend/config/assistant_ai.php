<?php

return [
    // Disabled until a provider endpoint, model and server-side key are configured.
    'enabled' => (bool) env('ASSISTANT_AI_ENABLED', false),
    // OpenAI-compatible Chat Completions base URL, e.g. https://api.provider.example/v1
    'base_url' => env('ASSISTANT_AI_BASE_URL', ''),
    'api_key' => env('ASSISTANT_AI_API_KEY', ''),
    'model' => env('ASSISTANT_AI_MODEL', ''),
    'timeout' => (int) env('ASSISTANT_AI_TIMEOUT', 20),
    'temperature' => (float) env('ASSISTANT_AI_TEMPERATURE', 0.2),
    'max_tokens' => (int) env('ASSISTANT_AI_MAX_TOKENS', 900),
];
