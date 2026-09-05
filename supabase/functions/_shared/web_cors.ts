const allowedOrigins = new Set([
  'https://deagil-web-gj8b.vercel.app',
  'https://daegil.allinfoworld119.com',
]);
// Matches the documented Supabase v2 client headers; no cookie credentials.
const allowedHeaders = 'authorization, apikey, content-type, x-client-info, x-retry-count, traceparent, tracestate, baggage';
const allowedHeaderNames = new Set(allowedHeaders.split(', '));
type Handler = (request: Request) => Promise<Response>;

export async function withWebCors(request: Request, handler: Handler): Promise<Response> {
  const origin = request.headers.get('Origin');
  if (origin === null) return handler(request); // Native clients retain existing auth behavior.
  if (!allowedOrigins.has(origin)) return new Response(null, { status: 403 });
  const cors = {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': allowedHeaders,
    'Vary': 'Origin',
  };
  if (request.method === 'OPTIONS') {
    const method = request.headers.get('Access-Control-Request-Method');
    const headers = (request.headers.get('Access-Control-Request-Headers') ?? '').toLowerCase().split(',').map((value) => value.trim()).filter(Boolean);
    if (method !== 'POST' || headers.some((header) => !allowedHeaderNames.has(header))) {
      return new Response(null, { status: 403, headers: cors });
    }
    return new Response(null, { status: 204, headers: cors });
  }
  let response: Response;
  try { response = await handler(request); }
  catch {
    response = new Response(JSON.stringify({ code: 'INTERNAL_ERROR' }), {
      status: 500, headers: { 'Content-Type': 'application/json' },
    });
  }
  const headers = new Headers(response.headers);
  for (const [key, value] of Object.entries(cors)) {
    if (key === 'Vary') headers.append(key, value);
    else headers.set(key, value);
  }
  return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}

export function serveWithWebCors(handler: Handler) {
  Deno.serve((request: Request) => withWebCors(request, handler));
}
