# AI 페르소나 아키텍처

## 개요

Jina 담당의 AI 채팅 페르소나 시스템.
MBTI 4분면 기반 + 캐릭터 기반 페르소나로 구성.

---

## 파일 구조

```
frontend/lib/AI/jina/
├── personas/                      # 페르소나 정의
│   ├── persona_base.dart          # 추상 기본 클래스
│   ├── persona_registry.dart      # 중앙 등록소
│   ├── persona_selector.dart      # 선택 로직
│   │
│   ├── [MBTI 4분면 - Base Persona]
│   ├── base_nf.dart               # NF 감성형 (직관+감정)
│   ├── base_nt.dart               # NT 분석형 (직관+사고)
│   ├── base_sf.dart               # SF 친근형 (감각+감정)
│   ├── base_st.dart               # ST 현실형 (감각+사고)
│   │
│   ├── [캐릭터 기반 페르소나]
│   ├── cute_friend.dart           # 귀여운 친구
│   ├── friendly_sister.dart       # 친근한 언니 (기본값)
│   ├── wise_scholar.dart          # 현명한 학자
│   ├── grandma.dart               # 할머니
│   ├── baby_monk.dart             # 아기 스님
│   ├── scenario_writer.dart       # 시나리오 작가
│   ├── newbie_shaman.dart         # 신입 무당
│   ├── detail_book.dart           # 사주 책
│   └── saeongjima.dart            # 새옹지마
│
├── chat/                          # 채팅 처리
│   ├── response_generator.dart    # 응답 생성 (TODO)
│   ├── tone_adjuster.dart         # 톤 조절
│   └── emoji_injector.dart        # 이모지 주입
│
├── context/                       # 컨텍스트 빌드
│   ├── context_builder.dart       # 컨텍스트 조립 (TODO)
│   └── chat_history_manager.dart  # 대화 히스토리
│
└── providers/
    └── jina_chat_provider.dart    # Riverpod Provider (TODO)
```

---

## MBTI 4분면 페르소나

| ID | 이름 | MBTI | 톤 | 이모지 | 테마색 | 특징 |
|----|------|------|-----|--------|--------|------|
| `base_nf` | NF 감성형 | 직관+감정 | polite | 3 | 빨강 | 공감, 따뜻함, 격려 |
| `base_nt` | NT 분석형 | 직관+사고 | polite | 1 | 파랑 | 논리, 체계, 전략 |
| `base_sf` | SF 친근형 | 감각+감정 | casual | 4 | 초록 | 유쾌, 실용, 편안 |
| `base_st` | ST 현실형 | 감각+사고 | polite | 1 | 주황 | 직설, 간결, 실행 |

---

## 참조 관계 (화살표 방향 중요!)

### 1. 페르소나 파일이 참조하는 것

```dart
// base_nf.dart (예시)
import 'package:flutter/material.dart';
import 'persona_base.dart';  // ← 이것만 참조!
```

**페르소나 파일들은 `persona_base.dart`만 참조하고, 다른 건 아무것도 참조 안 함.**

### 2. 참조 방향 다이어그램

```
┌──────────────────────────────────────────────────────────────────┐
│  페르소나 레이어 (독립적, 외부 참조 없음)                           │
│                                                                  │
│  base_nf.dart ─────┐                                             │
│  base_nt.dart ─────┼──import──▶ persona_base.dart               │
│  base_sf.dart ─────┤            (추상 클래스)                     │
│  base_st.dart ─────┘                                             │
│  cute_friend.dart ─┘                                             │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
                              ▲
                              │ 인스턴스 등록
                              │
┌──────────────────────────────────────────────────────────────────┐
│  레지스트리 레이어                                                │
│                                                                  │
│  persona_registry.dart                                           │
│    - 모든 페르소나 import                                         │
│    - _allPersonas 리스트에 인스턴스 등록                          │
│    - getById(), getByCategory() API 제공                         │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
                              ▲
                              │ getById() 호출
                              │
┌──────────────────────────────────────────────────────────────────┐
│  채팅 서비스 레이어                                               │
│                                                                  │
│  system_prompt_builder.dart                                      │
│    - personaPrompt: String (문자열로 받음)                        │
│    - aiSummary: AiSummary (GPT-5.2 결과)                         │
│    - sajuAnalysis: SajuAnalysis (로컬 계산)                       │
│    - profile: SajuProfile                                        │
│    → 전체 프롬프트 조립                                           │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                      Gemini 채팅 API
```

