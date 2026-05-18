# Post-Deploy Wiring

Use this after `install.sh` has finished and the stack is reachable over HTTPS.
The installer already creates the Dokploy project/environment, deploys the
compose services, configures domains, and runs smoke checks. This doc only covers
product-level credentials that need third-party dashboards or first-run admin UI
steps.

## How To Apply Changes

1. Open `https://dokploy.<domain>`.
2. Open the relevant compose service.
3. Update the environment variables in Dokploy.
4. Click redeploy in Dokploy.

For product wiring, Dokploy is the intended place to enter credentials. You
should not need to SSH into the VPS or manually edit generated env files.

## What Still Needs Wiring

| Area | Where to configure | Values |
| --- | --- | --- |
| Logto app for the starter | Logto Admin, then app compose env | `LOGTO_APP_ID`, `LOGTO_APP_SECRET` |
| Umami tracking | Umami UI, then app compose env | `UMAMI_WEBSITE_ID` |
| useSend login | GitHub OAuth app, then useSend compose env | `USESEND_GITHUB_ID`, `USESEND_GITHUB_SECRET` |
| useSend sending | AWS SES/SNS and useSend UI | `AWS_DEFAULT_REGION`, `AWS_ACCESS_KEY`, `AWS_SECRET_KEY` |
| App email | useSend UI, then app compose env | `USESEND_API_KEY` |
| Logto email | Logto Admin SMTP connector | useSend API key as SMTP password |

## 1. Logto App

Open:

```text
https://auth-admin.<domain>
```

Create a Traditional Web App in Logto.

Use these URLs:

```text
Redirect URI: https://<app-domain>/callback
Post sign-out redirect URI: https://<app-domain>/
```

`<app-domain>` is the apex domain by default, for example `example.com`. If you
used `--app-domain`, use that host instead.

Open the `hostr-app` compose service in Dokploy and set:

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

Use the actual app domain here. By default that is the apex domain.

Open the `hostr-app` compose service in Dokploy and set:

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

Open the `usesend` compose service in Dokploy and set:

```sh
USESEND_GITHUB_ID=<github-client-id>
USESEND_GITHUB_SECRET=<github-client-secret>
```

Redeploy `usesend`. Expected result: `https://mail.<domain>` redirects to GitHub
and returns to useSend after authorization.

## 4. useSend Sending

useSend sends through AWS SES and uses SNS for delivery, bounce, and complaint
events.

In AWS, set up access for useSend. Do not manually verify the sending domain in
SES first when you want useSend to manage it.

1. Pick an SES region.
2. Create IAM credentials for useSend.
3. Start broad enough to prove the flow, then narrow permissions for production.
4. Request SES production access if the account is still in sandbox mode.

Open the `usesend` compose service in Dokploy and set:

```sh
AWS_DEFAULT_REGION=<aws-region>
AWS_ACCESS_KEY=<aws-access-key-id>
AWS_SECRET_KEY=<secret-access-key>
```

Redeploy `usesend`, then open the useSend UI:

```text
https://mail.<domain>
```

When useSend asks for **Add SES Settings**, use:

```text
Region: <aws-region>
Callback URL: https://mail.<domain>
Send Rate: 1
Transactional Quota: 80
```

The SES callback URL is the public base URL of the useSend instance. Do not use
the main app URL and do not use the GitHub OAuth callback path here. The GitHub
OAuth callback remains:

```text
https://mail.<domain>/api/auth/callback/github
```

Then add the sending domain inside useSend:

1. Go to **Domains**.
2. Add the domain you want to send from, for example `<domain>`.
3. Add the DNS records useSend shows you.
4. Verify the domain from useSend.
5. Create a useSend API key under developer settings.

For app-level email, put that API key on the `hostr-app` compose service in
Dokploy:

```sh
USESEND_API_URL=https://mail.<domain>/api
USESEND_API_KEY=<usesend-api-key>
```

Redeploy `hostr-app`. Keep this key server-side only. Do not expose it as a
`NEXT_PUBLIC_` variable.

Do not create a separate SES identity for the same sending domain before adding
it in useSend. If you already created the identity manually in SES, either delete
that SES identity and add the domain through useSend, or use a dedicated sending
subdomain such as `send.<domain>`.

If you already have SPF or DMARC records, do not add duplicate SPF records for
the same host. Merge SPF into one TXT record when needed. DKIM records are
provider-specific, so add the DKIM record useSend gives you.

If useSend asks you to add MX or TXT records on `mail.<domain>`, also keep an
explicit DNS A record for `mail.<domain>` pointing to the VPS IP. A wildcard
record like `* -> <server-ip>` does not supply an A record for `mail.<domain>`
once MX or TXT records exist at that same host.

SES sandbox mode can block real recipient delivery until AWS grants production
access.

## 5. Logto Email

This is required for real verification and password reset emails.

The default stack includes useSend's SMTP proxy on the private Docker network so
Logto can send auth emails through useSend without exposing SMTP ports publicly.
The SMTP proxy forwards mail to the useSend API.

Recommended order:

1. Finish useSend sending and verify the sending domain.
2. Create a useSend API key under **Developer Settings**.
3. Open Logto Admin at `https://auth-admin.<domain>`.
4. Go to **Connectors** and add the **SMTP** email connector.
5. Use these SMTP settings:

```text
Host: usesend-smtp
Port: 587
Username: usesend
Password: <usesend-api-key>
Secure: off
Ignore TLS: off
Require TLS: on
TLS: {"rejectUnauthorized": false}
From email: noreply@<verified-sending-domain>
Sender name: <your-product-name>
```

`usesend-smtp` is the internal Docker service name. Use that value in Logto, not
`mail.<domain>`. The API key is entered in Logto Admin as the SMTP password; it
does not need to be added to the `logto` compose service environment. The SMTP
connection stays inside the private Docker network. The stack mounts a
self-signed certificate into the useSend SMTP proxy so Logto can issue STARTTLS
before sending the API key as the SMTP password. `rejectUnauthorized` is disabled
because the certificate is internal and self-signed.

6. Send a test email from Logto.

Expected result: Logto can deliver verification and password reset emails from
your domain.

## Readiness Checklist

The stack is ready for product work when:

- `https://<app-domain>` loads.
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
