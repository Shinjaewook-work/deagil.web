const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const vm = require('node:vm');
const ts = require('../../../daegil_web/node_modules/typescript');

function fixture({ networkError = false, status = 200, recordError = false, stale = false, hang = false } = {}) {
  const calls = [];
  let signal;
  const exports = {};
  vm.runInNewContext(ts.transpileModule(readFileSync(`${__dirname}/rewarded_ad_helpers.ts`, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
  }).outputText, {
    exports, Response, AbortSignal: hang ? { timeout: (ms) => {
      assert.equal(ms, 60_000);
      const controller = new AbortController();
      queueMicrotask(() => controller.abort());
      return controller.signal;
    } } : AbortSignal,
    Deno: { env: { get: () => 'synthetic-config' } },
    require: () => ({ createClient: () => ({ rpc: async (name, args) => {
      calls.push({ name, args }); return { data: !stale, error: recordError ? { message: 'synthetic-secret-must-not-escape' } : null };
    } }) }),
    fetch: async (_url, options) => {
      signal = options.signal; calls.push({ name: 'fetch' });
      if (hang) return new Promise((_, reject) => signal.addEventListener('abort', () => reject(new Error('synthetic-timeout')), { once: true }));
      if (networkError) throw new Error('synthetic-network-detail');
      return new Response(null, { status });
    },
  });
  return { start: exports.startGenerationIfRequired, calls, signal: () => signal };
}
const payload = () => ({ generation_started: true, session_id: 'synthetic-session', generation_epoch: 7, generation_status: 'generating' });

test('network rejection records dispatch failure for exactly the claimed epoch', async () => {
  const f = fixture({ networkError: true });
  assert.equal(await f.start(payload()), false);
  assert.equal(f.calls[1]?.name, 'mark_generation_dispatch_failed');
  assert.equal(f.calls[1].args.generation_epoch_value, 7);
  assert.equal(f.calls.length, 2);
});

test('successful dispatch is bounded and does not mark failure', async () => {
  const f = fixture();
  assert.equal(await f.start(payload()), true);
  assert.ok(f.signal() instanceof AbortSignal);
  assert.equal(f.calls.length, 1);
});

test('HTTP worker failure records failure without guessing the authoritative fortune state', async () => {
  const f = fixture({ status: 502 });
  const state = payload();
  assert.equal(await f.start(state), false);
  assert.equal(f.calls[1].name, 'mark_generation_dispatch_failed');
  assert.equal(state.generation_status, 'generating');
});

test('failure recording errors are normalized and not reported as recovery success', async () => {
  const f = fixture({ status: 502, recordError: true });
  await assert.rejects(f.start(payload()), /^Error: GENERATION_FAILURE_RECORD_FAILED$/);
});

test('superseded epochs do not change response state or retry the worker', async () => {
  const f = fixture({ status: 409, stale: true });
  const state = payload();
  assert.equal(await f.start(state), false);
  assert.equal(state.generation_status, 'generating');
  assert.equal(f.calls.length, 2);
});

test('non-owner trigger performs no worker request or failure mutation', async () => {
  const f = fixture();
  assert.equal(await f.start({ generation_started: false }), false);
  assert.equal(f.calls.length, 0);
});

test('a worker timeout aborts dispatch and reaches fenced failure recording', async () => {
  const f = fixture({ hang: true });
  assert.equal(await f.start(payload()), false);
  assert.equal(f.signal().aborted, true);
  assert.equal(f.calls[1].name, 'mark_generation_dispatch_failed');
});
