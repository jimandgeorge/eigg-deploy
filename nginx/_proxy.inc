# Shared proxy headers. After cloudflare-realip processing, $remote_addr is the real
# visitor IP, so X-Forwarded-For carries it through to the apps (login rate limiter,
# audit trail). Upgrade headers allow websockets if ever needed.
proxy_set_header Host              $host;
proxy_set_header X-Real-IP         $remote_addr;
proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_http_version 1.1;
proxy_set_header Upgrade    $http_upgrade;
proxy_set_header Connection "upgrade";
