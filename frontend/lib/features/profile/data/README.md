# Profile Data Layer

> 작성: 2024-12-26
> 담당: DK

---

## 파일 구조

```
data/
├── schema.dart      # 테이블 스키마 정의
├── queries.dart     # SELECT 쿼리 (조회)
├── mutations.dart   # INSERT/UPDATE/DELETE (변경)
├── models/          # Freezed 데이터 모델
├── datasources/     # 로컬 데이터소스 (Hive)
└── README.md        # 이 파일
```

---

## 사용법

### 1. 쿼리 (조회)

```dart
import 'package:saju_app/features/profile/data/queries.dart';

// 모든 프로필 조회
final result = await profileQueries.getAllByUserId(userId);
if (result.isSuccess) {
  final profiles = result.data!;
  // ...
} else if (result.isOffline) {
  // 오프라인 - 캐시 데이터 사용
  final cached = result.data;
} else {
  // 에러 처리
  print(result.errorMessage);
}

// 단일 프로필 조회
final profile = await profileQueries.getById(profileId);

// Primary 프로필 조회
final primary = await profileQueries.getPrimaryByUserId(userId);
```

### 2. 뮤테이션 (변경)

```dart
import 'package:saju_app/features/profile/data/mutations.dart';

// 프로필 생성
final result = await profileMutations.create(profile, userId);

// 프로필 업데이트
await profileMutations.update(profile, userId);

// 프로필 삭제
await profileMutations.delete(profileId);

// Primary 설정
await profileMutations.setPrimary(profileId, userId);

// 부분 업데이트
await profileMutations.patch(profileId, {
  'display_name': '새 이름',
});
```

---

## 테이블 스키마

**Supabase 테이블: `saju_profiles`**

| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | uuid | PK |
| user_id | uuid | FK → auth.users |
| display_name | text | 표시 이름 |
| gender | text | male/female |
| birth_date | date | 생년월일 (양력) |
| birth_time_minutes | int | 출생시간 (분) |
| birth_time_unknown | bool | 시간 모름 여부 |
| is_lunar | bool | 음력 여부 |
| is_leap_month | bool | 윤달 여부 |
| birth_city | text | 출생 도시 |
| time_correction | int | 진태양시 보정 (분) |
| use_ya_jasi | bool | 야자시 사용 여부 |
| is_primary | bool | 기본 프로필 여부 |
| relation_type | text | 관계 (me, family, friend...) |
| memo | text | 메모 |
| created_at | timestamptz | 생성일 |
| updated_at | timestamptz | 수정일 |

---

## QueryResult 패턴

모든 쿼리/뮤테이션은 `QueryResult<T>` 반환:

```dart
sealed class QueryResult<T> {
  // 성공
  factory QueryResult.success(T data) = QuerySuccess;

  // 실패
  factory QueryResult.failure(String message) = QueryFailure;

  // 오프라인 (캐시 데이터)
  factory QueryResult.offline(T? cachedData) = QueryOffline;
}
```

### 패턴 매칭

```dart
final result = await profileQueries.getById(id);

switch (result) {
  case QuerySuccess(:final data):
    // 성공 처리
    break;
  case QueryOffline(:final cachedData):
    // 오프라인 - 캐시 사용
    break;
  case QueryFailure(:final message):
    // 에러 표시
    break;
}
```

---

## 오프라인 처리

1. **쿼리**: Hive 캐시 데이터 반환 (`QueryOffline`)
2. **뮤테이션**: 실패 반환 (`QueryFailure`)

오프라인 우선 전략:
```dart
// Provider에서
final profile = await ref.fetchWithCache(
  getCache: () => hiveBox.get(profileId),
  fetchRemote: () => profileQueries.getById(profileId),
  updateCache: (data) => hiveBox.put(profileId, data),
);
```

---

## AI 모듈 연동

AI 팀원 (JH_AI, Jina)은 `AIContext`를 통해 데이터 접근:

```dart
// AI/common/data/ai_context.dart
class AIContext {
  final SajuProfileModel profile;
  final SajuAnalysisDbModel analysis;
  // ...
}

// AI 모듈에서
final context = await ref.read(aiContextProvider.future);
final profile = context.profile;
```

직접 queries/mutations 호출 대신 `ai_data_provider`를 통해 접근.
