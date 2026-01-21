# 평생운세 청크 분할 아키텍처

> 작성일: 2026-01-21
> 목적: Supabase Edge Function 타임아웃 해결 + UX 개선

---

## 현재 문제

- 한 번의 API 호출로 17개 섹션 전체 생성 → ~5분 소요
- Supabase Edge Function 타임아웃 제한
- 폴링 타임아웃 60회 발생
- 사용자 체감 대기 시간이 너무 김

---

## Phase 분할 전략

### 개요

| Phase | 이름 | 섹션 | 모델 | 예상 시간 |
|-------|------|------|------|----------|
| **1** | Foundation | 원국, 십성, 합충, 성격, 행운요소 | GPT-5.2 Thinking | 60-90초 |
| **2** | Fortune | 재물운, 직업운, 사업운, 애정운, 결혼운 | GPT-5.2 Instant | 30-45초 |
| **3** | Special | 신살/길성, 건강운, 대운상세 | GPT-5.2 Instant | 30-45초 |
| **4** | Synthesis | 인생주기, 전성기, 현대해석, 마무리 | GPT-5.2 Thinking | 60-90초 |

**총 예상 시간: 3-4.5분** (기존 5분에서 개선)

**핵심 포인트: 첫 콘텐츠를 60-90초 만에 표시 가능!**

---

### Phase 1: Foundation (기초 분석)

**모델**: GPT-5.2 Thinking (필수 - 정확성 최우선)

**출력 섹션**:
- `original_chart` - 원국 분석
- `ten_stars` - 십성 분석
- `hapchung` - 합충 분석
- `personality` - 성격 분석
- `lucky_elements` - 행운 요소

**의존성**: 없음 (최초 분석)

**입력**: 사주 데이터 (생년월일시, 성별, 만세력 계산 결과)

---

### Phase 2: Fortune (운세 분석)

**모델**: GPT-5.2 Instant (비용 절약 가능)

**출력 섹션**:
- `wealth` - 재물운
- `career` - 직업운
- `business` - 사업운
- `love` - 애정운
- `marriage` - 결혼운

**의존성**: Phase 1 결과 필요 (십성, 합충 기반)

**입력**: 사주 데이터 + Phase 1 결과 요약

---

### Phase 3: Special (특수 분석)

**모델**: GPT-5.2 Instant (비용 절약 가능)

**출력 섹션**:
- `sinsal_gilseong` - 신살/길성
- `health` - 건강운
- `daeun_detail` - 대운 상세

**의존성**: Phase 1 결과 필요

**입력**: 사주 데이터 + Phase 1 결과 요약

---

### Phase 4: Synthesis (종합 분석)

**모델**: GPT-5.2 Thinking (권장 - 전체 맥락 종합)

**출력 섹션**:
- `life_cycles` - 인생 주기 (청년기/중년기/후년기)
- `peak_years` - 인생 전성기
- `modern` - 현대적 해석
- `closing_message` - 마무리 메시지

**의존성**: Phase 1~3 결과 전체 필요

**입력**: 사주 데이터 + Phase 1~3 결과 전체

---

## 시스템 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                        클라이언트 (Flutter)                       │
├─────────────────────────────────────────────────────────────────┤
│  1. 사주 입력 → 만세력 계산 → DB 저장                              │
│  2. Phase 1 Edge Function 호출                                   │
│  3. 폴링 시작 (3초 간격)                                          │
│  4. Phase 1 완료 → 원국/성격 UI 표시 + Phase 2 호출               │
│  5. Phase 2 완료 → 운세 UI 추가 표시 + Phase 3 호출               │
│  6. Phase 3 완료 → 신살/건강 UI 추가 + Phase 4 호출               │
│  7. Phase 4 완료 → 인생주기 UI 추가, 폴링 중단                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Supabase Edge Functions                      │
├─────────────────────────────────────────────────────────────────┤
│  saju-analysis-phase1  │ Thinking │ 원국,십성,합충,성격,행운     │
│  saju-analysis-phase2  │ Instant  │ 재물,직업,사업,애정,결혼     │
│  saju-analysis-phase3  │ Instant  │ 신살,건강,대운상세           │
│  saju-analysis-phase4  │ Thinking │ 인생주기,전성기,현대해석     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Supabase DB                               │
├─────────────────────────────────────────────────────────────────┤
│  ai_tasks 테이블 확장:                                           │
│  - phase: INTEGER (현재 진행 중인 Phase, 1-4)                    │
│  - total_phases: INTEGER (기본값 4)                              │
│  - partial_result: JSONB (Phase별 누적 결과)                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## DB 스키마 변경

### Option A: ai_tasks 테이블 확장 (권장)

