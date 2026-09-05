import {
  authenticatedClient,
  errorResponse,
  json,
} from '../_shared/rewarded_ad_helpers.ts';
import { serveWithWebCors } from '../_shared/web_cors.ts';

serveWithWebCors(async (request) => {
  if (request.method !== 'POST') return json(405, { code: 'METHOD_NOT_ALLOWED' });
  try {
    const client = await authenticatedClient(request);
    const body = await request.json() as Record<string, unknown>;
    if (typeof body.ad_attempt_id !== 'string' ||
      !['dismissed', 'show_failed'].includes(String(body.terminal_reason))) {
      return json(400, { code: 'INVALID_DISMISSAL_PAYLOAD' });
    }
    const { data, error } = await client.rpc('report_my_ad_dismissed', {
      ad_attempt_id_value: body.ad_attempt_id,
      terminal_reason_value: body.terminal_reason,
    });
    if (error) throw new Error(error.message);
    return json(200, data as Record<string, unknown>);
  } catch (error) {
    return errorResponse(error);
  }
});
