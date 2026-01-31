# AI 캐시 & prompt_version 무효화 구조

## 캐시 레이어

```
[사용자 요청]
    │
    ▼
┌───────────────────────────────────────────────┐
│ Layer 1: AiSummaryService.getCachedSummary()  │  ← saju_base 전용
│ (core/services/ai_summary_service.dart)       │
│ - select: content, model_name, prompt_version │
│ - prompt_version 비교 → 불일치 시 null        │
└───────────────────────────────────────────────┘
    │ (캐시 miss)
    ▼
┌───────────────────────────────────────────────┐
│ Layer 2: AiQueries.getCachedSummary()         │  ← 모든 summary_type
│ (AI/data/queries.dart)                        │
│ - select: * (prompt_version 포함)             │
│ - fromJson에서 prompt_version 비교            │
│ - 불일치 시 null 반환 (캐시 무효화)           │
└───────────────────────────────────────────────┘
    │ (캐시 miss)
    ▼
┌───────────────────────────────────────────────┐
│ AI API 호출 (GPT-5.2 / GPT-5-mini / Gemini)  │
│ → 결과를 ai_summaries에 저장                  │
│ → prompt_version = PromptVersions.xxx         │
└───────────────────────────────────────────────┘
```

## prompt_version 무효화 플로우

1. **프롬프트 수정** → `ai_constants.dart`의 `PromptVersions` 상수 변경
2. **앱 배포** → 새 버전의 앱이 설치됨
3. **캐시 조회 시** → DB의 `prompt_version`과 `PromptVersions.forSummaryType()` 비교
4. **불일치** → null 반환 (캐시 무효화) → AI 재생성 트리거

### 버전 해석기

`PromptVersions.forSummaryType(summaryType)` 메서드가 중앙 집중식으로 매핑:

| summaryType | 버전 상수 |
|---|---|
| `saju_base` | `PromptVersions.sajuBase` |
| `daily_fortune` | `PromptVersions.dailyFortune` |
| `monthly_fortune` | `PromptVersions.monthlyFortune` |
| `yearly_fortune` | `PromptVersions.yearlyFortune` |
| `yearly_fortune_2026` | `PromptVersions.yearlyFortune2026` |
| `yearly_fortune_2025` | `PromptVersions.yearlyFortune2025` |
| 그 외 | `null` (버전 체크 안 함) |

## 버전업 절차

1. 프롬프트 템플릿 수정
2. `ai_constants.dart` → 해당 `PromptVersions` 상수 버전 올리기 (예: `V9.5` → `V9.6`)
3. 빌드 & 배포
4. 사용자가 앱 열면 → 기존 캐시 자동 무효화 → AI 재생성

## 적용 범위

- **Fortune 쿼리들** (daily/monthly/yearly/lifetime): `mutations.dart`에서 저장 시 `prompt_version` 기록, `AiQueries.getCachedSummary()`에서 검증
- **AiSummaryService**: `getCachedSummary()`에서 `saju_base` 캐시 검증
- **question_answer, compatibility**: 버전 체크 불필요 (매번 새로 생성하거나 프롬프트 고정)
