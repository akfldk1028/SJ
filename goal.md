# Toss Miniapp Flutter Parity Goal

## Objective

Port the existing Flutter SaDam logic and screens into `toss-miniapp/frontend` while keeping the React module structure and Supabase data flow aligned with the Flutter app.

## Current Scope

- Keep Flutter route parity for `/saju/chart`, `/saju/detail`, `/saju/graph`, `/saju/chat`.
- Preserve `profileId` query loading through the existing React Router loader.
- Store saju analysis through the existing `saju_analyses` columns and JSON payloads.
- Compare Flutter screen/widget logic before adding React behavior.

## Verification Loop

- Run `npm run typecheck`.
- Run `npm run build`.
- Browser-check the affected route with Chromium/Playwright.
- Commit and push each verified loop.

## Recent Completed Commits

- `4e3e221 feat: add Toss saju core routes`
- `b26ccd6 feat: add Toss gongmang analysis`
- `224b541 feat: add Toss saju detail tab nav`

## Next Focus

- Match Flutter `FortuneDisplay` more closely in React detail page:
  - 대운 full list display
  - 최근 10년 세운
  - 최근 12개월 월운
