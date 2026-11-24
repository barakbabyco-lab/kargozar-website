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

Substantive, non-sensitive customer questions are sent to public web search by default, including general questions outside the Kargozar catalogue. Short acknowledgements such as «سلام»، «بله» and «ممنون» do not trigger a search. Personal identifiers are scrubbed before a query is sent.

If Laravel runs on the same VPS as SearXNG, use the loopback endpoint:

```dotenv
SUPPORT_WEB_SEARCH_ENABLED=true
SEARXNG_URL=http://127.0.0.1:8888/search
SEARXNG_API_TOKEN=
```

If Laravel runs on cPanel while SearXNG remains on the VPS, do **not** use the loopback address. Configure the HTTPS reverse-proxy bridge described in `docs/searxng-production-bridge.md`, then set:

```dotenv
SUPPORT_WEB_SEARCH_ENABLED=true
SEARXNG_URL=https://search.YOUR-OWNED-DOMAIN/search
SEARXNG_API_TOKEN=YOUR_SERVER_SIDE_BEARER_SECRET
```

Never expose port 8888 publicly. A remote search endpoint is rejected unless it uses HTTPS and a non-empty bearer token. If search is unavailable, the assistant must not claim that it performed live research.

## Verify service catalogue prices and durations

Before any numeric price is shown, set `ASSISTANT_QUOTE_CURRENCY=IRT` (toman) or `IRR` (rial) only after the owner confirms the unit used in the service catalogue. If it remains unset, no numeric price is quoted.

The assistant does not quote a number merely because `base_price` or `estimated_days` is populated. An authorized admin/supervisor must verify those values through the staff catalogue API:

- `PATCH /api/v1/staff/catalog/services/{serviceId}`
- send `base_price` together with `price_verified_at` when the current Kargozar fee has been checked;
- send `estimated_days` together with `duration_verified_at` when the current handling estimate has been checked.

Price verification is considered current for 30 days; duration verification is considered current for 90 days by default. Changing either value clears its previous verification timestamp unless a new timestamp is explicitly supplied. Never mark a value verified without checking it.

The assistant keeps government and third-party fees separate. They require current official-source evidence and are not included in the Kargozar service-fee subtotal automatically.

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
- Quote builder: implemented; it uses only active catalogue rows with current staff verification timestamps. Prices remain hidden until the currency unit is explicitly configured. Official and third-party charges remain separate.
- Production: unchanged until explicit merge and deployment.
