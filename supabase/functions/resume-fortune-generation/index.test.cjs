const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const ts = require('../../../daegil_web/node_modules/typescript');

function fixture(workerFails = false) {
  let handler;
  const calls = [];
  const client = {
    auth: { getUser: async () => ({ data: { user: { id: 'synthetic-user' } }, error: null }) },
    rpc: async (name) => {
      calls.push(name);
      return {
        data: name === 'resume_my_fortune_generation'
          ? { status: 'started', session_id: 'synthetic-session', generation_started: true, generation_epoch: 8 }
          : true,
        error: null,
      };
    },
  };
  function load(file) {
    const exports = {};
    vm.runInNewContext(ts.transpileModule(readFileSync(file, 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
    }).outputText, {
      exports, Response, Request, Headers, AbortSignal,
      Deno: { env: { get: () => 'synthetic-config' }, serve: (f) => { handler = f; } },
      fetch: async () => {
        calls.push('worker');
        if (workerFails) throw new Error('synthetic-network');
        return new Response(null, { status: 200 });
      },
      require: (name) => name.startsWith('npm:') ? { createClient: () => client } : load(path.resolve(path.dirname(file), name)),
    });
    return exports;
  }
  load(`${__dirname}/index.ts`);
  return {
    call: (request = new Request('https://synthetic.invalid', {
      method: 'POST', headers: { Authorization: 'Bearer synthetic-token' },
    })) => handler(request),
    calls,
  };
}

test('authenticated recovery claims one bounded generation and dispatches the worker', async () => {
  const f = fixture();
  const response = await f.call();
  assert.equal(response.status, 200);
  assert.deepEqual(f.calls, ['resume_my_fortune_generation', 'worker']);
});

test('worker failure leaves the recovery claim retryable instead of claiming success', async () => {
  const f = fixture(true);
  const response = await f.call();
  assert.equal(response.status, 202);
  assert.deepEqual(f.calls, ['resume_my_fortune_generation', 'worker', 'mark_generation_dispatch_failed']);
});

test('browser preflight is handled without authentication or database access', async () => {
  const f = fixture();
  const response = await f.call(new Request('https://synthetic.invalid', {
    method: 'OPTIONS',
    headers: {
      Origin: 'https://deagil-web-gj8b.vercel.app',
      'Access-Control-Request-Method': 'POST',
      'Access-Control-Request-Headers': 'authorization,apikey,content-type',
    },
  }));
  assert.equal(response.status, 204);
  assert.equal(f.calls.length, 0);
});
