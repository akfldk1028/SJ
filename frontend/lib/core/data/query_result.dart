/// Supabase 쿼리 결과 래퍼
///
/// 성공/실패를 명확하게 처리하고, 오프라인 모드 지원
sealed class QueryResult<T> {
  const QueryResult();

  /// 성공
  factory QueryResult.success(T data) = QuerySuccess<T>;

  /// 실패
  factory QueryResult.failure(String message, {Object? error}) =
      QueryFailure<T>;

  /// 오프라인 (캐시 데이터 반환)
  factory QueryResult.offline(T? cachedData) = QueryOffline<T>;

  /// 성공 여부
  bool get isSuccess => this is QuerySuccess<T>;

  /// 실패 여부
  bool get isFailure => this is QueryFailure<T>;

  /// 오프라인 여부
  bool get isOffline => this is QueryOffline<T>;

  /// 데이터 가져오기 (실패 시 null)
  T? get data => switch (this) {
        QuerySuccess<T>(:final data) => data,
        QueryOffline<T>(:final cachedData) => cachedData,
        QueryFailure<T>() => null,
      };

  /// 데이터 가져오기 (실패 시 기본값)
  T getOrElse(T defaultValue) => data ?? defaultValue;

  /// 에러 메시지
  String? get errorMessage => switch (this) {
        QueryFailure<T>(:final message) => message,
        _ => null,
      };
}

/// 성공 결과
final class QuerySuccess<T> extends QueryResult<T> {
  final T data;
  const QuerySuccess(this.data);
}

/// 실패 결과
final class QueryFailure<T> extends QueryResult<T> {
  final String message;
  final Object? error;
  const QueryFailure(this.message, {this.error});
}

/// 오프라인 결과 (캐시 데이터)
final class QueryOffline<T> extends QueryResult<T> {
  final T? cachedData;
  const QueryOffline(this.cachedData);
}
