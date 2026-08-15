# Design System — Cat Oracle × Contemporary East Asian

## Thesis

> 세련된 동양풍 공간에서 한 마리 고양이가 매일 조용히 오늘의 운세를 읽어주는 경험.

성격:

```text
신비롭지만 무섭지 않음
귀엽지만 유아적이지 않음
동양적이지만 촌스럽지 않음
고급스럽지만 차갑지 않음
```

## 금지 Visual

```text
purple-blue AI gradient
glassmorphism
neon glow
AI sparkle 남발
mesh/aurora gradient
3D blob
우주/은하
카지노/슬롯
점집 간판
과도한 부적/팔괘/용/봉황
유아용 SD mascot
```

## Tokens

```text
bg.paper          #F4EFE5
bg.paperRaised    #FBF8F1
text.ink          #222622
text.secondary    #66645E
text.muted        #8A867D
accent.seal       #A14B3F
accent.gold       #B49A67
accent.jade       #6F8978
accent.plum       #725F6B
border.subtle     #D8D0C3
state.disabled    #B8B3AA
state.danger      #A6534A
state.success     #66806F
```

Gradient 기본 surface 금지.

Geometry:

```text
8pt grid
screen padding 20~24
card radius 18
button radius 16
sheet radius 24
card padding 20~24
```

## Typography

MVP = system-safe Korean Sans.
인터넷 font 임의 다운로드 금지.
Display Serif는 owner가 license 확인된 asset을 제공한 뒤만 추가.

```text
display   28/36 semibold
title1    24/32 semibold
title2    20/28 semibold
body      16/26 regular
small     14/22 regular
caption   12/18 regular
button    16/22 semibold
```

## Cat Character

```text
친근함 40
도도함 30
신비로움 20
장난기 10
```

금지:

```text
과도한 meme 표정
츄르/캣닢/집사 joke
어린이 mascot
```

## Cat Video

```text
local bundled MP4
autoplay
muted
loop
controls 없음
background pause
foreground resume
decode failure → poster
reduce motion → poster/static 우선
```

권장 경로:

```text
assets/videos/fortune_cat.mp4
```

실제 파일이 없으면 Codex가 임의 생성/다운로드하지 않는다.
Release 전 codec/resolution/fps/size/license 검토.

## Voice

UI는 냥체 적극 사용.
Fortune body는 약 20~40% 문장만 자연스럽게 냥체.

좋음:

```text
오늘은 속도보다 순서를 정하는 게 중요하다냥.
오전에 정리한 일이 오후의 부담을 줄여줄 수 있어요.
한 번 더 확인하고 움직이는 편이 좋겠다냥.
```

금지:

```text
냥냥
냐옹
집사
오늘 대박이다냥냥
무조건 된다냥
```

Legal/privacy/error-critical text는 명확성 우선.

Fixed:

```text
알려주겠다냥! 🐾
오늘의 운세가 도착했다냥!
지금 바로 확인해라냥! 🐾
운세를 보고 있다냥...
```

## Decoration

허용:

```text
달
구름
창호 리듬
매듭
도장
잔잔한 물결
먹의 질감
```

background opacity 3~10% 정도.
Pass badge는 game currency처럼 만들지 않는다.

## Motion

허용:

```text
slow fade
8~16px small slide
subtle rating reveal
cat video loop
```

금지:

```text
slot reel
confetti
coin shower
fast bounce
screen shake
big sparkle burst
```

## Accessibility

```text
44~48dp touch target
충분한 body contrast
dynamic text scaling
decorative motif semantic hidden
video 없어도 의미 전달
reduce-motion
```

## Visual QA

```text
[ ] 고양이가 주인공인가?
[ ] CTA가 5초 안에 보이는가?
[ ] AI SaaS처럼 보이지 않는가?
[ ] 점집/카지노처럼 보이지 않는가?
[ ] 유아용처럼 보이지 않는가?
[ ] 결과가 편하게 읽히는가?
[ ] 3/3에서도 광고 선택지가 보이는가?
```

가능하면 emulator screenshot → self-review → fix → screenshot.
