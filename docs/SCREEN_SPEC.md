# Screen Spec — v8 Compact

충돌 시 `LUNA_IMPLEMENTATION_MASTER.md`가 우선한다.

## Routes

```text
/auth
/today
/profile/setup
/fortune/result
/settings
/settings/profile
/settings/notification
/settings/privacy
/settings/account
/settings/account/delete
```

Bottom Navigation 없음.

## App Entry

```text
No Auth → /auth
Auth → get_my_app_state()
gate != NONE → gate/legal action
UNLOCKED → /fortune/result
TRANSITION_WINDOW → transition
otherwise → /today
```

Bootstrap 완료 전 Rewarded Ad show 금지.

## Social Login `/auth`

```text
브랜드 / 고양이 visual

□ 만 14세 이상입니다

[server-driven legal items]
□ 서비스 이용약관
□ AI 처리 관련 동의          # 실제 legal config가 consent_required일 때
□ 국외이전 동의              # 실제 provider/legal config가 요구할 때
□ 앱 개선/오류분석 허용      # 선택

[ 카카오로 계속하기 ]
[ Google로 계속하기 ]
[ Apple로 계속하기 ]
```

Rules:
- age + 필수 legal action 전 login disabled.
- 전체동의 convenience checkbox 가능, 개별 항목은 각각 표시.
- 정상 first-run에서 별도 post-login Consent screen 만들지 않음.
- OAuth 후 실제 표시한 legal document IDs를 server에 sync.
- OAuth 중 legal version이 바뀌면 registration/legal update gate.

## Cat Home `/today`

```text
┌─────────────────────────────┐
│ 오늘의 운세          설정 ⚙ │
│                             │
│      🎟 광고 패스권 2 / 3   │
│                             │
│       [ Cat Video ]         │
│                             │
│   [ 알려주겠다냥! 🐾 ]      │
└─────────────────────────────┘
```

Visual priority:

```text
Cat video > CTA > pass badge > decoration
```

CTA:

```text
birth 없음 → /profile/setup
birth 있음 + pass 0 → Reward explanation
birth 있음 + pass 1~3 → pass/ad choice
```

**3/3이어도 광고 선택지 유지.**

## Birth Profile `/profile/setup`

입력:

```text
nickname optional
양력/음력
윤달 — 음력일 때만
생년월일
출생시간: 정확히 / 대략 / 모름
출생국가
출생도시
```

Rules:

```text
unknown → birth_time NULL
00:00 fake unknown 금지
도시/시·군 정도만
정확한 주소/병원명 불필요
```

Save = `upsert_my_birth_profile()`.
Client direct table update 금지.

## Reward Choice

Pass 없음:

```text
오늘의 AI 운세를 알려줄까냥?

광고를 완료하면 오늘의 운세를 확인할 수 있다냥.
운세 생성에 일시적인 문제가 생겨도
추가 광고 없이 다시 준비해주겠다냥.

[ 광고 보고 알려달라냥! ]
[ 다음에 볼래냥 ]
```

Pass 1~3:

```text
[ 🎟 패스권 쓰겠다냥! ]
[ 광고 보고 알려달라냥! ]
[ 취소 ]
```

## Ad Loading / Failure

Loading:

```text
광고를 준비하고 있다냥...
```

Load/show failure before eligible ad interaction:

```text
지금은 광고를 불러오지 못했다냥.
잠시 뒤 다시 시도해달라냥.

[ 다시 시도 ]
```

AI/pass/entitlement mutation 금지.

## REWARD_VERIFYING

`ssv_strict` 전용:

```text
광고 완료를 확인하고 있다냥...
추가 광고를 볼 필요는 없다냥.
```

새 ad/pass CTA 없음.

## GENERATING

```text
운세를 보고 있다냥...
오늘의 흐름을 살펴보고 있어요.
```

Entitlement가 있으면 추가 monetization CTA 없음.

## RECOVERY_PENDING

```text
운세를 다시 준비하고 있다냥.
광고를 또 볼 필요는 없다냥.
준비되는 대로 바로 보여주겠다냥.

[ 다시 확인하기 ]
```

`next_retry_at` 전에는 재시도 disabled/hint.

## READY_LOCKED

Fast mode에서 generation은 ready지만 Reward가 없는 경우:

```text
운세는 이미 준비됐다냥!
광고만 끝까지 완료하면 바로 보여주겠다냥.
```

다음 valid Reward는 기존 result를 unlock.
AI 재생성 금지.

## Result `/fortune/result`

```text
오늘의 AI 운세
날짜
headline
overall rating

overall 5
재물운 3
연애운 3
직장·학업운 3
인간관계운 3
컨디션운 3

오늘 하면 좋다냥 3
오늘은 피하라냥 3

행운: 숫자 / 색상 / 시간 / 키워드

AI disclosure
```

Disclosure:

```text
AI 생성 콘텐츠

이 운세는 생성형 AI가 출생정보와 오늘 날짜를 바탕으로 생성했습니다.

오락·문화 목적으로 제공되며
의료·법률·재무 등 전문적인 판단을 대신하지 않습니다.
```

UNLOCKED same-day re-entry → Result 직행.

## Transition 03:55~03:59:59 KST

```text
새 운세가 곧 시작된다냥.
오전 4시 이후 다시 확인해달라냥.
```

신규 ad/pass/generation/recovery 금지.
기존 unlocked result는 03:59:59까지 읽기 가능.

## Settings

```text
프로필 / 출생정보
알림
개인정보 / 선택 데이터 제공
약관 및 AI 안내
로그아웃
계정 삭제
```

AI consent가 actual legal basis이며 withdrawable이면 설정에서 철회 가능.
철회 후 새 AI/ad/pass 차단.
같은 날 기존 entitlement가 있으면 재동의 + birth re-entry 후 추가 광고 없이 recovery 가능.

## Notification

첫 successful Fortune 이후 contextual permission 권장:

```text
내일도 알려줄까냥?
```

Title:

```text
오늘의 운세가 도착했다냥!
```

Body:

```text
지금 바로 확인해라냥! 🐾
```

Tap:

```text
UNLOCKED → Result
otherwise → authoritative server state
```

Notification 자체는 AI를 호출하지 않음.

## 04:00

이전 result 즉시 invalidate.
`FULFILLMENT_MISSED`를 새날 메인 UI state로 표시하지 않는다.

```text
old settlement → purge → new Fortune Day → NO_SESSION/Cat Home
```
