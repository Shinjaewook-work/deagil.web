# AGENTS.md — Codex Entry

## First Rule

항상 가장 먼저 `LUNA_IMPLEMENTATION_MASTER.md`를 읽는다.

사용자가 다음처럼 말하면:

> `LUNA_IMPLEMENTATION_MASTER.md 읽고 그대로 구현해.`

추가 설명 없이 Master를 최상위 구현 계약으로 사용한다.

## Priority

```text
1. 사용자의 최신 명시 지시
2. LUNA_IMPLEMENTATION_MASTER.md
3. docs/*.md
4. 기존 코드
```

## Every Session

```text
1. Master
2. docs/SESSION_RESUME.md
3. docs/logs/ERROR_LOG.md 검색
4. git status / git diff
5. python scripts/harness_lint.py
6. 현재 Phase/Task 구현
7. format/analyze/test
8. python scripts/repo_guard.py
9. 로그 업데이트
```

## Never

- 제품 기능 임의 추가
- pass 3/3에서 Rewarded Ad 숨김
- OpenAI를 필수 Provider로 고정
- 무료 AI API를 Flutter에서 직접 호출
- mutable `unlock_status` 생성
- 고정 `AI 2회`를 제품 invariant로 사용
- birth profile direct DB write
- client-callable `start-fortune-generation` 추가
- `FULFILLMENT_MISSED`를 새날 current UI state로 표시
- PII/Fortune/prompt/secret 로그
- 과거 규칙 보존용 새 audit/archive 문서 생성

## Documentation Rule

새 문서 생성 전 현재 8개 보조 문서 중 하나에 합칠 수 있는지 먼저 판단한다.
같은 오류 수정 전 `docs/logs/ERROR_LOG.md`를 검색한다.
