# hostr-stack

SaaS-in-a-box bootstrap kit for a single VPS managed by Dokploy.

It installs and wires:

- Auth: Logto
- Database: Postgres
- Analytics: Umami
- Email: useSend
- App: Next.js starter wired for Logto
- SSL: Dokploy + Traefik + Let's Encrypt

## Quick Start

Use this path for a fresh playground VPS. You do not need a domain; the installer
uses nip.io automatically.

1. SSH into the VPS as root:

```sh
ssh root@<server-ip>
```

2. Run the installer:

```sh
curl -fsSL https://raw.githubusercontent.com/martinzokov/hostr-stack/main/install.sh | bash
```

3. Save the Dokploy admin credentials printed at the end.

The installer prints URLs like:

```text
Dokploy: https://dokploy.<server-ip-with-dashes>.nip.io
App:     https://app.<server-ip-with-dashes>.nip.io
Auth:    https://auth.<server-ip-with-dashes>.nip.io
Admin:   https://auth-admin.<server-ip-with-dashes>.nip.io
Umami:   https://umami.<server-ip-with-dashes>.nip.io
Mail:    https://mail.<server-ip-with-dashes>.nip.io
```

It also prints a generated Dokploy admin email/password. The password is shown
once and is not written to disk.

## Clean Retest

To wipe the VPS Docker/Dokploy state before testing again:

```sh
curl -fsSL https://raw.githubusercontent.com/martinzokov/hostr-stack/main/scripts/reset-vps.sh | YES=1 bash
```

Then rerun the installer.

## What The Installer Does

The default installer is auto-mode. It:

1. Installs Docker/Dokploy dependencies.
2. Installs Dokploy.
3. Configures the Dokploy panel on HTTPS.
4. Creates or rotates a Dokploy admin login and prints it once.
5. Creates a Dokploy API key, project, and environment.
6. Clones this repo to `/opt/hostr-stack`.
7. Generates `.env`.
8. Deploys all services through Dokploy.
9. Runs smoke checks for app, auth, analytics, and email.

Generated deployment API values are stored at:

```sh
/root/hostr-stack.env
```

That file includes the Dokploy API key, but not the Dokploy admin password.

## Common Commands

From the installed repo:

```sh
cd /opt/hostr-stack
bin/hostr-stack info
bin/hostr-stack smoke
bin/hostr-stack backup
```

Restore is intentionally explicit because it replaces database state:

```sh
bin/hostr-stack restore .hostr/backups/<timestamp> --yes
```

## Use A Real Domain

If you already have DNS pointed at the VPS:

```sh
curl -fsSL https://raw.githubusercontent.com/martinzokov/hostr-stack/main/install.sh | ROOT_DOMAIN=example.com bash
```

Create these records, or use a wildcard record:

```text
dokploy.example.com     A     <server-ip>
app.example.com         A     <server-ip>
auth.example.com        A     <server-ip>
auth-admin.example.com  A     <server-ip>
umami.example.com       A     <server-ip>
mail.example.com        A     <server-ip>
```

To add or change service domains after install:

```sh
cd /opt/hostr-stack
bin/hostr-stack domain --domain example.com
```

That preserves the existing `DOKPLOY_DOMAIN` by default, so the Dokploy panel
can stay on the generated `nip.io` host while the product services move to your
domain. If you also want to move the Dokploy panel itself, pass the new admin
host too:

```sh
bin/hostr-stack domain --domain example.com --dokploy-domain dokploy.example.com
```

When `--dokploy-domain` is set, the CLI rewrites the Dokploy Traefik route,
updates Dokploy's Better Auth public URL, adds the new trusted origin, waits for
the new HTTPS endpoint, then deploys the service domains.

## Manual Dokploy Setup

Auto-mode is the default. If you want to create the Dokploy admin/API
key/project/environment yourself in the Dokploy UI:

```sh
curl -fsSL https://raw.githubusercontent.com/martinzokov/hostr-stack/main/install.sh | DOKPLOY_SETUP_MODE=manual bash
```

