import {
  authenticatedClient,
  errorResponse,
  json,
  startGenerationIfRequired,
} from '../_shared/rewarded_ad_helpers.ts';

Deno.serve(async (request) => {
  if (request.method !== 'POST') return json(405, { code: 'METHOD_NOT_ALLOWED' });
  try {
    const client = await authenticatedClient(request);
    const body = await request.json() as Record<string, unknown>;
    if (typeof body.ad_attempt_id !== 'string') {
      return json(400, { code: 'INVALID_AD_ATTEMPT_ID' });
    }
    const { data, error } = await client.rpc('report_my_ad_impression', {
      ad_attempt_id_value: body.ad_attempt_id,
    });
    if (error) throw new Error(error.message);
    const result = data as Record<string, unknown>;
    await startGenerationIfRequired(result);
    return json(200, result);
  } catch (error) {
    return errorResponse(error);
  }
});
