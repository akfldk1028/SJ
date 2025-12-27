# Core Data Layer

> 작성: 2024-12-26
> 담당: DK

---

## 개요

모든 Feature의 Data Layer에서 공통으로 사용하는 기반 코드입니다.
- 쿼리/뮤테이션 기본 클래스
- 결과 래퍼 타입
- 오프라인 처리

---

## 파일 구조

```
core/data/
├── query_result.dart   # QueryResult sealed class (성공/실패/오프라인)
├── base_query.dart     # BaseQueries, BaseMutations 믹스인
├── data.dart           # Barrel export
└── README.md           # 이 파일
```

---

## 파일별 역할

| 파일 | 역할 |
|------|------|
| `query_result.dart` | `QueryResult<T>` - 쿼리 결과 래퍼 (sealed class) |
| `base_query.dart` | `BaseQueryMixin` - 안전한 쿼리/뮤테이션 실행 |
| `data.dart` | 전체 export |

---

## QueryResult<T>

Supabase 쿼리 결과를 래핑하는 sealed class:

```dart
sealed class QueryResult<T> {
  // 성공
  factory QueryResult.success(T data);

  // 실패
  factory QueryResult.failure(String message, {Object? error});

  // 오프라인 (캐시 데이터)
  factory QueryResult.offline(T? cachedData);
}
```

### 사용법

```dart
final result = await profileQueries.getById(id);

// 패턴 매칭
switch (result) {
  case QuerySuccess(:final data):
    // 성공 - 데이터 사용
    showProfile(data);
  case QueryOffline(:final cachedData):
    // 오프라인 - 캐시 사용
    if (cachedData != null) showProfile(cachedData);
  case QueryFailure(:final message):
    // 실패 - 에러 표시
    showError(message);
}

// 간단한 체크
if (result.isSuccess) {
  final data = result.data!;
}

// 기본값 사용
final data = result.getOrElse(defaultProfile);
```

---

## BaseQueryMixin

모든 Query/Mutation 클래스에서 사용하는 공통 기능:

### 안전한 쿼리 메서드

| 메서드 | 용도 |
|--------|------|
| `safeQuery<T>()` | 일반 쿼리 |
| `safeSingleQuery<T>()` | 단일 결과 쿼리 |
| `safeListQuery<T>()` | 리스트 쿼리 |
| `safeMutation<T>()` | INSERT/UPDATE/DELETE |

### 예시: Query 클래스 구현

```dart
class ProfileQueries extends BaseQueries {
  const ProfileQueries();

  Future<QueryResult<SajuProfiles?>> getById(String id) {
    return safeSingleQuery(
      query: (client) => client
          .from(SajuProfiles.table_name)
          .select()
          .eq(SajuProfiles.c_id, id)
          .maybeSingle(),
      fromJson: SajuProfiles.fromJson,
      offlineData: () => _hiveBox.get(id),
      errorPrefix: '프로필 조회 실패',
    );
  }
}
```

### 예시: Mutation 클래스 구현

```dart
class ProfileMutations extends BaseMutations {
  const ProfileMutations();

  Future<QueryResult<void>> update(SajuProfiles profile) {
    return safeMutation(
      mutation: (client) => client
          .from(SajuProfiles.table_name)
          .update(profile.toJson())
          .eq(SajuProfiles.c_id, profile.id),
      errorPrefix: '프로필 수정 실패',
    );
  }
}
```

---

## 오프라인 처리

### 자동 처리

`safeQuery` 메서드들은 자동으로:
1. 연결 상태 확인
2. 오프라인이면 `offlineData` 콜백 호출
3. `QueryOffline` 반환

### Ref.fetchWithCache

캐시 우선 전략:

```dart
final profile = await ref.fetchWithCache(
  getCache: () => hiveBox.get(profileId),
  fetchRemote: () => profileQueries.getById(profileId),
  updateCache: (data) => hiveBox.put(profileId, data),
);
```

---

## 관련 파일

- `core/services/supabase_service.dart` - Supabase 연결 관리
- `core/supabase/generated/` - 자동 생성된 타입
- `features/*/data/queries.dart` - 각 Feature 쿼리
- `features/*/data/mutations.dart` - 각 Feature 뮤테이션
