# SaDam Toss Miniapp

React Router + Vite prototype for an Apps in Toss miniapp.

## Current MVP

- Start page: name, birth year, focus input
- Result page: local 12-character personality card
- Extra page: mocked rewarded-ad flow
- Premium page: mocked in-app-purchase flow

The first pass intentionally uses local deterministic data and mock Toss adapters.
Real Apps in Toss auth, ads, and IAP SDK calls should replace `app/features/sadam/toss-adapters.ts` after UI verification.

## Commands

```bash
npm install
npm run typecheck
npm run build
npm run dev -- --host 127.0.0.1 --port 5177
```
