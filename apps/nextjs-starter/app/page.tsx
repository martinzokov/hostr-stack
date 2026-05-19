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

  const displayName = claims?.name ?? claims?.email ?? claims?.sub;

  return (
    <div className="appShell">
      <header className="header">
        <div className="headerInner">
          <a className="logo" href="/">
            <span className="logoMark" />
            hostr
          </a>
          <div className="headerRight">
            {isAuthenticated ? (
              <div className="profileRow">
                <div className="avatar">{getInitial(displayName)}</div>
                <span className="profileName">{displayName}</span>
                <SignOut
                  onSignOut={async () => {
                    'use server';
                    await signOut(logtoConfig);
                  }}
                />
              </div>
            ) : (
              <SignIn
                disabled={!configured}
                onSignIn={async () => {
                  'use server';
                  await signIn(logtoConfig);
                }}
              />
            )}
          </div>
        </div>
      </header>

      <main className="main">
        <div className="container">
          <section className="hero">
            {isAuthenticated ? (
              <>
                <p className="eyebrow">Welcome back</p>
                <h1>Hello, {displayName?.split(' ')[0] ?? 'there'}.</h1>
                <p className="lede">
                  Your SaaS stack is live and ready. Start building your product.
                </p>
              </>
            ) : (
              <>
                <p className="eyebrow">hostr-stack</p>
                <h1>Hello, World.</h1>
                <p className="lede">
                  A production-ready SaaS starter — auth, database, analytics, and email,
                  all self-hosted on your VPS via Dokploy.
                </p>
                <div className="heroCta">
                  <SignIn
                    disabled={!configured}
                    onSignIn={async () => {
                      'use server';
                      await signIn(logtoConfig);
                    }}
                  />
                  <a className="ghostLink" href="https://github.com/martinzokov/hostr-stack" target="_blank" rel="noopener">
                    View on GitHub
                  </a>
                </div>
              </>
            )}
          </section>

          <section className="stackSection">
            <h2 className="sectionTitle">Stack status</h2>
            <div className="statusGrid">
              <Status label="Auth" value={configured ? 'Logto configured' : 'Add credentials'} ok={configured} />
              <Status label="Database" value="Postgres ready" ok />
              <Status label="Analytics" value="Umami configured" ok />
              <Status label="Email" value="useSend configured" ok />
            </div>
          </section>
        </div>
      </main>

      <footer className="footer">
        <p>hostr-stack · self-hosted SaaS infrastructure</p>
      </footer>
    </div>
  );
}

function getInitial(name?: string) {
  return name?.charAt(0).toUpperCase() ?? '?';
}

function Status({ label, value, ok = false }: { label: string; value: string; ok?: boolean }) {
  return (
    <div className="status">
      <p className="label">{label}</p>
      <p className="statusValue">
        <span className={ok ? 'statusDot statusDot--ok' : 'statusDot statusDot--warn'} />
        {value}
      </p>
    </div>
  );
}
