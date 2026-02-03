# v30 복리 구조 구현 요약 (2026-02-02)

> `v30_ai_cost_audit.md`의 실행 계획을 실제 코드로 구현한 결과 정리

---

## 0. 한줄 요약

**"프로필 저장 시 $0.197 즉시 소모 → 유저가 실제로 쓸 때만 트리거 + 광고 중 백그라운드 분석 + 캐시 에러 자동 복구"**

---

## 1. 구현 완료 항목

| # | 항목 | 파일 | 상태 |
|---|------|------|------|
| 1 | Edge Function 변수 오타 수정 | `ai-gemini/index.ts:472` | 배포 완료 (v48) |
| 2 | Context Caching API 형식 수정 | `ai-gemini/index.ts:254-258` | 배포 완료 |
| 3 | 캐시 만료 시 fallback 재시도 | `ai-gemini/index.ts:363-388` | 배포 완료 |
| 4 | session_id 프론트→Edge 전달 | datasource→repository→provider 체인 | 완료 |
| 5 | DB 마이그레이션 (gemini_cache_name) | `chat_sessions` 테이블 | 적용 완료 |
| 6 | AdMob 정책 준수 배너 텍스트 | `token_depleted_banner.dart` | 완료 |
| 7 | Lazy saju_base (하단 네비) | `main_bottom_nav.dart` | 완료 |
| 8 | Lazy saju_base (운세 버튼) | `fortune_category_list.dart` | 완료 |
| 9 | Lazy saju_base (첫 채팅) | `chat_provider.dart` | 완료 |

---

## 2. 복리 구조 — 핵심 로직

### 2.1 비용 구조

```
유저 첫 사용 시 (1회성):
  saju_base (GPT-5.2)     = $0.197
  monthly_fortune (mini)   = $0.025
  yearly_2026 (mini)       = $0.019
  yearly_2025 (mini)       = $0.018
  daily_fortune (Gemini)   = $0.006
  ─────────────────────────────────
  초기 투자 합계           = $0.265

매일 반복:
  채팅 비용 (Gemini Flash) = ~$0.016/일 (20K 토큰 기준)
  daily_fortune 갱신       = $0.006/일
```

### 2.2 수익 구조

```
매일 반복:
  기본 20K 무료 채팅        → impression $0.004 + interstitial $0.010  = $0.014
  Native Ad click ×1       → CPC $0.050 (핵심!)                      = $0.050
  Rewarded Video ×1        → eCPM $0.020                             = $0.020
  인라인 impression ×2      → eCPM $0.008                             = $0.008
  ─────────────────────────────────────────────────────────────────────
  일일 수익 합계                                                       = $0.092
  일일 비용 합계 (기본+daily)                                           = $0.024
  일일 순수익                                                          = $0.068
```

### 2.3 BEP (손익분기점)

```
초기 투자 $0.265 ÷ 일일 순수익 $0.068 = 3.9일

Context Caching 적용 후: 3.6일
Lazy saju_base + Phase 분리 후: 1.4일
```

---

## 3. Lazy saju_base — 트리거 흐름

### 3.1 기존 (v29 이전)
```
프로필 저장 → 즉시 GPT-5.2 호출 ($0.197)
  → 채팅 안 하고 이탈하면 $0.197 손실
```

### 3.2 현재 (v30)
```
프로필 저장 → 트리거 없음 (비용 $0)

유저가 실제로 사용할 때만 트리거:

  경로 A: 하단 네비 "운세" 또는 "AI 상담" 탭
    main_bottom_nav.dart → _triggerSajuBaseIfNeeded()
    → 광고 표시 전에 fire-and-forget으로 분석 시작
    → 광고 보는 5~30초 동안 GPT-5.2 분석 진행

  경로 B: 운세 카테고리 버튼 (평생운세, 2025, 2026, 한달)
    fortune_category_list.dart → _triggerSajuBaseIfNeeded()
    → 전면광고 표시 중 백그라운드 분석
    → 페이지 도착 시 분석 완료/진행 중

  경로 C: 평생운세 페이지 로드
    lifetime_fortune_provider.dart → _triggerAnalysisIfNeeded()
    → 캐시 없으면 분석 시작 + 폴링으로 완료 감지
    → A/B에서 이미 시작했으면 중복 스킵

  경로 D: AI 채팅 첫 메시지
    chat_provider.dart → _ensureSajuBase()
    → 안전장치 (A/B에서 놓쳤을 경우)

  모든 경로에서 SajuAnalysisService._analyzingProfiles Set이
  중복 분석 방지 → 여러 경로 동시 호출해도 1번만 실행
```

