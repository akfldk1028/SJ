# Phase 60 v3: Daily Fortune 무한 로딩 버그 수정 (2026-02-06)

Daily Fortune Provider의 `build()` 실행 순서 문제로 인한 무한 로딩 버그 분석 및 수정.

---

## 문제 현상

- 오늘의 운세 탭 진입 시 **무한 로딩** (스피너가 끝나지 않음)
- 로그에 `⏳ FortuneCoordinator에서 분석 중` + `invalidateSelf()` 반복
- monthly/yearly 분석 완료까지 60~120초간 daily 데이터 표시 불가

## 근본 원인

`daily_fortune_provider.dart`의 `build()` 메서드에서 **FortuneCoordinator.isAnalyzing() 체크가 DB 캐시 확인보다 먼저** 실행됨.

```
[수정 전 순서]
1. _currentlyAnalyzing 체크
2. FortuneCoordinator.isAnalyzing() 체크  ← 여기서 차단됨
3. DB 캐시 확인                           ← 도달 불가
```

### 왜 문제인가?

- `FortuneCoordinator.isAnalyzing()`은 4개 분석(daily + monthly + yearly2025 + yearly2026)을 **하나의 Set**으로 추적
- `_analyzingProfiles`는 `finally` 블록에서만 제거 → **4개 전부 끝나야 해제**
- Daily는 Gemini Flash로 ~3초면 끝나서 DB에 이미 저장됨
- 하지만 monthly/yearly는 GPT-5.2로 60~120초 소요
- 그 사이에 `isAnalyzing() = true` → DB 확인 스킵 → null 반환 → 무한 로딩

---

## 수정 내용

### 파일: `frontend/lib/features/menu/presentation/providers/daily_fortune_provider.dart`

### Fix 1: build() 실행 순서 변경 (핵심)

```
[수정 후 순서]
1. _currentlyAnalyzing 체크          (변경 없음)
2. DB 캐시 확인                      ← 먼저! 데이터 있으면 즉시 반환
3. FortuneCoordinator.isAnalyzing()  (캐시 miss일 때만 도달)
4. _analyzedToday 중복 방지 체크
5. AI 분석 트리거
```

**효과**: Daily 데이터가 DB에 있으면 FortuneCoordinator 상태와 무관하게 즉시 반환.

### Fix 2: 중복 폴링 방지 (`_pollingForCompletion` Set 추가)

```dart
static final Set<String> _pollingForCompletion = {};
```

- `_waitForCoordinatorCompletion()` 진입 시 Set 체크
- 이미 폴링 중이면 스킵 → build() 재호출로 폴링이 누적되는 문제 해결

### Fix 3: invalidateSelf() 조건부 호출

```dart
// 수정 전: 성공/실패 무관하게 항상 invalidateSelf()
// 수정 후: 성공 시에만 invalidateSelf()
fortuneCoordinator.analyzeDailyOnly(...).then((result) {
  _currentlyAnalyzing.remove(profileId);
  if (result.success) {
    ref.invalidateSelf();  // 성공 시에만
  }
}).catchError((e) {
  _currentlyAnalyzing.remove(profileId);
  // 에러 시 invalidate 안 함 → 수동 새로고침으로 재시도 유도
});
```

### refresh() 업데이트

```dart
_pollingForCompletion.remove(activeProfile.id);  // 폴링 플래그도 리셋
```

---

## DB Migration (v32)

### 파일: `sql/migrations/20260206_remove_ai_summaries_profile_display_name_sync.sql`

- `sync_user_display_name()` 트리거에서 `ai_summaries.profile_display_name` 동기화 제거
- 앱에서 이 필드를 사용하지 않으며, 프로필 이름 변경 시 과거 운세 기록 보존
- **서버 측 변경이므로 이미 모든 사용자에게 적용됨**

---

## 배포 영향

| 수정 | 위치 | 반영 방식 |
|------|------|----------|
| v32 migration | 서버 (Supabase DB) | 자동 반영 (적용 완료) |
| daily_fortune_provider.dart | 클라이언트 (Flutter) | **새 빌드 필요** |

---

## 테스트 결과

- 에뮬레이터에서 `✅ 캐시 히트 - 오늘의 운세 로드 (분석 스킵)` 즉시 출력
- 무한 루프 로그 없음
- idiom 파싱 정상 (사자성어 + 한자)
- `dart analyze`: 0 errors
