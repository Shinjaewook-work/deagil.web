const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const ts = require('../../../daegil_web/node_modules/typescript');

function fixture(networkFails) {
  let handler;
  const calls = [];
  const client = {
    auth: { getUser: async () => ({ data: { user: { id: 'synthetic-user' } }, error: null }) },
    rpc: async (name) => {
      calls.push(name);
      return { data: name === 'use_my_fortune_pass' ? { status: 'reserved', session_id: 'synthetic-session', generation_epoch: 4 } : true, error: null };
    },
  };
  function load(file) {
    const exports = {};
    vm.runInNewContext(ts.transpileModule(readFileSync(file, 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
    }).outputText, {
      exports, Response, Request, Headers, AbortSignal,
      Deno: { env: { get: () => 'synthetic-config' }, serve: (f) => { handler = f; } },
      fetch: async () => { calls.push('worker'); if (networkFails) throw new Error('synthetic-network'); return new Response(null, { status: 200 }); },
      require: (name) => name.startsWith('npm:') ? { createClient: () => client } : load(path.resolve(path.dirname(file), name)),
    });
    return exports;
  }
  load(`${__dirname}/index.ts`);
  return { call: () => handler(new Request('https://synthetic.invalid', { method: 'POST', headers: { Authorization: 'Bearer synthetic-token' } })), calls };
}

test('pass reservation survives failed worker dispatch without a second reservation or invented ready state', async () => {
  const f = fixture(true);
  const response = await f.call();
  assert.equal(response.status, 202);
  assert.equal((await response.json()).generation_status, undefined);
  assert.deepEqual(f.calls, ['use_my_fortune_pass', 'worker', 'mark_generation_dispatch_failed']);
});

test('successful pass dispatch does not schedule failure recovery', async () => {
  const f = fixture(false);
  assert.equal((await f.call()).status, 200);
  assert.deepEqual(f.calls, ['use_my_fortune_pass', 'worker']);
});
