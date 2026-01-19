import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../AI/services/saju_analysis_service.dart';
import '../../../../core/data/query_result.dart';
import '../../data/data.dart';

part 'relation_provider.g.dart';

/// 특정 프로필의 관계 목록 Provider
///
/// fromProfileId: "나"의 프로필 ID
/// 나와 연결된 모든 사람들의 관계를 조회
@riverpod
class RelationList extends _$RelationList {
  @override
  Future<List<ProfileRelationModel>> build(String fromProfileId) async {
    final result = await relationQueries.getByFromProfile(fromProfileId);
    return switch (result) {
      QuerySuccess(:final data) => data,
      QueryFailure(:final message) => throw Exception(message),
      QueryOffline() => throw Exception('오프라인 상태입니다'),
    };
  }

  /// 관계 목록 새로 고침
  Future<void> refresh() async {
    final fromProfileId = this.fromProfileId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await relationQueries.getByFromProfile(fromProfileId);
      return switch (result) {
        QuerySuccess(:final data) => data,
        QueryFailure(:final message) => throw Exception(message),
        QueryOffline() => throw Exception('오프라인 상태입니다'),
      };
    });
  }
}

/// 사용자의 모든 관계 목록 Provider
///
/// userId 기준으로 모든 관계 조회 (모든 프로필의 관계 포함)
@riverpod
Future<List<ProfileRelationModel>> userRelations(Ref ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    return [];
  }

  final result = await relationQueries.getAllByUserId(user.id);
  return switch (result) {
    QuerySuccess(:final data) => data,
    QueryFailure() => [],
    QueryOffline() => [],
  };
}

/// 카테고리별 그룹핑된 관계 Provider
///
/// Map<카테고리라벨, List<관계>> 형태 반환
/// 예: {'가족': [...], '친구': [...], '직장': [...]}
@riverpod
Future<Map<String, List<ProfileRelationModel>>> relationsByCategory(
  Ref ref,
  String fromProfileId,
) async {
  final result = await relationQueries.getGroupedByCategory(fromProfileId);
  return switch (result) {
    QuerySuccess(:final data) => data,
    QueryFailure(:final message) => throw Exception(message),
    QueryOffline() => {},
  };
}

/// 즐겨찾기 관계 목록 Provider
@riverpod
Future<List<ProfileRelationModel>> favoriteRelations(
  Ref ref,
  String fromProfileId,
) async {
  final result = await relationQueries.getFavorites(fromProfileId);
  return switch (result) {
    QuerySuccess(:final data) => data,
    QueryFailure(:final message) => throw Exception(message),
    QueryOffline() => [],
  };
}

/// 단일 관계 조회 Provider
@riverpod
Future<ProfileRelationModel?> relationById(
  Ref ref,
  String relationId,
) async {
  final result = await relationQueries.getById(relationId);
  return switch (result) {
    QuerySuccess(:final data) => data,
    QueryFailure() => null,
    QueryOffline() => null,
  };
}

/// 두 프로필 간 관계 조회 Provider
@riverpod
Future<ProfileRelationModel?> relationByProfilePair(
  Ref ref,
  String fromProfileId,
  String toProfileId,
) async {
  final result = await relationQueries.getByProfilePair(
    fromProfileId,
    toProfileId,
  );
  return switch (result) {
    QuerySuccess(:final data) => data,
    QueryFailure() => null,
    QueryOffline() => null,
  };
}

/// 관계 개수 Provider
@riverpod
Future<int> relationCount(Ref ref, String fromProfileId) async {
  final result = await relationQueries.countByFromProfile(fromProfileId);
  return switch (result) {
    QuerySuccess(:final data) => data,
    QueryFailure() => 0,
    QueryOffline() => 0,
  };
}

/// 관계 존재 여부 Provider
@riverpod
Future<bool> relationExists(
  Ref ref,
  String fromProfileId,
  String toProfileId,
) async {
  final result = await relationQueries.exists(fromProfileId, toProfileId);
  return switch (result) {
    QuerySuccess(:final data) => data,
    QueryFailure() => false,
    QueryOffline() => false,
  };
}

