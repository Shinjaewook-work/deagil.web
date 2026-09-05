import { createClient, SupabaseClient } from 'npm:@supabase/supabase-js@2';

const url = Deno.env.get('SUPABASE_URL');
const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

if (!url || !anonKey || !serviceKey) throw new Error('SERVER_CONFIG_MISSING');

const admin = createClient(url, serviceKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

export function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

export async function authenticatedClient(
  request: Request,
): Promise<SupabaseClient> {
  const authorization = request.headers.get('Authorization');
  if (!authorization?.startsWith('Bearer ')) throw new Error('UNAUTHENTICATED');
  const client = createClient(url!, anonKey!, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await client.auth.getUser();
  if (error || !data.user) throw new Error('UNAUTHENTICATED');
  return client;
}

export async function startGenerationIfRequired(payload: Record<string, unknown>): Promise<boolean> {
  if (payload.generation_started !== true) return false;
  try {
    const response = await fetch(`${url}/functions/v1/generate-fortune`, {
      method: 'POST',
      redirect: 'error',
      // Allow the provider's 45s request deadline plus worker/DB overhead.
      signal: AbortSignal.timeout(60_000),
      headers: { 'Content-Type': 'application/json', apikey: serviceKey! },
      body: JSON.stringify({
        session_id: payload.session_id,
        generation_epoch: payload.generation_epoch,
      }),
    });
    if (response.ok) return true;
  } catch {
    // Connection errors and timeout need the same fenced recovery as HTTP errors.
  }
  try {
    const { error } = await admin.rpc('mark_generation_dispatch_failed', {
      session_id_value: payload.session_id,
      generation_epoch_value: payload.generation_epoch,
    });
    if (error) throw new Error('GENERATION_FAILURE_RECORD_FAILED');
  } catch {
    throw new Error('GENERATION_FAILURE_RECORD_FAILED');
  }
  // The RPC may be a stale-epoch no-op. Only get_my_app_state determines state.
  return false;
}

export function errorResponse(error: unknown) {
  const message = error instanceof Error ? error.message : 'UNKNOWN_FAILURE';
  if (message === 'UNAUTHENTICATED') return json(401, { code: message });
  return json(409, { code: message });
}

export function randomOpaqueToken() {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

export async function sha256Hex(value: string) {
  const digest = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}
