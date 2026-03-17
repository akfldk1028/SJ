import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../AI/services/compatibility_analysis_service.dart';
import '../../../../core/data/query_result.dart';
import '../../data/data.dart';

part 'compatibility_provider.g.dart';

/// 특정 프로필의 모든 궁합 분석 목록 Provider
///
/// profileId가 포함된 모든 궁합 분석 조회 (profile1 또는 profile2)
@riverpod
class CompatibilityAnalysisList extends _$CompatibilityAnalysisList {
  @override
  Future<List<CompatibilityAnalysisModel>> build(String profileId) async {
    final result = await compatibilityQueries.getByProfile(profileId);
    return switch (result) {
      QuerySuccess(:final data) => data,
      QueryFailure(:final message) => throw Exception(message),
      QueryOffline() => throw Exception('오프라인 상태입니다'),
    };
  }

  /// 목록 새로 고침
  Future<void> refresh() async {
    final profileId = this.profileId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await compatibilityQueries.getByProfile(profileId);
      return switch (result) {
        QuerySuccess(:final data) => data,
        QueryFailure(:final message) => throw Exception(message),
        QueryOffline() => throw Exception('오프라인 상태입니다'),
      };
    });
  }
}

/// 최근 궁합 분석 N개 Provider
@riverpod
Future<List<CompatibilityAnalysisModel>> recentCompatibilityAnalyses(
  Ref ref,
  String profileId, {
  int limit = 5,
}) async {
  final result = await compatibilityQueries.getRecentByProfile(
    profileId,
    limit: limit,
  );
  return switch (result) {
    QuerySuccess(:final data) => data,
    QueryFailure() => [],
    QueryOffline() => [],
  };
}

/// 두 프로필 간 궁합 분석 Provider
///
/// 순서 무관하게 조회 (profile1↔profile2 모두 확인)
@riverpod
Future<CompatibilityAnalysisModel?> compatibilityByProfilePair(
  Ref ref,
  String profileId1,
  String profileId2,
) async {
  final result = await compatibilityQueries.getByProfilePair(
    profileId1,
    profileId2,
  );
  return switch (result) {
    QuerySuccess(:final data) => data,
    QueryFailure() => null,
    QueryOffline() => null,
  };
}

/// 단일 궁합 분석 조회 Provider
@riverpod
Future<CompatibilityAnalysisModel?> compatibilityById(
  Ref ref,
  String analysisId,
) async {
  final result = await compatibilityQueries.getById(analysisId);
  return switch (result) {
    QuerySuccess(:final data) => data,
    QueryFailure() => null,
    QueryOffline() => null,
  };
}

/// 궁합 분석 상세 조회 Provider (인연 사주 포함)
@riverpod
Future<CompatibilityAnalysisModel?> compatibilityByIdWithDetails(
  Ref ref,
  String analysisId,
) async {
  final result = await compatibilityQueries.getByIdWithDetails(analysisId);
  return switch (result) {
    QuerySuccess(:final data) => data,
    QueryFailure() => null,
    QueryOffline() => null,
  };
}

/// 프로필 정보 포함 궁합 분석 조회 Provider
@riverpod
Future<CompatibilityAnalysisModel?> compatibilityByIdWithProfiles(
  Ref ref,
  String analysisId,
) async {
  final result = await compatibilityQueries.getByIdWithProfiles(analysisId);
  return switch (result) {
    QuerySuccess(:final data) => data,
    QueryFailure() => null,
    QueryOffline() => null,
  };
}

/// 궁합 분석 개수 Provider
@riverpod
Future<int> compatibilityCount(Ref ref, String profileId) async {
  final result = await compatibilityQueries.countByProfile(profileId);
  return switch (result) {
    QuerySuccess(:final data) => data,
    QueryFailure() => 0,
    QueryOffline() => 0,
  };
}

/// 궁합 분석 존재 여부 Provider
@riverpod
Future<bool> compatibilityExists(
  Ref ref,
  String profileId1,
  String profileId2,
) async {
  final result = await compatibilityQueries.exists(profileId1, profileId2);
  return switch (result) {
    QuerySuccess(:final data) => data,
    QueryFailure() => false,
    QueryOffline() => false,
  };
}

/// 점수별 궁합 분석 조회 Provider
@riverpod
Future<List<CompatibilityAnalysisModel>> compatibilityByScoreRange(
  Ref ref,
  String profileId, {
  required int minScore,
  required int maxScore,
}) async {
  final result = await compatibilityQueries.getByScoreRange(
    profileId,
    minScore: minScore,
    maxScore: maxScore,
  );
  return switch (result) {
    QuerySuccess(:final data) => data,
    QueryFailure() => [],
    QueryOffline() => [],
  };
}

