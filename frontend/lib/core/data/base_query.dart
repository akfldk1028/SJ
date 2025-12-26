import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import 'query_result.dart';

export 'query_result.dart';

/// 기본 쿼리 믹스인
///
/// 모든 Query/Mutation 클래스에서 사용할 공통 기능 제공
mixin BaseQueryMixin {
  /// Supabase 클라이언트 (null이면 오프라인)
  SupabaseClient? get client => SupabaseService.client;

  /// 연결 상태
  bool get isConnected => SupabaseService.isConnected;

  /// 현재 사용자 ID
  String? get currentUserId => SupabaseService.currentUserId;

  /// 안전한 쿼리 실행
  ///
  /// 오프라인 모드, 에러 처리 자동화
  Future<QueryResult<T>> safeQuery<T>({
    required Future<T> Function(SupabaseClient client) query,
    T? Function()? offlineData,
    String errorPrefix = '쿼리 실패',
  }) async {
    if (!isConnected || client == null) {
      final cached = offlineData?.call();
      return QueryResult.offline(cached);
    }

    try {
      final result = await query(client!);
      return QueryResult.success(result);
    } on PostgrestException catch (e) {
      return QueryResult.failure(
        '$errorPrefix: ${e.message}',
        error: e,
      );
    } catch (e) {
      return QueryResult.failure(
        '$errorPrefix: $e',
        error: e,
      );
    }
  }

  /// 안전한 단일 결과 쿼리
  Future<QueryResult<T?>> safeSingleQuery<T>({
    required Future<Map<String, dynamic>?> Function(SupabaseClient client)
        query,
    required T Function(Map<String, dynamic> json) fromJson,
    T? Function()? offlineData,
    String errorPrefix = '단일 쿼리 실패',
  }) async {
    if (!isConnected || client == null) {
      final cached = offlineData?.call();
      return QueryResult.offline(cached);
    }

    try {
      final result = await query(client!);
      if (result == null) {
        return QueryResult.success(null);
      }
      return QueryResult.success(fromJson(result));
    } on PostgrestException catch (e) {
      return QueryResult.failure(
        '$errorPrefix: ${e.message}',
        error: e,
      );
    } catch (e) {
      return QueryResult.failure(
        '$errorPrefix: $e',
        error: e,
      );
    }
  }

  /// 안전한 리스트 쿼리
  Future<QueryResult<List<T>>> safeListQuery<T>({
    required Future<List<Map<String, dynamic>>> Function(SupabaseClient client)
        query,
    required T Function(Map<String, dynamic> json) fromJson,
    List<T> Function()? offlineData,
    String errorPrefix = '리스트 쿼리 실패',
  }) async {
    if (!isConnected || client == null) {
      final cached = offlineData?.call() ?? [];
      return QueryResult.offline(cached);
    }

    try {
      final result = await query(client!);
      final items = result.map((json) => fromJson(json)).toList();
      return QueryResult.success(items);
    } on PostgrestException catch (e) {
      return QueryResult.failure(
        '$errorPrefix: ${e.message}',
        error: e,
      );
    } catch (e) {
      return QueryResult.failure(
        '$errorPrefix: $e',
        error: e,
      );
    }
  }

  /// 안전한 뮤테이션 실행
  Future<QueryResult<T>> safeMutation<T>({
    required Future<T> Function(SupabaseClient client) mutation,
    String errorPrefix = '뮤테이션 실패',
  }) async {
    if (!isConnected || client == null) {
      return QueryResult.failure('오프라인 상태에서는 저장할 수 없습니다.');
    }

    try {
      final result = await mutation(client!);
      return QueryResult.success(result);
    } on PostgrestException catch (e) {
      return QueryResult.failure(
        '$errorPrefix: ${e.message}',
        error: e,
      );
    } catch (e) {
      return QueryResult.failure(
        '$errorPrefix: $e',
        error: e,
      );
    }
  }
}

/// 쿼리 클래스 기본
abstract class BaseQueries with BaseQueryMixin {
  const BaseQueries();
}

/// 뮤테이션 클래스 기본
abstract class BaseMutations with BaseQueryMixin {
  const BaseMutations();
}

/// Ref 확장 - 편의 메서드
extension RefQueryExtensions on Ref {
  /// 오프라인 우선 데이터 가져오기
  ///
  /// 1. 캐시 확인
  /// 2. Supabase 쿼리
  /// 3. 캐시 업데이트
  Future<T?> fetchWithCache<T>({
    required T? Function() getCache,
    required Future<QueryResult<T>> Function() fetchRemote,
    required void Function(T data) updateCache,
  }) async {
    // 1. 캐시 먼저 확인
    final cached = getCache();

    // 2. 온라인이면 원격 데이터 가져오기
    final result = await fetchRemote();

    if (result.isSuccess && result.data != null) {
      // 3. 캐시 업데이트
      updateCache(result.data as T);
      return result.data;
    }

    // 실패 시 캐시 반환
    return cached;
  }
}
