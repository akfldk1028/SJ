# Toss Miniapp Flutter Parity + Monetization Goal

## Objective

Port the existing Flutter SaDam logic and screens into `toss-miniapp/frontend` while keeping the React module structure and Supabase data flow aligned with the Flutter app. The Toss miniapp must support the real AI chat flow and Toss-compatible paid premium access, not just static preview screens.

## Current Scope

- Keep Flutter route parity for `/saju/chart`, `/saju/detail`, `/saju/graph`, `/saju/chat`.
- Preserve `profileId` query loading through the existing React Router loader.
- Store saju analysis through the existing `saju_analyses` columns and JSON payloads.
- Compare Flutter screen/widget logic before adding React behavior.
- Implement real `/saju/chat` behavior from the Flutter chat stack.
- Implement Toss-compatible payment entry, success/failure handling, and premium state persistence.
- Use official Toss/App-in-Toss/Toss Payments docs before payment implementation because payment APIs and review rules can change.

## Verification Loop

- Run `npm run typecheck`.
- Run `npm run build`.
- Browser-check the affected route with Chromium/Playwright.
- Commit and push each verified loop.
- For payment work, verify test-mode routing without exposing secret keys to the browser.

## Recent Completed Commits

- `4e3e221 feat: add Toss saju core routes`
- `b26ccd6 feat: add Toss gongmang analysis`
- `224b541 feat: add Toss saju detail tab nav`
- `eb15301 feat: expand Toss fortune detail section`
- `5af66bb feat: enrich Toss oheng distribution`
- `d81fb20 feat: add Toss sipsin distribution summary`
- `ccb9e1a fix: align Toss saju lunar chart with Flutter`
- `f43ee82 refactor: polish Toss miniapp route surfaces`
- `40e2671 fix: refine Toss result and graph visuals`
- `a81411e refactor: unify Toss route card treatments`

## Current Verified Progress

- `/saju/chart`, `/saju/detail`, `/saju/graph`, `/saju/chat` load from `profileId` through the shared React Router loader.
- Lunar `1994-11-28` matches the Flutter reference conversion and resolves to day pillar `庚寅`.
- `/saju/chat` now stores `chat_sessions` and `chat_messages`, calls the Supabase `ai-gemini` Edge Function, and persists assistant replies with suggested questions.
- Toss premium products use the same `sadam_day_pass`, `sadam_week_pass`, and `sadam_monthly` IDs used by Flutter/RevenueCat and the `ai-gemini` quota bypass.
- Toss payment success confirms server-side, upserts `subscriptions` with `platform = 'toss'`, and the shared loader reads active premium status back for UI display.
- `npm run typecheck`, `npm run build`, and Playwright mobile/desktop route checks pass.

## Next Focus

- AI chat parity gaps:
  - Streaming response parity with Flutter, if required by the Toss runtime.
  - `type=compatibility`, `targetProfileId`, `autoMention`, persona, and context-summary flows from Flutter chat.
  - Quota/exhausted UI parity around `user_daily_token_usage`.
- Toss monetization gaps:
  - Real rewarded-ad capability replacement for the current local simulated adapter.
  - Full Toss test payment run with valid test keys in the target Toss environment.
  - Premium gating copy and active-subscription badges on every route that exposes paid content.
