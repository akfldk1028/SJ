# AI 모듈 가이드

> **담당자**: JH_AI (분석) + Jina (대화)
> **마지막 업데이트**: 2026-01

---

## 목차

1. [모듈 구조](#모듈-구조)
2. [팀 역할 분담](#팀-역할-분담)
3. [새 페르소나 추가하기](#새-페르소나-추가하기-jina)
4. [새 프롬프트 추가하기](#새-프롬프트-추가하기)
5. [AI 모델 정보](#ai-모델-정보)
6. [파이프라인 흐름](#파이프라인-흐름)
7. [체크리스트](#체크리스트)

---

## 모듈 구조

```
AI/
├── ai.dart                 # 메인 exports (barrel)
├── core/                   # 설정, 로거, 캐시 (통합)
│   ├── ai_constants.dart   # 모델명, 가격, 상수, 프롬프트 버전
│   ├── ai_config.dart      # AI 설정
│   ├── ai_cache.dart       # 응답 캐시
│   ├── ai_simple_logger.dart # 로거
│   └── base_provider.dart  # Provider 베이스
│
├── fortune/                # ⭐ 운세 프롬프트 통합
│   ├── common/             # 공통 (prompt_template, input_data, state)
│   ├── lifetime/           # 평생운세 (saju_base 프롬프트)
│   │   ├── lifetime_prompt.dart
│   │   └── lifetime_phase1~4_prompt.dart
│   ├── daily/              # 오늘운세
│   ├── monthly/            # 월별운세
│   ├── yearly_2025/        # 2025 회고
│   └── yearly_2026/        # 2026 신년
│
├── common/                 # 공용 모듈
│   ├── data/               # AI 데이터 제공자
│   ├── providers/          # AI Provider (OpenAI, Google, Image)
│   │   ├── openai/         # GPT-5.2 (JH_AI)
│   │   ├── google/         # Gemini 3.0 (Jina)
│   │   └── image/          # DALL-E, Imagen
│   ├── pipelines/          # 분석 파이프라인
│   └── prompts/            # 공통 프롬프트
│
├── jh/                     # JH_AI 전용
│   ├── jh.dart
│   ├── analysis/           # 사주 분석 로직
│   └── providers/
│
├── jina/                   # Jina 전용
│   ├── jina.dart
│   ├── chat/               # 대화 생성
│   ├── context/            # 맥락 관리
│   ├── image/              # Nanabanan 이미지
│   ├── personas/           # ⭐ 페르소나 시스템
│   │   ├── persona_base.dart
│   │   ├── persona_registry.dart
│   │   └── ...
│   └── providers/
│
├── services/               # AI 서비스
└── data/                   # 쿼리/뮤테이션
```

---

## 팀 역할 분담

| 담당 | 역할 | 주요 폴더 |
|------|------|----------|
| **JH_AI** | GPT-5.2로 사주 분석 | `jh/`, `fortune/`, `common/providers/openai/` |
| **Jina** | Gemini 3.0으로 대화 생성 | `jina/`, `common/providers/google/` |
| **공동** | 파이프라인, 캐시, 로거 | `core/`, `common/pipelines/` |

### 작업 영역

```
JH_AI:
- 사주 분석 프롬프트 작성
- 분석 결과 파싱
- GPT API 호출 로직

Jina:
- 페르소나 캐릭터 정의
- 대화 톤/이모지 조절
- Gemini API 호출 로직
```

---

## 새 페르소나 추가하기 (Jina)

### 1단계: 템플릿 복사

```bash
# personas/ 폴더에서 템플릿 복사
cp _TEMPLATE.dart my_new_persona.dart
```

### 2단계: 클래스 수정

```dart
// my_new_persona.dart
class MyNewPersona extends PersonaBase {
  @override
  String get id => 'my_new_persona';  // 영문 snake_case

  @override
  String get name => '새 페르소나';  // 한글 이름

  @override
  String get description => '설명';

  @override
  PersonaTone get tone => PersonaTone.casual;  // 말투 선택

  @override
  int get emojiLevel => 3;  // 이모지 정도 (0~5)

  @override
  String get systemPrompt => '''
당신은 [역할]입니다.
...
''';
}
```

### 3단계: 레지스트리 등록

```dart
// persona_registry.dart 열기
static final List<PersonaBase> _allPersonas = [
  FriendlySisterPersona(),
  CuteFriendPersona(),
  WiseScholarPersona(),
  MyNewPersona(),  // ← 추가!
];
```

### 4단계: jina.dart에 export 추가

```dart
// jina.dart
export 'personas/my_new_persona.dart';  // ← 추가!
```

### 말투 옵션 (PersonaTone)

| 옵션 | 예시 | 용도 |
|------|------|------|
| `formal` | ~합니다 | 전문가, 학자 |
| `polite` | ~해요 | 언니, 선배 |
| `casual` | ~해 | 친구, 동생 |
| `mixed` | 혼합 | 상황별 변화 |

### 카테고리 옵션 (PersonaCategory)

| 옵션 | 설명 |
|------|------|
| `friend` | 친구 스타일 |
| `expert` | 전문가 스타일 |
| `family` | 가족 스타일 |
| `fun` | 재미 스타일 |
| `special` | 시즌 한정 등 |

---

## 새 프롬프트 추가하기

### 1단계: fortune/ 하위에 파일 생성

```bash
# fortune/ 하위 적절한 폴더에 생성
# 예: fortune/yearly_2027/yearly_2027_prompt.dart
```

### 2단계: 클래스 수정

```dart
class YearlyFortunePrompt extends PromptTemplate {
  @override
  String get summaryType => 'yearly_fortune';  // DB 저장용 키

  @override
  String get modelName => OpenAIModels.gpt52;  // 또는 GoogleModels.gemini25FlashLite

  @override
  int get maxTokens => 2000;

  @override
  double get temperature => 0.7;

  @override
  Duration? get cacheExpiry => Duration(days: 365);  // 1년 캐시

  @override
  String get systemPrompt => '''
당신은 사주 전문가입니다.
...
''';

  @override
  String buildUserPrompt(Map<String, dynamic> input) {
    final data = SajuInputData.fromJson(input);
    return '''
## 대상 정보
- 이름: ${data.profileName}
...
''';
  }
}
```

### 모델 선택 가이드

| 용도 | 모델 | 속도 | 비용 |
|------|------|------|------|
| 정밀 분석 | `OpenAIModels.gpt52` | 느림 | 높음 |
| 빠른 분석 | `OpenAIModels.gpt4oMini` | 빠름 | 낮음 |
| 대화 생성 | `GoogleModels.gemini30Flash` | 빠름 | 낮음 |
| 고급 대화 | `GoogleModels.gemini30Pro` | 보통 | 보통 |

---

## AI 모델 정보

### 사용 모델 (2026-04 기준)

| 모델 | ID | 용도 |
|------|-----|------|
| GPT-5.2 | `gpt-5.2` | 사주 분석 (사주 base) |
| GPT-5 Mini | `gpt-5-mini` | 운세 분석 (월운/연운) |
| **Gemini 2.5 Flash Lite** | `gemini-2.5-flash-lite` | **대화/일운 (기본 모델)** |
| Gemini 3.0 Pro | `gemini-3-pro-preview` | 고급 대화 (미사용) |
| DALL-E 3 | `dall-e-3` | 이미지 생성 |
| Imagen 3 | `imagen-3.0-generate-001` | 이미지 생성 |

### 상수 위치

```dart
// core/ai_constants.dart
class OpenAIModels {
  static const gpt52 = 'gpt-5.2';
  static const gpt5Mini = 'gpt-5-mini';    // 운세 분석용
}

class GoogleModels {
  static const gemini25FlashLite = 'gemini-2.5-flash-lite';  // 기본 모델
  static const chat = gemini25FlashLite;
  static const dailyFortune = gemini25FlashLite;
}
```

---

## 파이프라인 흐름

```
┌─────────────┐
│  사용자 입력  │
└──────┬──────┘
       ▼
┌─────────────┐
│ SajuPipeline│ ← 사주 데이터 준비
└──────┬──────┘
       ▼
┌─────────────┐     ┌─────────────┐
│   JH_AI     │────▶│    Jina     │
│  GPT-5.2    │     │ Gemini 3.0  │
│  (분석)      │     │  (대화)      │
└──────┬──────┘     └──────┬──────┘
       │                    │
       ▼                    ▼
┌─────────────┐     ┌─────────────┐
│ 분석 결과    │     │ 대화 응답    │
│ (JSON)      │     │ (자연어)     │
└─────────────┘     └─────────────┘
```

---

## 체크리스트

### 새 페르소나 추가 시

- [ ] `_TEMPLATE.dart` 복사
- [ ] 클래스명 변경
- [ ] id 설정 (영문 snake_case)
- [ ] name, description 작성
- [ ] tone, emojiLevel 선택
- [ ] systemPrompt 작성
- [ ] greetings, examples 추가 (선택)
- [ ] `persona_registry.dart`에 등록
- [ ] `jina.dart`에 export 추가
- [ ] 빌드 테스트

### 새 프롬프트 추가 시

- [ ] `fortune/` 하위 적절한 폴더에 파일 생성
- [ ] 클래스명 변경
- [ ] summaryType 설정 (필요시 `ai_constants.dart`에 추가)
- [ ] modelName 선택
- [ ] maxTokens, temperature, cacheExpiry 설정
- [ ] systemPrompt 작성
- [ ] buildUserPrompt 작성 (JSON 스키마 포함)
- [ ] `ai.dart` barrel에 export 추가
- [ ] `ai_constants.dart`에 PromptVersions 추가
- [ ] 사용하는 서비스에서 import
- [ ] 테스트 완료

---

## 🚨 AI 캐싱 시스템 (중요!)

### 캐시 저장 위치
- **테이블**: `ai_summaries`
- **캐시 키**: `profile_id` + `summary_type` + `target_date/year/month`

### 캐시 무효화 조건
1. **프롬프트 버전 변경** - `PromptVersions` 상수 변경 시
2. **만료 시간 도달** - `expires_at` 필드
3. **수동 삭제** - DB에서 직접 삭제

### ⚠️ 주의: 같은 사주 ≠ 같은 캐시
```
프로필 A (profile_id: aaa-111)  →  사주: 1994-11-28 여자
프로필 B (profile_id: bbb-222)  →  사주: 1994-11-28 여자 (동일!)

BUT 캐시는 별도! profile_id가 다르므로 각각 분석됨
```

### 프롬프트 버전 관리
```dart
// core/ai_constants.dart
class PromptVersions {
  static const String sajuBase = 'V9.5';
  static const String dailyFortune = 'V2.1';
  static const String monthlyFortune = 'V5.1';
  static const String yearlyFortune2025 = 'V2.0';
  static const String yearlyFortune2026 = 'V2.0';
}
```

버전을 올리면 기존 캐시가 무효화되고 새로 분석됩니다.

---

## 문제 해결

### Q: 페르소나가 목록에 안 보여요
→ `persona_registry.dart`의 `_allPersonas`에 인스턴스 추가했는지 확인

### Q: 프롬프트 응답이 잘려요
→ `maxTokens` 값을 늘려보세요 (최대 4000~8000)

### Q: 캐시가 안 돼요
→ `cacheExpiry`가 null이면 무기한, Duration 설정시 해당 시간만 캐시

### Q: 같은 사주인데 왜 또 분석하나요?
→ **profile_id가 다르면 별도 캐시!** 새 프로필 생성 시 항상 새로 분석됩니다.

### Q: DB에 데이터 있는데 UI에 안 보여요
→ **파싱 경로 확인!** content 구조가 `current.months`, `categories.lucky` 등 중첩되어 있을 수 있음

---

## 연락처

- JH_AI: AI 분석 관련
- Jina: 대화/페르소나 관련
- DK: 전체 아키텍처
