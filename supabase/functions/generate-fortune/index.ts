// Internal generation worker. This is not a client-callable start endpoint.
// The handler accepts only the server secret in the apikey header.

import { createClient } from 'npm:@supabase/supabase-js@2';
import {
  OpenRouterNemotronProvider,
  OpenRouterProviderError,
  type FortuneProviderInput,
} from '../_shared/openrouter_provider.ts';

const jsonHeaders = { 'Content-Type': 'application/json' };
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const FORBIDDEN_CONTENT = /<\s*(script|iframe|object)\b|\b(죽음|자살|중병|사고|범죄 피해|임신|유산|파산|복권 당첨)\b/i;

type SessionRow = {
  id: string;
  user_id: string;
  fortune_date: string;
  generation_status: string;
  entitlement_status: string;
  generation_epoch: number;
  provider_set_version: string;
  generation_input_snapshot: FortuneProviderInput | null;
};

function response(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function isText(value: unknown): value is string {
  return typeof value === 'string' && value.trim().length > 0 && value.length <= 500;
}

function isCatStyleSentence(value: string): boolean {
  return /냥[.!?]?$/u.test(value.trim());
}

function validateFortunePayload(raw: string): Record<string, unknown> {
  if (new TextEncoder().encode(raw).byteLength > 32 * 1024) throw new OpenRouterProviderError('invalid_response');
  let value: unknown;
  try {
    value = JSON.parse(raw);
  } catch {
    throw new OpenRouterProviderError('invalid_response');
  }
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new OpenRouterProviderError('schema_invalid');
  }
  const payload = value as Record<string, unknown>;
  const textFields = ['headline'];
  for (const field of textFields) {
    if (!isText(payload[field]) || !isCatStyleSentence(payload[field])) {
      throw new OpenRouterProviderError('schema_invalid');
    }
  }
  const ratings = payload.ratings;
  if (typeof ratings !== 'object' || ratings === null || Array.isArray(ratings)) {
    throw new OpenRouterProviderError('schema_invalid');
  }
  for (const field of ['overall', 'money', 'love', 'career', 'relationship', 'condition']) {
    const rating = (ratings as Record<string, unknown>)[field];
    if (!Number.isInteger(rating) || (rating as number) < 1 || (rating as number) > 5) {
      throw new OpenRouterProviderError('schema_invalid');
    }
  }
  for (const field of ['overall', 'money', 'love', 'career', 'relationship', 'condition', 'recommended_actions', 'avoid_actions']) {
    const items = payload[field];
    const expectedLength = field === 'overall' ? 5 : 3;
    if (!Array.isArray(items) || items.length !== expectedLength || !items.every((item) => isText(item) && isCatStyleSentence(item))) {
      throw new OpenRouterProviderError('schema_invalid');
    }
  }
  const lucky = payload.lucky;
  if (typeof lucky !== 'object' || lucky === null || Array.isArray(lucky)) {
    throw new OpenRouterProviderError('schema_invalid');
  }
  const luckyRecord = lucky as Record<string, unknown>;
  if (!Number.isInteger(luckyRecord.number) || (luckyRecord.number as number) < 1 || (luckyRecord.number as number) > 99) {
    throw new OpenRouterProviderError('schema_invalid');
  }
  if (!isText(luckyRecord.color) || !isText(luckyRecord.keyword) || !isText(luckyRecord.time)) {
    throw new OpenRouterProviderError('schema_invalid');
  }
  const allText = JSON.stringify(payload);
  if (FORBIDDEN_CONTENT.test(allText)) throw new OpenRouterProviderError('content_invalid');
  return payload;
}

function normalizeWorkerError(error: unknown): string {
  if (error instanceof OpenRouterProviderError) return error.code;
  return 'unknown';
}

function isTrustedWorker(request: Request): boolean {
  const supplied = request.headers.get('apikey');
  const trusted = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SECRET_KEY');
  return Boolean(supplied && trusted && supplied === trusted);
}

const supabaseUrl = Deno.env.get('SUPABASE_URL');
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
if (!supabaseUrl || !serviceRoleKey) throw new Error('SERVER_CONFIG_MISSING');
const admin = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false, autoRefreshToken: false } });

Deno.serve(async (request) => {
  if (request.method !== 'POST') return response(405, { code: 'METHOD_NOT_ALLOWED' });
  if (!isTrustedWorker(request)) return response(401, { code: 'WORKER_UNAUTHORIZED' });

  let body: { session_id?: unknown; generation_epoch?: unknown };
  try {
    body = await request.json();
  } catch {
    return response(400, { code: 'INVALID_JSON' });
  }
  if (typeof body.session_id !== 'string' || !UUID_PATTERN.test(body.session_id) || !Number.isInteger(body.generation_epoch)) {
    return response(400, { code: 'INVALID_WORKER_REQUEST' });
  }

  const { data: session, error: sessionError } = await admin
    .from('daily_fortune_sessions')
    .select('id,user_id,fortune_date,generation_status,entitlement_status,generation_epoch,provider_set_version,generation_input_snapshot')
    .eq('id', body.session_id)
    .eq('generation_epoch', body.generation_epoch)
    .maybeSingle<SessionRow>();
  if (sessionError || !session) return response(409, { code: 'STALE_GENERATION' });
  if (!['generating', 'recovery_pending'].includes(session.generation_status)) {
    return response(409, { code: 'GENERATION_NOT_ALLOWED' });
  }
  if (!session.generation_input_snapshot) return response(409, { code: 'GENERATION_SNAPSHOT_MISSING' });
  if (session.provider_set_version !== 'dev-openrouter-nemotron-v1') {
    return response(409, { code: 'PROVIDER_SET_NOT_APPROVED' });
  }

  const provider = new OpenRouterNemotronProvider();
  try {
    const result = await provider.generate(session.generation_input_snapshot);
    const payload = validateFortunePayload(result.rawContent);
    const { data: committed, error: commitError } = await admin.rpc('commit_fortune_generation', {
      session_id_value: session.id,
      generation_epoch_value: session.generation_epoch,
      payload_value: payload,
      provider_id_value: result.providerId,
      model_name_value: result.modelName,
      provider_request_id_value: result.providerRequestId,
    });
    if (commitError || committed !== true) return response(409, { code: 'STALE_GENERATION' });
    return response(200, { status: 'ready', session_id: session.id });
  } catch (error) {
    const normalizedError = normalizeWorkerError(error);
    const { error: failureError } = await admin.rpc('record_generation_failure', {
      session_id_value: session.id,
      generation_epoch_value: session.generation_epoch,
      error_class_value: normalizedError,
    });
    if (failureError) return response(500, { code: 'GENERATION_FAILURE_RECORD_FAILED' });
    return response(502, { code: normalizedError });
  }
});
