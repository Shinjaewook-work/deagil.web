const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const ts = require('../../../daegil_web/node_modules/typescript');

const origins = ['https://deagil-web-gj8b.vercel.app', 'https://daegil.allinfoworld119.com'];
const endpoints = ['prepare-ad-session', 'report-ad-impression', 'claim-ad-reward', 'report-ad-dismissed', 'use-fortune-pass', 'resume-fortune-generation', 'delete-account'];
function handlerFor(endpoint) {
  let handler;
  let userCalls = 0;
  const json = (status, body) => new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
  function load(file) {
    const exports = {};
    vm.runInNewContext(ts.transpileModule(readFileSync(file, 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
    }).outputText, {
      exports, Request, Response, Headers,
      Deno: { serve: (f) => { handler = f; }, env: { get: () => 'synthetic-config' } },
      require: (name) => {
        if (name.includes('rewarded_ad_helpers')) return {
          json, authenticatedClient: async () => { userCalls++; throw new Error('UNAUTHENTICATED'); },
          errorResponse: () => json(401, { code: 'UNAUTHENTICATED' }),
        };
        if (name.startsWith('npm:')) return { createClient: () => { userCalls++; throw new Error('UNEXPECTED_DB_ACCESS'); } };
        return load(path.resolve(path.dirname(file), name));
      },
    });
    return exports;
  }
  load(path.resolve(__dirname, '..', endpoint, 'index.ts'));
  return { call: (request) => handler(request), userCalls: () => userCalls };
}

for (const endpoint of endpoints) {
  test(`${endpoint}: allowed browser preflight succeeds without auth or DB`, async () => {
    const f = handlerFor(endpoint);
    for (const origin of origins) {
      const response = await f.call(new Request('https://synthetic.invalid/', {
        method: 'OPTIONS', headers: { origin, 'Access-Control-Request-Method': 'POST', 'Access-Control-Request-Headers': 'authorization,apikey,content-type,x-client-info' },
      }));
      assert.equal(response.status, 204);
      assert.equal(response.headers.get('Access-Control-Allow-Origin'), origin);
      assert.match(response.headers.get('Access-Control-Allow-Headers'), /authorization/);
      assert.equal(f.userCalls(), 0);
    }
  });
  test(`${endpoint}: browser CORS does not bypass JWT and native auth is preserved`, async () => {
    const f = handlerFor(endpoint);
    const response = await f.call(new Request('https://synthetic.invalid/', { method: 'POST', headers: { origin: origins[0] } }));
    assert.equal(response.status, 401);
    assert.equal(response.headers.get('Access-Control-Allow-Origin'), origins[0]);
    const native = await f.call(new Request('https://synthetic.invalid/', { method: 'POST' }));
    assert.equal(native.status, 401);
    assert.equal(native.headers.get('Access-Control-Allow-Origin'), null);
  });
  test(`${endpoint}: unapproved browser origin cannot execute the handler`, async () => {
    const f = handlerFor(endpoint);
    for (const origin of ['https://untrusted.invalid', 'null', `${origins[0]}.untrusted.invalid`]) {
      const response = await f.call(new Request('https://synthetic.invalid/', { method: 'POST', headers: { origin } }));
      assert.equal(response.status, 403);
      assert.equal(response.headers.get('Access-Control-Allow-Origin'), null);
      assert.equal(f.userCalls(), 0);
    }
  });
}
