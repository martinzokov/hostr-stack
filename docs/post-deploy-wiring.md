# Post-Deploy Wiring

This stack deploys and serves over HTTPS after `bin/hostr-stack deploy`, but a few product-level integrations still need provider-specific credentials before the SaaS starter is fully usable.

Use this runbook after the stack is live and `bin/hostr-stack smoke` passes.

## Current Missing Pieces

| Area | Why it is needed | Current placeholder |
| --- | --- | --- |
| Logto application credentials | Lets the Next.js starter sign users in with Logto | `LOGTO_APP_ID=`, `LOGTO_APP_SECRET=` |
| Umami website ID | Lets the starter app send analytics events to Umami | `UMAMI_WEBSITE_ID` unset |
| useSend GitHub OAuth | Lets you log into useSend | `USESEND_GITHUB_ID=replace-with-github-client-id`, `USESEND_GITHUB_SECRET=replace-with-github-client-secret` |
| useSend AWS SES/SNS credentials | Lets useSend send email and receive delivery/bounce status | `AWS_ACCESS_KEY=usesend-local`, `AWS_SECRET_KEY=usesend-local` |
| Logto email connector | Enables production auth email flows such as verification and password reset | not configured |

## 1. Logto App For The Next.js Starter

Open:

```text
https://auth-admin.<root-domain>
```

For the verification VPS this was:

```text
https://auth-admin.verify.178-105-108-173.nip.io
```

Steps:

1. Complete the first-run Logto admin setup if it has not already been done.
2. In Logto Console, create a new application.
3. Choose a traditional web application.
4. Name it something like `hostr-nextjs-starter`.
5. Set the redirect URI:

```text
https://app.<root-domain>/callback
```

6. Set the post sign-out redirect URI:

```text
https://app.<root-domain>/
```

7. Copy the generated application ID and application secret.
8. Put them in `.env`:

```sh
LOGTO_APP_ID=<logto-app-id>
LOGTO_APP_SECRET=<logto-app-secret>
```

9. Redeploy:

```sh
bin/hostr-stack deploy
bin/hostr-stack smoke
```

Expected result:

- `https://app.<root-domain>` shows an enabled sign-in button.
- Clicking sign in redirects to `https://auth.<root-domain>`.
- Successful login returns to `https://app.<root-domain>/callback`, then back to the app.

Automation assessment:

- Automatable after Logto Management API access exists.
- Not fully automatable from a clean install without either Logto admin credentials, a machine-to-machine Management API app, or direct database seeding.
- Recommended future CLI command: `bin/hostr-stack wire logto --admin-email ...` or `bin/hostr-stack wire logto --management-token ...`.

## 2. Umami Website Tracking

Open:

```text
https://umami.<root-domain>
```

For the verification VPS this was:

```text
https://umami.verify.178-105-108-173.nip.io
```

Steps:

1. Sign into Umami.
2. Create a website.
3. Use a name like `hostr app`.
4. Use the tracked domain:

```text
app.<root-domain>
```

5. Copy the website ID.
6. Add it to `.env`:

```sh
UMAMI_WEBSITE_ID=<umami-website-id>
```

7. Redeploy:

```sh
bin/hostr-stack deploy
```

Expected result:

- The app renders Umami’s script with `data-website-id`.
- Visits to `https://app.<root-domain>` appear in Umami.

Automation assessment:

- Automatable with Umami API credentials.
- Umami exposes self-hosted API endpoints under `/api`, including login and website creation.
- Recommended future CLI command: `bin/hostr-stack wire umami --username ... --password ...`.

## 3. useSend GitHub OAuth Login

useSend requires GitHub OAuth for login in self-hosted mode.

Open GitHub:

```text
https://github.com/settings/developers
```

Steps:

1. Go to Developer settings.
2. Go to OAuth Apps.
3. Create a new OAuth app.
4. Set application name:

```text
hostr useSend
```

5. Set homepage URL:

```text
https://mail.<root-domain>
```

6. Set authorization callback URL:

```text
https://mail.<root-domain>/api/auth/callback/github
```

7. Register the app.
8. Copy the client ID and generate/copy the client secret.
9. Put them in `.env`:

```sh
USESEND_GITHUB_ID=<github-client-id>
USESEND_GITHUB_SECRET=<github-client-secret>
```

10. Redeploy:

```sh
bin/hostr-stack deploy
```

Expected result:

- `https://mail.<root-domain>` loads the useSend UI.
- Login redirects to GitHub.
- GitHub redirects back to `/api/auth/callback/github`.

Automation assessment:

- Not reliably automatable through this repo alone.
- GitHub OAuth App creation is normally done in the GitHub web UI under the user or organization that owns the app.
- Browser automation is possible if an authenticated GitHub session is available, but it is brittle and account-specific.
- Recommended automation boundary: keep creation manual, then automate `.env` update and redeploy once `USESEND_GITHUB_ID` and `USESEND_GITHUB_SECRET` are provided.