/// 관계 CRUD 작업 Notifier
///
/// 관계 생성, 수정, 삭제, 즐겨찾기 토글 등 수행
@riverpod
class RelationNotifier extends _$RelationNotifier {
  @override
  FutureOr<void> build() {
    // 초기 상태 없음 - 즉시 완료
  }

  /// 관계 생성
  ///
  /// ## Phase 52: 인연 등록 시 상대방 사주 자동 분석
  /// 1. profile_relations INSERT
  /// 2. 상대방(toProfile) 사주 분석 (백그라운드)
  /// 3. 분석 완료 시 to_profile_analysis_id 업데이트
  Future<ProfileRelationModel?> create({
    required String fromProfileId,
    required String toProfileId,
    required String relationType,
    String? displayName,
    String? memo,
    bool isFavorite = false,
    int sortOrder = 0,
    String? fromProfileAnalysisId,
    String? toProfileAnalysisId,
  }) async {
    debugPrint('🔍 [RelationNotifier.create] 시작');
    debugPrint('   - fromProfileId: $fromProfileId');
    debugPrint('   - toProfileId: $toProfileId');
    debugPrint('   - relationType: $relationType');
    debugPrint('   - fromProfileAnalysisId: $fromProfileAnalysisId');
    debugPrint('   - toProfileAnalysisId: $toProfileAnalysisId');

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('❌ [RelationNotifier.create] 실패: 로그인 필요');
      throw Exception('로그인이 필요합니다');
    }
    debugPrint('   - userId: ${user.id}');

    // AsyncValue.guard를 사용하여 안전하게 상태 관리
    ProfileRelationModel? createdModel;

    debugPrint('🔍 [RelationNotifier.create] relationMutations.create 호출');
    state = await AsyncValue.guard(() async {
      final result = await relationMutations.create(
        userId: user.id,
        fromProfileId: fromProfileId,
        toProfileId: toProfileId,
        relationType: relationType,
        displayName: displayName,
        memo: memo,
        isFavorite: isFavorite,
        sortOrder: sortOrder,
        fromProfileAnalysisId: fromProfileAnalysisId,
        toProfileAnalysisId: toProfileAnalysisId,
      );

      debugPrint('🔍 [RelationNotifier.create] relationMutations 결과: ${result.runtimeType}');

      switch (result) {
        case QuerySuccess(:final data):
          debugPrint('✅ [RelationNotifier.create] 성공: id=${data.id}');
          createdModel = data;
          _invalidateRelatedProviders(fromProfileId);
          return;
        case QueryFailure(:final message):
          debugPrint('❌ [RelationNotifier.create] 실패: $message');
          throw Exception(message);
        case QueryOffline():
          debugPrint('❌ [RelationNotifier.create] 오프라인');
          throw Exception('오프라인 상태입니다');
      }
    });

    // 에러가 발생했으면 다시 던지기
    if (state.hasError) {
      debugPrint('❌ [RelationNotifier.create] state 에러: ${state.error}');
      throw state.error!;
    }

    // Phase 52: 상대방 사주 자동 분석 (백그라운드)
    // toProfileAnalysisId가 없으면 새로 분석
    if (createdModel != null && toProfileAnalysisId == null) {
      debugPrint('👫 [RelationNotifier.create] 상대방 사주 분석 시작 (백그라운드)');
      _triggerRelationAnalysis(
        userId: user.id,
        relationId: createdModel!.id,
        toProfileId: toProfileId,
        fromProfileId: fromProfileId,
      );
    }

