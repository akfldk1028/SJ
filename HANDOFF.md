# HANDOFF — Qwen 3.5 Flash 전환 완료 + 궁통보감 FC 도구 + 프롬프트 정리 대기

> 작성: 2026-04-07 | DK-DD 브랜치 | Edge Function v98

---

## Goal

1. ~~Gemini 2.5 Flash Lite 추론력 부족 (GPQA 64.6%)~~ → **Qwen 3.5 Flash (GPQA 84.2%) 전환 완료**
2. 사주 FC 도구 확장 (궁통보감 조후 120조합 + 지장간) → **v98 배포 완료**
3. 프롬프트 정리 (FC 중복 ~1400토큰 삭제) → **미완료, 다음 세션**
4. 비용 모니터링 (DashScope 대시보드 확인) → **24시간 후 확인 필요**

---

## Current Progress (완료)

### 1. Qwen 3.5 Flash 전환 (v94~v98)

| 버전 | 변경 | 결과 |
|------|------|------|
| v94 | Qwen 추가 (thinking ON) | 23~69초, 비용 폭발 |
| v95 | `enable_thinking: false` | 4초로 개선 |
| v96 | saju-tools Record 에러 수정 + Qwen FC 루프 | 3.5초, 도구 정상 |
| v97 | `stop: ["[/SUGGESTED_QUESTIONS]"]` | 추천 질문 칩 정상화 |
| v98 | 궁통보감 조후 + 지장간 FC 도구 추가 | 9개 도구 |

**Qwen 설정:**
- API Key: Supabase secret `QWEN_API_KEY` (DashScope 싱가포르)
- Base URL: `https://dashscope-intl.aliyuncs.com/compatible-mode/v1`
- 모델: `qwen3.5-flash`
- `enable_thinking: false` (⛔ 절대 true 금지)
- `stop: ["[/SUGGESTED_QUESTIONS]"]`
- explicit cache: `cache_control: {"type": "ephemeral"}` (system message)
- Fallback: Qwen 실패 → Gemini 2.5 Flash Lite 자동

### 2. saju-tools 9개 도구

```
supabase/functions/ai-gemini/saju-tools/
├── index.ts          # 도구 9개 선언 (Gemini + OpenAI 자동 변환)
├── interactions.ts   # 충/원진/해/육합/삼합/방합/형/파
├── spouse.ts         # 육친 배우자성
├── sipsin.ts         # 십성 계산
├── cheongan.ts       # 천간합 5쌍
├── gungwi.ts         # 궁위 4궁
├── johu.ts           # ✅ 궁통보감 조후용신 120조합 (신규)
└── jijanggan.ts      # ✅ 지장간 본기/중기/여기 (신규)
```

- `openaiToolDeclarations`가 Gemini 형식에서 자동 변환 (geminiToOpenAI 함수)
- Qwen non-streaming에 FC 루프 (최대 6회)
- 스트리밍은 도구 없음 (non-streaming에서만 FC 동작)

### 3. 테스트 결과

| 모델 | 정답률 | 속도 |
|------|--------|------|
| Gemini 2.5 Flash Lite (v92) | ~73% | ~1.8초 |
| **Qwen 3.5 Flash (v98)** | **100% (12/12)** | ~3.5초 |

테스트 스크립트: `test_saju_chat.mjs` (Gemini vs Qwen 비교 모드 추가됨)
```bash
QWEN_API_KEY=sk-xxx node test_saju_chat.mjs compare  # 양쪽 비교
QWEN_API_KEY=sk-xxx node test_saju_chat.mjs qwen     # Qwen만
node test_saju_chat.mjs gemini                        # Gemini만
```

### 4. 가격 (Gemini와 동일)

| | Gemini Lite | Qwen Flash |
|--|:-:|:-:|
| Input | $0.10/M | $0.10/M |
| Output | $0.40/M | $0.40/M |
| Cached | $0.01/M (implicit) | $0.01/M (explicit 90%) |
| 월 예상 | ~$14 | ~$14-18 |

### 5. 리서치 결과 (사주 분석 방법론)

리서치 에이전트 완료 (`a409c03d54a7c26e1`). 핵심 발견:
- **BaZi MCP 서버** (cantian-ai/bazi-mcp, 354 stars): 30.3~62.6% 정확도 향상
- **커뮤니티 AI 사주 불만 Top 5**: 합충 할루, 격국 오판, 조후/억부 혼동, 육친 반전, 지장간 오류
- **우리 FC 9개 도구가 Top 5 중 4개 커버**
- 상세 결과: 메모리 `architecture/qwen_vs_gemini_evaluation.md` 참조