---

## 4. Context Caching — 동작 흐름

### 4.1 세션 시작 시
```
프론트엔드:
  chat_provider.dart → sessionId 설정
  → gemini_edge_datasource.dart → HTTP body에 session_id 포함
  → Edge Function 수신

Edge Function (ai-gemini/index.ts):
  1. session_id로 chat_sessions.gemini_cache_name 조회
  2. 캐시 이름 없으면 → createGeminiCache() 호출
     - systemInstruction만 캐시 (contents 없음)
     - TTL 3600초 (1시간)
     - 생성된 cache_name을 DB에 저장
  3. 캐시 이름 있으면 → cachedContent로 요청
     - 캐시 히트: input $0.05/1M (90% 할인)
     - 캐시 미스: fallback으로 표준 요청
```

### 4.2 캐시 에러 시 (v27 fallback)
```
요청 실패 (400 등)
  → DB에서 gemini_cache_name 삭제
  → cacheName = null
  → 캐시 없이 표준 body로 재시도
  → 유저 입장에서는 정상 응답 (에러 안 보임)
```

---

## 5. 수정된 Edge Function 버그 3건

### BUG-1: 변수명 오타 (치명)
```
수정 전: cachedTokens (존재하지 않는 변수)
수정 후: totalCachedTokens
영향: 비용 기록 ReferenceError → 전체 비용 추적 실패
```

### BUG-2: Context Caching API 형식 (치명)
```
수정 전: contents + systemInstruction 동시 전송
  → Gemini API: contents 마지막이 model role이어야 함
  → user만 있으면 400 에러

수정 후: systemInstruction만 캐시
  → contents 없이 system prompt만 캐시 (우리 목적에 정확히 맞음)
  → 실제 대화는 별도 generateContent 요청에서 처리
```

### BUG-3: 캐시 만료 시 에러 반환 (중요)
```
수정 전: 캐시 에러 → DB 정리 → throw Error → 유저 메시지 실패
수정 후: 캐시 에러 → DB 정리 → 캐시 없이 재시도 → 정상 응답
```

---

## 6. 광고 배너 텍스트 변경

```
수정 전: "📋 광고 확인하고 바로 계속"
  → AdMob 정책 위반 가능 ("확인하고"가 클릭 유도로 해석)

수정 후: "📋 바로 대화 계속하기"
  → 광고 직접 언급 최소화, 정책 안전
```

---

## 7. 파일 변경 목록

| 파일 | 변경 내용 |
|------|----------|
| `supabase/functions/ai-gemini/index.ts` | BUG 3건 수정 + v27 버전 |
| `frontend/lib/core/widgets/main_bottom_nav.dart` | ConsumerWidget 전환 + saju_base lazy trigger |
| `frontend/lib/features/menu/presentation/widgets/fortune_category_list.dart` | ConsumerWidget 전환 + saju_base lazy trigger |
| `frontend/lib/features/saju_chat/presentation/providers/chat_provider.dart` | _ensureSajuBase() 추가 + import |
| `frontend/lib/features/saju_chat/data/datasources/gemini_edge_datasource.dart` | session_id 지원 |
| `frontend/lib/features/saju_chat/data/repositories/chat_repository_impl.dart` | session_id 패스스루 |
| `frontend/lib/features/saju_chat/presentation/widgets/token_depleted_banner.dart` | 배너 텍스트 변경 |
| `frontend/lib/features/profile/presentation/providers/profile_provider.dart` | _triggerSajuBaseAnalysis 주석 처리 (기존) |
| `supabase/migrations/20260202_add_gemini_cache_name.sql` | gemini_cache_name 컬럼 |

---

## 8. 미구현 (향후)

| 항목 | 설명 | 효과 |
|------|------|------|
| saju_base Phase 분리 | Phase 1-2만 즉시, 3-4는 접근 시 | $0.197 → $0.100 |
| AdMob 실측 CPC 추적 | 실제 Native click CPC 데이터 수집 | 정확한 BEP 계산 |
| GPT-5.2 Prompt Caching | system prompt 캐싱 ($1.75→$0.175) | 호출당 $0.007 절감 |