### 3. 각 파일의 import 정리

| 파일 | import 하는 것 |
|------|---------------|
| `base_nf.dart` | `persona_base.dart` **만** |
| `base_nt.dart` | `persona_base.dart` **만** |
| `base_sf.dart` | `persona_base.dart` **만** |
| `base_st.dart` | `persona_base.dart` **만** |
| `persona_registry.dart` | 모든 페르소나 파일들, `persona_base.dart` |
| `system_prompt_builder.dart` | `ai_summary_service.dart`, `saju_profile.dart`, `saju_analysis.dart` |

**핵심: 페르소나 파일들은 system_prompt_builder를 참조하지 않음. 반대로 system_prompt_builder가 페르소나를 (문자열로) 사용함.**

### 4. 모든 페르소나가 사주 정보를 참조하는가?

## ✅ YES. 모든 페르소나는 사주 정보를 참조합니다.

```
system_prompt_builder가 합쳐서 Gemini에 전달:

┌─────────────────────────────────────┐
│  최종 프롬프트                        │
├─────────────────────────────────────┤
│  페르소나 프롬프트  ←  base_nf 등     │
│  +                                  │
│  내 사주 정보      ←  sajuAnalysis   │
│  +                                  │
│  내 프로필        ←  profile         │
│  +                                  │
│  AI 분석 결과     ←  aiSummary       │
└─────────────────────────────────────┘
            ↓
      Gemini 채팅 API
```

### 5. 채팅 시점의 조합

```dart
// 채팅 시작 시 system_prompt_builder.build() 호출
final prompt = systemPromptBuilder.build(
  personaPrompt: persona.buildFullSystemPrompt(),  // ← 페르소나 (문자열)
  aiSummary: aiSummary,                            // ← GPT-5.2 결과
  sajuAnalysis: sajuAnalysis,                      // ← 로컬 계산
  profile: profile,                                // ← 프로필
  isFirstMessage: true,
);
```

**결론: 페르소나 자체는 사주 정보를 모르지만, 채팅할 때 system_prompt_builder가 합쳐서 Gemini에 전달하므로 "함께 사용됨"**

---

## 토큰 최적화 (isFirstMessage)

### 첫 메시지 vs 이후 메시지

| 대화 순서 | 포함 내용 |
|-----------|----------|
| **첫 메시지** | 프로필 + 사주 전체 (이름, 생년월일, 사주팔자, 오행, 용신, 십성, 신살 등) |
| **2번째 이후** | "(이전 대화에서 제공된 상세 사주 정보를 참조하세요)" 한 줄만 |

### 코드 (system_prompt_builder.dart:83-99)

```dart
// 프로필 정보 (첫 메시지만)
if (isFirstMessage && profile != null) {
  _addProfileInfo(profile, person1Label);
}

// 사주 데이터 (첫 메시지만)
if (isFirstMessage && sajuAnalysis != null) {
  _addSajuAnalysis(sajuAnalysis, person1SajuLabel);
} else if (!isFirstMessage) {
  _buffer.writeln('(이전 대화에서 제공된 상세 사주 정보를 참조하세요)');
}
```

### 이유

**토큰 비용 절약** - 매번 전체 사주 정보 보내면 Gemini API 비용 낭비

---