---

## What Worked

1. **Qwen 3.5 Flash**: 같은 가격에 GPQA +19.6p, 정답률 73%→100%
2. **`enable_thinking: false`**: thinking ON이 기본이라 23~69초 → OFF로 3.5초
3. **explicit caching**: `cache_control: {"type": "ephemeral"}` → 90% 할인 (Gemini implicit과 동일)
4. **OpenAI 호환 API**: Gemini → Qwen 전환이 endpoint/format만 바꾸면 됨
5. **saju-tools Record 에러 수정**: `Record<>` → `{ [k: string]: ... }` + 한자 변수명 → 영문
6. **FC openaiToolDeclarations 자동 변환**: Gemini 형식 → OpenAI 형식 `geminiToOpenAI()` 함수

## What Didn't Work

1. **`enable_thinking: true` (기본값)**: 비용 5~8배 + 속도 10배 느림. 절대 켜지 마라
2. **Gemma 4 (OpenRouter)**: 캐싱 미지원 → 월 $60+ 예상, 탈락
3. **프롬프트 대량 수정**: system_prompt_builder.dart에서 80줄 한번에 교체하려니 인코딩 문제로 Edit 도구 실패. 줄 단위로 접근해야 함
4. **curl로 Edge Function 테스트**: `verify_jwt: true`라 JWT 없이 안 됨. node fetch나 앱에서 테스트해야 함
5. **Supabase MCP로 대용량 파일 배포**: index.ts가 56KB라 MCP files 파라미터에 직접 넣기 어려움. CLI `supabase functions deploy`가 확실

---

## Next Steps (다음 세션)

### 🔴 P0: 비용 모니터링 (배포 24시간 후)

1. **DashScope 대시보드** 확인: https://modelstudio.console.alibabacloud.com (싱가포르)
   - 실제 과금 금액 확인
   - cached_tokens 비율 확인
2. **AI Studio (Gemini)** 확인: https://aistudio.google.com (hanvit4303@gmail.com)
   - Gemini fallback이 얼마나 호출됐는지
3. DB `user_daily_token_usage` → `gemini_cost_usd` 값과 대시보드 비교

### ✅ P1: 프롬프트 정리 (~1000토큰 절약) — 완료

**파일**: `frontend/lib/features/saju_chat/data/services/system_prompt_builder.dart`
**메서드**: `_addSajuCoreRules()` (v99)

완료 내역:
- 천간 오행/음양, 십성 판별법, 지장간 테이블, 조후 계절 4줄, 천간합/삼합/방합/육합/충/원진/해, 배우자성, 궁위 **전부 삭제** (FC 도구가 대체)
- 【도구 활용】 섹션 추가 (9줄, 7개 도구 매핑 + 경고 2줄)
- 순 40줄 감소 (diff: +65/-105)

### ✅ P2: 추가 프롬프트 개선 — 완료

- 조후 우선순위: "사주 온도가 극단적이면 조후가 억부보다 우선" 추가
- 격국 판정: "① 종격 확인 → ② 월지 본기 투간 → ③ 중기 → ④ 여기" 추가

### 🟢 P3: 스트리밍 FC (선택)

현재 스트리밍에서는 도구 없음 (non-streaming에서만 FC). 
스트리밍에서도 도구 호출하려면 OpenAI streaming + tool_calls 처리 필요 — 복잡도 높음, 현재 정확도 100%이니 우선순위 낮음.

---

## Key Files

| 파일 | 역할 |
|------|------|
| `supabase/functions/ai-gemini/index.ts` | Edge Function 메인 (Qwen+Gemini fallback) |
| `supabase/functions/ai-gemini/saju-tools/` | FC 도구 9개 |
| `frontend/lib/features/saju_chat/data/services/system_prompt_builder.dart` | 사주 프롬프트 빌더 |
| `test_saju_chat.mjs` | Qwen vs Gemini 비교 테스트 |
| `memory/architecture/qwen_vs_gemini_evaluation.md` | 전환 기록 + 설정 |

---

## 절대 금지 사항

1. **Qwen `enable_thinking: true`** → 비용 5~8배 + 속도 10배
2. **Gemini `thinkingBudget` ≠ 0** → 비용 25배
3. **QWEN_API_KEY를 코드에 하드코딩** → Supabase secret으로만
4. **Play Store 기본 언어를 영어로 바꾸기** → 한국어 유지 (메모리 참조)
