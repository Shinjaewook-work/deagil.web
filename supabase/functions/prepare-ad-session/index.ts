import {
  authenticatedClient,
  errorResponse,
  json,
  randomOpaqueToken,
  sha256Hex,
} from '../_shared/rewarded_ad_helpers.ts';

const securityMode = Deno.env.get('AD_SECURITY_MODE') ?? 'fast';
const androidAdUnitId = Deno.env.get('ADMOB_EXPECTED_AD_UNIT_ID');
const iosAdUnitId = Deno.env.get('ADMOB_EXPECTED_IOS_AD_UNIT_ID');
const rewardItem = Deno.env.get('ADMOB_EXPECTED_REWARD_ITEM');
const rewardAmount = Number(Deno.env.get('ADMOB_EXPECTED_REWARD_AMOUNT') ?? '0');

Deno.serve(async (request) => {
  if (request.method !== 'POST') return json(405, { code: 'METHOD_NOT_ALLOWED' });
  try {
    const client = await authenticatedClient(request);
    const body = await request.json() as Record<string, unknown>;
    const platform = body.platform;
    const prepareRequestId = body.prepare_request_id;
    if (platform !== 'android' && platform !== 'ios') {
      return json(400, { code: 'INVALID_PLATFORM' });
    }
    if (typeof prepareRequestId !== 'string') {
      return json(400, { code: 'INVALID_PREPARE_REQUEST_ID' });
    }
    const expectedAdUnitId = platform === 'android' ? androidAdUnitId : iosAdUnitId;
    if (!expectedAdUnitId || !rewardItem || !Number.isFinite(rewardAmount) || rewardAmount <= 0) {
      return json(503, { code: 'AD_REWARD_SPEC_NOT_CONFIGURED' });
    }
    if (!['fast', 'reward_gated', 'ssv_strict'].includes(securityMode)) {
      return json(503, { code: 'AD_SECURITY_MODE_INVALID' });
    }
    const customData = randomOpaqueToken();
    const { data, error } = await client.rpc('prepare_my_ad_session', {
      prepare_request_id_value: prepareRequestId,
      challenge_hash_value: await sha256Hex(customData),
      security_mode_value: securityMode,
      expected_ad_unit_id_value: expectedAdUnitId,
      expected_reward_item_value: rewardItem,
      expected_reward_amount_value: rewardAmount,
    });
    if (error) throw new Error(error.message);
    const result = data as Record<string, unknown>;
    if (result.status !== 'prepared') {
      return json(409, { code: 'AD_ATTEMPT_ALREADY_PREPARED' });
    }
    return json(200, { ...result, custom_data: customData });
  } catch (error) {
    return errorResponse(error);
  }
});
