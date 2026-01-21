/// # AI 모듈 쿼리
///
/// ## 개요
/// AI 분석에 필요한 데이터 조회 기능을 제공합니다.
/// - `ai_summaries` 테이블: AI 분석 결과 캐시
/// - `saju_analyses` 테이블: 사주 계산 데이터 (GPT 입력용)
///
/// ## 파일 위치
/// `frontend/lib/AI/data/queries.dart`
///
/// ## 주요 기능
/// 1. **캐시 조회**: 이미 분석된 결과가 있으면 API 호출 없이 반환
/// 2. **GPT 입력 데이터 준비**: saju_analyses → SajuInputData 변환
/// 3. **만료 체크**: expires_at 기준 유효한 캐시만 반환
///
/// ## 데이터 흐름
/// ```
/// saju_profiles + saju_analyses (DB)
///       ↓
/// AiQueries.getProfileWithAnalysis()
///       ↓
/// AiQueries.convertToInputData()
///       ↓
/// SajuInputData
///       ↓
/// PromptTemplate.buildUserPrompt()
///       ↓
/// GPT/Gemini API 호출
/// ```
///
/// ## 사용 예시
/// ```dart
/// // 1. 캐시된 평생 사주 분석 조회
/// final cached = await aiQueries.getSajuBaseSummary(profileId);
/// if (cached.isSuccess && cached.data != null) {
///   return cached.data!.content; // 캐시 반환
/// }
///
/// // 2. GPT 입력 데이터 준비
/// final result = await aiQueries.getProfileWithAnalysis(profileId);
/// final inputData = aiQueries.convertToInputData(
///   profile: profile,
///   analysis: analysis,
/// );
/// ```
///
/// ## 관련 파일
/// - `mutations.dart`: AI 분석 결과 저장
/// - `saju_analysis_service.dart`: 분석 오케스트레이션
/// - `prompt_template.dart`: SajuInputData 정의

import '../../core/data/data.dart';
import '../../core/supabase/generated/ai_summaries.dart';
import '../../core/supabase/generated/saju_analyses.dart';
import '../../core/supabase/generated/saju_profiles.dart';
import '../../features/saju_chart/domain/services/hapchung_service.dart';
import '../core/ai_constants.dart';
import '../prompts/prompt_template.dart';

/// AI 관련 쿼리
///
/// ## BaseQueries 상속
/// - `safeSingleQuery()`: 단일 결과 조회 (null 허용)
/// - `safeListQuery()`: 리스트 조회
/// - 자동 에러 처리 및 로깅
///
/// ## 전역 인스턴스
/// ```dart
/// const aiQueries = AiQueries();
/// final result = await aiQueries.getSajuBaseSummary(profileId);
/// ```
class AiQueries extends BaseQueries {
  const AiQueries();

  // ═══════════════════════════════════════════════════════════════════════════
  // ai_summaries 조회 (캐시)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 캐시된 분석 결과 조회
  ///
  /// ## 캐시 유효성 조건
  /// 1. `status = 'completed'`
  /// 2. `expires_at IS NULL` 또는 `expires_at > NOW()`
  ///
  /// ## 파라미터
  /// - `profileId`: 프로필 UUID
  /// - `summaryType`: 분석 유형 (saju_base, daily_fortune 등)
  /// - `targetDate`: 일운의 경우 대상 날짜
  /// - `targetPeriod`: 월운/년운의 경우 대상 기간 (예: "2024-12")
  Future<QueryResult<AiSummaries?>> getCachedSummary({
    required String profileId,
    required String summaryType,
    DateTime? targetDate,
    String? targetPeriod,
  }) async {
    return safeSingleQuery(
      query: (client) async {
        var query = client
            .from(AiSummaries.table_name)
            .select()
            .eq(AiSummaries.c_profileId, profileId)
            .eq(AiSummaries.c_summaryType, summaryType)
            .eq(AiSummaries.c_status, 'completed');

        // 날짜/기간 필터
        if (targetDate != null) {
          query = query.eq(
            AiSummaries.c_targetDate,
            targetDate.toIso8601String().split('T').first,
          );
        }
        if (targetPeriod != null) {
          query = query.eq(AiSummaries.c_targetPeriod, targetPeriod);
        }

        // 만료되지 않은 것만
        query = query.or(
          '${AiSummaries.c_expiresAt}.is.null,${AiSummaries.c_expiresAt}.gt.${DateTime.now().toUtc().toIso8601String()}',
        );

        return await query.maybeSingle();
      },
      fromJson: AiSummaries.fromJson,
      errorPrefix: 'AI 분석 캐시 조회 실패',
    );
  }

