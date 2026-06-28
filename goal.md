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

## Next Focus

- AI chat parity:
  - Flutter `features/saju_chat` providers/repositories/datasources
  - Supabase `chat_sessions` and `chat_messages`
  - Edge Function streaming or compatible API call path
- Toss monetization:
  - Premium product UI
  - Toss Payments JS SDK or App-in-Toss payment capability
  - Payment success/failure routes
  - Server-side payment confirmation or premium activation path
