# Jina - Gemini 3.0 대화 생성 TODO

> 작성일: 2024-12-21
> 담당: Jina (Gemini 3.0 대화 + 페르소나 + 이미지 생성)

---

## 핵심 원칙

**JH_AI의 정확한 분석 → Jina가 재미있게 변환**

```
[JH_AI]                        [Jina]
GPT-5.2 분석 → JSON 결과 → Gemini 대화 생성 → 최종 응답
                                    ↓
                            (선택) Nanabanan 이미지 생성
```

---

## 우선순위 가이드

| 우선순위 | 설명 |
|----------|------|
| **P0** | MVP 필수 - 앱 출시 전 완료 |
| **P1** | 핵심 기능 - MVP 직후 |
| **P2** | 고급 기능 - 추후 |

---

## Phase 1: Gemini 3.0 기본 연동 (P0)

### 1.1 Gemini Provider 설정

```
📁 frontend/lib/AI/common/providers/google/
├── gemini_provider.dart         [ ] 기본 Provider
├── gemini_config.dart           [ ] 설정 (모델, API키)
└── gemini_response_parser.dart  [ ] 응답 파싱
```

### 1.2 ThinkingLevel 설정

```dart
enum ThinkingLevel {
  none,       // 빠른 응답 (단순 질문)
  low,        // 약간의 추론
  medium,     // 보통 추론 (일반 대화)
  high,       // 깊은 추론 (복잡한 해석)
}
```

| 상황 | ThinkingLevel |
|------|---------------|
| 단순 인사 | none |
| 일반 사주 질문 | medium |
| 심층 해석 요청 | high |
| 궁합 분석 | high |

- [ ] ThinkingLevel enum 정의
- [ ] 상황별 레벨 자동 선택 로직
- [ ] Gemini API 호출 구현

---

## Phase 2: 대화 생성 (P0)

### 2.1 JSON → 대화 변환

```
📁 frontend/lib/AI/jina/chat/
├── response_generator.dart      [ ] 응답 생성기
├── tone_adjuster.dart           [ ] 톤 조절
└── emoji_injector.dart          [ ] 이모지 추가
```

### 2.2 대화 스타일 가이드

| 항목 | 규칙 |
|------|------|
| 말투 | 반말 (친근) |
| 이모지 | 2-3개 적절히 |
| 문장 수 | 4-5문장 이내 |
| 사주 용어 | 쉽게 풀어서 |
| 톤 | 긍정적, 희망적 |

- [ ] JSON 파싱 로직
- [ ] 템플릿 기반 문장 생성
- [ ] 이모지 자동 삽입
- [ ] 긍정적 톤 유지 로직

---

## Phase 3: 페르소나 시스템 (P1)

### 3.1 페르소나 정의

```
📁 frontend/lib/AI/jina/personas/
├── persona_base.dart            [ ] 기본 클래스
├── friendly_sister.dart         [ ] 친근한 언니
├── wise_scholar.dart            [ ] 현명한 학자
├── cute_friend.dart             [ ] 귀여운 친구
└── persona_selector.dart        [ ] 페르소나 선택
```

### 3.2 기본 페르소나들

| 페르소나 | 말투 | 특징 |
|----------|------|------|
| 친근한 언니 | 반말, 따뜻 | 기본값 |
| 현명한 학자 | 존댓말, 진중 | 심층 분석 시 |
| 귀여운 친구 | 반말, 발랄 | 젊은 유저용 |
| 도도한 점술가 | 반말, 신비 | 재미 요소 |

- [ ] 4가지 기본 페르소나 정의
- [ ] 유저 선호도 저장
- [ ] 상황별 자동 전환 로직

---

## Phase 4: 맥락 기반 대화 (P1)

### 4.1 대화 히스토리 관리

```
📁 frontend/lib/AI/jina/context/
├── chat_history_manager.dart    [ ] 히스토리 관리
├── context_builder.dart         [ ] 맥락 구성
└── memory_summarizer.dart       [ ] 요약 (토큰 절약)
```

### 4.2 맥락 유형

| 유형 | 활용 |
|------|------|
| 사주 정보 | 이전 분석 결과 참조 |
| 대화 히스토리 | 이전 질문 기억 |
| 유저 선호도 | 관심 주제 파악 |
| 시간 정보 | 계절/시간대별 맞춤 |

- [ ] 대화 히스토리 저장 (최근 10개)
- [ ] 토큰 최적화를 위한 요약
- [ ] 맥락 기반 응답 생성

---

## Phase 5: Nanabanan 이미지 생성 (P2)

### 5.1 Nanabanan 연동

