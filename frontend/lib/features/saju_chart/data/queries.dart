import '../../../core/data/data.dart';
import 'models/saju_analysis_db_model.dart';
import 'schema.dart';

/// Saju Analysis 쿼리 클래스
///
/// SELECT 작업 담당
/// 오프라인 모드 + 에러 처리 내장
class SajuAnalysisQueries extends BaseQueries {
  const SajuAnalysisQueries();

  /// 프로필 ID로 사주 분석 조회
  Future<QueryResult<SajuAnalysisDbModel?>> getByProfileId(
    String profileId,
  ) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(sajuAnalysesTable)
            .select(sajuAnalysisSelectColumns)
            .eq(SajuAnalysisColumns.profileId, profileId)
            .maybeSingle();
        return response;
      },
      fromJson: SajuAnalysisDbModel.fromSupabase,
      errorPrefix: '사주 분석 조회 실패',
    );
  }

  /// 분석 ID로 조회
  Future<QueryResult<SajuAnalysisDbModel?>> getById(String analysisId) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(sajuAnalysesTable)
            .select(sajuAnalysisSelectColumns)
            .eq(SajuAnalysisColumns.id, analysisId)
            .maybeSingle();
        return response;
      },
      fromJson: SajuAnalysisDbModel.fromSupabase,
      errorPrefix: '사주 분석 조회 실패',
    );
  }

  /// 기본 사주 정보만 조회 (빠른 로딩)
  Future<QueryResult<SajuAnalysisDbModel?>> getBasicByProfileId(
    String profileId,
  ) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(sajuAnalysesTable)
            .select(sajuBasicSelectColumns)
            .eq(SajuAnalysisColumns.profileId, profileId)
            .maybeSingle();
        return response;
      },
      fromJson: SajuAnalysisDbModel.fromSupabase,
      errorPrefix: '기본 사주 조회 실패',
    );
  }

  /// AI 컨텍스트용 데이터 조회
  Future<QueryResult<SajuAnalysisDbModel?>> getForAiContext(
    String profileId,
  ) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(sajuAnalysesTable)
            .select(sajuAiContextColumns)
            .eq(SajuAnalysisColumns.profileId, profileId)
            .maybeSingle();
        return response;
      },
      fromJson: SajuAnalysisDbModel.fromSupabase,
      errorPrefix: 'AI 컨텍스트 조회 실패',
    );
  }

  /// 여러 프로필의 사주 분석 일괄 조회
  Future<QueryResult<List<SajuAnalysisDbModel>>> getByProfileIds(
    List<String> profileIds,
  ) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(sajuAnalysesTable)
            .select(sajuAnalysisSelectColumns)
            .inFilter(SajuAnalysisColumns.profileId, profileIds);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: SajuAnalysisDbModel.fromSupabase,
      errorPrefix: '다중 사주 분석 조회 실패',
    );
  }

  /// 분석 존재 여부 확인
  Future<QueryResult<bool>> existsByProfileId(String profileId) async {
    return safeQuery(
      query: (client) async {
        final response = await client
            .from(sajuAnalysesTable)
            .select(SajuAnalysisColumns.id)
            .eq(SajuAnalysisColumns.profileId, profileId)
            .maybeSingle();
        return response != null;
      },
      errorPrefix: '분석 존재 확인 실패',
    );
  }

  /// 특정 일간(日干)을 가진 분석 목록 조회 (통계용)
  Future<QueryResult<List<SajuAnalysisDbModel>>> getByDayGan(
    String dayGan,
  ) async {
    return safeListQuery(
      query: (client) async {
        final response = await client
            .from(sajuAnalysesTable)
            .select(sajuBasicSelectColumns)
            .eq(SajuAnalysisColumns.dayGan, dayGan);
        return List<Map<String, dynamic>>.from(response);
      },
      fromJson: SajuAnalysisDbModel.fromSupabase,
      errorPrefix: '일간별 분석 조회 실패',
    );
  }

  /// 오행 분포만 조회
  Future<QueryResult<Map<String, dynamic>?>> getOhengDistribution(
    String profileId,
  ) async {
    return safeQuery(
      query: (client) async {
        final response = await client
            .from(sajuAnalysesTable)
            .select(SajuAnalysisColumns.ohengDistribution)
            .eq(SajuAnalysisColumns.profileId, profileId)
            .maybeSingle();
        return response?[SajuAnalysisColumns.ohengDistribution]
            as Map<String, dynamic>?;
      },
      errorPrefix: '오행 분포 조회 실패',
    );
  }

  /// 용신 정보만 조회
  Future<QueryResult<Map<String, dynamic>?>> getYongsin(
    String profileId,
  ) async {
    return safeQuery(
      query: (client) async {
        final response = await client
            .from(sajuAnalysesTable)
            .select(SajuAnalysisColumns.yongsin)
            .eq(SajuAnalysisColumns.profileId, profileId)
            .maybeSingle();
        return response?[SajuAnalysisColumns.yongsin] as Map<String, dynamic>?;
      },
      errorPrefix: '용신 조회 실패',
    );
  }

  /// 대운 정보만 조회
  Future<QueryResult<Map<String, dynamic>?>> getDaeun(
    String profileId,
  ) async {
    return safeQuery(
      query: (client) async {
        final response = await client
            .from(sajuAnalysesTable)
            .select(SajuAnalysisColumns.daeun)
            .eq(SajuAnalysisColumns.profileId, profileId)
            .maybeSingle();
        return response?[SajuAnalysisColumns.daeun] as Map<String, dynamic>?;
      },
      errorPrefix: '대운 조회 실패',
    );
  }
}

/// 싱글톤 인스턴스
const sajuAnalysisQueries = SajuAnalysisQueries();
