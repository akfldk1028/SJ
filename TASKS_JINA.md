# Jina's Task Log

이 파일은 Jina의 작업 내역과 현재 이슈를 요약합니다. (간결 버전)

---

## 📅 2026년 01월 08일
### ✅ 완료된 작업
1. '아기동자' 페르소나가 사주와 무관하게 흐르는 문제 수정 → 사주 기반 대화만 허용
2. 새 페르소나 추가: scenario_writer.dart(송작가), newbie_shaman.dart(장군 신내림), saeongjima.dart(새옹지마), detail_book.dart(명리의 서)
3. 추가 페르소나들은 세부 내용/길이 조정 예정 (공동 검토 필요)

---

## 📅 2026년 01월 19일
### 📊 Semantic Intent Routing (토큰 최적화) 현황
- 목적: AI Summary 전체(JSON)에서 질문 의도별 섹션만 포함해 토큰 절약
- 현재: GENERAL이 자주 붙어 필터가 거의 미동작 → 실질적으로 전체 JSON 포함
- 구성요소: Edge Function `ai-gemini`(classify-intent), Flutter `IntentClassifierService`, `FilteredAiSummary` (saju_origin/wonGuk 기본 포함)

### 주요 수정 파일
- `frontend/lib/core/services/ai_summary_service.dart`: SummaryCategory/IntentClassificationResult/FilteredAiSummary 추가, DB `content` 전체 JSON 조회·캐싱
- `frontend/lib/core/services/intent_classifier_service.dart`: Edge Function 호출, userId 전달, 에러 로깅 강화
- `frontend/lib/features/saju_chat/data/services/system_prompt_builder.dart`: intentClassification 파라미터 추가, 필터 적용, 간지 계산 추가
- `frontend/lib/features/saju_chat/presentation/providers/chat_provider.dart`: 모든 메시지에서 분류 시도, aiSummary 캐시·로그 정비
- `supabase/functions/ai-gemini/after.ts`: classify-intent 액션, GENERAL 남발 방지 프롬프트, 모델명 고정

### 현재 이슈 / 결정 필요
- GENERAL 과다로 토큰 절약 효과 미미
- 선택지: A) Intent Classification 제거·항상 전체 사용, B) GENERAL 억제 로직 보강, C) 현상 유지

### 배포 메모
- Edge Function: `after.ts` → `index.ts` 복사 후 `supabase functions deploy ai-gemini`
- Flutter: 별도 배포 없음, 세션 초기에 DB `ai_summaries.content` 전체 캐시 사용

### 남은 할 일
1) GENERAL 과다 사용 해결 방향 결정 (A/B/C)
2) 호칭 룰, 노잼 대응, 인사 길이, 노가리 대응 등 페르소나 룰 개선 (`chat_provider.dart` / `system_prompt_builder.dart`)

---

## 📅 2026년 01월 21일
### ✅ 완료된 작업: AI 대화 참조 데이터 구조 개선

#### 1. `sajuOrigin` 중복 제거
- **문제**: `ai_summaries.content`의 `sajuOrigin` 필드가 `saju_analyses` 테이블 데이터와 중복
- **해결**: `sajuOrigin` 관련 코드 전체 제거 (196줄 삭제)
  - `system_prompt_builder.dart`: `_addSajuOrigin()` 메서드 삭제 (148줄)
  - `system_prompt_builder.dart`: `sajuOrigin` 호출 로직 제거
  - `chat_provider.dart`: `sajuOrigin` 체크 및 GPT-5.2 트리거 로직 제거 (40줄)

#### 2. 시스템 프롬프트 데이터 소스 명확화
**현재 AI 대화 시 참조하는 데이터 (첫 메시지):**
1. **`sajuAnalysis`** (saju_analyses 테이블) - 만세력 계산 원본 데이터
   - 사주팔자, 오행 분포, 용신, 십성, 합충형파해, 신살, 대운 등
   - `system_prompt_builder.dart:94` → `_addSajuAnalysis()` 호출

2. **`aiSummary`** (ai_summaries 테이블 content) - GPT-5.2 평생 운세 분석
   - Intent Classification으로 필터링된 섹션만 포함
   - `system_prompt_builder.dart:105` → `_addAiSummary(aiSummary, intentClassification)` 호출
   - 필터링 로직: `FilteredAiSummary` (Line 834-855)

#### 3. 추가 필요
- [ ] 디버깅 로그 추가: `_addSajuAnalysis()`와 `_addAiSummary()` 파싱 결과 확인
- [ ] Intent Classification 필터링 효과 검증
- [ ] GPT-5.2 Edge Function에서 `sajuOrigin` 생성 제거 (추후)
