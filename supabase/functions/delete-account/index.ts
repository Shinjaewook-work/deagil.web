import { createClient } from 'npm:@supabase/supabase-js@2';

const url = Deno.env.get('SUPABASE_URL');
const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
if (!url || !anonKey || !serviceKey) throw new Error('SERVER_CONFIG_MISSING');

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') return json(405, { code: 'METHOD_NOT_ALLOWED' });
  const authorization = request.headers.get('Authorization');
  if (!authorization?.startsWith('Bearer ')) return json(401, { code: 'UNAUTHENTICATED' });
  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await userClient.auth.getUser();
  if (error || !data.user) return json(401, { code: 'UNAUTHENTICATED' });
  const admin = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const { error: deleteError } = await admin.auth.admin.deleteUser(data.user.id);
  if (deleteError) return json(502, { code: 'ACCOUNT_DELETE_FAILED' });
  return json(200, { status: 'deleted' });
});
