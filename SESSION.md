# Session recap — 2026-05-08

## What we did

### 1. Put Jellyfin OIDC credentials in Vault

Generated client ID/secret and stored at `secret/jellyfin` (`oidc-client-id`, `oidc-client-secret`). ExternalSecret `authentik-blueprint-jellyfin-env` syncs them into Authentik as env vars. Blueprint `authentik-blueprint-jellyfin-oidc` applies the OIDC provider to Authentik.

### 2. Configured Jellyfin SSO plugin (9p4)

Plugin is installed by init container into `/config/plugins/SSO-Auth_4.0.0.4/`. Config lives at `/config/plugins/configurations/SSO-Auth.xml` on the PVC.

Key settings that were required to make it work:
- `DisableHttps: true` — Duende OidcClient refuses HTTP endpoints by default; this bypasses it
- `DoNotValidateEndpoints: true` — avoids endpoint mismatch errors
- `DoNotValidateIssuerName: true` — avoids issuer validation errors

Provider name must be `Authentik` (case-sensitive, matches the URL paths).

### 3. Correct SSO plugin URL paths (not obvious)

- **Initiation**: `/sso/OID/p/{provider}` — starts the OIDC flow
- **Callback**: `/sso/OID/r/{provider}` — receives the code/state from Authentik

The `/sso/OID/redirect/{provider}` path is different and just returns "Missing state" immediately — don't use it.

### 4. Wired the auto-redirect via nginx app-root

Added `nginx.ingress.kubernetes.io/app-root: /sso/OID/p/Authentik` to the Jellyfin ingress. This redirects `/` to the SSO initiation URL. Users hit Authentik once, then land in Jellyfin.

Note: `server-snippet` and `configuration-snippet` are both blocked in nginx-ingress v1.15.1 when `auth-url` is also present (classified as risky). `app-root` is the safe alternative for root redirects.

### 5. Navidrome (already working)

`ND_REVERSEPROXYUSERHEADER` and `ND_REVERSEPROXYWHITELIST` were already set in the deployment. Headers forwarded by nginx from Authentik should auto-login users.

## Current state

- Jellyfin: Authentik SSO working, login screen bypassed via app-root redirect
- Navidrome: forward auth + header-based auth configured
- Grafana: OAuth working (from previous session)
- Authentik blueprints: Grafana, Jellyfin OIDC, media proxy providers all declarative

## Next up

- Verify Navidrome header auth actually auto-logs in (test it)
- Loki, Tempo, Uptime Kuma
- Immich, Nextcloud, Ollama
