# JH_AI 사주 분석 프롬프트 수정 가이드

> **담당자**: JH_AI (평생사주 분석)
> **목적**: GPT-5.2 사주 분석 프롬프트 수정 시 Claude가 바로 이해할 수 있도록 정리

---

## 폴더 구조

```
frontend/lib/AI/
├── prompts/                         ← 프롬프트 템플릿 (JH_AI 주담당)
│   ├── prompt_template.dart         ← 베이스 클래스 + SajuInputData
│   ├── saju_base_prompt.dart        ← ★ 평생사주 (GPT-5.2) - JH_AI 담당
│   ├── daily_fortune_prompt.dart    ← 오늘운세 (Gemini, Jina 담당)
│   └── _TEMPLATE.dart               ← 새 프롬프트 생성용
├── core/
│   └── ai_constants.dart            ← 모델명, 가격, 토큰 제한 상수
├── services/
│   └── saju_analysis_service.dart   ← 분석 오케스트레이션 (수정 주의)
└── data/
    ├── queries.dart                 ← 데이터 조회
    └── mutations.dart               ← 결과 저장
```

---

## 작업별 수정 위치

### 1. 시스템 프롬프트 수정 (AI 역할/분석 원칙)

**파일**: `prompts/saju_base_prompt.dart`

| 수정 내용 | 위치 | 라인 |
|----------|------|------|
| AI 역할 정의 | `systemPrompt` getter | 120-141 |
| 분석 원칙 | `systemPrompt` 내 "## 분석 원칙" | 123-128 |
| 분석 영역 | `systemPrompt` 내 "## 분석 영역" | 130-138 |

**예시 - 시스템 프롬프트 수정**:
```dart
// 120줄
@override
String get systemPrompt => '''
당신은 한국 전통 사주명리학 전문가입니다. 수십 년간의 연구와 실전 경험을 바탕으로...

## 분석 원칙
1. **정확성**: 명리학 원리에 충실하되 현대적 해석을 가미
// ← 새로운 원칙 추가 가능
''';
```

---

### 2. 입력 데이터 포맷 수정 (프롬프트에 들어가는 사주 정보)

**파일**: `prompts/saju_base_prompt.dart`

| 수정 내용 | 위치 | 라인 |
|----------|------|------|
| 기본 정보 포맷 | `buildUserPrompt()` | 144-158 |
| 사주팔자 표시 | `data.sajuString` | 155 |
| 오행분포 표시 | `data.ohengString` | 158 |
| 용신 섹션 | `_buildYongsinSection()` | 225-243 |
| 신강/신약 섹션 | `_buildDayStrengthSection()` | 246-258 |
| 격국 섹션 | `_buildGyeokgukSection()` | 310-326 |
| 십신 섹션 | `_buildSipsinSection()` | 329-349 |
| 지장간 섹션 | `_buildJijangganSection()` | 352-372 |
| 신살 섹션 | `_buildSinsalSection()` | 260-273 |
| 길성 섹션 | `_buildGilseongSection()` | 275-288 |
| 12운성 섹션 | `_buildUnsungSection()` | 290-307 |
| 12신살 섹션 | `_buildTwelveSinsalSection()` | 375-392 |
| 대운 섹션 | `_buildDaeunSection()` | 395-433 |
| 합충형파해 섹션 | `_buildHapchungSection()` | 444-570 |

**예시 - 새 섹션 추가**:
```dart
// buildUserPrompt() 내부 (174줄 부근)
${_buildYongsinSection(data.yongsin)}
${_buildDayStrengthSection(data.dayStrength)}
${_buildMyNewSection(data.myNewData)}  // ← 새 섹션 추가

// 파일 하단에 빌더 메서드 추가
String _buildMyNewSection(Map<String, dynamic>? myData) {
  if (myData == null || myData.isEmpty) return '';

  final buffer = StringBuffer('\n## 새 섹션 제목\n');
  // ... 포맷팅 로직
  return buffer.toString();
}
```

---

### 3. JSON 응답 스키마 변경 (AI 출력 형식)

**파일**: `prompts/saju_base_prompt.dart`

| 수정 내용 | 위치 | 라인 |
|----------|------|------|
| JSON 스키마 전체 | `buildUserPrompt()` 내부 | 181-217 |

