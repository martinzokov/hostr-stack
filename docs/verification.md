# Verification

The target VPS provided for verification is:

```sh
ssh -i ~/.ssh/hetz root@178.105.108.173
```

The CLI supports two verification levels:

1. `bin/hostr-stack validate`: renders the compose file and checks it with Docker Compose.
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

SigNoz is excluded from the default deployment. To verify the heavy observability profile separately, set `ENABLE_SIGNOZ=true`, ensure the VPS has enough CPU/RAM for ClickHouse and ZooKeeper, then redeploy. The smoke command only checks `SIGNOZ_DOMAIN` when that profile is enabled.

Post-deploy Logto setup:

1. Open `https://auth-admin.<domain>`.
2. Create a traditional web application.
3. Add redirect URI `https://app.<domain>/callback`.
4. Add post sign-out redirect URI `https://app.<domain>/`.
5. Put the generated app id and app secret into `LOGTO_APP_ID` and `LOGTO_APP_SECRET`.
6. Redeploy from Dokploy or run `bin/hostr-stack deploy` again.
