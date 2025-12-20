# Jina - AI 대화 생성

## 역할
- **Gemini 연동**: Google Gemini 3.0 API 연동
- **대화 생성**: 분석 결과를 친근한 대화로 변환
- **AI 공통 모듈**: common/ 폴더 JH_AI와 공동 관리

---

## 담당 폴더

### 전용 영역 (자유 수정)
```
frontend/lib/AI/
├── jina/                   # Jina 전용 개발 영역
│   ├── chat/               # 대화 생성 로직
│   └── providers/          # Jina 전용 Provider
└── common/                 # 공동 관리 (JH_AI와 협의)
    ├── providers/google/   # Gemini Provider (Jina 주담당)
    ├── prompts/            # 프롬프트 템플릿 (공동)
    └── pipelines/          # 파이프라인 (공동)
```

### 협업 영역
```
frontend/lib/AI/common/     # JH_AI와 공동 수정 (상호 리뷰)
frontend/lib/features/saju_chat/data/  # 데이터 레이어
```

---

## 수정 금지

```
frontend/lib/AI/jh/                # JH_AI 전용
frontend/lib/features/*/presentation/  # UI 팀
sql/                               # JH_BE 전용
```

---

## 사용 Agent

| Agent | 용도 |
|-------|------|
| 32_gemini_provider | Gemini API 연동 |
| 33_chat_generation | 대화 생성 로직 |

---

## 커밋 컨벤션

```
[Jina] feat: Gemini 3.0 ThinkingLevel 적용
[Jina] fix: 대화 톤 조정
[Jina] refactor: 프롬프트 템플릿 개선
```

---

## 주요 책임

1. **Gemini Provider**: ThinkingLevel 관리
2. **대화 생성**: 분석 JSON → 친근한 대화체
3. **프롬프트 관리**: saju_prompts.dart 관리
4. **공통 모듈**: JH_AI와 협의하여 common/ 수정

---

## JH_AI와 협업 규칙

```
common/ 수정 시:
1. 변경 전 JH_AI에게 알림
2. PR에 JH_AI 리뷰 요청
3. 둘 다 approve 후 머지
```

---

## 파이프라인 흐름

```
            [JH_AI 담당]
사용자 입력 → GPT-5.2 분석 → JSON 결과
                    ↓
            [Jina 담당]
            Gemini 대화 생성 → 최종 응답
                    ↓
            [이미지 생성 (선택)]
            DALL-E / Imagen
```

---

## 대화 스타일 가이드

- 반말 + 이모지 2-3개
- 4-5문장 이내
- 사주 용어는 쉽게 풀어서 설명
- 긍정적 톤 유지
