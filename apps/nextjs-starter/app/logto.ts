import type { LogtoNextConfig } from '@logto/next';

const fallbackCookieSecret = 'replace-with-at-least-32-characters';

export const logtoConfig: LogtoNextConfig = {
  appId: process.env.LOGTO_APP_ID ?? '',
  appSecret: process.env.LOGTO_APP_SECRET ?? '',
  endpoint: process.env.LOGTO_ENDPOINT ?? 'http://localhost:3001',
  baseUrl: process.env.LOGTO_BASE_URL ?? 'http://localhost:3000',
  cookieSecret: process.env.LOGTO_COOKIE_SECRET ?? fallbackCookieSecret,
  cookieSecure: process.env.NODE_ENV === 'production',
};

export function hasLogtoCredentials() {
  return Boolean(process.env.LOGTO_APP_ID && process.env.LOGTO_APP_SECRET);
}

