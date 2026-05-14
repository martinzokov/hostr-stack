# hostr-stack

SaaS-in-a-box bootstrap kit for a single VPS managed by Dokploy.

The first stack profile ships:

- Auth: Logto
- Database: Postgres
- Analytics: Umami
- Observability: optional SigNoz profile, disabled by default because it is heavy for small VPSes
- Email: useSend
- App: Next.js starter wired for Logto
- SSL: handled by Dokploy domains through Traefik/Let's Encrypt

## Quick Start

```sh
cp .env.example .env
bin/hostr-stack init --domain example.com
bin/hostr-stack validate
bin/hostr-stack deploy
bin/hostr-stack smoke
```

`deploy` expects an existing HTTPS-only Dokploy instance and these variables:

```sh
DOKPLOY_DOMAIN=dokploy.example.com
DOKPLOY_API_KEY=...
DOKPLOY_ENVIRONMENT_ID=...
```

Dokploy itself must be reachable over HTTPS before the stack deploy begins. Point DNS records for `dokploy`, `app`, `auth`, `auth-admin`, `umami`, and `mail` to the VPS before deployment. The CLI derives `https://$DOKPLOY_DOMAIN` and rejects `DOKPLOY_DOMAIN` values that include an `http://` or `https://` scheme.

## Optional SigNoz

SigNoz is available as an opt-in Compose profile. It is not part of the default deploy because ClickHouse and ZooKeeper can saturate small VPSes.

To enable it:

```sh
ENABLE_SIGNOZ=true
SIGNOZ_DOMAIN=signoz.example.com
bin/hostr-stack init
bin/hostr-stack deploy
```

When enabled, the CLI also sets `COMPOSE_PROFILES=signoz`, creates the SigNoz Dokploy domain, and includes the SigNoz endpoint in smoke checks.

## Bring Your Own App

The template defaults to `apps/nextjs-starter`. To use your own app, set these in `.env`:

```sh
APP_BUILD_CONTEXT=./path/to/app
APP_DOCKERFILE=./path/to/app/Dockerfile
```

Your app should read the generated `LOGTO_*`, `DATABASE_URL`, `NEXT_PUBLIC_UMAMI_*`, and `USESEND_*` variables. `OTEL_EXPORTER_OTLP_ENDPOINT` is only set when the optional SigNoz profile is enabled.

For Dokploy Compose deployment, the app service uses `APP_IMAGE`. The CLI builds the default starter image locally before deployment when `APP_BUILD_CONTEXT` exists. For your own app, point `APP_IMAGE` at a registry image, or set `APP_BUILD_CONTEXT` to a local app directory on the VPS where the CLI runs.

## Files

- `bin/hostr-stack`: CLI for initialization, render, validation, Dokploy deploy, and smoke checks.
- `templates/dokploy/saas-core/docker-compose.yml`: core stack compose source.
- `templates/dokploy/saas-core/template.toml`: Dokploy template metadata for domains/env.
- `apps/nextjs-starter`: minimal Next.js App Router starter with Logto SDK integration.
- `docs/verification.md`: VPS verification notes.
- `docs/post-deploy-wiring.md`: remaining provider setup and automation assessment.
