# Personas 모듈

## 개요
AI 챗봇 페르소나를 관리하는 모듈입니다.
모든 페르소나는 `PersonaBase`를 상속받아 구현됩니다.

## 파일 구조

```
frontend/lib/AI/jina/personas/
├── README.md                 # 이 파일
├── persona_base.dart         # 페르소나 베이스 클래스 (필수 상속)
├── persona_registry.dart     # 페르소나 등록/조회 시스템
├── persona_selector.dart     # UI용 페르소나 선택기
├── _TEMPLATE.dart            # 새 페르소나 템플릿
│
├── # 페르소나 구현체
├── cute_friend.dart          # 귀여운 친구
├── friendly_sister.dart      # 친근한 언니 (기본값)
├── wise_scholar.dart         # 현명한 학자
├── grandma.dart              # 할머니
├── baby_monk.dart            # 아기 스님
├── newbie_shaman.dart        # 초보 무당
├── saeongjima.dart           # 사성지마 (독설가)
├── scenario_writer.dart      # 시나리오 작가
├── detail_book.dart          # 사주 책
│
└── # MBTI 기반 베이스 페르소나
    ├── base_nf.dart          # NF 유형
    ├── base_nt.dart          # NT 유형
    ├── base_sf.dart          # SF 유형
    └── base_st.dart          # ST 유형
```

## AI 응답 경로 (중요!)

### 채팅 응답 흐름
```
사용자 메시지
    ↓
PersonaRegistry.getById(personaId)     # 페르소나 선택
    ↓
PersonaBase.buildFullSystemPrompt()    # 시스템 프롬프트 생성
    ↓
GeminiEdgeDatasource.sendMessageStream()
    ↓
Edge Function (ai-gemini)
    ↓
Gemini API
    ↓
AI 응답 (max_tokens 제한 적용)
```

### 토큰 제한 설정 경로

| 용도 | 파일 | 상수 | 값 |
|------|------|------|-----|
| **채팅 응답** | `AI/core/ai_constants.dart` | `TokenLimits.questionAnswerMaxTokens` | 2048 |
| **일일운세** | `AI/core/ai_constants.dart` | `TokenLimits.dailyFortuneMaxTokens` | 4096 |
| **평생운세** | `AI/core/ai_constants.dart` | `TokenLimits.sajuBaseMaxTokens` | 30000 |
| **월운** | `AI/core/ai_constants.dart` | `TokenLimits.monthlyFortuneMaxTokens` | 8192 |

### 채팅에서 max_tokens 적용 위치
```
frontend/lib/features/saju_chat/data/datasources/gemini_edge_datasource.dart
  └── Line 174, 299: TokenLimits.questionAnswerMaxTokens
```

## 핵심 파일 참조

### 1. 토큰/모델 설정
```
frontend/lib/AI/core/ai_constants.dart
├── TokenLimits          # 응답 최대 토큰
├── OpenAIModels         # OpenAI 모델 ID
├── GoogleModels         # Gemini 모델 ID
└── PromptVersions       # 프롬프트 버전 (캐시 무효화)
```

### 2. 채팅 데이터소스
```
frontend/lib/features/saju_chat/data/datasources/
├── gemini_edge_datasource.dart   # Edge Function 호출 (채팅용)
├── gemini_rest_datasource.dart   # 직접 API 호출 (레거시)
└── ai_pipeline_manager.dart      # 파이프라인 관리
```

### 3. Edge Function
```
Supabase Edge Function: ai-gemini
├── 기본 max_tokens: 16384 (fallback)
└── 클라이언트 전달값 우선 사용
```

## 새 페르소나 추가 방법

### 1. 파일 생성
`_TEMPLATE.dart`를 복사하여 새 파일 생성

### 2. 클래스 구현
```dart
class MyNewPersona extends PersonaBase {
  @override
  String get id => 'my_new_persona';  // snake_case

  @override
  String get name => '새 페르소나';

  @override
  String get description => '설명...';

  @override
  PersonaTone get tone => PersonaTone.polite;

  @override
  int get emojiLevel => 2;

  @override
  String get systemPrompt => '''
    당신은 ...
  ''';
}
```

### 3. 레지스트리 등록
`persona_registry.dart`에 추가:
```dart
import 'my_new_persona.dart';

static final List<PersonaBase> _allPersonas = [
  // ... 기존 페르소나
  MyNewPersona(),  // 추가
];
```

## 페르소나 조회 API

```dart
// ID로 조회
final persona = PersonaRegistry.getById('cute_friend');

// 기본 페르소나
final defaultPersona = PersonaRegistry.defaultPersona;

// 모든 페르소나
final all = PersonaRegistry.all;

// 카테고리별 조회
final friends = PersonaRegistry.getByCategory(PersonaCategory.friend);
```

## 담당자
- **Jina**: 페르소나 설계 및 프롬프트 작성
- **JH_AI**: AI 파이프라인 연동

## 관련 문서
- `frontend/lib/AI/core/ai_constants.dart` - 토큰 제한 설정
- `frontend/lib/features/saju_chat/data/datasources/gemini_edge_datasource.dart` - 채팅 API 호출
- `.claude/team/Jina.md` - Jina 역할 정의