```sql
-- 기존 ai_tasks 테이블에 컬럼 추가
ALTER TABLE ai_tasks ADD COLUMN phase INTEGER DEFAULT 1;
ALTER TABLE ai_tasks ADD COLUMN total_phases INTEGER DEFAULT 4;
ALTER TABLE ai_tasks ADD COLUMN partial_result JSONB DEFAULT '{}';
```

### 상태 흐름

```
Phase 1 시작: status='processing', phase=1
Phase 1 완료: partial_result에 Phase 1 결과 저장, phase=2
Phase 2 시작: status='processing' 유지
Phase 2 완료: partial_result에 Phase 2 결과 병합, phase=3
...
Phase 4 완료: status='completed', result에 전체 결과 저장
```

---

## UX: Progressive Disclosure (점진적 표시)

### 진행 상황 UI

```
[=====>          ] 25% - 기초 분석 중...
[===========>    ] 50% - 운세 분석 중...
[===============>] 75% - 특수 분석 중...
[==================] 100% - 분석 완료!
```

### 콘텐츠 표시 전략

| Phase 완료 | 표시할 섹션 |
|-----------|------------|
| Phase 1 | 원국 분석, 십성 분석, 성격 분석 |
| Phase 2 | + 재물운, 직업운, 사업운, 애정운, 결혼운 |
| Phase 3 | + 신살/길성, 건강운, 대운 상세 |
| Phase 4 | + 인생 주기, 전성기, 현대 해석, 마무리 |

**이점**:
1. 사용자가 기다리는 동안 이미 완료된 부분 읽을 수 있음
2. 체감 대기 시간 대폭 감소
3. 앱이 "일하고 있다"는 느낌 제공

---

## 폴링 전략

```dart
// 폴링 간격
const pollingInterval = Duration(seconds: 3);

// 폴링 로직
void pollTaskStatus() async {
  final task = await getTaskStatus(taskId);

  if (task.phase > currentDisplayedPhase) {
    // 새 Phase 완료됨 → UI 업데이트
    updateUI(task.partialResult);
    currentDisplayedPhase = task.phase;

    if (task.phase < 4) {
      // 다음 Phase 호출
      await triggerNextPhase(taskId, task.phase + 1);
    }
  }

  if (task.status == 'completed') {
    // 전체 완료 → 폴링 중단
    stopPolling();
  }
}
```

---

## 비용 최적화

| 모델 | 가격 (1K tokens) | 사용 Phase |
|------|-----------------|-----------|
| GPT-5.2 Thinking | ~$0.15 | Phase 1, 4 |
| GPT-5.2 Instant | ~$0.03 | Phase 2, 3 |

**예상 비용 절약: 기존 대비 ~40%**

---

## 캐싱 전략

### Phase 1 결과 캐싱

- Phase 1 결과(원국, 십성, 합충)는 동일 사주에 대해 재사용 가능
- 원국은 변하지 않으므로 영구 캐싱 가능

```
캐시 키: {user_id}_{birth_data_hash}
TTL: 영구 (사주 정보가 변경되지 않는 한)
```

---

## 실패 복구

1. 특정 Phase 실패시 해당 Phase만 재시도
2. `partial_result`가 있으므로 처음부터 다시 시작할 필요 없음
3. 최대 3회 재시도 후 실패 처리

```dart
Future<void> retryPhase(String taskId, int phase) async {
  for (int attempt = 1; attempt <= 3; attempt++) {
    try {
      await triggerPhase(taskId, phase);
      return; // 성공
    } catch (e) {
      if (attempt == 3) {
        markTaskFailed(taskId, 'Phase $phase failed after 3 attempts');
      }
      await Future.delayed(Duration(seconds: 5 * attempt)); // 백오프
    }
  }
}
```

---

## 구현 우선순위

1. **DB 스키마 수정** - phase, partial_result 컬럼 추가
2. **Edge Function 4개 분리** - 각 Phase별 함수 생성
3. **프롬프트 4개 분할** - 각 Phase별 JSON 스키마 정의
4. **프론트엔드 폴링 수정** - Phase 감지 + 다음 Phase 호출
5. **Progressive UI** - Phase별 섹션 표시 구현

---

## 대안: 스트리밍 방식

만약 추후 Supabase Edge Function이 스트리밍을 완전 지원한다면:

- 한 번의 호출로 전체 생성
- SSE(Server-Sent Events)로 섹션별 스트리밍
- 프론트에서 실시간 표시

현재는 Supabase Edge Function의 스트리밍 지원이 제한적이므로
**Phase 분할 방식이 더 현실적**

---

## 관련 파일

- `saju_base_prompt.md` - 기존 전체 프롬프트
- `saju_base_prompt.dart` - 프롬프트 Dart 클래스
- `saju_analysis_service.dart` - 분석 서비스 (수정 필요)