## 4. useSend AWS SES/SNS Credentials

useSend uses AWS SES to send mail and SNS for delivery/bounce events.

AWS setup:

1. Open the AWS console.
2. Choose an SES region, usually the same region users are closest to. `us-east-1` is a reasonable default.
3. Verify your sending domain in SES.
4. Configure DNS records that SES gives you.
5. Create an IAM user for useSend.
6. Attach permissions that allow SES sending and SNS management. The useSend guide suggests `AmazonSESFullAccess` and `AmazonSNSFullAccess`; for production, narrow this later.
7. Create an access key for that IAM user.
8. Put the values in `.env`:

```sh
AWS_DEFAULT_REGION=<aws-region>
AWS_ACCESS_KEY=<aws-access-key-id>
AWS_SECRET_KEY=<aws-secret-access-key>
```

useSend setup:

1. Sign into useSend at:

```text
https://mail.<root-domain>
```

2. Follow the in-app SES setup.
3. Add the same AWS region.
4. Add the callback URL when prompted. Use the public app URL:

```text
https://mail.<root-domain>
```

5. Complete any SES/SNS DNS or webhook setup that useSend displays.

Expected result:

- useSend can create/verify sender domains.
- useSend can send transactional email through SES.
- Delivery events, bounces, and complaints can flow back through SNS.

Automation assessment:

- Partially automatable if AWS credentials with IAM, SES, SNS, and Route 53 permissions are provided.
- Not safe to automate by default because it can create IAM users, access keys, DNS records, SES identities, and SNS topics.
- Recommended future CLI command: `bin/hostr-stack wire usesend-aws --profile ... --domain ... --region ...`, gated behind explicit confirmation.

## 5. Logto Email Connector

This is not required for the first sign-in smoke test, but it is required for a production auth system with email verification, password reset, and notification flows.

Recommended approach:

1. Finish useSend AWS setup first.
2. In useSend, create an API key for transactional email.
3. In Logto Admin, open Connectors.
4. Configure an email connector that can send through your chosen provider.
5. Use your verified sender domain.
6. Test email delivery from Logto.

Expected result:

- New-user verification emails work.
- Password reset emails work.
- Logto email templates can be delivered from your own domain.

Automation assessment:

- Automatable only after both sides exist:
  - a useSend API key or SMTP credentials
  - Logto Management API access or admin UI automation
- Recommended future CLI command: `bin/hostr-stack wire logto-email --usesend-api-key ...`.

## Applying Changes

After changing any `.env` value:

```sh
bin/hostr-stack validate
bin/hostr-stack deploy
bin/hostr-stack smoke
```

On the verification VPS, the deployed copy lives at:

```sh
ssh -i ~/.ssh/hetz root@178.105.108.173
cd /opt/hostr-stack-verify
```

Dokploy admin access must stay on HTTPS. The verification VPS uses:

```text
https://dokploy.178-105-108-173.nip.io
```

The Dokploy admin/API bootstrap values created during verification are stored root-only at:

```text
/root/dokploy-admin.env
```

Do not commit real `.env` values.

## Automation Roadmap

| Task | Can automate? | Requirement |
| --- | --- | --- |
| Generate stack secrets | Already automated | `bin/hostr-stack init` |
| Deploy compose and domains to Dokploy | Already automated | `DOKPLOY_DOMAIN`, `DOKPLOY_API_KEY`, `DOKPLOY_ENVIRONMENT_ID`; the CLI always uses HTTPS for Dokploy API access |
| Build default Next.js image | Already automated | local Docker on the deployment host |
| Create Logto app | Partially | Logto Management API token or admin credentials |
| Update `LOGTO_APP_ID` / `LOGTO_APP_SECRET` and redeploy | Yes | values from Logto |
| Create Umami website and set `UMAMI_WEBSITE_ID` | Yes | Umami username/password or API token |
| Create GitHub OAuth app for useSend | Mostly manual | GitHub user/org ownership and UI flow |
| Update useSend GitHub OAuth env and redeploy | Yes | GitHub OAuth client ID/secret |
| Create AWS IAM/SES/SNS resources | Yes, but high-risk | AWS credentials and explicit confirmation |
| Configure useSend SES in app | Partially | useSend session/API support |
| Configure Logto email delivery | Partially | Logto API access plus email provider credentials |

## References

- Logto Next.js App Router quick start: https://docs.logto.io/quick-starts/next-app-router
- Logto Management API application creation: https://bump.sh/logto/doc/logto-management-api/operation/operation-createapplication
- Umami API overview and self-hosted API: https://umami.is/docs/api
- Umami website API: https://docs.umami.is/docs/api/websites
- useSend self-hosting guide: https://docs.usesend.com/self-hosting/overview
- GitHub OAuth app creation: https://docs.github.com/en/developers/apps/creating-an-oauth-app
- AWS SES credentials: https://docs.aws.amazon.com/ses/latest/dg/smtp-credentials.html
