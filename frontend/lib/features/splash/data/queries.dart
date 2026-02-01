import 'package:flutter/foundation.dart';

import '../../../core/data/data.dart';
import '../../profile/data/models/saju_profile_model.dart';
import '../../profile/data/schema.dart' as profile_schema;
import '../../saju_chart/data/models/saju_analysis_db_model.dart';
import '../../saju_chart/data/schema.dart' as analysis_schema;
import '../../saju_chat/data/models/chat_session_model.dart';
import '../../saju_chat/data/schema.dart' as chat_schema;
import 'schema.dart';

/// Splash Pre-fetch 쿼리 클래스
///
/// 앱 시작 시 필요한 데이터를 한 번에 로드
/// - Primary 프로필
/// - 사주 분석
/// - 최근 채팅 세션 (optional)
class SplashQueries extends BaseQueries {
  const SplashQueries();

  /// Primary 프로필 + 사주 분석 한 번에 조회
  ///
  /// 앱 시작 시 가장 먼저 호출
  /// Returns: (프로필, 분석) 또는 null
  /// Note: 프로덕션에서는 admin 제외, Debug 모드에서는 admin 포함
  Future<QueryResult<SplashPrefetchData?>> prefetchPrimaryData(
    String userId,
  ) async {
    return safeQuery(
      query: (client) async {
        // 1. Primary 프로필 조회 (프로덕션에서만 admin 제외)
        var query = client
            .from(profile_schema.profilesTable)
            .select(primaryProfileColumns)
            .eq(profile_schema.ProfileColumns.userId, userId)
            .eq(profile_schema.ProfileColumns.profileType, 'primary');

        // 프로덕션에서만 admin 제외 (Debug 모드에서는 admin 포함)
        if (!kDebugMode) {
          query = query.neq(profile_schema.ProfileColumns.relationType, 'admin');
        }

        final profileResponse = await query.maybeSingle();

        if (profileResponse == null) {
          return null;
        }

        final profile = SajuProfileModel.fromSupabaseMap(profileResponse);

        // 2. 해당 프로필의 사주 분석 조회
        final analysisResponse = await client
            .from(analysis_schema.sajuAnalysesTable)
            .select(coreAnalysisColumns)
            .eq(analysis_schema.SajuAnalysisColumns.profileId, profile.id)
            .maybeSingle();

        SajuAnalysisDbModel? analysis;
        if (analysisResponse != null) {
          analysis = SajuAnalysisDbModel.fromSupabase(analysisResponse);
        }

        return SplashPrefetchData(
          profile: profile,
          analysis: analysis,
        );
      },
      errorPrefix: 'Pre-fetch 실패',
    );
  }

  /// Primary 프로필만 조회 (프로덕션에서만 admin 제외)
  Future<QueryResult<SajuProfileModel?>> getPrimaryProfile(
    String userId,
  ) async {
    return safeSingleQuery(
      query: (client) async {
        var query = client
            .from(profile_schema.profilesTable)
            .select(primaryProfileColumns)
            .eq(profile_schema.ProfileColumns.userId, userId)
            .eq(profile_schema.ProfileColumns.profileType, 'primary');

        if (!kDebugMode) {
          query = query.neq(profile_schema.ProfileColumns.relationType, 'admin');
        }

        final response = await query.maybeSingle();
        return response;
      },
      fromJson: SajuProfileModel.fromSupabaseMap,
      errorPrefix: 'Primary 프로필 조회 실패',
    );
  }

