# JH_AI - AI 분석 모듈

## 역할
- **GPT 연동**: OpenAI GPT-5.2 API 연동
- **사주 분석**: 사주팔자 분석 로직 구현
- **AI 공통 모듈**: common/ 폴더 JH_AI + Jina 공동 관리

---

## 담당 폴더

### 전용 영역 (자유 수정)
```
frontend/lib/AI/
├── jh/                     # JH 전용 개발 영역
│   ├── analysis/           # 분석 로직
│   └── providers/          # JH 전용 Provider
└── common/                 # 공동 관리 (Jina와 협의)
    ├── core/               # 설정, 로거
    ├── providers/openai/   # GPT Provider (JH 주담당)
    └── pipelines/          # 파이프라인 (공동)
```

### 협업 영역
```
frontend/lib/AI/common/     # Jina와 공동 수정 (상호 리뷰)
frontend/lib/features/saju_chat/data/  # 데이터 레이어
```

---

## 수정 금지

```
frontend/lib/AI/jina/              # Jina 전용
frontend/lib/features/*/presentation/  # UI 팀
sql/                               # JH_BE 전용
```

---

## 사용 Agent

| Agent | 용도 |
|-------|------|
| 30_gpt_provider | GPT API 연동 |
| 31_saju_analysis | 사주 분석 로직 |
| 09_manseryeok_calculator | 만세력 계산 |

---

## 커밋 컨벤션

```
[JH_AI] feat: GPT-5.2 Responses API 적용
[JH_AI] fix: 사주 분석 오류 수정
[JH_AI] refactor: 공통 Provider 구조 개선
```

---

## 주요 책임

1. **GPT Provider**: ReasoningEffort 레벨 관리
2. **분석 파이프라인**: GPT 분석 → JSON 파싱 → 결과 반환
3. **공통 모듈**: Jina와 협의하여 common/ 수정

---

## Jina와 협업 규칙

```
common/ 수정 시:
1. 변경 전 Jina에게 알림
2. PR에 Jina 리뷰 요청
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
```
