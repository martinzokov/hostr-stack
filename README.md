# hostr-stack

SaaS-in-a-box bootstrap kit for a single VPS managed by Dokploy.

Ships with:

- Auth: Logto
- Database: Postgres
- Analytics: Umami
- Email: useSend
- App: Next.js starter wired for Logto
- SSL: handled by Dokploy domains through Traefik/Let's Encrypt

## Quick Start

For a fresh VPS, start with [docs/fresh-vps-setup.md](docs/fresh-vps-setup.md).

Automated VPS install:

```sh
curl -fsSL https://raw.githubusercontent.com/martinzokov/hostr-stack/main/install.sh | ROOT_DOMAIN=example.com bash
```

For a playground VPS, `ROOT_DOMAIN` can be omitted and the installer will use
`<server-ip-with-dashes>.nip.io`.

Fresh reset before retesting:

```sh
curl -fsSL https://raw.githubusercontent.com/martinzokov/hostr-stack/main/scripts/reset-vps.sh | YES=1 bash
```

For a VPS that already has Dokploy reachable over HTTPS:

```sh
cp .env.example .env
bin/hostr-stack init --domain example.com
bin/hostr-stack validate
bin/hostr-stack deploy
bin/hostr-stack smoke
bin/hostr-stack backup
bin/hostr-stack info
```

`deploy` expects an existing HTTPS-only Dokploy instance and these variables:

```sh
DOKPLOY_DOMAIN=dokploy.example.com
DOKPLOY_API_KEY=...
DOKPLOY_ENVIRONMENT_ID=...
```

Dokploy itself must be reachable over HTTPS before the stack deploy begins. Point DNS records for `dokploy`, `app`, `auth`, `auth-admin`, `umami`, and `mail` to the VPS before deployment. The CLI derives `https://$DOKPLOY_DOMAIN` and rejects `DOKPLOY_DOMAIN` values that include an `http://` or `https://` scheme.

## Fresh VPS Setup

The tested path is:

1. Provision a VPS with public IPv4, at least 2GB RAM, and enough disk for Docker image builds.
2. Point DNS records at the VPS, or use the default nip.io hostnames.
3. Run the curl installer.
4. Store the one-time Dokploy admin credentials printed by the installer.

See [docs/fresh-vps-setup.md](docs/fresh-vps-setup.md) for the exact commands and the post-deploy checklist.

## Post-Deploy Wiring

After `deploy` completes, a few credentials must be wired manually before the app is fully functional. See `docs/post-deploy-wiring.md`.

The minimum path to a working sign-in:

1. Open Logto admin at `https://auth-admin.<domain>` and complete first-run setup.
2. Create a Traditional Web App, set the redirect URI to `https://app.<domain>/callback`.
3. Copy the App ID and App Secret into `.env` as `LOGTO_APP_ID` and `LOGTO_APP_SECRET`.
4. Redeploy: `bin/hostr-stack deploy && bin/hostr-stack smoke`.

## CI/CD

The included GitHub Actions workflow (`.github/workflows/deploy-app.yml`) builds and pushes the Next.js image to GHCR on every push to `main`, then triggers a Dokploy redeploy of the `hostr-app` stack.

Required GitHub secrets: `DOKPLOY_DOMAIN`, `DOKPLOY_API_KEY`, `DOKPLOY_ENVIRONMENT_ID`, `DOKPLOY_COMPOSE_NAME` (value: `hostr-app`).

For the CI/CD path, set in `.env`:

```sh
APP_IMAGE=ghcr.io/<owner>/<repo>/app:latest
APP_PULL_POLICY=always
APP_BUILD_CONTEXT=
```

## Bring Your Own App

The template defaults to `apps/nextjs-starter`. If `APP_BUILD_CONTEXT` is set,
`bin/hostr-stack deploy` builds `APP_IMAGE` before deploying `hostr-app`. This
is best when the CLI runs on the VPS or against the same Docker daemon Dokploy
uses.

To use your own app from a local path on the VPS:

```sh
APP_BUILD_CONTEXT=./path/to/app
APP_DOCKERFILE=Dockerfile
APP_IMAGE=your-image:tag
```

To use an app from another repo or CI pipeline, build and push the image
elsewhere, then leave `APP_BUILD_CONTEXT` empty:

```sh
APP_IMAGE=ghcr.io/<owner>/<repo>/app:latest
APP_PULL_POLICY=always
APP_BUILD_CONTEXT=
```

Your app receives: `LOGTO_*`, `DATABASE_URL`, `NEXT_PUBLIC_UMAMI_*`, `USESEND_API_URL`.

## Backups

`bin/hostr-stack backup` writes a timestamped backup directory under
`.hostr/backups/` with dumps for the core Postgres service and the useSend
Postgres service: `app.sql`, `logto.sql`, `umami.sql`, and `usesend.sql`.

Restore is intentionally explicit because it replaces database state:

```sh
bin/hostr-stack restore .hostr/backups/<timestamp> --yes
```

## Files

- `bin/hostr-stack`: CLI for initialization, validation, Dokploy deploy, smoke checks, and credentials output.
- `install.sh`: fresh-VPS installer for Dokploy HTTPS, admin/API bootstrap, deploy, and smoke checks.
- `scripts/reset-vps.sh`: destructive VPS reset utility for clean retests.
- `templates/dokploy/`: Per-service Compose files deployed as separate Dokploy stacks.
- `apps/nextjs-starter`: Minimal Next.js App Router starter with Logto auth integration.
- `docs/fresh-vps-setup.md`: End-to-end setup from a new VPS to a live stack.
- `docs/post-deploy-wiring.md`: Manual wiring steps for Logto, Umami, useSend, and AWS SES.
- `docs/verification.md`: VPS verification notes.
