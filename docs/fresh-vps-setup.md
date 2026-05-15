# Fresh VPS Setup

This runbook takes a new VPS to a working HTTPS hostr-stack deployment.

The recommended path is `install.sh`. It installs Dokploy, configures the
Dokploy panel behind Traefik/Let's Encrypt, creates the first admin account,
creates a Dokploy API key/project/environment, writes `.env`, deploys the
stack, and runs smoke tests.

## 1. Provision The VPS

Use a Linux VPS with:

- Ubuntu 24.04, Ubuntu 22.04, or Debian 12.
- At least 2GB RAM and 30GB disk.
- Public IPv4.
- Ports `80` and `443` open.

For a playground server you can use nip.io and skip DNS setup. If the server IP
is `178.105.108.173`, the installer defaults to:

```text
https://dokploy.178-105-108-173.nip.io
https://app.178-105-108-173.nip.io
https://auth.178-105-108-173.nip.io
https://auth-admin.178-105-108-173.nip.io
https://umami.178-105-108-173.nip.io
https://mail.178-105-108-173.nip.io
```

For a real domain, point these records at the VPS:

```text
dokploy.example.com     A     <server-ip>
app.example.com         A     <server-ip>
auth.example.com        A     <server-ip>
auth-admin.example.com  A     <server-ip>
umami.example.com       A     <server-ip>
mail.example.com        A     <server-ip>
```

A wildcard `*.example.com` record also works.

## 2. Run The Installer With curl

Once the repo is public, the easiest fresh install is:

```sh
curl -fsSL https://raw.githubusercontent.com/martinzokov/hostr-stack/main/install.sh | bash
```

For a real domain:

```sh
curl -fsSL https://raw.githubusercontent.com/martinzokov/hostr-stack/main/install.sh | ROOT_DOMAIN=example.com bash
```

The installer clones `https://github.com/martinzokov/hostr-stack.git` into
`/opt/hostr-stack` by default. For a fork:

```sh
curl -fsSL https://raw.githubusercontent.com/<owner>/hostr-stack/main/install.sh | \
  HOSTR_REPO_URL=https://github.com/<owner>/hostr-stack.git ROOT_DOMAIN=example.com bash
```

At the end, the installer prints the Dokploy admin email and generated password
once. Store those credentials immediately; the admin password is not written to
disk.

In auto-mode, if a Dokploy admin already exists from a partial previous run, the
installer rotates that first admin user's password to the newly generated value
and prints it. This keeps auto-mode recoverable without requiring manual
database cleanup.

## 3. Run The Installer From A Checkout

Copy or clone this repo onto the VPS, then run:

```sh
cd /opt/hostr-stack
ROOT_DOMAIN=example.com ./install.sh
```

For nip.io playground installs, `ROOT_DOMAIN` is optional:

```sh
cd /opt/hostr-stack
./install.sh
```

Useful installer options:

```sh
ROOT_DOMAIN=example.com              # defaults to <server-ip-with-dashes>.nip.io
DOKPLOY_DOMAIN=dokploy.example.com   # defaults to dokploy.$ROOT_DOMAIN
DOKPLOY_SETUP_MODE=auto              # auto or manual
ADMIN_EMAIL=admin@example.com        # defaults to admin@$ROOT_DOMAIN
ADMIN_PASSWORD='...'                 # generated if omitted
INSTALL_DIR=/opt/hostr-stack
HOSTR_REPO_URL=https://github.com/martinzokov/hostr-stack.git
HOSTR_BRANCH=main
DEPLOY_STACK=0                       # install/configure Dokploy only
RUN_SMOKE=0                          # deploy but skip smoke tests
BLOCK_DOKPLOY_PORT=0                 # leave raw :3000 reachable
```

The installer stores deployment API values on the VPS:

```sh
/root/hostr-stack.env
```

That file contains the Dokploy URL, admin email, API key, environment ID, and
root domain. It intentionally does not contain the Dokploy admin password.
Treat it as a secret anyway because it contains the Dokploy API key.

## 4. Optional Manual Dokploy Setup

Auto-mode is the default and is the recommended path:

```sh
curl -fsSL https://raw.githubusercontent.com/martinzokov/hostr-stack/main/install.sh | bash
```

If you want to choose your own Dokploy admin account, API key, project, and
environment in the Dokploy UI, use manual mode:

```sh
curl -fsSL https://raw.githubusercontent.com/martinzokov/hostr-stack/main/install.sh | DOKPLOY_SETUP_MODE=manual bash
```

The installer still installs Dokploy and configures the HTTPS Dokploy panel.
Then it waits while you:

1. Open the printed Dokploy URL.
2. Create the first admin account.
3. Create a Dokploy API key.
4. Create a project and environment.
5. Paste the API key and environment ID back into the installer.

Manual mode is useful when you do not want the installer to create the first
Dokploy admin/API/project state through Dokploy internals.

## 5. Reset A VPS Before Retesting

If Dokploy logs you in immediately after a supposed reset, some Docker volume,
Dokploy database, browser session, or repo/env state was left behind. Use the
reset utility to remove the server-side state:

```sh
curl -fsSL https://raw.githubusercontent.com/martinzokov/hostr-stack/main/scripts/reset-vps.sh | YES=1 bash
```

From a checkout:

```sh
YES=1 scripts/reset-vps.sh
```

This removes all Docker services, containers, images, volumes, user-defined
networks, Docker Swarm state, `/etc/dokploy`, `/opt/hostr-stack`,
`/root/hostr-stack.env`, and the older `/root/dokploy-admin.env` file. It does
not clear your browser cookies; use an incognito window if you want to confirm
the login session is not browser-side.

