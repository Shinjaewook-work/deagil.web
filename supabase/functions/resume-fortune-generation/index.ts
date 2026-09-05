import {
  authenticatedClient,
  errorResponse,
  json,
  startGenerationIfRequired,
} from '../_shared/rewarded_ad_helpers.ts';
import { serveWithWebCors } from '../_shared/web_cors.ts';

serveWithWebCors(async (request) => {
  if (request.method !== 'POST') return json(405, { code: 'METHOD_NOT_ALLOWED' });
  try {
    const client = await authenticatedClient(request);
    const { data, error } = await client.rpc('resume_my_fortune_generation');
    if (error) throw new Error(error.message);
    const result = data as Record<string, unknown>;
    const started = await startGenerationIfRequired(result);
    return json(started ? 200 : 202, result);
  } catch (error) {
    return errorResponse(error);
  }
});
