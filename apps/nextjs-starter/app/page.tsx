import { getLogtoContext, signIn, signOut } from '@logto/next/server-actions';
import { hasLogtoCredentials, logtoConfig } from './logto';
import SignIn from './sign-in';
import SignOut from './sign-out';

export const dynamic = 'force-dynamic';

export default async function Home() {
  const configured = hasLogtoCredentials();
  const { isAuthenticated, claims } = configured
    ? await getLogtoContext(logtoConfig)
    : { isAuthenticated: false, claims: undefined };

  return (
    <main className="shell">
      <section className="panel">
        <div>
          <p className="eyebrow">hostr-stack</p>
          <h1>SaaS starter deployed on your VPS</h1>
          <p className="lede">
            Auth, Postgres, analytics, email, and SSL are provisioned through Dokploy.
          </p>
        </div>

        <div className="statusGrid">
          <Status label="Auth" value={configured ? 'Logto configured' : 'Add Logto app credentials'} />
          <Status label="Database" value="Postgres ready" />
          <Status label="Analytics" value="Umami endpoint configured" />
          <Status label="Email" value="useSend endpoint configured" />
        </div>

        <div className="authBox">
          {isAuthenticated ? (
            <>
              <div>
                <p className="label">Signed in</p>
                <p className="subject">{claims?.email ?? claims?.name ?? claims?.sub}</p>
              </div>
              <SignOut
                onSignOut={async () => {
                  'use server';
                  await signOut(logtoConfig);
                }}
              />
            </>
          ) : (
            <>
              <div>
                <p className="label">Session</p>
                <p className="subject">{configured ? 'Signed out' : 'Waiting for Logto credentials'}</p>
              </div>
              <SignIn
                disabled={!configured}
                onSignIn={async () => {
                  'use server';
                  await signIn(logtoConfig);
                }}
              />
            </>
          )}
        </div>
      </section>
    </main>
  );
}

function Status({ label, value }: { label: string; value: string }) {
  return (
    <div className="status">
      <p className="label">{label}</p>
      <p>{value}</p>
    </div>
  );
}
