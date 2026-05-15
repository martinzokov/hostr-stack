# Post-Deploy Wiring

Use this after `install.sh` has finished and the stack is reachable over HTTPS.
The installer already creates the Dokploy project/environment, deploys the
compose services, configures domains, and runs smoke checks. This doc only covers
product-level credentials that need third-party dashboards or first-run admin UI
steps.

## How To Apply Changes

There are two valid workflows.

Recommended for repeatable setup:

```sh
cd /opt/hostr-stack
edit .env
bin/hostr-stack deploy
bin/hostr-stack smoke
```

This keeps the repo `.env` as the source of truth and syncs the compose env into
Dokploy.

Fast path inside Dokploy:

1. Open `https://dokploy.<domain>`.
2. Open the relevant compose service.
3. Update the environment variables in Dokploy.
4. Click redeploy in Dokploy.

This is fine for quick testing. If the change should survive a future CLI deploy,
copy the same value back into `/opt/hostr-stack/.env`; otherwise the next
`bin/hostr-stack deploy` can overwrite the Dokploy-side edit.

## What Still Needs Wiring

| Area | Where to configure | Values |
| --- | --- | --- |
| Logto app for the starter | Logto Admin, then app compose env | `LOGTO_APP_ID`, `LOGTO_APP_SECRET` |
| Umami tracking | Umami UI, then app compose env | `UMAMI_WEBSITE_ID` |
| useSend login | GitHub OAuth app, then useSend compose env | `USESEND_GITHUB_ID`, `USESEND_GITHUB_SECRET` |
| useSend sending | AWS SES/SNS and useSend UI | `AWS_DEFAULT_REGION`, `AWS_ACCESS_KEY`, `AWS_SECRET_KEY` |
| Logto email | Logto Admin connector | provider/API or SMTP values |

## 1. Logto App

Open:

```text
https://auth-admin.<domain>
```

Create a Traditional Web App in Logto.

Use these URLs:

```text
Redirect URI: https://app.<domain>/callback
Post sign-out redirect URI: https://app.<domain>/
```

Copy the application ID and secret into either `/opt/hostr-stack/.env` or the
`hostr-app` compose environment in Dokploy:

```sh
LOGTO_APP_ID=<logto-app-id>
LOGTO_APP_SECRET=<logto-app-secret>
```

Redeploy `hostr-app`. Expected result: the starter app sign-in button is enabled
and redirects through `https://auth.<domain>`.

## 2. Umami Tracking

Open:

```text
https://umami.<domain>
```

On a fresh Umami install, sign in with the default admin credentials and change
the password immediately. Create a website for:

```text
app.<domain>
```

Copy the website ID into `/opt/hostr-stack/.env` or the `hostr-app` compose
environment in Dokploy:

```sh
UMAMI_WEBSITE_ID=<umami-website-id>
```

Redeploy `hostr-app`. Expected result: the app renders the Umami script with the
website ID and visits appear in Umami. Ad blockers can hide analytics during
testing, so verify with a clean browser profile if needed.

## 3. useSend Login

useSend self-hosted login uses GitHub OAuth.

Create a GitHub OAuth app at:

```text
https://github.com/settings/developers
```

Use:

```text
Homepage URL: https://mail.<domain>
Authorization callback URL: https://mail.<domain>/api/auth/callback/github
```

Copy the client ID and secret into `/opt/hostr-stack/.env` or the `usesend`
compose environment in Dokploy:

```sh
USESEND_GITHUB_ID=<github-client-id>
USESEND_GITHUB_SECRET=<github-client-secret>
```

Redeploy `usesend`. Expected result: `https://mail.<domain>` redirects to GitHub
and returns to useSend after authorization.

## 4. useSend Sending

useSend sends through AWS SES and uses SNS for delivery, bounce, and complaint
events.

In AWS:

1. Pick an SES region.
2. Verify your sending domain.
3. Add the DNS records SES provides.
4. Create IAM credentials for useSend.
5. Start broad enough to prove the flow, then narrow permissions for production.

Set these in `/opt/hostr-stack/.env` or the `usesend` compose environment in
Dokploy:

```sh
AWS_DEFAULT_REGION=<aws-region>
AWS_ACCESS_KEY=<aws-access-key-id>
AWS_SECRET_KEY=<secret-access-key>
```

Redeploy `usesend`, then finish the SES/SNS setup inside the useSend UI at:

```text
https://mail.<domain>
```

SES sandbox mode can block real recipient delivery until AWS grants production
access.

## 5. Logto Email

This is required for real verification and password reset emails.

Recommended order:

1. Finish useSend sending or choose another email provider.
2. Create the API key or SMTP credentials in that provider.
3. Open Logto Admin at `https://auth-admin.<domain>`.
4. Configure an email connector.
5. Send a test email from Logto.

Expected result: Logto can deliver verification and password reset emails from
your domain.

## Readiness Checklist

The stack is ready for product work when:

- `https://app.<domain>` loads.
- Logto sign-in from the starter app works.
- Umami uses a non-default admin password and receives app visits.
- useSend GitHub login works.
- Transactional email sending works.
- Logto verification or password reset email can be delivered.
- `bin/hostr-stack backup` writes `app.sql`, `logto.sql`, `umami.sql`, and `usesend.sql`.

## References

- Logto Next.js App Router quick start: https://docs.logto.io/quick-starts/next-app-router
- Umami API docs: https://umami.is/docs/api
- useSend self-hosting guide: https://docs.usesend.com/self-hosting/overview
- GitHub OAuth app creation: https://docs.github.com/en/developers/apps/creating-an-oauth-app
- AWS SES credentials: https://docs.aws.amazon.com/ses/latest/dg/smtp-credentials.html
