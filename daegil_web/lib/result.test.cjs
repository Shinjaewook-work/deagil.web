const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const vm = require('node:vm');
const ts = require('typescript');
const React = require('react');
const { renderToStaticMarkup } = require('react-dom/server');

function renderResult(state) {
  // Drive the actual page's result branch without a network or a real account.
  const seeds = ['result', [], new Set(), false, state, false, false, true, true, '', false];
  let hook = 0;
  const exports = {};
  const source = readFileSync(`${__dirname}/../app/page.tsx`, 'utf8');
  vm.runInNewContext(ts.transpileModule(source, {
    compilerOptions: { module: ts.ModuleKind.CommonJS, jsx: ts.JsxEmit.ReactJSX, target: ts.ScriptTarget.ES2022 },
  }).outputText, {
    exports,
    require: (name) => {
      if (name === 'react') return { ...React, useMemo: (f) => f(), useCallback: (f) => f, useEffect: () => {}, useRef: (value) => ({ current: value }), useState: (initial) => [hook < seeds.length ? seeds[hook++] : initial, () => {}] };
      if (name === '@/lib/supabase') return { getSupabaseClient: () => ({}) };
      if (name === '@/lib/registration') return { isRegistrationComplete: (value) => value?.gate === 'NONE' };
      if (name === '@/lib/web-rewarded') return {};
      return require(name);
    },
  });
  return renderToStaticMarkup(React.createElement(exports.default));
}

test('remote result without a payload shows a recoverable error, never a sample fortune', () => {
  const html = renderResult({ gate: 'NONE', fortune_state: 'UNLOCKED', fortune_payload: null });
  assert.match(html, /결과를 불러오지 못했어요/);
  assert.doesNotMatch(html, /오늘은 속도보다 순서를/);
});

test('a locked or gated state never renders a retained fortune payload', () => {
  for (const state of [
    { gate: 'NONE', fortune_state: 'LOCKED' },
    { gate: 'AI_CONSENT_REQUIRED', fortune_state: 'UNLOCKED' },
  ]) {
    const html = renderResult({ ...state, fortune_payload: { headline: 'SYNTHETIC_PRIVATE_HEADLINE', overall: ['synthetic'] } });
    assert.doesNotMatch(html, /SYNTHETIC_PRIVATE_HEADLINE/);
    assert.match(html, /결과를 불러오지 못했어요/);
  }
});

test('an unlocked ungated response displays the actual server headline', () => {
  const html = renderResult({ gate: 'NONE', fortune_state: 'UNLOCKED', fortune_payload: { headline: 'SYNTHETIC_SERVER_HEADLINE', overall: ['synthetic'] } });
  assert.match(html, /SYNTHETIC_SERVER_HEADLINE/);
  assert.doesNotMatch(html, /결과를 불러오지 못했어요/);
});
