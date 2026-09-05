const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');

const migration = readFileSync(`${__dirname}/202609050001_generation_recovery.sql`, 'utf8');
const stateMigration = readFileSync(`${__dirname}/202609050002_recovery_state_flag.sql`, 'utf8');

test('recovery migration keeps the server-side entitlement and current-day fences', () => {
  assert.match(migration, /create or replace function public\.resume_my_fortune_generation\(\)/i);
  assert.match(migration, /current_user_id uuid := auth\.uid\(\)/i);
  assert.match(migration, /entitlement_status = 'none'/i);
  assert.match(migration, /\w+\.generation_status <> 'recovery_pending'/i);
  assert.match(migration, /\w+\.fortune_date <> current_day/i);
  assert.match(migration, /is_fortune_transition_window/i);
  assert.match(migration, /generation_input_snapshot is null/i);
  assert.match(migration, /recovery_round_count/i);
  assert.match(migration, /provider_request_count/i);
});

test('recovery claim changes epoch and status in one locked function', () => {
  assert.match(migration, /for update/i);
  assert.match(migration, /generation_status = 'generating'/i);
  assert.match(migration, /generation_epoch = generation_epoch \+ 1/i);
  assert.match(migration, /grant execute on function public\.resume_my_fortune_generation\(\) to authenticated/i);
});

test('app state exposes a server-authoritative recovery flag', () => {
  assert.match(stateMigration, /create or replace function public\.get_my_app_state\(\)/i);
  assert.match(stateMigration, /can_resume_generation/i);
  assert.match(stateMigration, /required_for_ai/i);
  assert.match(stateMigration, /max_provider_requests_per_session/i);
  assert.match(stateMigration, /max_recovery_rounds_per_session/i);
  assert.doesNotMatch(stateMigration, /singleton_id/i);
});
