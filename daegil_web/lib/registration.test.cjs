const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const vm = require('node:vm');
const ts = require('typescript');
const api = {};
vm.runInNewContext(ts.transpileModule(readFileSync(`${__dirname}/registration.ts`, 'utf8'), {
  compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
}).outputText, { exports: api, setTimeout, clearTimeout });

const registration = JSON.stringify({ age14PlusAttested: true, displayedDocumentIds: ['synthetic'], acceptedDocumentIds: ['synthetic'] });
function storageFixture() {
  let value = registration;
  return { getItem: () => value, removeItem: () => { value = null; }, setItem: (_, next) => { value = next; } };
}

test('registration RPC error rejects and preserves the pending consent snapshot', async () => {
  const storage = storageFixture();
  const client = { rpc: async () => ({ error: { code: 'SYNTHETIC_REJECTION' } }) };
  await assert.rejects(api.completePendingRegistration(client, storage));
  assert.equal(storage.getItem(), registration);
});

test('confirmed registration clears only its own pending snapshot', async () => {
  const storage = storageFixture();
  const client = { rpc: async () => ({ error: null }) };
  await api.completePendingRegistration(client, storage);
  assert.equal(storage.getItem(), null);
});

test('a newer consent snapshot survives an earlier successful request', async () => {
  const storage = storageFixture();
  const client = { rpc: async () => { storage.setItem('', 'newer-selection'); return { error: null }; } };
  await api.completePendingRegistration(client, storage);
  assert.equal(storage.getItem(), 'newer-selection');
});

test('a pending auth request has a finite deadline', async () => {
  await assert.rejects(api.withAuthDeadline(new Promise(() => {}), 5), /AUTH_REQUEST_TIMEOUT/);
  assert.equal(await api.withAuthDeadline(Promise.resolve('ready')), 'ready');
});

test('only explicit server NONE gate permits app entry', () => {
  for (const state of [null, undefined, {}, { gate: 'REGISTRATION_REQUIRED' }, { gate: 'AI_CONSENT_REQUIRED' }, { gate: 'ACCOUNT_SUSPENDED' }]) {
    assert.equal(api.isRegistrationComplete(state), false);
  }
  assert.equal(api.isRegistrationComplete({ gate: 'NONE' }), true);
});