**현재 JSON 스키마**:
```json
{
  "summary": "한 문장 요약",
  "personality": {
    "core_traits": ["핵심 성격 3-5개"],
    "strengths": ["장점 3-5개"],
    "weaknesses": ["약점 2-3개"],
    "description": "성격 설명"
  },
  "career": {
    "suitable_fields": ["적합 분야 3-5개"],
    "unsuitable_fields": ["피해야 할 분야 1-2개"],
    "work_style": "업무 스타일",
    "advice": "진로 조언"
  },
  "relationships": {...},
  "wealth": {...},
  "health": {...},
  "overall_advice": "종합 조언",
  "lucky_elements": {...}
}
```

**필드 추가 예시**:
```dart
// 181줄 부근, JSON 스키마 내부
```json
{
  "summary": "...",
  "personality": {...},
  "career": {...},
  "marriage": {  // ← 새 필드 추가
    "timing": "결혼 적기",
    "partner_traits": ["이상형 특성"],
    "advice": "결혼 관련 조언"
  },
  ...
}
```

**주의**: JSON 스키마 변경 시 관련 Provider/파싱 로직도 수정 필요
- `features/saju_chart/presentation/providers/saju_analysis_repository_provider.dart`

---

### 4. 모델 변경

**파일**: `core/ai_constants.dart`

```dart
// 56-87줄: OpenAI 모델 정의
abstract class OpenAIModels {
  static const String gpt52 = 'gpt-5.2';           // 기본 (추론 특화)
  static const String gpt52Chat = 'gpt-5.2-chat-latest';  // 빠른 응답
  static const String gpt52Pro = 'gpt-5.2-pro';    // 최고 품질 (비용 높음)

  static const String sajuAnalysis = gpt52;        // ← 여기서 변경
}
```

**비용 참고** (1M 토큰당):
| 모델 | 입력 | 출력 | 캐시 |
|------|------|------|------|
| GPT-5.2 | $1.75 | $14.00 | $0.175 (90% 할인) |
| GPT-5.2 Pro | 더 높음 | 더 높음 | - |

---

### 5. 토큰 제한 / 창의성 조절

**파일**: `prompts/saju_base_prompt.dart`

| 설정 | 위치 | 현재값 | 설명 |
|------|------|--------|------|
| `maxTokens` | 111줄 | 4096 | 응답 최대 토큰 (늘리면 상세, 비용 증가) |
| `temperature` | 114줄 | 0.7 | 창의성 (0=일관성, 1=다양성) |
| `cacheExpiry` | 117줄 | null | 캐시 만료 (null=무기한) |

**수정 예시**:
```dart
@override
int get maxTokens => 6000;  // 더 상세한 분석 원할 때

@override
double get temperature => 0.5;  // 더 일관된 분석 원할 때
```

---

### 6. 입력 데이터 구조 (SajuInputData)

**파일**: `prompts/prompt_template.dart`

`SajuInputData` 클래스가 AI에 전달되는 모든 데이터를 담음:

```dart
class SajuInputData {
  final String profileId;
  final String profileName;
  final DateTime birthDate;
  final String? birthTime;
  final String gender;

  // 사주 관련
  final Map<String, dynamic>? saju;        // 사주팔자 (년월일시)
  final Map<String, dynamic>? oheng;       // 오행 분포
  final Map<String, dynamic>? yongsin;     // 용신/희신/기신/구신
  final Map<String, dynamic>? dayStrength; // 신강/신약
  final Map<String, dynamic>? gyeokguk;    // 격국
  final Map<String, dynamic>? sipsinInfo;  // 십신
  final Map<String, dynamic>? jijangganInfo; // 지장간
  final List<Map<String, dynamic>>? sinsal;    // 신살
  final List<Map<String, dynamic>>? gilseong;  // 길성
  final List<dynamic>? twelveUnsung;           // 12운성
  final List<dynamic>? twelveSinsal;           // 12신살
  final Map<String, dynamic>? daeun;           // 대운
  final Map<String, dynamic>? hapchung;        // 합충형파해

