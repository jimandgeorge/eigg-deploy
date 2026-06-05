# EIGG deploy

Single-droplet deployment of both EIGG products behind one edge nginx, fronted by
Cloudflare.

| Host | App | Repo | Backend | DB |
|------|-----|------|---------|----|
| `prevent.eigg.io` | EIGG Prevent | `../eigg-prevent` | `:8001` `/api/v1` | bundled Postgres |
| `investigate.eigg.io` | EIGG Investigate | `../fraud-copilot` | `:8000` `/api/v1` | Neon (external) |

The edge nginx terminates TLS with a **Cloudflare Origin Certificate** (wildcard
`*.eigg.io`) and routes by hostname; per host, `/api/v1` + `/health` → that app's
backend, everything else (pages, NextAuth `/api/auth`, Prevent's `/api/admin` proxy)
→ that app's frontend.

## Layout on the droplet
Clone all three repos side by side:
```
~/eigg-deploy      (this repo)
~/eigg-prevent
~/fraud-copilot
```

## 1. Cloudflare
- DNS: `prevent` and `investigate` A records → droplet IP, **proxied** (orange cloud).
- **SSL/TLS → Overview → Full (strict)**.
- **SSL/TLS → Origin Server → Create Certificate**, hostnames `eigg.io` + `*.eigg.io`.
  Save the two blobs on the droplet:
  ```
  mkdir -p /etc/cloudflare
  nano /etc/cloudflare/eigg.io.pem   # Origin Certificate
  nano /etc/cloudflare/eigg.io.key   # Private Key
  chmod 600 /etc/cloudflare/eigg.io.key
  ```

## 2. Configure
```
cp .env.example .env   # fill in secrets, Neon URL, API keys
```

## 3. Build & run
```
docker compose up -d --build
```
- Prevent backend seeds its framework + platform admin on boot.
- Investigate uses Neon; ensure `INVEST_DATABASE_URL` points at it.

## 4. First sign-in
- Prevent admin panel: `https://prevent.eigg.io/login` → `PREVENT_ADMIN_EMAIL` /
  `PREVENT_ADMIN_PASSWORD` (must use the email, with `@`) → `/admin`.

## Notes
- `NEXT_PUBLIC_API_URL` is baked empty (same-origin `/api/v1`); rebuild the relevant
  frontend image if you ever change it.
- Cloudflare real-IP is restored in `nginx/cloudflare-realip.conf` so per-IP login
  rate limiting and the audit trail see real visitor IPs.
- Persisted volumes: `prevent_pgdata`, `prevent_uploads`. Investigate's data is in Neon.
