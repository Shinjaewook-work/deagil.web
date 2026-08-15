# Current Task

현재 repository에 Flutter scaffold가 없다면:

```text
Phase 0 — Safe Flutter repository bootstrap
```

## Goal

기존 Harness를 보존하면서 Flutter scaffold를 만들고 기본 dev/prod config와 quality command를 준비한다.

## Out of Scope

```text
Supabase schema
OAuth
AdMob production
Firebase production
real AI provider
```

## Verify

```text
python scripts/harness_lint.py
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
python scripts/repo_guard.py
git diff
```

완료 후 `docs/SESSION_RESUME.md` 갱신.
