import '../../../core/data/data.dart';
import 'models/compatibility_analysis_model.dart';
import 'compatibility_schema.dart';

/// Compatibility Analyses 쿼리 클래스
///
/// SELECT 작업 담당
/// 오프라인 모드 + 에러 처리 내장
class CompatibilityQueries extends BaseQueries {
  const CompatibilityQueries();

  /// 분석 ID로 단일 조회
  Future<QueryResult<CompatibilityAnalysisModel?>> getById(
    String analysisId,
  ) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(compatibilityAnalysesTable)
            .select(compatibilitySelectColumns)
            .eq(CompatibilityColumns.id, analysisId)
            .maybeSingle();
        return response;
      },
      fromJson: CompatibilityAnalysisModel.fromSupabaseMap,
      errorPrefix: '궁합 분석 조회 실패',
    );
  }

  /// 분석 ID로 상세 조회 (인연 사주 정보 포함)
  Future<QueryResult<CompatibilityAnalysisModel?>> getByIdWithDetails(
    String analysisId,
  ) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(compatibilityAnalysesTable)
            .select(compatibilityDetailSelectColumns)
            .eq(CompatibilityColumns.id, analysisId)
            .maybeSingle();
        return response;
      },
      fromJson: CompatibilityAnalysisModel.fromSupabaseMap,
      errorPrefix: '궁합 분석 상세 조회 실패',
    );
  }

  /// 분석 ID로 조회 (프로필 정보 포함)
  Future<QueryResult<CompatibilityAnalysisModel?>> getByIdWithProfiles(
    String analysisId,
  ) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(compatibilityAnalysesTable)
            .select(compatibilityWithProfilesSelectColumns)
            .eq(CompatibilityColumns.id, analysisId)
            .maybeSingle();
        return response;
      },
      fromJson: CompatibilityAnalysisModel.fromSupabaseMap,
      errorPrefix: '궁합 분석 조회 실패',
    );
  }

  /// 두 프로필 간 궁합 분석 조회 (순서 무관)
  ///
  /// profile1_id, profile2_id 조합으로 조회
  /// 순서가 바뀌어 저장되어 있어도 찾을 수 있음
  Future<QueryResult<CompatibilityAnalysisModel?>> getByProfilePair(
    String profileId1,
    String profileId2,
  ) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(compatibilityAnalysesTable)
            .select(compatibilitySelectColumns)
            .or('and(profile1_id.eq.$profileId1,profile2_id.eq.$profileId2),'
                'and(profile1_id.eq.$profileId2,profile2_id.eq.$profileId1)')
            .order(CompatibilityColumns.createdAt, ascending: false)
            .limit(1)
            .maybeSingle();
        return response;
      },
      fromJson: CompatibilityAnalysisModel.fromSupabaseMap,
      errorPrefix: '프로필 간 궁합 분석 조회 실패',
    );
  }

  /// 특정 프로필이 포함된 모든 궁합 분석 조회
  ///
  /// 내가 profile1 또는 profile2인 모든 분석 결과
  Future<QueryResult<List<CompatibilityAnalysisModel>>> getByProfile(
    String profileId,
  ) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(compatibilityAnalysesTable)
            .select(compatibilityWithProfilesSelectColumns)
            .or('profile1_id.eq.$profileId,profile2_id.eq.$profileId')
            .order(CompatibilityColumns.createdAt, ascending: false);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: CompatibilityAnalysisModel.fromSupabaseMap,
      errorPrefix: '프로필 궁합 분석 목록 조회 실패',
    );
  }

  /// 특정 프로필의 최신 궁합 분석 N개 조회
  Future<QueryResult<List<CompatibilityAnalysisModel>>> getRecentByProfile(
    String profileId, {
    int limit = 10,
  }) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(compatibilityAnalysesTable)
            .select(compatibilityWithProfilesSelectColumns)
            .or('profile1_id.eq.$profileId,profile2_id.eq.$profileId')
            .order(CompatibilityColumns.createdAt, ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: CompatibilityAnalysisModel.fromSupabaseMap,
      errorPrefix: '최근 궁합 분석 조회 실패',
    );
  }

  /// 분석 유형별 조회
  Future<QueryResult<List<CompatibilityAnalysisModel>>> getByType(
    String profileId,
    String analysisType,
  ) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(compatibilityAnalysesTable)
            .select(compatibilityWithProfilesSelectColumns)
            .or('profile1_id.eq.$profileId,profile2_id.eq.$profileId')
            .eq(CompatibilityColumns.analysisType, analysisType)
            .order(CompatibilityColumns.createdAt, ascending: false);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: CompatibilityAnalysisModel.fromSupabaseMap,
      errorPrefix: '유형별 궁합 분석 조회 실패',
    );
  }

  /// 궁합 분석 존재 여부 확인
  Future<QueryResult<bool>> exists(
    String profileId1,
    String profileId2,
  ) async {
    return safeQuery(
      query: (client) async {
        final response = await client
            .from(compatibilityAnalysesTable)
            .select(CompatibilityColumns.id)
            .or('and(profile1_id.eq.$profileId1,profile2_id.eq.$profileId2),'
                'and(profile1_id.eq.$profileId2,profile2_id.eq.$profileId1)')
            .maybeSingle();
        return response != null;
      },
      errorPrefix: '궁합 분석 존재 확인 실패',
    );
  }

  /// 특정 프로필의 궁합 분석 개수 조회
  Future<QueryResult<int>> countByProfile(String profileId) async {
    return safeQuery(
      query: (client) async {
        final response = await client
            .from(compatibilityAnalysesTable)
            .select()
            .or('profile1_id.eq.$profileId,profile2_id.eq.$profileId')
            .count();
        return response.count;
      },
      errorPrefix: '궁합 분석 개수 조회 실패',
    );
  }

  /// 점수 범위별 조회
  Future<QueryResult<List<CompatibilityAnalysisModel>>> getByScoreRange(
    String profileId, {
    required int minScore,
    required int maxScore,
  }) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(compatibilityAnalysesTable)
            .select(compatibilityWithProfilesSelectColumns)
            .or('profile1_id.eq.$profileId,profile2_id.eq.$profileId')
            .gte(CompatibilityColumns.overallScore, minScore)
            .lte(CompatibilityColumns.overallScore, maxScore)
            .order(CompatibilityColumns.overallScore, ascending: false);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: CompatibilityAnalysisModel.fromSupabaseMap,
      errorPrefix: '점수 범위 궁합 조회 실패',
    );
  }
}

/// 싱글톤 인스턴스
const compatibilityQueries = CompatibilityQueries();
