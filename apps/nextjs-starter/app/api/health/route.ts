export const dynamic = 'force-dynamic';

export async function GET() {
  return Response.json({
    ok: true,
    service: 'hostr-nextjs-starter',
    timestamp: new Date().toISOString(),
  });
}