/// 궁합 분석 CRUD Notifier
///
/// 궁합 분석 생성, 수정, 삭제 + AI 계산 트리거
@riverpod
class CompatibilityNotifier extends _$CompatibilityNotifier {
  @override
  FutureOr<void> build() {
    // 초기 상태 없음
  }

  /// 궁합 분석 실행 (기존 서비스 활용)
  ///
  /// 1. AI 서비스로 궁합 계산
  /// 2. compatibility_analyses 저장
  /// 3. profile_relations 연결
  Future<CompatibilityAnalysisResult> analyze({
    required String fromProfileId,
    required String toProfileId,
    required String relationType,
    bool forceRefresh = false,
  }) async {
    debugPrint('🔍 [CompatibilityNotifier.analyze] 시작');

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return CompatibilityAnalysisResult.failure('로그인이 필요합니다');
    }

    // 기존 AI 서비스 사용 (Dart 로직 계산 + DB 저장)
    final service = CompatibilityAnalysisService();
    final result = await service.analyzeCompatibility(
      userId: user.id,
      fromProfileId: fromProfileId,
      toProfileId: toProfileId,
      relationType: relationType,
      forceRefresh: forceRefresh,
    );

    if (result.success) {
      // Provider 무효화
      _invalidateRelatedProviders(fromProfileId, toProfileId);
    }

    return result;
  }

  /// 궁합 분석 결과 수정
  Future<CompatibilityAnalysisModel?> updateAnalysis({
    required String analysisId,
    required String profileId,
    int? overallScore,
    Map<String, dynamic>? categoryScores,
    String? summary,
    List<String>? strengths,
    List<String>? challenges,
    String? advice,
  }) async {
    CompatibilityAnalysisModel? updatedModel;

    state = await AsyncValue.guard(() async {
      final result = await compatibilityMutations.update(
        analysisId: analysisId,
        overallScore: overallScore,
        categoryScores: categoryScores,
        summary: summary,
        strengths: strengths,
        challenges: challenges,
        advice: advice,
      );

      switch (result) {
        case QuerySuccess(:final data):
          updatedModel = data;
          ref.invalidate(compatibilityAnalysisListProvider(profileId));
          ref.invalidate(compatibilityByIdProvider(analysisId));
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

  /// 조언 업데이트
  Future<CompatibilityAnalysisModel?> updateAdvice({
    required String analysisId,
    required String profileId,
    required String advice,
  }) async {
    CompatibilityAnalysisModel? updatedModel;

    state = await AsyncValue.guard(() async {
      final result = await compatibilityMutations.updateAdvice(
        analysisId,
        advice,
      );

      switch (result) {
        case QuerySuccess(:final data):
          updatedModel = data;
          ref.invalidate(compatibilityByIdProvider(analysisId));
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

  /// 궁합 분석 삭제
  Future<void> delete({
    required String analysisId,
    required String profileId,
  }) async {
    state = await AsyncValue.guard(() async {
      final result = await compatibilityMutations.delete(analysisId);

      switch (result) {
        case QuerySuccess():
          ref.invalidate(compatibilityAnalysisListProvider(profileId));
          ref.invalidate(compatibilityByIdProvider(analysisId));
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

  /// 재분석 (기존 분석 삭제 후 새로 분석)
  Future<CompatibilityAnalysisResult> reanalyze({
    required String fromProfileId,
    required String toProfileId,
    required String relationType,
  }) async {
    return analyze(
      fromProfileId: fromProfileId,
      toProfileId: toProfileId,
      relationType: relationType,
      forceRefresh: true,
    );
  }

  /// 관련 Provider 무효화
  void _invalidateRelatedProviders(String profileId1, String profileId2) {
    ref.invalidate(compatibilityAnalysisListProvider(profileId1));
    ref.invalidate(compatibilityAnalysisListProvider(profileId2));
    ref.invalidate(
      compatibilityByProfilePairProvider(profileId1, profileId2),
    );
    ref.invalidate(compatibilityCountProvider(profileId1));
    ref.invalidate(compatibilityCountProvider(profileId2));
    ref.invalidate(compatibilityExistsProvider(profileId1, profileId2));
  }
}

/// 궁합 점수에 따른 등급 계산 유틸리티
String getCompatibilityGrade(int? score) {
  final s = score ?? 0;
  if (s >= 80) return 'compatibility.score_grade_best'.tr();
  if (s >= 60) return 'compatibility.score_grade_good'.tr();
  if (s >= 40) return 'compatibility.score_grade_medium'.tr();
  return 'compatibility.score_grade_low'.tr();
}

/// 궁합 점수에 따른 색상 코드
String getCompatibilityColorCode(int? score) {
  final s = score ?? 0;
  if (s >= 80) return '#EC4899'; // pink
  if (s >= 60) return '#3B82F6'; // blue
  if (s >= 40) return '#F59E0B'; // amber
  return '#6B7280'; // gray
}
