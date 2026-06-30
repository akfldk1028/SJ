# SaDam Toss Miniapp

React Router + Vite prototype for an Apps in Toss miniapp.

## Current State

- Start page: profile creation backed by Supabase
- Result and saju pages: Flutter-compatible profile, chart, and chat routes
- Extra page: Apps in Toss full-screen rewarded ad first, clear unsupported-state fallback outside Toss
- Premium page: Apps in Toss IAP first, Toss Payments browser fallback for local development
- Safe Area: Apps in Toss `SafeAreaInsets` values are applied globally when available

Official Apps in Toss SDK calls are isolated in `app/features/sadam/toss-adapters.ts`.
Run browser tests locally, then validate IAP and ad behavior in the Apps in Toss sandbox or Toss app test scheme.

## Apps in Toss Loop

1. Run `npm run typecheck`, `npm run build`, and `npm run test:e2e`.
2. Build the `.ait` bundle with the Apps in Toss CLI flow.
3. Upload the bundle to the Apps in Toss console.
4. Test with the sandbox app or Toss app test QR/scheme.
5. Submit review, read feedback, patch, and upload a new bundle.

## Commands

```bash
npm install
npm run typecheck
npm run build
npm run dev -- --host 127.0.0.1 --port 5177
```
