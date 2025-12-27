import '../../../core/data/data.dart';
import 'models/saju_analysis_db_model.dart';
import 'schema.dart';

/// Saju Analysis 뮤테이션 클래스
///
/// INSERT, UPDATE, DELETE 작업 담당
/// 오프라인 모드에서는 실패 반환
class SajuAnalysisMutations extends BaseMutations {
  const SajuAnalysisMutations();

  /// 사주 분석 생성
  Future<QueryResult<SajuAnalysisDbModel>> create(
    SajuAnalysisDbModel analysis,
  ) async {
    return safeMutation(
      mutation: (client) async {
        final data = analysis.toSupabase();
        final response = await client
            .from(sajuAnalysesTable)
            .insert(data)
            .select(sajuAnalysisSelectColumns)
            .single();
        return SajuAnalysisDbModel.fromSupabase(response);
      },
      errorPrefix: '사주 분석 생성 실패',
    );
  }

  /// 사주 분석 업데이트
  Future<QueryResult<SajuAnalysisDbModel>> update(
    SajuAnalysisDbModel analysis,
  ) async {
    return safeMutation(
      mutation: (client) async {
        final data = analysis.toSupabase();
        data.remove('id');
        data['updated_at'] = DateTime.now().toUtc().toIso8601String();

        final response = await client
            .from(sajuAnalysesTable)
            .update(data)
            .eq(SajuAnalysisColumns.id, analysis.id)
            .select(sajuAnalysisSelectColumns)
            .single();
        return SajuAnalysisDbModel.fromSupabase(response);
      },
      errorPrefix: '사주 분석 업데이트 실패',
    );
  }

  /// Upsert (있으면 업데이트, 없으면 생성)
  Future<QueryResult<SajuAnalysisDbModel>> upsert(
    SajuAnalysisDbModel analysis,
  ) async {
    return safeMutation(
      mutation: (client) async {
        final data = analysis.toSupabase();
        data['updated_at'] = DateTime.now().toUtc().toIso8601String();

        final response = await client
            .from(sajuAnalysesTable)
            .upsert(data)
            .select(sajuAnalysisSelectColumns)
            .single();
        return SajuAnalysisDbModel.fromSupabase(response);
      },
      errorPrefix: '사주 분석 Upsert 실패',
    );
  }

  /// 사주 분석 삭제
  Future<QueryResult<void>> delete(String analysisId) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(sajuAnalysesTable)
            .delete()
            .eq(SajuAnalysisColumns.id, analysisId);
      },
      errorPrefix: '사주 분석 삭제 실패',
    );
  }

  /// 프로필 ID로 삭제
  Future<QueryResult<void>> deleteByProfileId(String profileId) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(sajuAnalysesTable)
            .delete()
            .eq(SajuAnalysisColumns.profileId, profileId);
      },
      errorPrefix: '프로필 분석 삭제 실패',
    );
  }

  /// 오행 분포만 업데이트
  Future<QueryResult<void>> updateOhengDistribution(
    String analysisId,
    Map<String, dynamic> ohengDistribution,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client.from(sajuAnalysesTable).update({
          SajuAnalysisColumns.ohengDistribution: ohengDistribution,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq(SajuAnalysisColumns.id, analysisId);
      },
      errorPrefix: '오행 분포 업데이트 실패',
    );
  }

  /// 일간 강약만 업데이트
  Future<QueryResult<void>> updateDayStrength(
    String analysisId,
    Map<String, dynamic> dayStrength,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client.from(sajuAnalysesTable).update({
          SajuAnalysisColumns.dayStrength: dayStrength,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq(SajuAnalysisColumns.id, analysisId);
      },
      errorPrefix: '일간 강약 업데이트 실패',
    );
  }

  /// 용신만 업데이트
  Future<QueryResult<void>> updateYongsin(
    String analysisId,
    Map<String, dynamic> yongsin,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client.from(sajuAnalysesTable).update({
          SajuAnalysisColumns.yongsin: yongsin,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq(SajuAnalysisColumns.id, analysisId);
      },
      errorPrefix: '용신 업데이트 실패',
    );
  }

  /// 대운만 업데이트
  Future<QueryResult<void>> updateDaeun(
    String analysisId,
    Map<String, dynamic> daeun,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client.from(sajuAnalysesTable).update({
          SajuAnalysisColumns.daeun: daeun,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq(SajuAnalysisColumns.id, analysisId);
      },
      errorPrefix: '대운 업데이트 실패',
    );
  }

  /// 현재 세운만 업데이트
  Future<QueryResult<void>> updateCurrentSeun(
    String analysisId,
    Map<String, dynamic> currentSeun,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client.from(sajuAnalysesTable).update({
          SajuAnalysisColumns.currentSeun: currentSeun,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq(SajuAnalysisColumns.id, analysisId);
      },
      errorPrefix: '세운 업데이트 실패',
    );
  }

  /// 12운성만 업데이트
  Future<QueryResult<void>> updateTwelveUnsung(
    String analysisId,
    List<Map<String, dynamic>> twelveUnsung,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client.from(sajuAnalysesTable).update({
          SajuAnalysisColumns.twelveUnsung: twelveUnsung,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq(SajuAnalysisColumns.id, analysisId);
      },
      errorPrefix: '12운성 업데이트 실패',
    );
  }

  /// 12신살만 업데이트
  Future<QueryResult<void>> updateTwelveSinsal(
    String analysisId,
    List<Map<String, dynamic>> twelveSinsal,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client.from(sajuAnalysesTable).update({
          SajuAnalysisColumns.twelveSinsal: twelveSinsal,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq(SajuAnalysisColumns.id, analysisId);
      },
      errorPrefix: '12신살 업데이트 실패',
    );
  }

  /// 십신 정보만 업데이트
  Future<QueryResult<void>> updateSipsinInfo(
    String analysisId,
    Map<String, dynamic> sipsinInfo,
  ) async {
    return safeMutation(
      mutation: (client) async {
        await client.from(sajuAnalysesTable).update({
          SajuAnalysisColumns.sipsinInfo: sipsinInfo,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq(SajuAnalysisColumns.id, analysisId);
      },
      errorPrefix: '십신 정보 업데이트 실패',
    );
  }

  /// 부분 업데이트 (여러 필드 동시)
  Future<QueryResult<void>> patch(
    String analysisId,
    Map<String, dynamic> updates,
  ) async {
    return safeMutation(
      mutation: (client) async {
        updates['updated_at'] = DateTime.now().toUtc().toIso8601String();
        await client
            .from(sajuAnalysesTable)
            .update(updates)
            .eq(SajuAnalysisColumns.id, analysisId);
      },
      errorPrefix: '사주 분석 부분 업데이트 실패',
    );
  }
}

/// 싱글톤 인스턴스
const sajuAnalysisMutations = SajuAnalysisMutations();