  /// 사주 분석 조회 (AI 컨텍스트용 핵심 컬럼)
  Future<QueryResult<SajuAnalysisDbModel?>> getCoreAnalysis(
    String profileId,
  ) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(analysis_schema.sajuAnalysesTable)
            .select(coreAnalysisColumns)
            .eq(analysis_schema.SajuAnalysisColumns.profileId, profileId)
            .maybeSingle();
        return response;
      },
      fromJson: SajuAnalysisDbModel.fromSupabase,
      errorPrefix: '사주 분석 조회 실패',
    );
  }

  /// 사주 분석 전체 조회 (상세 화면용)
  Future<QueryResult<SajuAnalysisDbModel?>> getFullAnalysis(
    String profileId,
  ) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(analysis_schema.sajuAnalysesTable)
            .select(fullAnalysisColumns)
            .eq(analysis_schema.SajuAnalysisColumns.profileId, profileId)
            .maybeSingle();
        return response;
      },
      fromJson: SajuAnalysisDbModel.fromSupabase,
      errorPrefix: '사주 분석 전체 조회 실패',
    );
  }

  /// 최근 채팅 세션 조회 (Optional pre-fetch)
  Future<QueryResult<ChatSessionModel?>> getRecentSession(
    String profileId,
  ) async {
    return safeSingleQuery(
      query: (client) async {
        final response = await client
            .from(chat_schema.chatSessionsTable)
            .select(recentSessionColumns)
            .eq(chat_schema.ChatSessionColumns.profileId, profileId)
            .order(chat_schema.ChatSessionColumns.updatedAt, ascending: false)
            .limit(1)
            .maybeSingle();
        return response;
      },
      fromJson: ChatSessionModel.fromSupabaseMap,
      errorPrefix: '최근 세션 조회 실패',
    );
  }

  /// 프로필 존재 여부만 빠르게 확인 (프로덕션에서만 admin 제외)
  Future<QueryResult<bool>> hasPrimaryProfile(String userId) async {
    return safeQuery(
      query: (client) async {
        var query = client
            .from(profile_schema.profilesTable)
            .select(profile_schema.ProfileColumns.id)
            .eq(profile_schema.ProfileColumns.userId, userId)
            .eq(profile_schema.ProfileColumns.profileType, 'primary');

        if (!kDebugMode) {
          query = query.neq(profile_schema.ProfileColumns.relationType, 'admin');
        }

        final response = await query.maybeSingle();
        return response != null;
      },
      errorPrefix: '프로필 존재 확인 실패',
    );
  }

  /// 분석 존재 여부만 빠르게 확인
  Future<QueryResult<bool>> hasAnalysis(String profileId) async {
    return safeQuery(
      query: (client) async {
        final response = await client
            .from(analysis_schema.sajuAnalysesTable)
            .select(analysis_schema.SajuAnalysisColumns.id)
            .eq(analysis_schema.SajuAnalysisColumns.profileId, profileId)
            .maybeSingle();
        return response != null;
      },
      errorPrefix: '분석 존재 확인 실패',
    );
  }

  /// Pre-fetch 상태 확인
  ///
  /// 빠른 상태 확인용 (데이터 로드 없이)
  /// Note: 프로덕션에서는 admin 제외, Debug 모드에서는 admin 포함
  Future<QueryResult<PrefetchStatus>> checkPrefetchStatus(
    String userId,
  ) async {
    return safeQuery(
      query: (client) async {
        // 1. 프로필 존재 확인 (프로덕션에서만 admin 제외)
        var profileQuery = client
            .from(profile_schema.profilesTable)
            .select(profile_schema.ProfileColumns.id)
            .eq(profile_schema.ProfileColumns.userId, userId)
            .eq(profile_schema.ProfileColumns.profileType, 'primary');

        if (!kDebugMode) {
          profileQuery = profileQuery.neq(profile_schema.ProfileColumns.relationType, 'admin');
        }

        final profileResponse = await profileQuery.maybeSingle();

        if (profileResponse == null) {
          return PrefetchStatus.noProfile;
        }

        final profileId = profileResponse[profile_schema.ProfileColumns.id] as String;

        // 2. 분석 존재 확인
        final analysisResponse = await client
            .from(analysis_schema.sajuAnalysesTable)
            .select(analysis_schema.SajuAnalysisColumns.id)
            .eq(analysis_schema.SajuAnalysisColumns.profileId, profileId)
            .maybeSingle();

        if (analysisResponse == null) {
          return PrefetchStatus.noAnalysis;
        }

        return PrefetchStatus.hasData;
      },
      offlineData: () => PrefetchStatus.offline,
      errorPrefix: 'Pre-fetch 상태 확인 실패',
    );
  }
}

// ============================================================================
// Pre-fetch 결과 데이터 클래스
// ============================================================================

/// Splash Pre-fetch 결과
class SplashPrefetchData {
  final SajuProfileModel profile;
  final SajuAnalysisDbModel? analysis;
  final ChatSessionModel? recentSession;

  const SplashPrefetchData({
    required this.profile,
    this.analysis,
    this.recentSession,
  });

  /// 분석 데이터 있음?
  bool get hasAnalysis => analysis != null;

  /// 세션 데이터 있음?
  bool get hasRecentSession => recentSession != null;

  /// 완전한 데이터?
  bool get isComplete => hasAnalysis;

  /// 프로필 ID
  String get profileId => profile.id;

  /// 상태
  PrefetchStatus get status {
    if (analysis == null) return PrefetchStatus.noAnalysis;
    return PrefetchStatus.hasData;
  }

  /// 복사본 생성
  SplashPrefetchData copyWith({
    SajuProfileModel? profile,
    SajuAnalysisDbModel? analysis,
    ChatSessionModel? recentSession,
  }) {
    return SplashPrefetchData(
      profile: profile ?? this.profile,
      analysis: analysis ?? this.analysis,
      recentSession: recentSession ?? this.recentSession,
    );
  }
}

/// 싱글톤 인스턴스
const splashQueries = SplashQueries();
