# Persona System 파일 경로 정리

## 개요

BasePerson + MBTI 4분면 + SpecialCharacter 시스템

```
┌─────────────────────────────────────────────────────────┐
│  왼쪽 사이드바          │  오른쪽 채팅 영역              │
│  (MBTI 4분면)          │  (페르소나 5개 선택)            │
├─────────────────────────────────────────────────────────┤
│     N                  │  🎭 Base   👶 아기동자          │
│   NF│NT               │  🗣️ 송작가  👴 새옹지마         │
│  F──●──T              │  😱 하꼬무당                    │
│   SF│ST               │                                │
│     S                  │  ← 5개 중 1개 선택             │
│                        │                                │
│ (BasePerson만 활성화)   │                                │
└─────────────────────────────────────────────────────────┘
```

**조합:** BasePerson(1) × MBTI(4) + SpecialChar(4) = **8가지**

---

## 프롬프트 수정 가이드 (팀원용)

### BasePerson MBTI 프롬프트 수정

| MBTI | 파일 경로 |
|------|----------|
| **NF 감성형** | `AI/jina/personas/base_nf.dart` |
| **NT 분석형** | `AI/jina/personas/base_nt.dart` |
| **SF 친근형** | `AI/jina/personas/base_sf.dart` |
| **ST 현실형** | `AI/jina/personas/base_st.dart` |

### SpecialCharacter 프롬프트 수정

| 캐릭터 | 파일 경로 |
|--------|----------|
| 👶 **아기동자** | `AI/jina/personas/baby_monk.dart` |
| 🗣️ **송작가** | `AI/jina/personas/scenario_writer.dart` |
| 👴 **새옹지마** | `AI/jina/personas/saeongjima.dart` |
| 😱 **하꼬무당** | `AI/jina/personas/newbie_shaman.dart` |

---

## 파일 구조

```
frontend/lib/AI/jina/personas/
│
├── persona_base.dart          ← 베이스 클래스 (수정 X)
├── persona_registry.dart      ← 페르소나 등록 (수정 X)
│
├── base_nf.dart               ← ⭐ NF 감성형 프롬프트
├── base_nt.dart               ← ⭐ NT 분석형 프롬프트
├── base_sf.dart               ← ⭐ SF 친근형 프롬프트
├── base_st.dart               ← ⭐ ST 현실형 프롬프트
│
├── baby_monk.dart             ← 👶 아기동자 프롬프트
├── scenario_writer.dart       ← 🗣️ 송작가 프롬프트
├── saeongjima.dart            ← 👴 새옹지마 프롬프트
└── newbie_shaman.dart         ← 😱 하꼬무당 프롬프트
```

---

## 프롬프트 수정 방법

### 1. 파일 열기
```dart
// 예: NF 감성형 프롬프트 수정
// 파일: AI/jina/personas/base_nf.dart
```

### 2. systemPrompt 수정
```dart
@override
String get systemPrompt => '''
[Base Persona: NF 감성형 상담사]

// ✏️ 여기 내용 수정!
// 핵심 성향, 말투 특징, 응답 스타일 등

''';
```

### 3. 기타 속성 수정 (선택)
```dart
@override
List<String> get greetings => [
  // 인사말 수정
];

@override
List<Map<String, String>> get examples => [
  // 대화 예시 수정
];

@override
List<String> get prohibitions => [
  // 금지 사항 수정
];
```

---

## UI 관련 파일

| 파일 | 역할 |
|------|------|
| `domain/models/chat_persona.dart` | ChatPersona enum (5개) |
| `domain/models/ai_persona.dart` | MbtiQuadrant enum (4개) |
| `presentation/providers/chat_persona_provider.dart` | 상태 관리 |
| `presentation/widgets/.../persona_selector_grid.dart` | 사이드바 MBTI 선택기 |
| `presentation/screens/saju_chat_shell.dart` | 페르소나 선택 UI |

---

## 새 페르소나 추가 방법

1. `AI/jina/personas/` 폴더에 새 파일 생성
2. `PersonaBase` 상속
3. 필수 getter 구현 (`id`, `name`, `systemPrompt` 등)
4. `persona_registry.dart`에 import 추가
5. `_allPersonas` 리스트에 인스턴스 추가

---

*마지막 업데이트: 2026-01-14*
*담당: Jina*
