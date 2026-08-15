# Decision Log — Current Durable Decisions

## DEC-001 — Master is authoritative
`LUNA_IMPLEMENTATION_MASTER.md` is the highest repository implementation contract.

## DEC-002 — Pass 3/3
3/3이어도 Rewarded Ad를 허용한다. Cap은 추가 pass 발급만 제한한다.

## DEC-003 — Reward entitlement
Reward가 인정되면 current-day Fortune을 받을 권리가 생기며 Provider 실패 후 추가 광고/pass를 요구하지 않는다.

## DEC-004 — AI provider
OpenAI는 선택사항. 무료/상용 API 모두 backend ProviderAdapter 뒤에서만 사용한다.

## DEC-005 — Security mode
운영 설정은 `AD_SECURITY_MODE=fast|reward_gated|ssv_strict` 하나만 사용한다.

## DEC-006 — Result access
`unlock_status`를 저장하지 않고 entitlement + ready + current/unexpired 상태에서 server가 파생한다.

## DEC-007 — Pass cap
`available + reserved <= 3`을 원자적으로 강제한다.

## DEC-008 — Consent
Consent는 append-only accepted/withdrawn event로 관리하여 재동의를 허용한다.

## DEC-009 — Birth write
Birth profile은 validated server RPC로만 작성한다.

## DEC-010 — AI audience
AI output은 정확한 나이를 Provider에 추가 전송하지 않고 14+ 공통 안전수준으로 작성한다.
