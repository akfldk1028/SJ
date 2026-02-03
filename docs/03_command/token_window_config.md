# 토큰 윈도우 설정 가이드

## KST 트리거 수정 (2026-02-03)

**v30 마이그레이션 적용됨**: `update_daily_chat_tokens` 함수에서 `CURRENT_DATE`를 KST로 변환

| 변경 전 | 변경 후 |
|---------|---------|
| `CURRENT_DATE` (UTC) | `(NOW() AT TIME ZONE 'Asia/Seoul')::DATE` (KST) |

**문제**: 한국 시간 자정~오전 9시 사이에 채팅하면 날짜가 하루 전으로 잘못 기록됨
**해결**: KST 기준으로 날짜 계산

---

## 현재 설정 (2026-02-02 수정)

| 파라미터 | 변경 전 | 변경 후 | 파일 |
|----------|---------|---------|------|
| `defaultMaxInputTokens` | 20,000 | 20,000 (유지) | `token_counter.dart:28` |
| `safetyMargin` | 18,000 | 2,000 | `token_counter.dart:25` |

## 에러 원인

`purchase` 커밋(2/1)에서 `defaultMaxInputTokens`를 `50,000 → 20,000`으로 변경했으나, `safetyMargin`은 `18,000`으로 그대로 두었음.

```
availableTokens = defaultMaxInputTokens - safetyMargin - systemPromptTokens
                = 20,000 - 18,000 - ~1,500
                = 500  ← 대화 메시지 1개도 못 들어감!
```

결과: `_buildMessagesForEdge()`에서 user/assistant 메시지가 전부 잘려서 Gemini API에 `contents: []` 전송 → `"contents is not specified"` 에러 (500/400).

## 원리

### ConversationWindowManager 동작

```
[시스템 프롬프트] + [대화 메시지들] → Gemini API
     ↑                    ↑
 항상 포함         토큰 한도 내에서 최신 메시지 우선
```

1. `defaultMaxInputTokens`: Gemini에 보낼 **입력 토큰 총 한도** (컨텍스트 윈도우)
2. `safetyMargin`: 출력 토큰용 예약 공간 (Gemini 응답 생성에 필요)
3. `availableTokens = maxInputTokens - safetyMargin - systemPromptTokens`
4. 대화 메시지를 최신순으로 `availableTokens`만큼 채움
5. `availableTokens <= 0`이면 **대화 메시지 전부 삭제** → 에러 발생

### safetyMargin의 의미

- Gemini 모델의 컨텍스트 윈도우 = 입력 토큰 + 출력 토큰
- `safetyMargin`은 출력(응답) 토큰을 위해 미리 빼놓는 공간
- 실제 채팅 `max_tokens = 1024` → safetyMargin은 1024 + 여유분이면 충분

### defaultMaxInputTokens vs 일일 quota

| 개념 | 용도 | 현재 값 |
|------|------|---------|
| `defaultMaxInputTokens` | 1회 API 호출의 입력 토큰 한도 (컨텍스트 윈도우 크기) | 20,000 |
| `DAILY_QUOTA` | 하루 총 사용 가능 토큰 (Edge Function) | 20,000 |
| `safetyMargin` | 출력 토큰 예약 공간 | 2,000 |

이 두 값은 **별개 개념**:
- `defaultMaxInputTokens`: 한번에 Gemini에 보내는 대화 컨텍스트 크기
- `DAILY_QUOTA`: 하루 동안 누적 사용량 제한

## 설정 시나리오

### A. 현재 설정 (보수적)

```
defaultMaxInputTokens = 20,000
safetyMargin = 2,000
→ 대화 공간: ~16,500 토큰 (시스템 프롬프트 제외)
→ 약 10~15 교환 유지 가능
```

### B. 넉넉한 설정

```
defaultMaxInputTokens = 30,000
safetyMargin = 2,000
→ 대화 공간: ~26,500 토큰
→ 약 20~25 교환 유지 가능
→ 단, 1회 API 호출 비용 증가 (프롬프트 토큰 과금)
```

### C. 최소 설정 (비용 절약)

```
defaultMaxInputTokens = 10,000
safetyMargin = 2,000
→ 대화 공간: ~6,500 토큰
→ 약 5~7 교환 유지 가능
→ 오래된 대화가 빨리 잘림 (요약으로 보완)
```

## 비용 영향

Gemini 3 Flash 가격 (2026-02):
- 입력: $0.50 / 1M tokens
- 출력: $3.00 / 1M tokens

| 설정 | 1회 입력 비용 (만토큰) | 1회 출력 비용 (1024토큰) | 합계 |
|------|----------------------|------------------------|------|
| 10K | $0.005 | $0.003 | $0.008 |
| 20K | $0.010 | $0.003 | $0.013 |
| 30K | $0.015 | $0.003 | $0.018 |

## 결정 필요 사항

- [ ] `defaultMaxInputTokens` 최종 값 결정 (10K / 20K / 30K)
- [ ] `safetyMargin = 2,000` 유지 여부 확인
- [ ] 일일 quota(20,000)와 입력 윈도우 관계 정리 (같은 값이면 첫 메시지에서 쿼터 소진)
