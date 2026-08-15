# 오늘의 운세 앱 — Codex Luna Harness v8 Compact

Codex Luna 첫 지시는 이것 하나면 된다.

> **`LUNA_IMPLEMENTATION_MASTER.md를 처음부터 끝까지 읽고 그대로 구현해.`**

## Files

```text
AGENTS.md
LUNA_IMPLEMENTATION_MASTER.md
README.md

docs/
├── SCREEN_SPEC.md
├── DESIGN_SYSTEM.md
├── DATABASE_AND_API.md
├── SECURITY.md
├── AI_PROVIDER.md
├── TEST_PLAN.md
├── EXTERNAL_SETUP.md
├── RELEASE_CHECKLIST.md
├── CURRENT_TASK.md
├── SESSION_RESUME.md
└── logs/
    ├── ERROR_LOG.md
    ├── PROGRESS_LOG.md
    └── DECISION_LOG.md

scripts/
├── harness_lint.py
└── repo_guard.py
```

Harness 문서와 Flutter 프로젝트 소스를 함께 관리한다. 생성된 플랫폼 파일과 로컬 비밀값은 저장소에 넣지 않는다.

## Principle

- Master = 전체 구현 계약.
- 보조 문서 = 빠른 참조용.
- 과거 audit/archive = repository에서 제거.
- Production credential이 없어도 Mock AI Provider와 AdMob test config로 구현을 계속한다.
- 오류는 ERROR_LOG에 root cause + DO_NOT_REPEAT + regression guard를 남긴다.
