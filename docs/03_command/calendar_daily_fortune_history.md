# 캘린더 Daily Fortune 히스토리 조회 이슈 및 수정 (2026-02-06)

> 캘린더에서 과거 날짜 탭 시 "해당 날짜의 운세 기록이 없습니다" 표시 문제 분석 및 해결

---

## 문제 현상

캘린더 화면에서 과거 날짜를 탭하면 DB에 데이터가 있음에도 "해당 날짜의 운세 기록이 없습니다"로 표시됨.

### 스크린샷 증상
- 2/3, 2/4, 2/5 날짜 탭 → "해당 날짜의 운세 기록이 없습니다"
- 2/6 (오늘) → 정상 표시

---

## 원인 분석 (3단계)

### 원인 1: prompt_version 필터

`getCachedSummary()` (queries.dart)에서 **모든 날짜에 현재 프롬프트 버전 필터** 적용.

```
DB 데이터:
  2/1 → V2.3 (구 버전)
  2/3 → V2.3 (구 버전)
  2/6 → V2.4 (현재 버전)

앱 필터: prompt_version = 'V2.4'
결과: 2/1, 2/3 → BLOCKED (버전 불일치)
```

**문제**: 과거 날짜는 그 당시 버전으로 생성된 데이터. 현재 버전과 다를 수밖에 없음.

### 원인 2: expires_at 필터

Daily fortune은 `expires_at`이 해당 날짜 23:59:59 KST로 설정됨.

```
DB 데이터:
  2/3 → expires_at: 2026-02-03 14:59:59+00 (= 2/3 23:59:59 KST)
  2/5 → expires_at: 2026-02-05 14:59:59+00 (= 2/5 23:59:59 KST)

앱 필터: expires_at > NOW() (2026-02-06 09:00 UTC)
결과: 2/3, 2/5 → BLOCKED (만료됨)
```

**문제**: 과거 날짜의 daily fortune은 구조적으로 항상 만료 상태.

### 원인 3: isPastDate 판정 타이밍 이슈 (수정 전 코드)

초기 수정에서 `DateTime.now().subtract(Duration(hours: 15))` 사용:

```dart
// 수정 전 (불안정)
final isPastDate = targetDate.isBefore(
    DateTime.now().subtract(const Duration(hours: 15)));
```

**문제**: 15시간 버퍼가 시간대에 따라 "어제"를 과거로 인식 못하는 경우 발생.

```
시나리오: 2/6 18:00 KST (= 09:00 UTC)
NOW() - 15시간 = 2/6 03:00 KST

2/5 00:00:00 < 2/6 03:00:00 → true (past) ← 대부분 OK
BUT: 서버 시간이 UTC 기준이면 계산 달라질 수 있음

시나리오: 2/6 00:30 KST (= 2/5 15:30 UTC)
NOW() - 15시간 = 2/5 09:30 KST
2/5 00:00:00 < 2/5 09:30:00 → true ← OK

시나리오: DB 시뮬레이션에서 2/5가 BLOCKED
isPastDate = target_date < (NOW() - 15hours)::date
2/5 < 2/5 → false → NOT PAST → expiry 필터 적용 → BLOCKED!
```

---

## 수정 내용

### 파일 1: `frontend/lib/AI/data/queries.dart` (getCachedSummary)

**핵심 코드 경로**: 캘린더 날짜 탭 → `dailyFortuneForDateProvider` → `aiQueries.getDailyFortune()` → `getCachedSummary()`

#### 변경 1: isPastDate 판정 → KoreaDateUtils.today 기준

```dart
// 수정 전 (불안정)
final isPastDate = targetDate != null &&
    targetDate.isBefore(DateTime.now().subtract(const Duration(hours: 15)));

// 수정 후 (안정)
final koreaToday = KoreaDateUtils.today;
final isPastDate = targetDate != null &&
    targetDate.isBefore(koreaToday);
```

#### 변경 2: 과거 daily_fortune은 prompt_version 필터 스킵

```dart
final skipVersionFilter = isPastDate && summaryType == SummaryType.dailyFortune;

if (!skipVersionFilter) {
  final expectedVersion = PromptVersions.forSummaryType(summaryType);
  if (expectedVersion != null) {
    query = query.eq('prompt_version', expectedVersion);
  }
}
```

#### 변경 3: 과거 daily_fortune은 expires_at 필터 스킵

```dart
if (!skipVersionFilter) {
  query = query.or(
    '${AiSummaries.c_expiresAt}.is.null,${AiSummaries.c_expiresAt}.gt.${DateTime.now().toUtc().toIso8601String()}',
  );
}
```

#### import 추가

```dart
import '../fortune/common/korea_date_utils.dart';
```

### 파일 2: `frontend/lib/AI/fortune/daily/daily_queries.dart` (getCached)

> 참고: 캘린더 경로에서는 이 파일을 직접 호출하지 않지만, 일관성을 위해 동일 로직 적용.

#### 변경: 과거 날짜면 만료 + 버전 체크 모두 스킵

```dart
// 수정 전
final expiresAt = response['expires_at'];
if (expiresAt != null) { /* 항상 만료 체크 */ }

final isPastDate = targetDate.isBefore(
    DateTime.now().subtract(const Duration(hours: 15)));
// 과거면 버전만 스킵, 만료는 여전히 체크 ← 문제!

// 수정 후
final isPastDate = targetDate.isBefore(KoreaDateUtils.today);

if (!isPastDate) {
  // 오늘만 만료 체크
  final expiresAt = response['expires_at'];
  if (expiresAt != null) { /* 만료 체크 */ }
}

// 오늘만 버전 체크
if (!isPastDate && cachedVersion != kDailyFortunePromptVersion) {
  return null;
}
```

