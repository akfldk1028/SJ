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
