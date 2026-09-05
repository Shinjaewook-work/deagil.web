# Design QA

## 2026-09-05 — Home and rewarded-choice polish

Scope: native home -> explicit ad/pass selection -> cancellation/failure recovery.
The approved paper/cat style was retained, not replaced with a new prototype.

- Captured baseline: `C:/Users/every/AppData/Local/Temp/daegil-design-before-20260905/02-cat-home.png`.
- Current home: `C:/Users/every/AppData/Local/Temp/daegil-design-final-20260905/02-cat-home.png`.
- New choice sheet: `C:/Users/every/AppData/Local/Temp/daegil-design-final-20260905/02b-fortune-choice.png`.
- All captures are Flutter-rendered previews, not physical-device evidence.

Findings addressed: the original CTA claimed completion before generation; its
caption stranded the final syllable on another line. Passes were used immediately
without an ad alternative. The home now has truthful action text, a shorter
two-line caption, and a cream paper choice sheet with explicit pass/ad/cancel.
The same cat art, surfaces, typography, and restrained pink primary action remain.
At 320px/2x text, the pass badge overflowed; flexible text now wraps without clipping.

Three new tests cover 0/3 passes, ad visibility at the cap, cancellation without
spending, single-flight pass execution, and retry after failure. All 53 widget
tests, Flutter analysis, and the visual capture test pass. Screenshots were opened
and compared side by side; test preview navigation now highlights Home correctly.
Screen-reader traversal and real phone font/video behavior remain unverified.

Capture harness correction: per-page `ProviderScope` keys prevent changing the
override count on one live container. The capture boundary now includes modal
overlays, and the test-only debug banner is hidden.

## Evidence

- Problem reference: `C:\Users\every\.codex\attachments\fb737e7b-ff81-4404-bbc6-0e8fe52b9004\image-1.png`
- Selected benchmark: `C:\Users\every\.codex\attachments\fb737e7b-ff81-4404-bbc6-0e8fe52b9004\image-2.png`
- Final implementation screenshots: `C:\Users\every\.codex\visualizations\2026\08\29\daegil-benchmark-final\01-auth.png` through `09-account-delete.png`
- Implementation viewport: 390 x 844 logical pixels, captured from Flutter widget rendering.
- The benchmark and final screenshots were inspected together in the same visual-comparison input after each iteration.

## Benchmark analysis

The selected benchmark creates a sophisticated cute tone with one warm paper field, thin brown outlines, restrained cream cards, compact dark-brown typography, small hand-drawn cat or daily-life accents, and a single muted-pink primary action. It does not depend on floating decorations, elevated pastel layers, heavy shadows, or unrelated mascot marks.

The previous implementation diverged in three visible ways: the opaque mascot backgrounds were lighter than the surrounding page, circular backplates created another conflicting layer, and floating paw bubbles at opposite image corners had no information purpose. Multiple pastel card fills and shadows also made the page feel busier than the benchmark.

## Final comparison

- Mascot integration: the sampled mascot edge tone (`#FBEACD` family) is now the shared page and image-canvas color. `PaperBlendImage` fades only the artwork's outer paper pixels inside the true square image bounds, so no rectangular paste edge remains.
- Decorative restraint: the image-corner paw bubbles, Auth floating paws, Home floating paw, circular image backplates, and unnecessary card shadows were removed.
- Surface system: cards use a consistent warm-cream fill, 1.15 px brown outline, 18 px radius, and no elevation. Color is reserved for compact icon accents and the muted-pink primary CTA.
- Hierarchy: AppBars share the paper canvas, mascot banners use smaller headings, result sections use compact outlined icon tiles and simple bullet marks, and repeated thumbnail artwork was removed from the rating card.
- Continuity: all existing navigation, consent controls, birth form, ad CTA, notification/privacy controls, account actions, and the persistent bottom navigation remain functional.

## Findings and fixes

### Iteration 1

- P1: the two decorative paw bubbles and image backplates made the artwork feel pasted into a separate layer.
- P1: the mascot's opaque paper pixels did not match the former page tone.
- P2: elevated pastel cards and shadows were denser than the benchmark.
- Fix: removed decorative overlays, sampled the raster edge colors, aligned the paper token, flattened the card system, and moved the primary action to muted pink.

### Iteration 2

- P2: after the color match, faint square edges were still visible because the five assets contain slightly different textured paper values.
- P2: the first edge mask used the full available banner width instead of the fitted square image bounds, leaving a visible vertical strip on the large account-deletion banner.
- Fix: introduced a two-axis edge blend constrained to the asset's 1:1 fitted bounds and re-captured all nine screens.

## Verification checklist

- [x] Both supplied references inspected before implementation.
- [x] Benchmark and implementation screenshots compared in the same visual input.
- [x] Floating image-corner paw decorations removed.
- [x] Mascot backgrounds visually merge with the surrounding paper.
- [x] Auth, Today, birth profile, result, settings, notification, privacy, account, and deletion screens reviewed.
- [x] Main interactions and persistent navigation preserved.
- [x] No P0, P1, or P2 visual findings remain.

## Follow-up polish

- P3: physical Android font scaling and video-frame color variation remain part of the existing Phase 15 device QA gate.

final result: passed