    debugPrint('✅ [RelationNotifier.create] 완료');
    return createdModel;
  }

  /// Phase 52: 인연 사주 분석 트리거 (백그라운드)
  ///
  /// 분석 완료 시 profile_relations.to_profile_analysis_id 업데이트
  void _triggerRelationAnalysis({
    required String userId,
    required String relationId,
    required String toProfileId,
    required String fromProfileId,
  }) {
    sajuAnalysisService.analyzeRelationProfile(
      userId: userId,
      profileId: toProfileId,
      runInBackground: true,
      onComplete: (result) async {
        if (result.success && result.summaryId != null && result.summaryId != 'pending') {
          debugPrint('✅ [RelationNotifier] 인연 사주 분석 완료: ${result.summaryId}');

          // profile_relations.to_profile_analysis_id 업데이트
          final updateResult = await relationMutations.linkToProfileAnalysis(
            relationId,
            result.summaryId!,
          );

          if (updateResult is QuerySuccess) {
            debugPrint('✅ [RelationNotifier] to_profile_analysis_id 연결 완료');
            // Provider 무효화하여 UI 갱신
            _invalidateRelatedProviders(fromProfileId);
          } else {
            debugPrint('⚠️ [RelationNotifier] to_profile_analysis_id 연결 실패');
          }
        } else {
          debugPrint('⚠️ [RelationNotifier] 인연 사주 분석 실패: ${result.error}');
        }
      },
    );
  }

  /// 관계 업데이트
  Future<ProfileRelationModel?> updateRelation({
    required String relationId,
    required String fromProfileId,
    String? relationType,
    String? displayName,
    String? memo,
    bool? isFavorite,
    int? sortOrder,
  }) async {
    ProfileRelationModel? updatedModel;

    state = await AsyncValue.guard(() async {
      final result = await relationMutations.update(
        relationId: relationId,
        relationType: relationType,
        displayName: displayName,
        memo: memo,
        isFavorite: isFavorite,
        sortOrder: sortOrder,
      );

      switch (result) {
        case QuerySuccess(:final data):
          updatedModel = data;
          _invalidateRelatedProviders(fromProfileId);
          return;
        case QueryFailure(:final message):
          throw Exception(message);
        case QueryOffline():
          throw Exception('오프라인 상태입니다');
      }
    });

    if (state.hasError) {
      throw state.error!;
    }

    return updatedModel;
  }

  /// 관계 삭제
  Future<void> delete({
    required String relationId,
    required String fromProfileId,
  }) async {
    state = await AsyncValue.guard(() async {
      final result = await relationMutations.delete(relationId);

      switch (result) {
        case QuerySuccess():
          _invalidateRelatedProviders(fromProfileId);
          return;
        case QueryFailure(:final message):
          throw Exception(message);
        case QueryOffline():
          throw Exception('오프라인 상태입니다');
      }
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  /// 즐겨찾기 토글
  Future<ProfileRelationModel?> toggleFavorite({
    required String relationId,
    required String fromProfileId,
    required bool isFavorite,
  }) async {
    ProfileRelationModel? updatedModel;

    state = await AsyncValue.guard(() async {
      final result = await relationMutations.toggleFavorite(
        relationId,
        isFavorite,
      );

      switch (result) {
        case QuerySuccess(:final data):
          updatedModel = data;
          _invalidateRelatedProviders(fromProfileId);
          return;
        case QueryFailure(:final message):
          throw Exception(message);
        case QueryOffline():
          throw Exception('오프라인 상태입니다');
      }
    });

    if (state.hasError) {
      throw state.error!;
    }

    return updatedModel;
  }

  /// 정렬 순서 일괄 업데이트
  Future<void> updateSortOrders({
    required String fromProfileId,
    required Map<String, int> relationSortOrders,
  }) async {
    state = await AsyncValue.guard(() async {
      final result = await relationMutations.updateSortOrders(relationSortOrders);

      switch (result) {
        case QuerySuccess():
          _invalidateRelatedProviders(fromProfileId);
          return;
        case QueryFailure(:final message):
          throw Exception(message);
        case QueryOffline():
          throw Exception('오프라인 상태입니다');
      }
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  /// 관계 유형 변경
  Future<ProfileRelationModel?> updateRelationType({
    required String relationId,
    required String fromProfileId,
    required String relationType,
  }) async {
    ProfileRelationModel? updatedModel;

    state = await AsyncValue.guard(() async {
      final result = await relationMutations.updateRelationType(
        relationId,
        relationType,
      );

      switch (result) {
        case QuerySuccess(:final data):
          updatedModel = data;
          _invalidateRelatedProviders(fromProfileId);
          return;
        case QueryFailure(:final message):
          throw Exception(message);
        case QueryOffline():
          throw Exception('오프라인 상태입니다');
      }
    });

    if (state.hasError) {
      throw state.error!;
    }

    return updatedModel;
  }

  /// Upsert (있으면 업데이트, 없으면 생성)
  Future<ProfileRelationModel?> upsert({
    required String fromProfileId,
    required String toProfileId,
    required String relationType,
    String? displayName,
    String? memo,
    bool isFavorite = false,
    int sortOrder = 0,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다');
    }

    ProfileRelationModel? upsertedModel;

    state = await AsyncValue.guard(() async {
      final result = await relationMutations.upsert(
        userId: user.id,
        fromProfileId: fromProfileId,
        toProfileId: toProfileId,
        relationType: relationType,
        displayName: displayName,
        memo: memo,
        isFavorite: isFavorite,
        sortOrder: sortOrder,
      );

      switch (result) {
        case QuerySuccess(:final data):
          upsertedModel = data;
          _invalidateRelatedProviders(fromProfileId);
          return;
        case QueryFailure(:final message):
          throw Exception(message);
        case QueryOffline():
          throw Exception('오프라인 상태입니다');
      }
    });

    if (state.hasError) {
      throw state.error!;
    }

    return upsertedModel;
  }

  /// 관련 Provider들 무효화
  void _invalidateRelatedProviders(String fromProfileId) {
    ref.invalidate(relationListProvider(fromProfileId));
    ref.invalidate(relationsByCategoryProvider(fromProfileId));
    ref.invalidate(favoriteRelationsProvider(fromProfileId));
    ref.invalidate(relationCountProvider(fromProfileId));
    ref.invalidate(userRelationsProvider);
  }
}

/// 관계 폼 상태
class RelationFormState {
  final String? toProfileId;
  final ProfileRelationType relationType;
  final String? displayName;
  final String? memo;
  final bool isFavorite;

  const RelationFormState({
    this.toProfileId,
    this.relationType = ProfileRelationType.other,
    this.displayName,
    this.memo,
    this.isFavorite = false,
  });

  /// 폼 유효성 검사
  bool get isValid => toProfileId != null && toProfileId!.isNotEmpty;

  RelationFormState copyWith({
    String? toProfileId,
    ProfileRelationType? relationType,
    String? displayName,
    String? memo,
    bool? isFavorite,
  }) {
    return RelationFormState(
      toProfileId: toProfileId ?? this.toProfileId,
      relationType: relationType ?? this.relationType,
      displayName: displayName ?? this.displayName,
      memo: memo ?? this.memo,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// 관계 폼 Provider
@riverpod
class RelationForm extends _$RelationForm {
  @override
  RelationFormState build() {
    return const RelationFormState();
  }

  /// 대상 프로필 설정
  void setToProfile(String profileId) {
    state = state.copyWith(toProfileId: profileId);
  }

  /// 관계 유형 설정
  void setRelationType(ProfileRelationType type) {
    state = state.copyWith(relationType: type);
  }

  /// 표시명 설정
  void setDisplayName(String? name) {
    state = state.copyWith(displayName: name);
  }

  /// 메모 설정
  void setMemo(String? memo) {
    state = state.copyWith(memo: memo);
  }

  /// 즐겨찾기 설정
  void setFavorite(bool value) {
    state = state.copyWith(isFavorite: value);
  }

  /// 기존 관계로 폼 초기화 (수정 모드)
  void loadRelation(ProfileRelationModel relation) {
    state = RelationFormState(
      toProfileId: relation.toProfileId,
      relationType: relation.relationTypeEnum,
      displayName: relation.displayName,
      memo: relation.memo,
      isFavorite: relation.isFavorite,
    );
  }

  /// 폼 초기화
  void reset() {
    state = const RelationFormState();
  }
}