---

## 코드 경로 요약

```
캘린더 날짜 탭
  │
  ├─ calendar_screen.dart:408
  │   ref.watch(dailyFortuneForDateProvider(selectedDay))
  │
  ├─ daily_fortune_provider.dart:440-456
  │   aiQueries.getDailyFortune(profileId, date)
  │
  └─ queries.dart:90-142  getCachedSummary()
      │
      ├─ FILTER 1: profile_id = ? ............... 항상 적용
      ├─ FILTER 2: summary_type = 'daily_fortune'  항상 적용
      ├─ FILTER 3: status = 'completed' ......... 항상 적용
      ├─ FILTER 4: target_date = 'YYYY-MM-DD' .. 항상 적용
      │
      ├─ isPastDate 판정: targetDate < KoreaDateUtils.today
      │
      ├─ FILTER 5: prompt_version = 'V2.4' ..... 오늘만 (과거 SKIP)
      └─ FILTER 6: expires_at > NOW() .......... 오늘만 (과거 SKIP)
```

---

## 검증 결과

"김동현" 프로필 (`fadcbb3c`) 8일치 데이터로 시뮬레이션:

| 날짜 | 버전 | expires_at | isPast? | 수정 전 | 수정 후 |
|------|------|-----------|---------|---------|---------|
| 1/30 | V2.1 | 만료 | past | ✅ | ✅ |
| 1/31 | V2.1 | 만료 | past | ✅ | ✅ |
| 2/1  | V2.3 | 만료 | past | ✅ | ✅ |
| 2/2  | V2.3 | 만료 | past | ✅ | ✅ |
| 2/3  | V2.3 | 만료 | past | ✅ | ✅ |
| 2/4  | V2.4 | 만료 | past | ✅ | ✅ |
| **2/5** | **V2.4** | **만료** | **past** | **❌ BLOCKED** | **✅ SHOW** |
| 2/6  | V2.4 | 유효 | today | ✅ | ✅ |

수정 전: Duration(hours:15) 방식으로 2/5가 과거로 인식 안 됨 → expires_at 필터에 걸림
수정 후: KoreaDateUtils.today 기준으로 어제(2/5)가 확실히 과거 → 필터 스킵 → 정상 표시

---

## 캘린더 마커(점) vs 콘텐츠 경로

캘린더에는 두 가지 데이터 경로가 있음:

### 경로 A: 캘린더 마커 (날짜에 분홍 점)

```
dailyFortuneDatesProvider
  → aiQueries.getDailyFortuneDates()
  → daily_fortune_calendar VIEW (DB)
```

**VIEW 정의:**
```sql
SELECT id, user_id, profile_id, target_date, content, prompt_version, created_at
FROM ai_summaries
WHERE summary_type = 'daily_fortune'
  AND status = 'completed'
  AND target_date IS NOT NULL;
```

- prompt_version 필터 **없음**
- expires_at 필터 **없음**
- profile_id로만 필터링

→ 마커는 항상 정상 표시됨 (이슈 없음)

### 경로 B: 캘린더 콘텐츠 (날짜 탭 시)

```
dailyFortuneForDateProvider(date)
  → aiQueries.getDailyFortune(profileId, date)
  → getCachedSummary()
```

- prompt_version 필터 **있음** ← 이슈 원인
- expires_at 필터 **있음** ← 이슈 원인
- 수정으로 과거 날짜는 두 필터 모두 스킵

→ **수정 후 정상 표시됨**

---

## 에뮬레이터 테스트 시 주의사항

에뮬레이터에서 프로필 변경(김동현 → 불재현) 시:

1. **앱 재설치/로그아웃하면 새 익명 계정(user_id) 생성됨**
2. 이전 프로필의 데이터는 다른 user_id → 캘린더에서 안 보임
3. **이것은 코드 버그가 아님** - 실제 유저는 동일 계정 유지

### DB에서 확인한 증거

```
불재현 (db7ad2bf) → user_id: 29efeaf9 → daily_fortune 1건 (2/6)
김동현 (fadcbb3c) → user_id: 4826f42e → daily_fortune 8건 (1/30~2/6)
김동현 (b4890e9c) → user_id: 271121f6 → daily_fortune 3건 (2/2~2/6)
```

모두 **다른 user_id** → 같은 기기에서 테스트했지만 매번 새 계정으로 인식됨.

---

## 관련 문서

- [phase60_daily_fortune_fix.md](./phase60_daily_fortune_fix.md) - Daily Fortune 무한 로딩 버그 수정
- [daily_fortune_profile_change_test.md](./daily_fortune_profile_change_test.md) - 프로필 변경 테스트
- [db_schema_integrated.md](./db_schema_integrated.md) - DB 스키마 (daily_fortune_calendar VIEW 포함)

---

## 배포 영향

| 수정 | 위치 | 반영 방식 |
|------|------|----------|
| queries.dart 필터 스킵 | 클라이언트 (Flutter) | **새 빌드 필요** |
| daily_queries.dart 필터 스킵 | 클라이언트 (Flutter) | **새 빌드 필요** |
| daily_fortune_calendar VIEW | 서버 (Supabase DB) | 이미 적용됨 |

**서버 변경 없음** - 순수 클라이언트 로직 수정. 앱 업데이트 배포 시 자동 반영.
