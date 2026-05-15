# Verification

For full setup from a new server, use [fresh-vps-setup.md](fresh-vps-setup.md).

The target VPS provided for verification is:

```sh
ssh -i ~/.ssh/hetz root@178.105.108.173
```

Last verified from a cleaned hostr-stack state on May 15, 2026.

The CLI supports two verification levels:

1. `bin/hostr-stack validate`: renders the compose files and checks them with Docker Compose.
2. `bin/hostr-stack smoke`: checks the public HTTPS endpoints after Dokploy deploys the stack and issues certificates.

For a full Dokploy deployment, Dokploy must already be reachable over HTTPS. Set the Dokploy API values in `.env`:

```sh
DOKPLOY_DOMAIN=dokploy.example.com
DOKPLOY_API_KEY=...
DOKPLOY_ENVIRONMENT_ID=...
```

Then run:

```sh
bin/hostr-stack deploy
bin/hostr-stack smoke
```

Expected HTTPS smoke output for the verification domain:

```text
[ok] app https://app.verify.178-105-108-173.nip.io
[ok] logto https://auth.verify.178-105-108-173.nip.io
[ok] logto-admin https://auth-admin.verify.178-105-108-173.nip.io
[ok] umami https://umami.verify.178-105-108-173.nip.io
[ok] usesend https://mail.verify.178-105-108-173.nip.io
```

The default app image path builds locally before deployment when
`APP_BUILD_CONTEXT` is set. For remote CI/CD or a separate app repo, push an
image to a registry, set `APP_IMAGE`, set `APP_PULL_POLICY=always`, and leave
`APP_BUILD_CONTEXT` empty.

Database backup verification:

```sh
bin/hostr-stack backup
```

The command writes `app.sql`, `logto.sql`, `umami.sql`, and `usesend.sql` under
`.hostr/backups/`. Restore is destructive and requires an explicit confirmation
flag:

```sh
bin/hostr-stack restore .hostr/backups/<timestamp> --yes
```

The May 15, 2026 verification run wrote all four SQL dumps from the live Dokploy-managed containers.

Post-deploy Logto setup:

1. Open `https://auth-admin.<domain>`.
2. Create a traditional web application.
3. Add redirect URI `https://<app-domain>/callback`.
4. Add post sign-out redirect URI `https://<app-domain>/`.
5. Put the generated app id and app secret into `LOGTO_APP_ID` and `LOGTO_APP_SECRET` on the `hostr-app` compose service in Dokploy.
6. Redeploy `hostr-app` from Dokploy.