  /// 기본 사주 분석 캐시 조회
  ///
  /// ## UNIQUE INDEX
  /// `idx_ai_summaries_unique_base`: (profile_id) WHERE summary_type = 'saju_base'
  /// saju_base는 target_date가 NULL (날짜 필터 없이 profile_id + summary_type으로 조회)
  Future<QueryResult<AiSummaries?>> getSajuBaseSummary(String profileId) {
    return getCachedSummary(
      profileId: profileId,
      summaryType: SummaryType.sajuBase,
      // saju_base는 target_date 없음 (NULL) - 날짜 필터 적용 안 함
    );
  }

  /// 일운 캐시 조회
  Future<QueryResult<AiSummaries?>> getDailyFortune(
    String profileId,
    DateTime date,
  ) {
    return getCachedSummary(
      profileId: profileId,
      summaryType: SummaryType.dailyFortune,
      targetDate: date,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // saju_analyses 조회 (GPT 입력 데이터)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 프로필의 사주 분석 데이터 조회 (GPT 입력용)
  ///
  /// ## 용도
  /// GPT/Gemini에 전달할 사주 데이터 조회.
  /// 프로필 저장 시 자동 생성된 만세력 계산 결과.
  Future<QueryResult<SajuAnalyses?>> getSajuAnalysis(String profileId) async {
    return safeSingleQuery(
      query: (client) => client
          .from(SajuAnalyses.table_name)
          .select()
          .eq(SajuAnalyses.c_profileId, profileId)
          .maybeSingle(),
      fromJson: SajuAnalyses.fromJson,
      errorPrefix: '사주 분석 조회 실패',
    );
  }

  /// 프로필 + 사주 분석 함께 조회
  Future<QueryResult<Map<String, dynamic>?>> getProfileWithAnalysis(
    String profileId,
  ) async {
    return safeSingleQuery(
      query: (client) => client
          .from(SajuProfiles.table_name)
          .select('''
            *,
            saju_analyses (*)
          ''')
          .eq(SajuProfiles.c_id, profileId)
          .maybeSingle(),
      fromJson: (json) => json,
      errorPrefix: '프로필+분석 조회 실패',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 데이터 변환 (DB → GPT 입력)
  // ═══════════════════════════════════════════════════════════════════════════

  /// SajuAnalyses → SajuInputData 변환
  ///
  /// ## 변환 내용
  /// - 사주 팔자: "갑(甲)" → "갑" (한글만 추출)
  /// - 오행 분포: JSON → Map<String, int>
  /// - 생시: minutes → "HH:mm" 형식
  /// - 신살/길성: Map<pillar, List> → List<Map> 평탄화
  ///
  /// ## 반환값
  /// - 성공: SajuInputData 객체
  /// - 실패: null (변환 오류 시)
  SajuInputData? convertToInputData({
    required SajuProfiles profile,
    required SajuAnalyses analysis,
  }) {
    try {
      // 사주 정보 추출
      final saju = <String, String>{
        'year_gan': _extractHangul(analysis.yearGan),
        'year_ji': _extractHangul(analysis.yearJi),
        'month_gan': _extractHangul(analysis.monthGan),
        'month_ji': _extractHangul(analysis.monthJi),
        'day_gan': _extractHangul(analysis.dayGan),
        'day_ji': _extractHangul(analysis.dayJi),
      };

      if (analysis.hourGan != null) {
        saju['hour_gan'] = _extractHangul(analysis.hourGan!);
      }
      if (analysis.hourJi != null) {
        saju['hour_ji'] = _extractHangul(analysis.hourJi!);
      }

      // 오행 분포 (DB에는 한글(한자) 키로 저장됨: 목(木), 화(火), 토(土), 금(金), 수(水))
      final ohengRaw = analysis.ohengDistribution;
      final oheng = <String, int>{
        'wood': (ohengRaw['목(木)'] as num?)?.toInt() ?? 0,
        'fire': (ohengRaw['화(火)'] as num?)?.toInt() ?? 0,
        'earth': (ohengRaw['토(土)'] as num?)?.toInt() ?? 0,
        'metal': (ohengRaw['금(金)'] as num?)?.toInt() ?? 0,
        'water': (ohengRaw['수(水)'] as num?)?.toInt() ?? 0,
      };

      // 생시 변환 (minutes → HH:mm)
      String? birthTime;
      if (profile.birthTimeMinutes != null) {
        final hours = profile.birthTimeMinutes! ~/ 60;
        final minutes = profile.birthTimeMinutes! % 60;
        birthTime =
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
      }

      // 신살 리스트 (이미 List<Map> 형태)
      List<Map<String, dynamic>>? sinsalList;
      if (analysis.sinsalList != null) {
        sinsalList = analysis.sinsalList!.cast<Map<String, dynamic>>();
      }

      // 길성 변환
      List<Map<String, dynamic>>? gilseongList;
      if (analysis.gilseong != null) {
        gilseongList = _convertGilseong(analysis.gilseong!);
      }

      // 합충형파해 계산
      final hapchungResult = HapchungService.analyzeSaju(
        yearGan: saju['year_gan'] ?? '',
        monthGan: saju['month_gan'] ?? '',
        dayGan: saju['day_gan'] ?? '',
        hourGan: saju['hour_gan'] ?? '',
        yearJi: saju['year_ji'] ?? '',
        monthJi: saju['month_ji'] ?? '',
        dayJi: saju['day_ji'] ?? '',
        hourJi: saju['hour_ji'] ?? '',
      );
      final hapchungMap = _convertHapchungResult(hapchungResult);

      return SajuInputData(
        profileId: profile.id,
        profileName: profile.displayName,
        birthDate: profile.birthDate,
        birthTime: birthTime,
        gender: profile.gender,
        saju: saju,
        oheng: oheng,
        yongsin: analysis.yongsin,
        dayStrength: analysis.dayStrength,
        sinsal: sinsalList,
        gilseong: gilseongList,
        twelveUnsung: analysis.twelveUnsung,
        // 추가 분석 데이터
        sipsinInfo: analysis.sipsinInfo,
        jijangganInfo: analysis.jijangganInfo,
        gyeokguk: analysis.gyeokguk,
        twelveSinsal: analysis.twelveSinsal,
        daeun: analysis.daeun,
        hapchung: hapchungMap,
      );
    } catch (e) {
      print('[AiQueries] convertToInputData 오류: $e');
      return null;
    }
  }

  /// 한글(한자) 형식에서 한글만 추출
  /// 예: "갑(甲)" → "갑"
  String _extractHangul(String value) {
    final match = RegExp(r'^([가-힣]+)').firstMatch(value);
    return match?.group(1) ?? value;
  }

  /// 신살 리스트 변환
  List<Map<String, dynamic>> _convertSinsalList(Map<String, dynamic> raw) {
    final result = <Map<String, dynamic>>[];

    raw.forEach((pillar, sinsals) {
      if (sinsals is List) {
        for (final sinsal in sinsals) {
          if (sinsal is Map) {
            result.add({
              'name': sinsal['name'] ?? '',
              'pillar': pillar,
              'meaning': sinsal['meaning'] ?? sinsal['description'] ?? '',
            });
          }
        }
      }
    });

    return result;
  }

  /// 길성 변환
  List<Map<String, dynamic>> _convertGilseong(Map<String, dynamic> raw) {
    final result = <Map<String, dynamic>>[];

    raw.forEach((pillar, gilseongs) {
      if (gilseongs is List) {
        for (final g in gilseongs) {
          if (g is Map) {
            result.add({
              'name': g['name'] ?? '',
              'pillar': pillar,
              'meaning': g['meaning'] ?? g['description'] ?? '',
            });
          }
        }
      }
    });

    return result;
  }

  /// 합충형파해 결과를 Map으로 변환
  ///
  /// HapchungAnalysisResult → GPT 프롬프트용 Map 변환
  Map<String, dynamic> _convertHapchungResult(HapchungAnalysisResult result) {
    return {
      // 천간 관계
      'cheongan_haps': result.cheonganHaps
          .map((h) => {
                'gan1': h.gan1,
                'gan2': h.gan2,
                'pillar1': h.pillar1,
                'pillar2': h.pillar2,
                'description': h.description,
              })
          .toList(),
      'cheongan_chungs': result.cheonganChungs
          .map((c) => {
                'gan1': c.gan1,
                'gan2': c.gan2,
                'pillar1': c.pillar1,
                'pillar2': c.pillar2,
                'description': c.description,
              })
          .toList(),

      // 지지 관계
      'jiji_yukhaps': result.jijiYukhaps
          .map((y) => {
                'ji1': y.ji1,
                'ji2': y.ji2,
                'pillar1': y.pillar1,
                'pillar2': y.pillar2,
                'description': y.description,
              })
          .toList(),
      'jiji_samhaps': result.jijiSamhaps
          .map((s) => {
                'jijis': s.jijis,
                'pillars': s.pillars,
                'result_oheng': s.resultOheng,
                'description': s.description,
                'is_full': s.isFullSamhap,
              })
          .toList(),
      'jiji_banghaps': result.jijiBanghaps
          .map((b) => {
                'jijis': b.jijis,
                'pillars': b.pillars,
                'result_oheng': b.resultOheng,
                'season': b.season,
                'direction': b.direction,
                'description': b.description,
              })
          .toList(),
      'jiji_chungs': result.jijiChungs
          .map((c) => {
                'ji1': c.ji1,
                'ji2': c.ji2,
                'pillar1': c.pillar1,
                'pillar2': c.pillar2,
                'description': c.description,
              })
          .toList(),
      'jiji_hyungs': result.jijiHyungs
          .map((h) => {
                'ji1': h.ji1,
                'ji2': h.ji2,
                'pillar1': h.pillar1,
                'pillar2': h.pillar2,
                'description': h.description,
              })
          .toList(),
      'jiji_pas': result.jijiPas
          .map((p) => {
                'ji1': p.ji1,
                'ji2': p.ji2,
                'pillar1': p.pillar1,
                'pillar2': p.pillar2,
                'description': p.description,
              })
          .toList(),
      'jiji_haes': result.jijiHaes
          .map((h) => {
                'ji1': h.ji1,
                'ji2': h.ji2,
                'pillar1': h.pillar1,
                'pillar2': h.pillar2,
                'description': h.description,
              })
          .toList(),
      'wonjins': result.wonjins
          .map((w) => {
                'ji1': w.ji1,
                'ji2': w.ji2,
                'pillar1': w.pillar1,
                'pillar2': w.pillar2,
                'description': w.description,
              })
          .toList(),

      // 집계
      'total_haps': result.totalHaps,
      'total_chungs': result.totalChungs,
      'total_negatives': result.totalNegatives,
      'has_relations': result.hasRelations,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ai_tasks 조회 (중복 방지)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 진행 중인 AI task 확인 (중복 생성 방지)
  ///
  /// ## 용도
  /// GPT-5.2 분석은 100-150초 소요.
  /// 그 사이 다른 곳에서 동일 사용자가 분석 요청을 하면
  /// 이미 진행 중인 task가 있는지 확인하여 중복 생성 방지.
  ///
  /// ## 파라미터
  /// - `userId`: 사용자 UUID
  /// - `taskType`: task 유형 (saju_analysis 등)
  /// - `model`: AI 모델명 (gpt-5.2, gpt-5-mini 등) - **필수** ⚠️
  ///
  /// ## 반환값
  /// - pending/processing task가 있으면: task_id
  /// - 없으면: null
  ///
  /// ## 참고
  /// - Edge Function에서 user_id로 task 생성
  /// - 같은 user의 동시 분석 요청 방지
  /// - **v6.4 (2026-01-21)**: model 필터 추가
  ///   - saju_base(gpt-5.2)와 Fortune(gpt-5-mini)이 같은 task_type 사용
  ///   - model로 구분하지 않으면 Fortune task가 saju_base를 블로킹함!
  Future<QueryResult<String?>> getPendingTaskId({
    required String userId,
    required String model,
    String taskType = 'saju_analysis',
  }) async {
    return safeSingleQuery(
      query: (client) async {
        // ai_tasks 테이블에서 pending/processing 상태 조회
        // user_id + model로 필터링 (동일 사용자 + 동일 모델의 중복 task 방지)
        final result = await client
            .from('ai_tasks')
            .select('id')
            .eq('task_type', taskType)
            .eq('user_id', userId)
            .eq('model', model)
            .inFilter('status', ['pending', 'processing'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        return result;
      },
      fromJson: (json) => json['id'] as String,
      errorPrefix: '진행 중 task 조회 실패',
    );
  }

  /// 진행 중인 task 상세 조회
  ///
  /// ## 용도
  /// task_id로 현재 상태 확인 (폴링용)
  Future<QueryResult<Map<String, dynamic>?>> getTaskStatus(String taskId) async {
    return safeSingleQuery(
      query: (client) => client
          .from('ai_tasks')
          .select('id, status, result_data, error_message, created_at, completed_at')
          .eq('id', taskId)
          .maybeSingle(),
      fromJson: (json) => json,
      errorPrefix: 'task 상태 조회 실패',
    );
  }
}

/// 전역 인스턴스
const aiQueries = AiQueries();