## 6. What The Installer Does

The script performs these steps:

1. Installs base packages.
2. Installs Dokploy with the official Dokploy installer if it is not present.
3. Writes Dokploy Traefik config for `https://$DOKPLOY_DOMAIN`.
4. Starts or restarts a `dokploy-traefik` service.
5. Creates the first Dokploy admin account through Dokploy's auth endpoint.
6. Creates a Dokploy API key, project, and production environment.
7. Runs `bin/hostr-stack init --domain "$ROOT_DOMAIN"`.
8. Writes Dokploy credentials and service domains into `.env`.
9. Runs `bin/hostr-stack validate`, `deploy`, and `smoke`.
10. Blocks external raw `:3000` access with a `DOCKER-USER` iptables rule.

The admin/API bootstrap uses Dokploy internals because Dokploy does not expose a
single documented headless first-run setup command. Keep this script pinned in
the repo and re-test it when upgrading Dokploy.

## 7. Expected Smoke Output

```text
[ok] app https://app.example.com
[ok] logto https://auth.example.com
[ok] logto-admin https://auth-admin.example.com
[ok] umami https://umami.example.com
[ok] usesend https://mail.example.com
```

At this point the stack is deployed and serving over HTTPS, but product wiring
is not complete yet.

## 8. Add Or Change Domains Later

`bin/hostr-stack init --domain example.com` is safe before first deploy, but it
also changes `DOKPLOY_DOMAIN` to `dokploy.example.com`. After setup, the CLI
must keep talking to the current Dokploy panel unless you have also moved the
panel domain.

For post-install app/service domain changes, use:

```sh
cd /opt/hostr-stack
bin/hostr-stack domain --domain example.com
```

That updates:

```text
APP_DOMAIN=app.example.com
LOGTO_DOMAIN=auth.example.com
LOGTO_ADMIN_DOMAIN=auth-admin.example.com
UMAMI_DOMAIN=umami.example.com
USESEND_DOMAIN=mail.example.com
```

It preserves the existing `DOKPLOY_DOMAIN`, deploys updated service env, creates
the new Dokploy domains, and runs smoke tests. This is the safest path if the
generated `nip.io` Dokploy URL is already working and you only want the product
services on your real domain.

If you also want to move the Dokploy panel itself to the new domain, pass it
explicitly:

```sh
bin/hostr-stack domain --domain example.com --dokploy-domain dokploy.example.com
```

With `--dokploy-domain`, the CLI rewrites Dokploy's Traefik route, updates
Dokploy's Better Auth public URL, adds the new trusted origin, waits for the new
HTTPS admin endpoint, and then deploys the service domains through that endpoint.

To only update generated service domains and deploy later:

```sh
bin/hostr-stack domain --domain example.com --no-deploy
```

## 9. Take The First Backup

```sh
cd /opt/hostr-stack
bin/hostr-stack backup
```

The backup directory should contain:

```text
app.sql
logto.sql
umami.sql
usesend.sql
```

Restore is explicit because it replaces database state:

```sh
bin/hostr-stack restore .hostr/backups/<timestamp> --yes
```

## 10. Wire Product Credentials

Follow [post-deploy-wiring.md](post-deploy-wiring.md).

Minimum useful order:

1. Complete Logto admin setup.
2. Create the Logto app for the Next.js starter.
3. Add `LOGTO_APP_ID` and `LOGTO_APP_SECRET` to the `hostr-app` compose env in Dokploy.
4. Redeploy `hostr-app` in Dokploy.
5. Log into Umami, change the default password, create a website, and set `UMAMI_WEBSITE_ID` on `hostr-app` in Dokploy.
6. Configure useSend GitHub OAuth.
7. Configure SES/SNS or your chosen email provider.
8. Configure Logto email delivery.

For product credentials, use the Dokploy UI instead of manually editing the
generated `.env` file on the VPS.

## 11. Bring Your Own App

The installer defaults to the bundled Next.js starter:

```sh
APP_IMAGE=hostr-nextjs-starter:latest
APP_PULL_POLICY=never
APP_BUILD_CONTEXT=./apps/nextjs-starter
APP_DOCKERFILE=Dockerfile
```

To use your own app from a path on the VPS, set these before running
`install.sh` or edit `.env` after install:

```sh
APP_BUILD_CONTEXT=/opt/my-app
APP_DOCKERFILE=Dockerfile
APP_IMAGE=my-app:latest
APP_PULL_POLICY=never
```

To use an app image built by CI:

```sh
APP_IMAGE=ghcr.io/<owner>/<repo>/app:latest
APP_PULL_POLICY=always
APP_BUILD_CONTEXT=
```

Then redeploy:

```sh
bin/hostr-stack deploy
bin/hostr-stack smoke
```

## 12. Manual Fallback

If the automated Dokploy bootstrap breaks after a Dokploy upgrade:

1. Install Dokploy manually.
2. Open `http://<server-ip>:3000`.
3. Create the first admin account.
4. Configure `https://dokploy.example.com`.
5. Create a Dokploy API key, project, and environment.
6. Fill `.env` with `DOKPLOY_DOMAIN`, `DOKPLOY_API_KEY`, and `DOKPLOY_ENVIRONMENT_ID`.
7. Run `bin/hostr-stack validate && bin/hostr-stack deploy && bin/hostr-stack smoke`.

## 13. Operational Checks

Useful checks on the VPS:

```sh
docker service ls
docker ps
docker volume ls | grep hostr
docker network ls | grep hostr
bin/hostr-stack info
```

Dokploy remains the source of truth for compose deployments and public HTTPS
routes. The hostr-stack repo is the source of truth for templates, installer
logic, and backup/restore commands.
