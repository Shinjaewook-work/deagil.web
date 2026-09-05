const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const vm = require('node:vm');
const ts = require('typescript');
const React = require('react');
const flush = () => new Promise(setImmediate);

function fixture() {
  const listeners = new Map();
  const calls = [];
  const ui = { busy: false, error: '' };
  const slot = { addService: () => {} };
  const pubads = {
    addEventListener: (name, callback) => { if (!listeners.has(name)) listeners.set(name, new Set()); listeners.get(name).add(callback); },
    removeEventListener: (name, callback) => listeners.get(name)?.delete(callback),
  };
  const gpt = {
    cmd: { push: (callback) => callback() },
    enums: { OutOfPageFormat: { REWARDED: 1 } },
    defineOutOfPageSlot: () => slot, pubads: () => pubads,
    enableServices: () => calls.push('enable'),
    display: () => calls.push('display'),
    destroySlots: () => calls.push('destroy'),
  };
  const client = {
    rpc: async () => ({ data: { gate: 'NONE', fortune_state: 'LOCKED' }, error: null }),
    functions: { invoke: async (name) => {
      calls.push(name);
      return { data: { ad_attempt_id: 'synthetic-attempt' }, error: null };
    } },
  };
  const state = { gate: 'NONE', fortune_state: 'LOCKED', birth_profile_exists: true, can_prepare_rewarded_ad: true };
  const seeds = ['today', [], new Set(), false, state, false, false, true, true, '', false];
  let hook = 0;
  const modules = {};
  function load(path) {
    if (modules[path]) return modules[path];
    const exports = {};
    modules[path] = exports;
    vm.runInNewContext(ts.transpileModule(readFileSync(path, 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.CommonJS, jsx: ts.JsxEmit.ReactJSX, target: ts.ScriptTarget.ES2022 },
    }).outputText, {
      exports, setTimeout, clearTimeout, AbortController,
      crypto: { randomUUID: () => 'synthetic-request' },
      window: { googletag: gpt },
      process: { env: { NEXT_PUBLIC_WEB_REWARDED_AD_UNIT: '/synthetic/rewarded' } },
      require: (name) => {
        if (name === 'react') return {
          ...React, useMemo: (f) => f(), useCallback: (f) => f, useEffect: () => {}, useRef: (value) => ({ current: value }),
          useState: (initial) => { const index = hook++; return [index < seeds.length ? seeds[index] : initial, (value) => { if (index === 5) ui.busy = value; if (index === 9) ui.error = value; }]; },
        };
        if (name === '@/lib/supabase') return { getSupabaseClient: () => client };
        if (name.startsWith('@/lib/')) return load(`${__dirname}/${name.slice(6)}.ts`);
        return require(name);
      },
    });
    return exports;
  }
  const page = load(`${__dirname}/../app/page.tsx`).default();
  function findToday(node) {
    if (!node || typeof node !== 'object') return null;
    if (node.type?.name === 'Today') return node;
    for (const child of React.Children.toArray(node.props?.children)) { const found = findToday(child); if (found) return found; }
    return null;
  }
  return {
    ui, calls, gpt, slot, listeners, client,
    run: (options) => load(`${__dirname}/web-rewarded.ts`).runWebRewardedAd({
      gpt, unit: '/synthetic/rewarded', signal: new AbortController().signal,
      onImpression: async () => calls.push('impression'),
      onReward: async () => calls.push('reward'),
      onDismiss: async (reason) => calls.push(reason), ...options,
    }),
    start: () => findToday(page).props.onAd(),
    emit: (name, extra = {}) => { for (const handler of [...(listeners.get(name) ?? [])]) handler({ slot, makeRewardedVisible: () => true, ...extra }); },
  };
}

test('web rewarded flow enables GPT services before display', async () => {
  const f = fixture();
  void f.start(); await flush();
  assert.ok(f.calls.indexOf('enable') >= 0 && f.calls.indexOf('enable') < f.calls.indexOf('display'));
  f.emit('rewardedSlotClosed'); await flush();
});

test('closing without reward ends busy state, dismisses once and removes listeners', async () => {
  const f = fixture();
  void f.start(); await flush();
  f.emit('rewardedSlotClosed'); await flush();
  assert.equal(f.ui.busy, false);
  assert.equal(f.calls.filter((name) => name === 'report-ad-dismissed').length, 1);
  assert.equal(f.calls.includes('claim-ad-reward'), false);
  assert.ok(f.calls.includes('destroy'));
  assert.equal([...f.listeners.values()].reduce((n, list) => n + list.size, 0), 0);
});