The installer still installs Dokploy and configures HTTPS, then waits while you
finish setup and paste back the API key and environment ID.

## Installer Options

Pass options as environment variables before `bash`:

```sh
curl -fsSL https://raw.githubusercontent.com/martinzokov/hostr-stack/main/install.sh | ROOT_DOMAIN=example.com RUN_SMOKE=0 bash
```

Available options:

```sh
ROOT_DOMAIN=example.com
DOKPLOY_DOMAIN=dokploy.example.com
DOKPLOY_SETUP_MODE=auto              # auto or manual
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD='...'                 # generated if omitted
INSTALL_DIR=/opt/hostr-stack
HOSTR_REPO_URL=https://github.com/martinzokov/hostr-stack.git
HOSTR_BRANCH=main
DEPLOY_STACK=0                       # install/configure Dokploy only
RUN_SMOKE=0                          # deploy but skip smoke tests
BLOCK_DOKPLOY_PORT=0                 # leave raw :3000 reachable
```

## Existing Dokploy

If Dokploy is already reachable over HTTPS and you have an API key/environment:

```sh
cd /opt/hostr-stack
cp .env.example .env
bin/hostr-stack init --domain example.com
```

Set:

```sh
DOKPLOY_DOMAIN=dokploy.example.com
DOKPLOY_API_KEY=...
DOKPLOY_ENVIRONMENT_ID=...
```

Then deploy:

```sh
bin/hostr-stack validate
bin/hostr-stack deploy
bin/hostr-stack smoke
```

## Bring Your Own App

The default app is `apps/nextjs-starter`.

Use a local app path on the VPS:

```sh
APP_BUILD_CONTEXT=/opt/my-app
APP_DOCKERFILE=Dockerfile
APP_IMAGE=my-app:latest
APP_PULL_POLICY=never
```

Or use an image built by CI:

```sh
APP_IMAGE=ghcr.io/<owner>/<repo>/app:latest
APP_PULL_POLICY=always
APP_BUILD_CONTEXT=
```

Your app receives `LOGTO_*`, `DATABASE_URL`, `NEXT_PUBLIC_UMAMI_*`, and
`USESEND_API_URL`.

## Post-Deploy Wiring

After deployment, complete product-level setup:

1. Open Logto admin at `https://auth-admin.<domain>`.
2. Create a Traditional Web App.
3. Set the redirect URI to `https://app.<domain>/callback`.
4. Add `LOGTO_APP_ID` and `LOGTO_APP_SECRET` to `.env`.
5. Redeploy with `bin/hostr-stack deploy && bin/hostr-stack smoke`.

See [docs/post-deploy-wiring.md](docs/post-deploy-wiring.md) for Umami,
useSend, AWS SES/SNS, and Logto email setup.

## CI/CD

The included GitHub Actions workflow builds and pushes the Next.js image to
GHCR on every push to `main`, then triggers a Dokploy redeploy of `hostr-app`.

Required GitHub secrets:

```text
DOKPLOY_DOMAIN
DOKPLOY_API_KEY
DOKPLOY_ENVIRONMENT_ID
DOKPLOY_COMPOSE_NAME=hostr-app
```

For CI-built app images, set:

```sh
APP_IMAGE=ghcr.io/<owner>/<repo>/app:latest
APP_PULL_POLICY=always
APP_BUILD_CONTEXT=
```

## Files

- `install.sh`: fresh-VPS installer.
- `scripts/reset-vps.sh`: destructive VPS reset utility.
- `bin/hostr-stack`: CLI for init, deploy, domains, smoke, backup, restore, and info.
- `templates/dokploy/`: Dokploy Compose templates.
- `apps/nextjs-starter`: bundled Next.js starter.
- `docs/fresh-vps-setup.md`: detailed VPS setup guide.
- `docs/post-deploy-wiring.md`: product wiring guide.
- `docs/verification.md`: VPS verification notes.
