# Splash Data Layer

> 작성: 2024-12-26
> 담당: DK

---

## 개요

앱 시작 시 필수 데이터를 Pre-fetch하는 모듈입니다.
Splash 화면에서 빠르게 데이터를 로드하여 사용자 경험을 개선합니다.

---

## 파일 구조

```
splash/data/
├── schema.dart    # Pre-fetch 스키마 정의
├── queries.dart   # SELECT 쿼리 (Pre-fetch)
├── mutations.dart # 동기화 관련 작업
└── README.md      # 이 파일
```

---

## Pre-fetch 흐름

```
┌─────────────────────────────────────────────────────────────┐
│                      SplashScreen                           │
│                                                             │
│  1. checkPrefetchStatus(userId)                             │
│     → noProfile: Onboarding으로                              │
│     → noAnalysis: 분석 재계산                                │
│     → hasData: 데이터 로드                                   │
│                                                             │
│  2. prefetchPrimaryData(userId)                             │
│     → Primary 프로필 + 사주 분석 한 번에                     │
│                                                             │
│  3. (Optional) getRecentSession(profileId)                  │
│     → 최근 채팅 세션                                         │
│                                                             │
│  4. 화면 이동                                                │
│     → Menu (데이터 있음)                                     │
│     → Onboarding (프로필 없음)                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 쿼리 사용법

### 1. Pre-fetch 상태 확인 (빠름)

```dart
// 데이터 로드 없이 상태만 확인
final statusResult = await splashQueries.checkPrefetchStatus(userId);

switch (statusResult) {
  case QuerySuccess(:final data):
    switch (data) {
      case PrefetchStatus.hasData:
        // 메인 화면으로
        break;
      case PrefetchStatus.noProfile:
        // 온보딩으로
        break;
      case PrefetchStatus.noAnalysis:
        // 분석 계산 필요
        break;
      case PrefetchStatus.offline:
        // 오프라인 모드
        break;
      default:
        break;
    }
  case QueryFailure():
  case QueryOffline():
    // 에러 처리
    break;
}
```

### 2. 데이터 한 번에 로드

```dart
// Primary 프로필 + 사주 분석 동시 조회
final result = await splashQueries.prefetchPrimaryData(userId);

if (result.isSuccess && result.data != null) {
  final prefetchData = result.data!;

  // 프로필 정보
  final profile = prefetchData.profile;
  print('환영합니다, ${profile.displayName}님!');

  // 사주 분석 (nullable)
  if (prefetchData.hasAnalysis) {
    final analysis = prefetchData.analysis!;
    print('일간: ${analysis.dayGan}');
  }
}
```

### 3. 개별 조회

```dart
// Primary 프로필만
final profileResult = await splashQueries.getPrimaryProfile(userId);

// 사주 분석만 (핵심 컬럼)
final analysisResult = await splashQueries.getCoreAnalysis(profileId);

// 사주 분석 전체 (상세용)
final fullResult = await splashQueries.getFullAnalysis(profileId);

// 최근 채팅 세션
final sessionResult = await splashQueries.getRecentSession(profileId);
```

---

## Mutation 사용법

### 동기화 상태 확인

```dart
// 로컬 캐시와 원격 데이터 비교
final syncResult = await splashMutations.checkSyncNeeded(
  profileId,
  localProfile.updatedAt,
);

if (syncResult.isSuccess) {
  switch (syncResult.data!) {
    case SyncCheckResult.syncNeeded:
      // 동기화 실행
      break;
    case SyncCheckResult.upToDate:
      // 캐시 사용
      break;
    case SyncCheckResult.notFound:
      // 원격에 없음 (업로드 필요)
      break;
  }
}
```

### Primary 프로필 설정

```dart
// 첫 프로필 자동 Primary 설정
await splashMutations.setFirstProfileAsPrimary(userId);

// 특정 프로필을 Primary로
await splashMutations.ensurePrimaryProfile(userId, profileId);
```

---

## SplashPrefetchData

Pre-fetch 결과 데이터 클래스

```dart
class SplashPrefetchData {
  final SajuProfileModel profile;       // 필수
  final SajuAnalysisDbModel? analysis;  // Optional
  final ChatSessionModel? recentSession; // Optional

  // 편의 getter
  bool get hasAnalysis;
  bool get hasRecentSession;
  bool get isComplete;
  String get profileId;
  PrefetchStatus get status;
}
```

---

## PrefetchStatus

```dart
enum PrefetchStatus {
  loading,     // 로딩 중
  hasData,     // 완료 - 데이터 있음
  noProfile,   // 완료 - 신규 사용자
  noAnalysis,  // 완료 - 분석 없음
  error,       // 실패
  offline,     // 오프라인
}
```

---

## Provider 연동

Riverpod Provider에서 사용:

```dart
@riverpod
Future<SplashPrefetchData?> splashPrefetch(SplashPrefetchRef ref) async {
  final userId = SupabaseService.currentUserId;
  if (userId == null) return null;

  final result = await splashQueries.prefetchPrimaryData(userId);
  return result.data;
}
```

---

## 성능 최적화

1. **최소 쿼리**: 상태 확인 → 2개 쿼리 (profile + analysis)
2. **필요한 컬럼만**: `coreAnalysisColumns` 사용
3. **Hive 캐시 우선**: 오프라인에서도 동작
4. **병렬 로드**: 필요시 Future.wait 활용

---

## 관련 파일

- `../README.md` - Splash 전체 아키텍처
- `../../profile/data/` - 프로필 데이터 레이어
- `../../saju_chart/data/` - 사주 분석 데이터 레이어
- `../../saju_chat/data/` - 채팅 데이터 레이어
