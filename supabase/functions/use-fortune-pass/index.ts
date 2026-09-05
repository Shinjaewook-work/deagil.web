import { createClient } from 'npm:@supabase/supabase-js@2';
import { serveWithWebCors } from '../_shared/web_cors.ts';
import { startGenerationIfRequired } from '../_shared/rewarded_ad_helpers.ts';

const headers = { 'Content-Type': 'application/json' };
const url = Deno.env.get('SUPABASE_URL');
const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
if (!url || !anonKey || !serviceKey) throw new Error('SERVER_CONFIG_MISSING');

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers });
}

serveWithWebCors(async (request) => {
  if (request.method !== 'POST') return json(405, { code: 'METHOD_NOT_ALLOWED' });
  const authorization = request.headers.get('Authorization');
  if (!authorization?.startsWith('Bearer ')) return json(401, { code: 'UNAUTHENTICATED' });
  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) return json(401, { code: 'UNAUTHENTICATED' });
  const { data: reservation, error: reservationError } = await userClient.rpc('use_my_fortune_pass');
  if (reservationError) return json(409, { code: reservationError.message });
  const reservationMap = reservation as Record<string, unknown>;
  if (reservationMap.status !== 'reserved') return json(200, reservationMap);

  const completed = await startGenerationIfRequired({
    ...reservationMap, generation_started: true,
  });
  return json(completed ? 200 : 202, reservationMap);
});