test('no-fill ends the flow without claiming a reward', async () => {
  const f = fixture();
  void f.start(); await flush();
  f.emit('slotRenderEnded', { isEmpty: true }); await flush();
  assert.equal(f.ui.busy, false);
  assert.equal(f.calls.includes('claim-ad-reward'), false);
  assert.ok(f.ui.error);
});

test('reward is claimed once but UI stays busy until the ad is closed', async () => {
  const f = fixture();
  void f.start(); await flush();
  f.emit('rewardedSlotReady');
  f.emit('impressionViewable');
  f.emit('rewardedSlotGranted');
  f.emit('rewardedSlotGranted'); await flush();
  assert.equal(f.ui.busy, true);
  assert.equal(f.calls.filter((name) => name === 'claim-ad-reward').length, 1);
  f.emit('rewardedSlotClosed'); await flush();
  assert.equal(f.ui.busy, false);
  assert.equal(f.calls.filter((name) => name === 'report-ad-dismissed').length, 1);
});

test('same-tick double ad activation prepares only one server attempt', async () => {
  const f = fixture();
  void f.start(); void f.start(); await flush();
  assert.equal(f.calls.filter((name) => name === 'prepare-ad-session').length, 1);
  f.emit('rewardedSlotClosed'); await flush();
});

test('blocked GPT script times out and a late queued callback cannot show an ad', async () => {
  const f = fixture();
  const queue = [];
  f.gpt.cmd = queue;
  await assert.rejects(f.run({ loadTimeoutMs: 5 }), /WEB_AD_LOAD_TIMEOUT/);
  queue[0]();
  assert.equal(f.calls.includes('display'), false);
  assert.equal(f.calls.filter((name) => name === 'show_failed').length, 1);
});

test('unsupported slot and failed show both release resources without granting', async () => {
  for (const unsupported of [true, false]) {
    const f = fixture();
    if (unsupported) f.gpt.defineOutOfPageSlot = () => null;
    const task = f.run();
    const rejected = assert.rejects(task, /WEB_REWARDED_UNAVAILABLE|WEB_AD_SHOW_FAILED/);
    if (!unsupported) f.emit('rewardedSlotReady', { makeRewardedVisible: () => false });
    await rejected;
    assert.equal(f.calls.includes('reward'), false);
    assert.equal(f.calls.filter((name) => name === 'show_failed').length, 1);
  }
});

test('impression is separate from reward and unrelated slot events are ignored', async () => {
  const f = fixture();
  const task = f.run();
  f.emit('rewardedSlotGranted', { slot: {} });
  f.emit('impressionViewable'); f.emit('impressionViewable');
  await flush();
  assert.equal(f.calls.filter((name) => name === 'impression').length, 1);
  assert.equal(f.calls.includes('reward'), false);
  f.emit('rewardedSlotClosed');
  assert.equal(await task, 'dismissed');
});

test('unmount abort cleans up and ignores later reward callbacks', async () => {
  const f = fixture();
  const controller = new AbortController();
  const task = f.run({ signal: controller.signal });
  const rejected = assert.rejects(task, /WEB_AD_CANCELLED/);
  controller.abort();
  await rejected;
  f.emit('rewardedSlotGranted');
  assert.equal(f.calls.includes('reward'), false);
  assert.ok(f.calls.includes('destroy'));
});

test('server reward failure still reports dismissal and does not hang', async () => {
  const f = fixture();
  const task = f.run({ onReward: async () => { throw new Error('synthetic'); } });
  const rejected = assert.rejects(task, /WEB_AD_REPORT_FAILED/);
  f.emit('rewardedSlotGranted');
  await flush();
  f.emit('rewardedSlotClosed');
  await rejected;
  assert.equal(f.calls.filter((name) => name === 'dismissed').length, 1);
});

test('GPT command queue exceptions also release the prepared attempt', async () => {
  const f = fixture();
  f.gpt.cmd.push = () => { throw new Error('synthetic'); };
  await assert.rejects(f.run(), /WEB_AD_SETUP_FAILED/);
  assert.equal(f.calls.filter((name) => name === 'show_failed').length, 1);
});
