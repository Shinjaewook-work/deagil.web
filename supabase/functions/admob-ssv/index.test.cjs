const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { resolve } = require('node:path');
const vm = require('node:vm');
const { generateKeyPairSync, sign, webcrypto } = require('node:crypto');
const ts = require('../../../daegil_web/node_modules/typescript');

// Exercise the actual handler with real ECDSA signatures and isolated services.
// These keys and callbacks are synthetic; no live reward or user data is used.
function fixture() {
  const { privateKey, publicKey } = generateKeyPairSync('ec', { namedCurve: 'prime256v1' });
  const calls = [];
  const env = {
    SUPABASE_URL: 'https://synthetic.supabase.co',
    SUPABASE_SERVICE_ROLE_KEY: 'synthetic-not-a-credential',
    ADMOB_SSV_PUBLIC_KEY_URL: 'https://www.gstatic.com/admob/reward/verifier-keys.json',
    ADMOB_EXPECTED_AD_UNIT_ID: 'ca-app-pub-1234567890123456/1234567890',
    ADMOB_EXPECTED_REWARD_ITEM: 'fortune',
    ADMOB_EXPECTED_REWARD_AMOUNT: '1',
  };
  let handler;
  const source = readFileSync(resolve(__dirname, 'index.ts'), 'utf8');
  const { outputText } = ts.transpileModule(source, {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
  });
  vm.runInNewContext(outputText, {
    exports: {}, URL, URLSearchParams, Response, TextEncoder, Uint8Array, atob,
    crypto: webcrypto,
    Deno: { env: { get: (name) => env[name] }, serve: (callback) => { handler = callback; } },
    fetch: async () => Response.json({ keys: [{
      keyId: 123,
      base64: publicKey.export({ type: 'spki', format: 'der' }).toString('base64'),
    }] }),
    require: (name) => {
      if (name === 'npm:@supabase/supabase-js@2') return {
        createClient: () => ({ rpc: async (name, args) => {
          calls.push({ name, args });
          return { data: { status: 'rejected' }, error: null };
        } }),
      };
      if (name === '../_shared/rewarded_ad_helpers.ts') return {
        startGenerationIfRequired: async () => {},
      };
      throw new Error('Unexpected test dependency');
    },
  });
  function callback(query) {
    const signature = sign('sha256', Buffer.from(query), privateKey).toString('base64url');
    return `https://synthetic.example/admob-ssv?${query}&signature=${signature}&key_id=123`;
  }
  return { handler, calls, callback };
}

const rewardTime = Date.now() - 1000;
const query = `ad_network=1&ad_unit=ca-app-pub-1234567890123456%2F1234567890&custom_data=synthetic%2Btoken&reward_amount=1&reward_item=fortune&timestamp=${rewardTime}&transaction_id=synthetic`;

test('valid Google-shaped signed query verifies without the URL question mark', async () => {
  const { handler, calls, callback } = fixture();
  const response = await handler(new Request(callback(query)));
  assert.equal(response.status, 200, await response.text());
  assert.equal(calls.length, 1);
  assert.equal(calls[0].args.custom_data_value, 'synthetic+token');
});

test('numeric ad unit resolves to configured full ID and preserves signed reward time', async () => {
  const { handler, calls, callback } = fixture();
  const response = await handler(new Request(callback(query.replace('ca-app-pub-1234567890123456%2F1234567890', '1234567890'))));
  assert.equal(response.status, 200, await response.text());
  assert.equal(calls[0].args.ad_unit_id_value, 'ca-app-pub-1234567890123456/1234567890');
  assert.equal(calls[0].args.reward_timestamp_value, new Date(rewardTime).toISOString());
});

test('valid signed callbacks for unrelated units or reward specs acknowledge without reward processing', async () => {
  const { handler, calls, callback } = fixture();
  for (const otherQuery of [
    query.replace('ca-app-pub-1234567890123456%2F1234567890', '9999999999'),
    query.replace('ca-app-pub-1234567890123456', 'ca-app-pub-9999999999999999'),
    query.replace('reward_amount=1', 'reward_amount=2'),
  ]) {
    const response = await handler(new Request(callback(otherQuery)));
    assert.equal(response.status, 200);
    assert.equal((await response.json()).status, 'rejected');
  }
  assert.equal(calls.length, 0);
});

test('invalid signed reward timestamp is rejected before reward processing', async () => {
  const { handler, calls, callback } = fixture();
  for (const value of ['', 'NaN', '0', String(Date.now() + 3600000)]) {
    const response = await handler(new Request(callback(query.replace(String(rewardTime), value))));
    assert.equal(response.status, 400);
  }
  assert.equal(calls.length, 0);
});

test('tampered signature and unsigned health probe never reconcile rewards', async () => {
  const { handler, calls, callback } = fixture();
  const response = await handler(new Request(callback(query).replace('reward_amount=1', 'reward_amount=9')));
  assert.equal(response.status, 400);
  assert.equal((await handler(new Request('https://synthetic.example/admob-ssv'))).status, 200);
  assert.equal((await handler(new Request('https://synthetic.example/admob-ssv?custom_data=synthetic'))).status, 400);
  assert.equal((await handler(new Request(`https://synthetic.example/admob-ssv?${'x'.repeat(8193)}`))).status, 400);
  assert.equal(calls.length, 0);
});