```
📁 frontend/lib/AI/jina/image/
├── nanabanan_provider.dart      [ ] 이미지 생성 Provider
├── saju_illustration_prompt.dart [ ] 사주 일러스트 프롬프트
└── image_style_config.dart      [ ] 스타일 설정
```

### 5.2 이미지 생성 시나리오

| 시나리오 | 설명 |
|----------|------|
| 오행 캐릭터 | 목/화/토/금/수 의인화 |
| 사주 만화 | 사주 해석을 만화 형식으로 |
| 운세 일러스트 | 오늘의 운세 시각화 |
| 궁합 이미지 | 두 사주의 궁합 표현 |

- [ ] Gemini Image 모델 연동 (gemini-2.5-flash-image-preview)
- [ ] 오행별 캐릭터 프롬프트
- [ ] 스타일 일관성 유지
- [ ] 생성 이미지 캐싱

---

## Phase 6: 특수 기능 (P2)

### 6.1 궁합 대화

- [ ] 궁합 점수 계산 (JH_AI에서 받음)
- [ ] 궁합 대화 템플릿
- [ ] 강점/약점 재미있게 표현

### 6.2 오늘의 조언

- [ ] 일진 분석 연동
- [ ] 맞춤 조언 생성
- [ ] 럭키 아이템 추천

### 6.3 질문 유형 분류

```dart
enum QuestionType {
  general,      // 일반 질문
  career,       // 직업/진로
  love,         // 연애/결혼
  money,        // 재물
  health,       // 건강
  relationship, // 대인관계
  timing,       // 시기/타이밍
}
```

- [ ] 질문 유형 자동 분류
- [ ] 유형별 맞춤 답변 템플릿

---

## 프롬프트 관리

### 공통 프롬프트 파일

```
📁 frontend/lib/AI/common/prompts/
├── base_system_prompt.dart      # 기본 시스템 프롬프트
├── saju_prompts.dart            # 사주 관련 프롬프트
├── chat_prompts.dart            # 대화 프롬프트 (Jina 주관)
└── persona_prompts.dart         # 페르소나 프롬프트 (Jina 주관)
```

---

## 체크리스트

### Phase 1: Gemini 연동 (P0)
- [ ] Gemini Provider 기본 구현
- [ ] ThinkingLevel 설정
- [ ] API 호출 테스트

### Phase 2: 대화 생성 (P0)
- [ ] JSON → 대화 변환 로직
- [ ] 톤/스타일 조절
- [ ] 이모지 자동 삽입
- [ ] 템플릿 시스템

### Phase 3: 페르소나 (P1)
- [ ] 4가지 기본 페르소나
- [ ] 페르소나 선택 UI
- [ ] 유저 선호도 저장

### Phase 4: 맥락 대화 (P1)
- [ ] 대화 히스토리 관리
- [ ] 맥락 기반 응답
- [ ] 토큰 최적화

### Phase 5: Nanabanan (P2)
- [ ] 이미지 생성 연동
- [ ] 오행 캐릭터 프롬프트
- [ ] 사주 만화 생성
- [ ] 이미지 캐싱

### Phase 6: 특수 기능 (P2)
- [ ] 궁합 대화
- [ ] 오늘의 조언
- [ ] 질문 유형 분류

---

## JH_AI와 연동 인터페이스

### JSON 입력 형식 (JH_AI → Jina)

```dart
class SajuAnalysisResult {
  final FourPillars fourPillars;       // 4주
  final OhaengDistribution ohaeng;      // 오행 분포
  final TenGodsResult tenGods;          // 십성
  final TwelveStagesResult twelveStages;// 12운성
  final RelationsResult relations;       // 합충형해파
  final SpiritsResult spirits;           // 신살
  final String yongshin;                 // 용신
  final String geokguk;                  // 격국
}
```

### 연동 Flow

```
1. JH_AI: GPT-5.2로 정확한 분석 수행
2. JH_AI: SajuAnalysisResult JSON 생성
3. Jina: JSON 수신
4. Jina: Gemini 3.0으로 재미있는 대화 생성
5. Jina: (선택) Nanabanan으로 이미지 생성
6. UI: 최종 응답 표시
```

---

## 일정

| Phase | 예상 | 비고 |
|-------|------|------|
| Phase 1 | 1일 | Gemini 연동 |
| Phase 2 | 2일 | 대화 생성 |
| Phase 3 | 2일 | 페르소나 |
| Phase 4 | 1일 | 맥락 대화 |
| Phase 5 | 3일 | Nanabanan |
| Phase 6 | 2일 | 특수 기능 |

**총: 약 11일**
