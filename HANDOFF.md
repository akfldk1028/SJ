# HANDOFF — Qwen v103 + saju_base GPT→Qwen + 마크다운 파서 + 빌드 대기

> 작성: 2026-04-07 | DK-DD 브랜치 | Edge Function v103 | Flutter 빌드 대기

---

## Goal

1. ~~Gemini→Qwen 전환~~ → **완료 (v94~v102)**
2. ~~FC 도구 확장~~ → **완료 (9개: 궁통보감 조후 + 지장간 포함)**
3. **마크다운 파서 + 한자 규칙 + 버전업 + 빌드** → **Flutter 수정 완료, 빌드만 남음**
4. **비용 일일 추적** → 매 세션 시작 시 확인
5. ~~saju_base GPT→Qwen~~ → **완료 (v103, Edge Function 배포 완료, Flutter 빌드 대기)**

---

## 즉시 할 일: 버전업 + 빌드

```bash
# 1. pubspec.yaml 버전업 (현재 0.1.6+79 → 0.1.6+80)
# 2. 빌드
cd frontend && flutter build appbundle --release
# 3. Play Store 업로드
```

### Flutter 수정 완료 (빌드 대기):

| 파일 | 변경 |
|------|------|
| `core/utils/markdown_parser.dart` (신규) | 블록 레벨 마크다운 파서 (헤더/불릿/구분선/번호/볼드/이탤릭) |
| `message_bubble.dart` | `parseToWidget()` 사용 (완성 메시지) |
| `streaming_message_bubble.dart` | `parse()` TextSpan 유지 (스트리밍) |
| `system_prompt_builder.dart` | 한자 규칙 추가 (사주용어 OK, 일상어 금지) |

---

## Current Progress

### Edge Function v103 (배포 완료)
- **ai-gemini**: Qwen 3.5 Flash primary, Gemini 2.5 Lite fallback (채팅)
- **ai-openai**: Qwen 3.5 Flash primary, GPT-5-mini fallback (saju_base)
  - json_schema → json_object 변환 + full schema 프롬프트 주입
  - 19필드 서버사이드 검증 → 실패 시 GPT fallback
  - 테스트 완료: 실제 프로필 데이터, 모든 nested 구조 일치
  - 호출당 $0.0025 (GPT $0.0115, **78% 절감**)
- `enable_thinking: false`
- `presence_penalty: 0.9` (장문 억제)
- FC 도구 7개 (Qwen용, think 제외) + Gemini 8개

### 마크다운 파서 (`core/utils/markdown_parser.dart`)
- `#` `##` `###` → 섹션 헤더 (큰글씨+볼드)
- `**카테고리:**` `* 카테고리:` → 섹션 헤더 + 카테고리 이모지
- `* ` `- ` → • 불릿 들여쓰기
- 중첩 불릿 → ◦ 추가 들여쓰기
- `1. ` → 번호 리스트
- `---` `***` → Divider 위젯
- `**볼드**` → FontWeight.bold
- `*이탤릭*` → FontStyle.italic
- 카테고리 이모지: 💰재물, 🏥건강, 💕사랑, 💼직업, ✨총운, ⚠️주의

### 한자 규칙 (`system_prompt_builder.dart`)
- 사주 전문용어 한자 병기 OK (경금(庚金), 편재(偏財))
- 일상 단어 한자 금지 (時間→시간, 重要→중요)

---

## 비용 추적 (매 세션 필수!)

### SQL
```sql
SELECT 
  usage_date,
  ROUND(SUM(gemini_cost_usd)::numeric, 4) as total_cost,
  COUNT(DISTINCT user_id) as dau,
  ROUND((SUM(gemini_cost_usd) / NULLIF(COUNT(DISTINCT user_id), 0))::numeric, 4) as cost_per_user,
  SUM(chatting_tokens) as chat_tokens
FROM user_daily_token_usage 
WHERE usage_date >= '2026-04-06'
GROUP BY usage_date 
ORDER BY usage_date;
```

### 기록
| 날짜 | 총비용 | DAU | 유저당 | 모델 | 비고 |
|------|--------|-----|--------|------|------|
| 4/5 | $0.48 | ~19 | $0.025 | Gemini Lite | 기준선 |
| 4/6 | $0.575 | 21 | $0.027 | Qwen v94~98 | thinking ON 포함 |
| 4/7 | $0.033 | 4 | $0.008 | Qwen v99~102 | think 제거 |
| **DashScope 4월 실측** | **$0.39** | - | - | 전체 | 4/6~4/7 합산 |

### 경보
- 일일 $1.00 이상 → ⚠️
- 일일 $2.00 이상 → 🚨 즉시 조사
- 유저당 $0.05 이상 → 비정상

### 확인할 곳
1. DB: 위 SQL
2. DashScope: https://modelstudio.console.alibabacloud.com (싱가포르)
3. AI Studio: https://aistudio.google.com (Gemini fallback)

### 캐시 디버깅 (v103)
- ai-gemini에 `cache_creation_input_tokens` 로깅 추가 배포 완료
- 로그 확인: `[ai-gemini v103] Cache debug:` 검색
- `created=N` → 캐시 생성됨 (첫 요청), `hit=N` → 캐시 적중 (후속 요청)
- `NO cache activity` → 캐시 자체가 안 되는 것 → 추가 조사 필요
- 싱가포르 리전에서 explicit cache 공식 지원 확인됨 (최소 1024 토큰, 유효 5분)

---

## What Worked
- Qwen 3.5 Flash: 동일 가격에 GPQA +19.6p, 정답률 73%→100%
- `enable_thinking: false`: 23~69초→3.5초
- `presence_penalty: 0.9`: Qwen 장문 억제
- think 도구 Qwen에서 제거: FC 5회→0회, 토큰 대폭 절약
- saju-tools Record 에러→{ [k: string] } + 한자 변수명→영문

## What Didn't Work
- `enable_thinking: true` (기본값): 비용 5~8배 + 속도 10배
- Gemma 4 (OpenRouter): 캐싱 미지원 → 월 $60+
- system_prompt_builder 대량 Edit: 인코딩 문제로 실패, 줄 단위로 해야

---

## 절대 금지
1. **Qwen `enable_thinking: true`** → 비용 5~8배
2. **Gemini `thinkingBudget` ≠ 0** → 비용 25배
3. **QWEN_API_KEY 하드코딩** → Supabase secret으로만
4. **Play Store 기본 언어 영어로 변경** → 한국어 유지

---

## 미완료 (다음 세션들)
- [ ] 프롬프트 정리 (~1400토큰 절약, FC 중복 삭제)
- [ ] 스트리밍 FC (현재 non-streaming만)
- [ ] DashScope 대시보드 24시간 비용 확인
- [ ] "무료 쿼터 소진 시 중지" OFF 확인 완료 (Playwright로 확인함)
