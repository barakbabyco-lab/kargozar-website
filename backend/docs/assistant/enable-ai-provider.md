# Enable the Kargozar AI assistant in staging

The AI path is disabled by default. Do not enable it in production until a staging provider test and acceptance review pass.

## Required model-provider settings

The provider must expose an OpenAI-compatible Chat Completions endpoint over HTTPS.

Set these values in the backend server's private `.env` file (never in Git, Flutter, or a public config file):

```dotenv
ASSISTANT_AI_ENABLED=true
ASSISTANT_AI_BASE_URL=https://YOUR-PROVIDER/v1
ASSISTANT_AI_API_KEY=YOUR_SERVER_SIDE_SECRET
ASSISTANT_AI_MODEL=YOUR_MODEL_ID
ASSISTANT_AI_TIMEOUT=20
ASSISTANT_AI_TEMPERATURE=0.2
ASSISTANT_AI_MAX_TOKENS=900
```

The backend calls `{ASSISTANT_AI_BASE_URL}/chat/completions`. Confirm that the provider accepts the `model`, `messages`, `temperature`, and `max_tokens` fields used by the adapter.

## Optional full-page web retrieval

Search snippets work without Firecrawl. Full-page Markdown retrieval is optional and needs a separate Firecrawl API key:

```dotenv
ASSISTANT_WEB_PAGE_RETRIEVAL_ENABLED=true
FIRECRAWL_API_URL=https://api.firecrawl.dev/v2
FIRECRAWL_API_KEY=YOUR_FIRECRAWL_SERVER_SIDE_SECRET
ASSISTANT_WEB_PAGE_TIMEOUT=20
ASSISTANT_WEB_PAGE_MAX_PAGES=3
ASSISTANT_WEB_PAGE_MAX_CONTENT_CHARS=6000
ASSISTANT_WEB_PAGE_CACHE_MINUTES=60
```

Firecrawl and the model provider are separate services and use separate credentials. Firecrawl is limited to a small number of HTTPS public pages per query and cached results.

## Search-provider settings

The current backend expects the self-hosted SearXNG endpoint to be reachable from the Laravel host:

```dotenv
SUPPORT_WEB_SEARCH_ENABLED=true
SEARXNG_URL=http://127.0.0.1:8888/search
SEARXNG_API_TOKEN=
```

If SearXNG is not running, the model can still answer general questions from its model knowledge, but it must not claim to have performed live research.

## Apply configuration

After setting the environment variables on the staging server:

1. Run `php artisan config:clear`.
2. Run `php artisan config:cache`.
3. Restart the PHP-FPM/application workers if the hosting environment requires it.
4. Check application logs for provider timeouts or authentication errors.
5. Keep the AI flag disabled in production until the staging checklist below passes.

Never paste a live API key into a chat, issue, pull request, source file, or client-side application.

## Staging acceptance checklist

- Ask a safe general question unrelated to Kargozar; confirm it receives a natural answer.
- Ask a current public-information question; confirm search sources and page-retrieval status are shown correctly.
- Ask about opening a clothing shop; confirm the assistant asks only for missing activity/location facts and uses the licensing portal source route.
- Ask about company registration; confirm it uses the company-registration source route.
- Ask about tax-file creation; confirm it uses the tax portal source route.
- Ask about a missing lease, health card, trade-law certificate, or vocational certificate; confirm the assistant distinguishes catalogue services from customer actions and pending owner confirmation.
- Ask about a personal tax debt or legal dispute; confirm it routes to a human.
- Ask for a human; confirm it requests a callback number.
- Verify no API key, phone number, national ID, bank number, or OTP appears in outbound model/search requests or application logs.

## Current rollout state

- Model adapter: implemented, disabled by default.
- Firecrawl page retrieval: implemented, disabled by default.
- Official source routing: configured for selected services; exact workflows still require validation.
- Guild-license prerequisite map: draft catalogue mapping, not operationally verified.
- Quote builder: not implemented; no price/time estimate may be invented.
- Production: unchanged until explicit merge and deployment.
