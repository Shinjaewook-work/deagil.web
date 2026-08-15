import { createClient } from 'npm:@supabase/supabase-js@2';

const url = Deno.env.get('SUPABASE_URL');
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const publicKeyUrl = Deno.env.get('ADMOB_SSV_PUBLIC_KEY_URL');
const expectedAdUnitId = Deno.env.get('ADMOB_EXPECTED_AD_UNIT_ID');
const expectedRewardItem = Deno.env.get('ADMOB_EXPECTED_REWARD_ITEM');
const expectedRewardAmount = Number(Deno.env.get('ADMOB_EXPECTED_REWARD_AMOUNT') ?? '0');
const keyCache = new Map<string, CryptoKey>();
if (!url || !serviceKey) throw new Error('SERVER_CONFIG_MISSING');
const admin = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}
function decodeBase64(value: string): Uint8Array {
  const binary = atob(value.replace(/-/g, '+').replace(/_/g, '/'));
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}
async function keyFor(keyId: string): Promise<CryptoKey> {
  const cached = keyCache.get(keyId);
  if (cached) return cached;
  if (!publicKeyUrl) throw new Error('SSV_PUBLIC_KEY_URL_MISSING');
  const response = await fetch(publicKeyUrl);
  if (!response.ok) throw new Error('SSV_KEY_FETCH_FAILED');
  const keys = await response.json() as Record<string, string>;
  const pem = keys[keyId];
  if (!pem) throw new Error('SSV_KEY_ID_UNKNOWN');
  const der = decodeBase64(pem.replace(/-----BEGIN PUBLIC KEY-----|-----END PUBLIC KEY-----|\s/g, ''));
  const key = await crypto.subtle.importKey('spki', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
  keyCache.set(keyId, key);
  return key;
}

Deno.serve(async (request) => {
  if (request.method !== 'GET') return json(405, { code: 'METHOD_NOT_ALLOWED' });
  const rawQuery = new URL(request.url).search.slice(0, 8193);
  if (rawQuery.length === 0 || rawQuery.length > 8192) return json(400, { code: 'INVALID_QUERY' });
  const params = new URLSearchParams(rawQuery);
  const signature = params.get('signature');
  const keyId = params.get('key_id');
  if (!signature || !keyId) return json(400, { code: 'SIGNATURE_MISSING' });
  const marker = rawQuery.indexOf('signature=');
  const signedQuery = marker >= 0 ? rawQuery.slice(0, marker).replace(/&$/, '') : rawQuery;
  try {
    const verified = await crypto.subtle.verify(
      { name: 'RSASSA-PKCS1-v1_5' }, await keyFor(keyId), decodeBase64(signature),
      new TextEncoder().encode(signedQuery),
    );
    if (!verified) return json(400, { code: 'SIGNATURE_INVALID' });
    const customData = params.get('custom_data');
    const transactionId = params.get('transaction_id');
    if (!customData || !transactionId) return json(400, { code: 'CALLBACK_FIELDS_MISSING' });
    const adUnit = params.get('ad_unit');
    const rewardItem = params.get('reward_item');
    const rewardAmount = Number(params.get('reward_amount') ?? '0');
    if (!expectedAdUnitId || !expectedRewardItem || !Number.isFinite(expectedRewardAmount) || expectedRewardAmount <= 0) {
      return json(503, { code: 'SSV_EXPECTED_SPEC_NOT_CONFIGURED' });
    }
    if (adUnit !== expectedAdUnitId || rewardItem !== expectedRewardItem || rewardAmount !== expectedRewardAmount) {
      return json(400, { code: 'REWARD_SPEC_MISMATCH' });
    }
    const { data, error } = await admin.rpc('process_admob_ssv_callback', {
      custom_data_value: customData, transaction_id_value: transactionId,
      reward_timestamp_value: params.get('timestamp_millis') ? new Date(Number(params.get('timestamp_millis'))).toISOString() : new Date().toISOString(),
      ad_unit_id_value: adUnit, reward_item_value: rewardItem, reward_amount_value: rewardAmount,
    });
    if (error) return json(500, { code: 'SSV_PROCESSING_FAILED' });
    return json(200, { status: (data as Record<string, unknown>).status });
  } catch {
    return json(400, { code: 'SIGNATURE_VERIFICATION_FAILED' });
  }
});
