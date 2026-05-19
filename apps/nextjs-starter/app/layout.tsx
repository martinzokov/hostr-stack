import type { Metadata } from 'next';
import './styles.css';

export const metadata: Metadata = {
  title: 'hostr SaaS',
  description: 'Next.js starter for the hostr SaaS stack',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const umamiSrc = process.env.NEXT_PUBLIC_UMAMI_SRC;
  const websiteId = process.env.NEXT_PUBLIC_UMAMI_WEBSITE_ID;

  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>
        {children}
        {umamiSrc && websiteId ? (
          <script async defer data-website-id={websiteId} src={umamiSrc} />
        ) : null}
      </body>
    </html>
  );
}

