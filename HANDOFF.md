# HANDOFF — 사주 정확도 대폭 개선 + Function Calling 인프라

> 작성: 2026-04-06 | DK-DD 브랜치 | v0.1.6+75 → Edge Function v92

---

## Goal

1. AI(Gemini)가 사주 기초를 틀리는 문제 해결 (원진살 지어내기, 남녀 배우자성 혼동 등)
2. Gemini function calling 인프라 구축 (flash 업그레이드 시 즉시 활성화)
3. Sequential Thinking (공식 MCP 기반) 도구 추가
4. 대운 해석 규칙은 인터넷+커뮤니티 리서치 후 별도 작업

---

## Current Progress (완료)

### 1. 시스템 프롬프트 규칙 추가 (`system_prompt_builder.dart` `_addSajuCoreRules()`)

| 추가된 규칙 | 내용 |
|------------|------|
| **원진살 6쌍** | 子未, 丑午, 寅酉, 卯申, 辰亥, 巳戌 + 해(害)와 구분 |
| **육친 배우자성 10간** | 남자=재성, 여자=관성. 10간 전체 매핑 |
| **4궁(宮位)** | 년주=조상궁, 월주=부모궁, 일간=나, 일지=배우자궁, 시주=자녀궁 |
| **조후용신 수정** | 봄: 수→**화** 수정 (궁통보감 원칙) |
| **금지 규칙 강화** | 원진 지어내기 금지, 남녀 육친 혼동 금지 |

### 2. compatibility_calculator.dart 원진 replaceAll 수정

- 기존: 해(害) 쌍을 원진으로 잘못 매핑 (인사→인유, 묘진→묘신 등)
- 수정: 원진 6쌍에 맞게 전체 12개 replaceAll 수정

### 3. Gemini Function Calling 인프라 (`saju-tools/`)

```
supabase/functions/ai-gemini/saju-tools/
├── index.ts          # 도구 선언 6개 + 실행 디스패처
├── interactions.ts   # 충6/원진6/해6/육합6/삼합4/방합4/형/파
├── spouse.ts         # 육친 배우자성 (10간×2성별)
├── sipsin.ts         # 십성 계산 (정기 기준 음양)
├── cheongan.ts       # 천간합 5쌍
└── gungwi.ts         # 궁위 (4궁)
```

6개 도구:
- `verify_interaction` — 지지 관계 판별
- `get_spouse_star` — 배우자성 조회
- `get_sipsin` — 십성 계산
- `verify_cheongan_hap` — 천간합 확인
- `get_gungwi` — 궁위 의미
- `think` — Sequential Thinking (공식 MCP description 그대로)

### 4. Edge Function 수정 (`index.ts` v92)

- 동적 import: saju-tools 로드 실패해도 기존 동작 유지
- **lite 모델은 tools 안 보냄** (`!model.includes('lite')` 체크)
- non-streaming 경로에 function call loop (최대 6회)
- functionResponse에 id 필드 포함 (Gemini 공식 스펙)

---

## What Worked

1. **프롬프트 규칙만으로 lite 4/5 통과** — function calling 없이도 규칙 텍스트로 충분
2. **원진살 6쌍 명시** → AI가 "인술은 원진 아님, 인유가 원진" 정확 답변
3. **육친 배우자성 명시** → "경금 남자 배우자=목(갑/을)" 정확 답변
4. **4궁 명시** → "일지=배우자궁, 일주 전체 아님" 정확 답변
5. **반합 규칙** → "자진=신자진 수국의 반합" 정확 답변
6. **동적 import** → saju-tools 로드 실패해도 프로덕션 영향 없음

## What Didn't Work

1. **gemini-2.5-flash-lite는 function calling 미지원** — 공식 문서 확인
2. **도구 사용 지시 너무 강하면 역효과** — lite가 도구를 텍스트로 출력하며 혼란
3. **정적 import** → saju-tools에 에러 있으면 전체 Edge Function 크래시 (500)
4. **thinkingBudget** → 돈 많이 듦. function calling이 더 경제적이나 lite 미지원

---

## 현재 상태

| 항목 | 상태 |
|------|------|
| Edge Function | v92 배포, 정상 동작 |
| 프롬프트 규칙 | 기초 + 대운 해석 규칙 추가 완료 |
| saju-tools 코드 | 완성, lite에서는 비활성 (flash 전환 시 즉시 활성화) |
| 테스트 결과 | 8문제 중 7/8 통과 (1개는 서버 과부하) |
| 프로덕션 영향 | 없음 (lite는 tools 안 보냄) |

---

## Next Steps

### 1. ~~대운 해석 규칙 리서치~~ ✅ 완료
- `_addSajuCoreRules()`에 대운 규칙 9개 추가 (천간지지 비중, 원국 작용, 교운기, 용신기신, 대운×세운, 순행역행)
- 테스트 3문제 추가 (용신판별, 교운기, 지지비중) → 7/8 통과

### 2. 궁통보감 120조합 (보류 — flash 전환 시)
- 10일간 × 12월지 = 120가지 조후용신
- ~3000토큰. lite에는 과부하, flash에서 넣을 것

### 3. 십성 정확도 마지막 1문제
- "경금→갑목=편재"를 "아빠"라고 잘못 비유 (1/5 실패)
- persona_base.dart 용어 번역 테이블에 "편재≠아빠" 명시 고려

### 4. Flash 업그레이드 시 체크리스트
- [ ] `model.includes('lite')` 체크 제거 → tools 활성화
- [ ] `toolConfig: { functionCallingConfig: { mode: "AUTO" } }` 추가
- [ ] 궁통보감 120조합 추가
- [ ] function calling 테스트 재실행

### 5. 앱 배포
- system_prompt_builder.dart 변경사항은 Flutter 앱 빌드+배포 필요
- `flutter build appbundle --release` → Play Store 업로드

---

## 핵심 파일

| 파일 | 역할 |
|------|------|
| `supabase/functions/ai-gemini/index.ts` | Edge Function v92 (동적 saju-tools import, lite safe) |
| `supabase/functions/ai-gemini/saju-tools/` | 🆕 사주 검증 도구 6개 (flash 전용) |
| `frontend/lib/features/saju_chat/data/services/system_prompt_builder.dart` | `_addSajuCoreRules()` — 원진/육친/궁위/조후/대운 추가 |
| `frontend/lib/AI/jina/personas/persona_base.dart` | 공통 프롬프트 (해석 태도, 용어 번역) |
| `frontend/lib/AI/services/compatibility_calculator.dart` | 원진 replaceAll 수정 |
| `test_saju_chat.mjs` | 함정 질문 테스트 (8문제: 기초5+대운3) |

---

## 테스트 명령어

```bash
# 사주 함정 질문 테스트 (lite, 프롬프트만)
node test_saju_chat.mjs

# Edge Function 배포
cd D:/Data/20_Flutter/01_SJ
npx supabase functions deploy ai-gemini --no-verify-jwt
```

---

## 메모리

전체 아키텍처/비용/버그 이력: `D:\DevCache\claude-data\projects\D--Data-20-Flutter-01-SJ\memory\`