## 데이터 흐름

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. 프로필 저장 시                                                │
│    saju_analysis_service.dart                                   │
│    → GPT-5.2 API 호출                                           │
│    → ai_summaries 테이블 저장 (saju_base)                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. 채팅 시작 시                                                  │
│    system_prompt_builder.dart                                   │
│    ├── aiSummary (GPT-5.2 결과) 불러옴                           │
│    ├── personaPrompt (페르소나.buildFullSystemPrompt()) 받음     │
│    ├── sajuAnalysis (로컬 계산 결과)                             │
│    └── profile (사용자 정보)                                     │
│    → 전체 프롬프트 조립                                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. Gemini 채팅 API                                              │
│    → 응답 생성                                                   │
│    → chat_messages 테이블 저장                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## system_prompt_builder의 전체 프롬프트 구조

```
┌─────────────────────────────────────────────────────────────────┐
│ ## 현재 날짜                                                    │
│ 오늘은 2025년 1월 20일 (월요일)입니다.                           │
├─────────────────────────────────────────────────────────────────┤
│ ## 캐릭터 설정                                                  │
│ [페르소나.buildFullSystemPrompt() 결과]                          │
│ - 역할 정의                                                     │
│ - 말투 특징                                                     │
│ - 응답 스타일                                                   │
│ - 예시 대화                                                     │
│ - 금지사항                                                      │
├─────────────────────────────────────────────────────────────────┤
│ ## 기본 프롬프트 (MD 파일)                                       │
├─────────────────────────────────────────────────────────────────┤
│ ## 상담 대상자 정보                                              │
│ - 이름, 성별, 생년월일, 출생시간, 출생지역                        │
├─────────────────────────────────────────────────────────────────┤
│ ## 사주 기본 데이터 ⭐                                           │
│ [sajuAnalysis 또는 aiSummary.sajuOrigin]                        │
│ - 사주팔자 (년월일시 천간/지지)                                   │
│ - 오행 분포                                                     │
│ - 용신/희신/기신/구신                                            │
│ - 신강/신약                                                     │
│ - 격국                                                          │
│ - 십성 배치                                                     │
│ - 신살                                                          │
│ - 대운                                                          │
├─────────────────────────────────────────────────────────────────┤
│ ## (궁합 모드) 상대방 정보                                        │
├─────────────────────────────────────────────────────────────────┤
│ ## (궁합 모드) AI 궁합 분석 결과                                  │
├─────────────────────────────────────────────────────────────────┤
│ ## 마무리 지시문                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 저장 위치 비교

| 데이터 | 저장 테이블 | 저장 시점 |
|--------|-------------|----------|
| GPT-5.2 분석 결과 (saju_base) | `ai_summaries` | 프로필 저장 시 |
| 일운/월운/년운 | `ai_summaries` | 분석 요청 시 |
| 채팅 메시지 | `chat_messages` | 채팅 시 |
| 채팅용 전체 프롬프트 | **저장 안 함** | 실시간 생성 |

---

## 페르소나 추가 방법

1. `personas/` 폴더에 새 파일 생성 (예: `romantic_advisor.dart`)
2. `PersonaBase` 상속
3. 필수 getter 구현 (id, name, description, tone, emojiLevel, systemPrompt)
4. `persona_registry.dart`의 `_allPersonas` 리스트에 추가

```dart
class RomanticAdvisorPersona extends PersonaBase {
  @override
  String get id => 'romantic_advisor';

  @override
  String get name => '로맨틱 상담사';

  @override
  String get systemPrompt => '''
    당신은 연애 전문 사주 상담사입니다...
  ''';
  // ... 기타 구현
}
```

---

## 관련 파일 경로

| 구분 | 경로 |
|------|------|
| 페르소나 기본 클래스 | `frontend/lib/AI/jina/personas/persona_base.dart` |
| 페르소나 레지스트리 | `frontend/lib/AI/jina/personas/persona_registry.dart` |
| 채팅 프롬프트 빌더 | `frontend/lib/features/saju_chat/data/services/system_prompt_builder.dart` |
| GPT-5.2 분석 서비스 | `frontend/lib/AI/services/saju_analysis_service.dart` |
| AI 분석 저장 | `frontend/lib/AI/data/mutations.dart` |
