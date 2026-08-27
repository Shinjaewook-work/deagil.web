import { createClient } from 'npm:@supabase/supabase-js@2';
import { startGenerationIfRequired } from '../_shared/rewarded_ad_helpers.ts';

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
  const normalized = value.replace(/-/g, '+').replace(/_/g, '/');
  const padded = normalized + '='.repeat((4 - normalized.length % 4) % 4);
  const binary = atob(padded);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}
function derToP1363(signature: Uint8Array, componentLength = 32): Uint8Array {
  if (signature[0] !== 0x30) return signature;
  let offset = 2;
  if ((signature[1] & 0x80) !== 0) offset += (signature[1] & 0x7f) - 1;
  if (signature[offset] !== 0x02) throw new Error('SSV_SIGNATURE_FORMAT_INVALID');
  const rLength = signature[offset + 1];
  const rStart = offset + 2;
  const sTag = rStart + rLength;
  if (signature[sTag] !== 0x02) throw new Error('SSV_SIGNATURE_FORMAT_INVALID');
  const sLength = signature[sTag + 1];
  const sStart = sTag + 2;
  const result = new Uint8Array(componentLength * 2);
  const r = signature.slice(rStart, rStart + rLength);
  const s = signature.slice(sStart, sStart + sLength);
  result.set(r.slice(Math.max(0, r.length - componentLength)), componentLength - Math.min(componentLength, r.length));
  result.set(s.slice(Math.max(0, s.length - componentLength)), componentLength * 2 - Math.min(componentLength, s.length));
  return result;
}
async function keyFor(keyId: string): Promise<CryptoKey> {
  const cached = keyCache.get(keyId);
  if (cached) return cached;
  if (!publicKeyUrl) throw new Error('SSV_PUBLIC_KEY_URL_MISSING');
  const response = await fetch(publicKeyUrl);
  if (!response.ok) throw new Error('SSV_KEY_FETCH_FAILED');
  const payload = await response.json() as { keys?: Array<{ keyId?: number; base64?: string; pem?: string }> };
  const entry = payload.keys?.find((item) => String(item.keyId) === keyId);
  if (!entry) throw new Error('SSV_KEY_ID_UNKNOWN');
  const encoded = entry.base64 ?? entry.pem?.replace(/-----BEGIN PUBLIC KEY-----|-----END PUBLIC KEY-----|\s/g, '');
  if (!encoded) throw new Error('SSV_KEY_MATERIAL_MISSING');
  const der = decodeBase64(encoded);
  const key = await crypto.subtle.importKey('spki', der, { name: 'ECDSA', namedCurve: 'P-256' }, false, ['verify']);
  keyCache.set(keyId, key);
  return key;
}

Deno.serve(async (request) => {
  if (request.method !== 'GET') return json(405, { code: 'METHOD_NOT_ALLOWED' });
  const rawQuery = new URL(request.url).search.slice(0, 8193);
  // AdMob's console performs a reachability probe before sending a signed
  // callback. This health check must never grant a reward.
  if (rawQuery.length === 0) return json(200, { status: 'ready' });
  if (rawQuery.length > 8192) return json(400, { code: 'INVALID_QUERY' });
  const params = new URLSearchParams(rawQuery);
  const signature = params.get('signature');
  const keyId = params.get('key_id');
  if (!signature || !keyId) return json(400, { code: 'SIGNATURE_MISSING' });
  const marker = rawQuery.indexOf('signature=');
  const signedQuery = marker >= 0 ? rawQuery.slice(0, marker).replace(/&$/, '') : rawQuery;
  try {
    const verified = await crypto.subtle.verify(
      { name: 'ECDSA', hash: 'SHA-256' }, await keyFor(keyId), derToP1363(decodeBase64(signature)),
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
    const result = data as Record<string, unknown>;
    await startGenerationIfRequired(result);
    return json(200, { status: result.status });
  } catch {
    return json(400, { code: 'SIGNATURE_VERIFICATION_FAILED' });
  }
});
