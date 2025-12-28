# Jina AI 프롬프트 수정 가이드

> **담당자**: Jina (AI 대화)
> **목적**: AI 프롬프트 수정 시 Claude가 바로 이해할 수 있도록 정리

---

## 폴더 구조

```
frontend/lib/AI/
├── prompts/                    ← 프롬프트 템플릿 (Jina 주담당)
│   ├── prompt_template.dart    ← 베이스 클래스 (수정 X)
│   ├── daily_fortune_prompt.dart ← 오늘운세 (Gemini)
│   ├── saju_base_prompt.dart   ← 평생사주 (GPT-5.2, JH_AI 담당)
│   └── _TEMPLATE.dart          ← 새 프롬프트 생성용
├── core/
│   └── ai_constants.dart       ← 모델명, 가격 상수
├── jina/                       ← Jina 전용 폴더
│   ├── personas/               ← AI 페르소나 (말투)
│   └── chat/                   ← 대화 처리
└── services/
    └── ai_api_service.dart     ← API 호출 (수정 X)
```

---

## 작업별 수정 위치

### 1. 오늘의 운세 프롬프트 수정

**파일**: `prompts/daily_fortune_prompt.dart`

| 수정 내용 | 위치 | 라인 |
|----------|------|------|
| AI 역할/톤 설정 | `systemPrompt` getter | 124-135 |
| 입력 데이터 포맷 | `buildUserPrompt()` | 138-237 |
| JSON 응답 스키마 | `buildUserPrompt()` 내부 | 196-233 |
| 모델 변경 | `modelName` getter | 112 |
| 토큰 제한 | `maxTokens` getter | 115 |
| 창의성 조절 | `temperature` getter | 118 |

**예시 - 시스템 프롬프트 수정**:
```dart
// 124줄
@override
String get systemPrompt => '''
당신은 친근하고 긍정적인 사주 상담사입니다.
// ← 여기에 원하는 역할/톤 추가
''';
```

**예시 - 응답 JSON 스키마 변경**:
```dart
// 196줄 부근
```json
{
  "date": "$dateStr",
  "overall_score": 75,
  // ← 필드 추가/수정 여기서
}
```

---

### 2. AI 페르소나 (말투) 수정

**폴더**: `jina/personas/`

| 파일 | 설명 |
|------|------|
| `cute_friend.dart` | 친근한 친구 말투 |
| `friendly_sister.dart` | 다정한 언니 말투 |
| `wise_scholar.dart` | 현명한 학자 말투 |
| `persona_base.dart` | 페르소나 베이스 클래스 |
| `_TEMPLATE.dart` | 새 페르소나 생성용 |

**새 페르소나 추가**:
1. `_TEMPLATE.dart` 복사
2. 클래스명, 말투 스타일 수정
3. `persona_registry.dart`에 등록

---

### 3. 모델 변경

**파일**: `core/ai_constants.dart`

```dart
class GoogleModels {
  static const dailyFortune = 'gemini-3-flash-preview';  // ← 모델명
}

class OpenAIModels {
  static const sajuBase = 'gpt-5.2';  // ← 모델명
}
```

---

### 4. 새 프롬프트 타입 추가

**예시**: 월운(monthly_fortune) 추가

1. `prompts/_TEMPLATE.dart` 복사 → `monthly_fortune_prompt.dart`
2. 수정할 항목:
   ```dart
   class MonthlyFortunePrompt extends PromptTemplate {
     @override
     String get summaryType => 'monthly_fortune';  // DB 저장 키

     @override
     String get modelName => GoogleModels.dailyFortune;

     @override
     String get systemPrompt => '''월운 분석 역할...''';

     @override
     String buildUserPrompt(Map<String, dynamic> input) {
       // 입력 데이터 포맷팅
     }
   }
   ```
3. `ai_constants.dart`에 `SummaryType.monthlyFortune` 추가
4. `saju_analysis_service.dart`에서 호출 로직 추가

---

## 자주 하는 작업

### A. 운세 톤 변경 (더 긍정적으로)

```
파일: prompts/daily_fortune_prompt.dart
위치: systemPrompt (124줄)
작업: "긍정적인" → "매우 희망적이고 격려하는" 등으로 수정
```

### B. 응답에 새 필드 추가

```
파일: prompts/daily_fortune_prompt.dart
위치: buildUserPrompt() 내부 JSON 스키마 (196-233줄)
작업:
  1. 스키마에 필드 추가
  2. daily_fortune_provider.dart에서 파싱 로직 추가
```

### C. 입력 데이터 추가 (예: 혈액형)

```
파일: prompts/prompt_template.dart
위치: SajuInputData 클래스
작업:
  1. 필드 추가: final String? bloodType;
  2. toJson(), fromJson() 수정
  3. buildUserPrompt()에서 사용
```

---

## 테스트 방법

1. 앱 실행 후 프로필 저장
2. 콘솔에서 `[AiApiService] Gemini 호출` 로그 확인
3. `frontend/assets/log/` 폴더에서 응답 확인
4. 또는 `tools/` 폴더에서 `npm run watch` 실행

---

## 주의사항

- `prompt_template.dart`의 `PromptTemplate` 클래스는 수정 X (다른 프롬프트에 영향)
- JSON 스키마 변경 시 `daily_fortune_provider.dart` 파싱 로직도 같이 수정
- 모델 변경 시 비용 확인 (`ai_constants.dart`의 Pricing 클래스)

---

## 관련 파일 빠른 링크

| 용도 | 경로 |
|------|------|
| 오늘운세 프롬프트 | `AI/prompts/daily_fortune_prompt.dart` |
| 평생사주 프롬프트 | `AI/prompts/saju_base_prompt.dart` |
| 모델/상수 | `AI/core/ai_constants.dart` |
| 페르소나 | `AI/jina/personas/` |
| 운세 Provider | `features/menu/presentation/providers/daily_fortune_provider.dart` |
| API 서비스 | `AI/services/ai_api_service.dart` |