  // 새 필드 추가 시 여기에 추가
}
```

**새 입력 필드 추가**:
1. `SajuInputData` 클래스에 필드 추가
2. `toJson()`, `fromJson()` 수정
3. `_buildXxxSection()` 메서드 작성
4. `buildUserPrompt()`에서 호출

---

## 분석 파이프라인 이해

### 실행 흐름
```
profile_provider.dart (프로필 저장)
  → _triggerAiAnalysis()
    → SajuAnalysisService.analyzeOnProfileSave()
      → _prepareInputData() (DB에서 사주 데이터 조회)
        → AiQueries.getProfileWithAnalysis()
        → AiQueries.convertToInputData()
      → _runSajuBaseAnalysis()  ← GPT-5.2 호출
        → SajuBasePrompt.buildMessages()
        → AiApiService.callOpenAI()
        → AiMutations.saveSajuBaseSummary()
      → _runDailyFortuneAnalysis()  ← Gemini 호출 (Jina 담당)
```

### 캐시 정책
- **saju_base**: 무기한 캐시 (프로필 수정 전까지 재생성 안함)
- 동일 profile_id로 2번째 저장 → GPT 호출 스킵 (캐시 히트)

---

## 자주 하는 작업

### A. 분석 영역 추가 (예: 배우자운)

```
1. prompts/saju_base_prompt.dart
   - systemPrompt에 "배우자운" 추가 (130줄 부근)
   - JSON 스키마에 "spouse" 필드 추가 (181-217줄)

2. prompt_template.dart (필요시)
   - SajuInputData에 관련 필드 추가
```

### B. 합충형파해 분석 정밀화

```
파일: prompts/saju_base_prompt.dart
위치: _buildHapchungSection() (444-570줄)
작업:
  - 이미 상세 구현됨 (천간합/충, 지지육합/삼합/방합/충/형/파/해/원진)
  - 새로운 관계 추가 시 해당 메서드 수정
```

### C. 대운 분석 상세화

```
파일: prompts/saju_base_prompt.dart
위치: _buildDaeunSection() (395-433줄)
작업:
  - 현재 대운, 대운 시작 나이, 대운 흐름 표시
  - 추가 정보는 daeun Map에 담겨서 전달됨
```

### D. 응답 톤 변경 (더 긍정적으로)

```
파일: prompts/saju_base_prompt.dart
위치: systemPrompt (120줄)
작업: "## 분석 원칙" 섹션에 "긍정적 표현 우선" 등 추가
```

---

## 테스트 방법

1. 앱 실행 → 프로필 저장
2. 콘솔에서 `[SajuAnalysisService] 평생 사주 분석 시작...` 로그 확인
3. `frontend/assets/log/` 폴더에서 응답 확인 (txt 파일)
4. Supabase `ai_summaries` 테이블에서 결과 확인

**로그 감시 실행**:
```bash
cd D:\Data\20_Flutter\01_SJ\tools
npm run watch
```

---

## 주의사항

- `prompt_template.dart`의 `PromptTemplate` 클래스는 **수정 주의** (Jina 프롬프트에도 영향)
- JSON 스키마 변경 시 **Provider 파싱 로직도 같이 수정**
- 모델 변경 시 **비용 확인** (`ai_constants.dart`의 OpenAIPricing)
- `saju_analysis_service.dart`는 GPT→Gemini 순차 실행 로직이므로 **수정 시 Jina와 협의**

---

## 관련 파일 빠른 링크

| 용도 | 경로 |
|------|------|
| 평생사주 프롬프트 | `AI/prompts/saju_base_prompt.dart` |
| 입력 데이터 구조 | `AI/prompts/prompt_template.dart` |
| 모델/상수 | `AI/core/ai_constants.dart` |
| 분석 서비스 | `AI/services/saju_analysis_service.dart` |
| API 호출 | `AI/services/ai_api_service.dart` |
| 데이터 조회 | `AI/data/queries.dart` |
| 결과 저장 | `AI/data/mutations.dart` |
| 결과 파싱 | `features/saju_chart/presentation/providers/` |

---

## 비용 추정 (GPT-5.2 기준)

| 분석 | 입력 토큰 | 출력 토큰 | 예상 비용 |
|------|----------|----------|----------|
| saju_base | ~1,000-1,500 | ~1,500-2,000 | ~$0.02-0.03 |

- 프로필당 **1회만 실행** (캐시)
- 재분석은 프로필 수정 시에만
