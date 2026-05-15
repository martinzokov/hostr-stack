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

## 2. Run The Installer

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

If you are running `install.sh` outside a checkout, provide the repo URL:

```sh
HOSTR_REPO_URL=https://github.com/<owner>/hostr-stack.git \
ROOT_DOMAIN=example.com \
bash install.sh
```

Useful installer options:

```sh
ROOT_DOMAIN=example.com              # defaults to <server-ip-with-dashes>.nip.io
DOKPLOY_DOMAIN=dokploy.example.com   # defaults to dokploy.$ROOT_DOMAIN
ADMIN_EMAIL=admin@example.com        # defaults to admin@$ROOT_DOMAIN
ADMIN_PASSWORD='...'                 # generated if omitted
INSTALL_DIR=/opt/hostr-stack
DEPLOY_STACK=0                       # install/configure Dokploy only
RUN_SMOKE=0                          # deploy but skip smoke tests
BLOCK_DOKPLOY_PORT=0                 # leave raw :3000 reachable
```

The installer stores generated credentials on the VPS:

```sh
/root/dokploy-admin.env
```

That file contains the Dokploy URL, admin login, API key, environment ID, and
root domain. Treat it as a secret.

## 3. What The Installer Does

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

## 4. Expected Smoke Output

```text
[ok] app https://app.example.com
[ok] logto https://auth.example.com
[ok] logto-admin https://auth-admin.example.com
[ok] umami https://umami.example.com
[ok] usesend https://mail.example.com
```

At this point the stack is deployed and serving over HTTPS, but product wiring
is not complete yet.

## 5. Take The First Backup

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

## 6. Wire Product Credentials

Follow [post-deploy-wiring.md](post-deploy-wiring.md).

Minimum useful order:

1. Complete Logto admin setup.
2. Create the Logto app for the Next.js starter.
3. Add `LOGTO_APP_ID` and `LOGTO_APP_SECRET` to `.env`.
4. Redeploy and smoke test.
5. Log into Umami, change the default password, create a website, and set `UMAMI_WEBSITE_ID`.
6. Configure useSend GitHub OAuth.
7. Configure SES/SNS or your chosen email provider.
8. Configure Logto email delivery.

After each `.env` change:

```sh
bin/hostr-stack validate
bin/hostr-stack deploy
bin/hostr-stack smoke
```

## 7. Bring Your Own App

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

## 8. Manual Fallback

If the automated Dokploy bootstrap breaks after a Dokploy upgrade:

1. Install Dokploy manually.
2. Open `http://<server-ip>:3000`.
3. Create the first admin account.
4. Configure `https://dokploy.example.com`.
5. Create a Dokploy API key, project, and environment.
6. Fill `.env` with `DOKPLOY_DOMAIN`, `DOKPLOY_API_KEY`, and `DOKPLOY_ENVIRONMENT_ID`.
7. Run `bin/hostr-stack validate && bin/hostr-stack deploy && bin/hostr-stack smoke`.

## 9. Operational Checks

Useful checks on the VPS:

```sh
docker service ls
docker ps
docker volume ls | grep hostr
docker network ls | grep hostr
bin/hostr-stack info
```

Dokploy remains the source of truth for compose deployments and public HTTPS
routes. The hostr-stack repo is the source of truth for templates, generated
environment values, and backup/restore commands.
