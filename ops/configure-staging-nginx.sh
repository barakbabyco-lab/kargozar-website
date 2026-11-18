#!/usr/bin/env bash
set -Eeuo pipefail

DOMAIN="kargozarr.ir"
WWW_DOMAIN="www.kargozarr.ir"
VPS_IPV4="194.5.205.233"
DEPLOY_USER="deploy"
APP_ROOT="/var/www/kargozar-staging/current"
APP_PUBLIC="$APP_ROOT/public"
SHARED_ENV="/var/www/kargozar-staging/shared/.env"
PHP_FPM_SOCKET="/run/php/php8.3-fpm.sock"
SITE_FILE="/etc/nginx/sites-available/kargozar-staging"
SITE_LINK="/etc/nginx/sites-enabled/kargozar-staging"

if [[ "${EUID}" -ne 0 ]]; then
  echo "ERROR: Run this script as root from the VPS console."
  exit 1
fi

for path in "$APP_PUBLIC/index.php" "$SHARED_ENV"; do
  if [[ ! -f "$path" ]]; then
    echo "ERROR: Required Laravel file not found: $path"
    exit 1
  fi
done

if [[ ! -S "$PHP_FPM_SOCKET" ]]; then
  echo "ERROR: PHP-FPM socket not found: $PHP_FPM_SOCKET"
  exit 1
fi

cat > "$SITE_FILE" <<'NGINX'
server {
    listen 80;
    listen [::]:80;
    server_name kargozarr.ir www.kargozarr.ir;

    root /var/www/kargozar-staging/current/public;
    index index.php;
    charset utf-8;
    client_max_body_size 20M;

    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy strict-origin-when-cross-origin always;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico {
        access_log off;
        log_not_found off;
    }

    location = /robots.txt {
        access_log off;
        log_not_found off;
    }

    location ~ \.php$ {
        try_files $uri =404;
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_read_timeout 60s;
    }

    location ~ /\. {
        deny all;
    }
}
NGINX

ln -sfn "$SITE_FILE" "$SITE_LINK"
if [[ -L /etc/nginx/sites-enabled/default ]]; then
  rm -f /etc/nginx/sites-enabled/default
fi

nginx -t
systemctl reload nginx

echo
echo "Checking Laravel API through Nginx on loopback..."
HTTP_CODE="$(curl -sS --max-time 10 -H "Host: $DOMAIN" -o /tmp/kargozar-nginx-check.json -w '%{http_code}' http://127.0.0.1/api/v1/service-categories || true)"
echo "API HTTP status: $HTTP_CODE"
if [[ "$HTTP_CODE" != "200" ]]; then
  echo "ERROR: Nginx is configured, but Laravel API did not return HTTP 200."
  head -c 500 /tmp/kargozar-nginx-check.json 2>/dev/null || true
  exit 1
fi

domain_ip="$(getent ahostsv4 "$DOMAIN" | awk 'NR==1 {print $1}')"
www_ip="$(getent ahostsv4 "$WWW_DOMAIN" | awk 'NR==1 {print $1}')"

if [[ "$domain_ip" == "$VPS_IPV4" && "$www_ip" == "$VPS_IPV4" ]]; then
  echo
  echo "DNS points both hostnames to $VPS_IPV4. Installing and enabling Let's Encrypt HTTPS..."
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y certbot python3-certbot-nginx
  certbot --nginx -d "$DOMAIN" -d "$WWW_DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email --redirect

  if grep -q '^APP_URL=' "$SHARED_ENV"; then
    sed -i "s#^APP_URL=.*#APP_URL=https://$DOMAIN#" "$SHARED_ENV"
  else
    printf '\nAPP_URL=https://%s\n' "$DOMAIN" >> "$SHARED_ENV"
  fi
  if grep -q '^APP_DEBUG=' "$SHARED_ENV"; then
    sed -i 's/^APP_DEBUG=.*/APP_DEBUG=false/' "$SHARED_ENV"
  else
    printf '\nAPP_DEBUG=false\n' >> "$SHARED_ENV"
  fi

  runuser -u "$DEPLOY_USER" -- bash -lc "cd '$APP_ROOT' && php artisan config:clear"
  systemctl enable --now certbot.timer >/dev/null 2>&1 || true

  echo
  echo "HTTPS API check:"
  curl -fsS --max-time 15 "https://$DOMAIN/api/v1/service-categories" -o /dev/null
  echo "HTTPS API returned HTTP 200."
else
  echo
  echo "HTTP virtual host is active, but public DNS is not ready."
  echo "Required DNS records:"
  echo "  $DOMAIN      A      $VPS_IPV4"
  echo "  $WWW_DOMAIN  A      $VPS_IPV4"
  echo "After DNS resolves to the VPS, run this same script again to enable HTTPS."
fi
