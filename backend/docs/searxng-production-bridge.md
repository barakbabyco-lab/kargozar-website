# SearXNG HTTPS bridge for a remote Laravel host

Use this bridge only when the Laravel API and SearXNG run on different machines (for example, Laravel on cPanel and SearXNG on the KarGozar VPS). If both services run on the same VPS, prefer the loopback endpoint and do not create a public search hostname.

## Security requirements

- Keep SearXNG bound to loopback or a private interface. Do not expose TCP port 8888 to the public internet.
- Publish the bridge only over HTTPS with a valid certificate.
- Require a long, random bearer token on every request. Store the same token in the Laravel server's private `.env` as `SEARXNG_API_TOKEN`.
- Do not put the token in a URL, query string, Git repository, mobile app, or browser code.
- Restrict the bridge to the exact `/search` path, apply request rate limits, and keep request logs free of authorization headers.
- Rotate the token if it is disclosed. The bridge is an internal integration endpoint, not a public search API.

## VPS reverse-proxy example (nginx)

Create a dedicated HTTPS virtual host such as `search.example-owned-domain.ir`. The example below assumes SearXNG listens on `127.0.0.1:8888`. Replace the hostname, certificate paths, and token placeholder before enabling it. Keep the token in a root-readable configuration file with restrictive permissions.

Add the `map` directive in nginx's `http` context (not inside the server block):

```nginx
map $http_authorization $kargozar_search_authorized {
    default 0;
    "Bearer REPLACE_WITH_A_LONG_RANDOM_SECRET" 1;
}
```

Then configure the dedicated virtual host:

```nginx
server {
    listen 443 ssl;
    server_name search.example-owned-domain.ir;

    ssl_certificate     /etc/letsencrypt/live/search.example-owned-domain.ir/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/search.example-owned-domain.ir/privkey.pem;

    location = /search {
        if ($kargozar_search_authorized = 0) { return 401; }

        limit_except GET { deny all; }

        proxy_pass http://127.0.0.1:8888/search;
        proxy_http_version 1.1;
        proxy_set_header Host 127.0.0.1;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Authorization "";
        proxy_connect_timeout 5s;
        proxy_read_timeout 15s;
    }

    location / {
        return 404;
    }
}
```

Do not add a public port-80 proxy to SearXNG. If HTTP is enabled for certificate renewal or redirect, redirect to HTTPS only; never forward an unauthenticated request to port 8888.

Validate nginx configuration before reload:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

Firewall rules must continue to deny public inbound access to TCP 8888. Confirm that SearXNG is reachable locally from the VPS and that the public hostname is reachable only on HTTPS.

## Laravel configuration on cPanel

Set these values in the Laravel backend's private `.env` file:

```dotenv
SUPPORT_WEB_SEARCH_ENABLED=true
SEARXNG_URL=https://search.example-owned-domain.ir/search
SEARXNG_API_TOKEN=THE_SAME_LONG_RANDOM_SECRET
```

The Laravel integration sends the bearer token in the HTTP Authorization header. The API key must remain server-side. Never copy it into Flutter, a public JavaScript bundle, a support ticket, or Git.

After changing environment values, clear and rebuild Laravel's configuration cache using the hosting provider's supported CLI access:

```bash
php artisan config:clear
php artisan config:cache
```

Restart PHP-FPM or application workers if the host requires it.

## Verification checklist

1. From the VPS, confirm SearXNG responds on `http://127.0.0.1:8888/search`.
2. Confirm the public HTTPS endpoint returns HTTP 401 when the bearer token is absent or incorrect.
3. Confirm the same endpoint returns a valid SearXNG response when the correct bearer token is supplied.
4. Confirm `https://search.example-owned-domain.ir/` and every path other than the exact search endpoint return 404.
5. Confirm public TCP port 8888 is closed from outside the VPS.
6. From the Laravel host, run a safe test query through the application and inspect logs for timeouts or TLS errors. Do not log or print the bearer token.
7. If Laravel and SearXNG are later moved onto the same VPS, switch Laravel to `http://127.0.0.1:8888/search`, clear the remote token setting, and remove the public bridge only after verifying no other consumer uses it.

This bridge only transports search requests. It does not make search results authoritative. For licensing, tax, legal, health, banking, and government processes, the assistant must still prioritize the relevant official authority and state uncertainty when the exact rule cannot be verified.
