# SaDam Toss Miniapp Module

This feature must stay self-contained under `app/features/sadam`.

## Porting Rule

- Keep the existing React template structure: `pages`, `components`, data/helpers, and adapters inside this feature folder.
- Do not move SaDam-specific UI into global common components until another feature needs it.
- Match the Flutter source by page/widget responsibility:
  - `zodiac_element_background.dart` -> `components/zodiac-widgets.tsx`
  - `zodiac_animal_avatar.dart` -> `components/zodiac-widgets.tsx`
  - `zodiac_chat_bubble.dart` -> `components/zodiac-widgets.tsx`
  - `zodiac_reveal_animation.dart` -> result/reveal composition
  - `zodiac_identity.dart` -> `personas.ts`
- Keep Toss SDK calls behind `toss-adapters.ts`.

## Accuracy Boundary

The current MVP uses a lightweight day-pillar calculation for the result card.
For full parity with the Flutter app, connect the existing Flutter/API logic for lunar conversion, true solar time, DST, and jasi adjustment.
