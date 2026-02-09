/// # Fortune Coordinator (운세 통합 조율 서비스) v3.0
///
/// ## 개요
/// saju_analyses(만세력 계산 데이터)를 기반으로 모든 운세 분석을 조율
/// - saju_base 대기 없이 즉시 분석 시작!
/// - 140초 대기 시간 제거 (성능 대폭 개선)
///
/// ## v3.0 핵심 변경 (2025-01)
/// ```
/// Before: saju_base(140초) 대기 → 운세 분석 시작
/// After:  saju_analyses(즉시) → 바로 운세 분석 시작!
/// ```
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/fortune_coordinator.dart`

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/error_logging_service.dart';
import '../core/ai_constants.dart';
import '../services/ai_api_service.dart';
import 'common/fortune_input_data.dart';
import 'common/fortune_state.dart';
import 'common/korea_date_utils.dart';
import 'common/saju_analyses_queries.dart';
import 'daily/daily_service.dart';
import 'monthly/monthly_service.dart';
import 'yearly_2025/yearly_2025_service.dart';
import 'yearly_2026/yearly_2026_service.dart';

/// 전체 운세 분석 결과
class FortuneAnalysisResults {
  final bool success;
  final Map<String, dynamic>? yearly2026;
  final Map<String, dynamic>? monthly;
  final Map<String, dynamic>? yearly2025;
  final Map<String, dynamic>? daily; // v7.0 추가
  final String? errorMessage;

  const FortuneAnalysisResults({
    required this.success,
    this.yearly2026,
    this.monthly,
    this.yearly2025,
    this.daily,
    this.errorMessage,
  });

  factory FortuneAnalysisResults.error(String message) {
    return FortuneAnalysisResults(
      success: false,
      errorMessage: message,
    );
  }

  /// 모든 분석이 완료되었는지
  bool get allCompleted =>
      yearly2026 != null && monthly != null && yearly2025 != null && daily != null;

  /// 완료된 분석 개수
  int get completedCount {
    int count = 0;
    if (yearly2026 != null) count++;
    if (monthly != null) count++;
    if (yearly2025 != null) count++;
    if (daily != null) count++;
    return count;
  }
}

/// Fortune Coordinator (운세 통합 조율 서비스)
class FortuneCoordinator {
  final SupabaseClient _supabase;
  final AIApiService _aiApiService;

  late final Yearly2026Service _yearly2026Service;
  late final MonthlyService _monthlyService;
  late final Yearly2025Service _yearly2025Service;
  late final DailyService _dailyService;
  late final SajuAnalysesQueries _sajuAnalysesQueries;

  /// v6.1 중복 분석 방지용 - 현재 분석 중인 프로필 ID 목록
  static final Set<String> _analyzingProfiles = {};

  /// v7.4 Daily 전용 중복 분석 방지용 - 현재 Daily 분석 중인 프로필+날짜 키
  /// key: "profileId_yyyy-MM-dd"
  static final Set<String> _analyzingDaily = {};

  FortuneCoordinator({
    required SupabaseClient supabase,
    required AIApiService aiApiService,
  })  : _supabase = supabase,
        _aiApiService = aiApiService {
    _yearly2026Service = Yearly2026Service(
      supabase: _supabase,
      aiApiService: _aiApiService,
    );
    _monthlyService = MonthlyService(
      supabase: _supabase,
      aiApiService: _aiApiService,
    );
    _yearly2025Service = Yearly2025Service(
      supabase: _supabase,
      aiApiService: _aiApiService,
    );
    _dailyService = DailyService(
      supabase: _supabase,
      aiApiService: _aiApiService,
    );
    _sajuAnalysesQueries = SajuAnalysesQueries(_supabase);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // saju_base 관련 메서드 (v3.0: Deprecated - 하위 호환성용)
  // v3.0부터 운세 분석은 saju_analyses만 사용 (140초 대기 제거!)
  // ═══════════════════════════════════════════════════════════════════════════

  /// saju_base 준비 상태 확인
  /// @deprecated v3.0부터 사용하지 않음 (saju_analyses 기반으로 변경)
  ///
  /// [profileId] 프로필 UUID
  /// 반환: FortuneState (waitingForSajuBase 또는 ready)
  @Deprecated('v3.0: 운세 분석은 이제 saju_analyses만 사용')
  Future<FortuneState> checkSajuBaseReady(String profileId) async {
    try {
      final sajuBase = await _getSajuBase(profileId);

      if (sajuBase == null) {
        return FortuneState.waitingForSajuBase;
      }

      return FortuneState.ready;
    } catch (e) {
      return FortuneState.error;
    }
  }

  /// saju_base 완료 대기 (폴링)
  /// @deprecated v3.0부터 사용하지 않음 (140초 대기 제거!)
  ///
  /// [profileId] 프로필 UUID
  /// [maxWaitSeconds] 최대 대기 시간 (초), 기본 300초 (5분)
  /// [pollIntervalSeconds] 폴링 간격 (초), 기본 5초
  ///
  /// 반환: saju_base content 또는 null (타임아웃)
  @Deprecated('v3.0: 운세 분석은 이제 saju_base 대기 없이 즉시 시작')
  Future<Map<String, dynamic>?> waitForSajuBase(
    String profileId, {
    int maxWaitSeconds = 300,
    int pollIntervalSeconds = 5,
  }) async {
    final maxAttempts = maxWaitSeconds ~/ pollIntervalSeconds;

    for (int i = 0; i < maxAttempts; i++) {
      final sajuBase = await _getSajuBase(profileId);

      if (sajuBase != null) {
        return sajuBase;
      }

      await Future.delayed(Duration(seconds: pollIntervalSeconds));
    }

    // 타임아웃
    return null;
  }

  /// saju_base 캐시 조회
  Future<Map<String, dynamic>?> _getSajuBase(String profileId) async {
    try {
      final response = await _supabase
          .from('ai_summaries')
          .select('content')
          .eq('profile_id', profileId)
          .eq('summary_type', SummaryType.sajuBase)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final content = response['content'];
      if (content is Map<String, dynamic>) {
        return content;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 통합 분석 메서드
  // ═══════════════════════════════════════════════════════════════════════════

  /// 전체 운세 일괄 분석 (v3.0 - 즉시 시작!)
  ///
  /// ## 플로우 (v3.0 개선)
  /// 1. saju_analyses 확인 (없으면 에러) - saju_base 대기 없음!
  /// 2. FortuneInputData 구성
  /// 3. 각 운세 독립적 병렬 분석 (하나 완료되면 바로 저장)
  /// 4. 결과 반환
  ///
  /// ## 성능 개선
  /// - Before: saju_base 완료 대기 (약 140초) → 운세 분석
  /// - After: saju_analyses(즉시) → 바로 운세 분석 시작!
  ///
  /// [userId] 사용자 UUID
  /// [profileId] 프로필 UUID
  /// [profileName] 프로필 이름
  /// [birthDate] 생년월일
  /// [birthTime] 태어난 시간 (선택)
  /// [gender] 성별 ('M' 또는 'F')
  Future<FortuneAnalysisResults> analyzeAllFortunes({
    required String userId,
    required String profileId,
    required String profileName,
    required String birthDate,
    String? birthTime,
    required String gender,
  }) async {
    // v6.1 중복 분석 방지
    if (_analyzingProfiles.contains(profileId)) {
      print('[FortuneCoordinator] ⏭️ 이미 분석 중: $profileId (스킵)');
      return FortuneAnalysisResults.error('이미 분석 중입니다.');
    }
    _analyzingProfiles.add(profileId);

    try {
      // 1. saju_analyses 조회 (v3.0: saju_base 대기 없이 즉시!)
      // - 프로필 저장 시 이미 계산된 만세력 데이터
      // - 용신/기신, 합충형파해, 일간강약, 신살, 사주팔자 포함
      final sajuAnalyses =
          await _sajuAnalysesQueries.getForFortuneInput(profileId);

      if (sajuAnalyses == null) {
        return FortuneAnalysisResults.error(
          'saju_analyses가 없습니다. 프로필 저장이 완료되어야 합니다.',
        );
      }

      print(
          '[FortuneCoordinator] ✅ saju_analyses 조회 성공: day_gan=${sajuAnalyses['day_gan']}');

      // 2. FortuneInputData 구성 (v3.0: saju_analyses만 사용!)
      // - saju_base 없이도 운세 분석 가능
      // - 140초 대기 시간 제거!
      final inputData = FortuneInputData.fromSajuAnalyses(
        profileName: profileName,
        birthDate: birthDate,
        birthTime: birthTime,
        gender: gender,
        sajuAnalyses: sajuAnalyses,
      );

      // 3. 독립적 병렬 분석 - 각각 완료되면 바로 저장됨 (실패해도 다른 것에 영향 없음)
      // v7.0: Daily Fortune 추가!
      print('[FortuneCoordinator] 🚀 v7.0 운세 분석 즉시 시작! (Daily 포함)');

      Yearly2026Result? yearly2026Result;
      MonthlyResult? monthlyResult;
      Yearly2025Result? yearly2025Result;
      DailyResult? dailyResult;

      // 각 Future를 독립적으로 실행 (하나 실패해도 나머지는 계속 진행)
      final yearly2026Future = _yearly2026Service
          .analyze(
            userId: userId,
            profileId: profileId,
            inputData: inputData,
          )
          .then((result) {
        yearly2026Result = result;
        print(
            '[FortuneCoordinator] ✅ 2026 신년운세 완료: ${result.success ? "성공" : "실패"}');
        return result;
      }).catchError((e, stackTrace) {
        print('[FortuneCoordinator] ❌ 2026 신년운세 에러: $e');
        ErrorLoggingService.logError(
          operation: 'fortune_analysis',
          errorMessage: e.toString(),
          sourceFile: 'fortune_coordinator.dart',
          stackTrace: stackTrace.toString(),
          extraData: {'fortuneType': 'yearly_2026', 'profileId': profileId},
        );
        return Yearly2026Result.error(e.toString());
      });

      final monthlyFuture = _monthlyService
          .analyze(
            userId: userId,
            profileId: profileId,
            inputData: inputData,
          )
          .then((result) {
        monthlyResult = result;
        print(
            '[FortuneCoordinator] ✅ 이번달 운세 완료: ${result.success ? "성공" : "실패"}');
        return result;
      }).catchError((e, stackTrace) {
        print('[FortuneCoordinator] ❌ 이번달 운세 에러: $e');
        ErrorLoggingService.logError(
          operation: 'fortune_analysis',
          errorMessage: e.toString(),
          sourceFile: 'fortune_coordinator.dart',
          stackTrace: stackTrace.toString(),
          extraData: {'fortuneType': 'monthly', 'profileId': profileId},
        );
        return MonthlyResult.error(e.toString());
      });

      final yearly2025Future = _yearly2025Service
          .analyze(
            userId: userId,
            profileId: profileId,
            inputData: inputData,
          )
          .then((result) {
        yearly2025Result = result;
        print(
            '[FortuneCoordinator] ✅ 2025 회고운세 완료: ${result.success ? "성공" : "실패"}');
        return result;
      }).catchError((e, stackTrace) {
        print('[FortuneCoordinator] ❌ 2025 회고운세 에러: $e');
        ErrorLoggingService.logError(
          operation: 'fortune_analysis',
          errorMessage: e.toString(),
          sourceFile: 'fortune_coordinator.dart',
          stackTrace: stackTrace.toString(),
          extraData: {'fortuneType': 'yearly_2025', 'profileId': profileId},
        );
        return Yearly2025Result.error(e.toString());
      });

      // v7.0: Daily Fortune 병렬 추가 (Gemini 3.0 Flash)
      // v7.4: _analyzingDaily에 등록하여 analyzeDailyOnly()와 중복 방지
      // v7.5: 먼저 체크! analyzeDailyOnly()에서 이미 분석 중이면 스킵
      final todayForDaily = KoreaDateUtils.today;
      final dailyKeyAll = '${profileId}_${todayForDaily.year}-${todayForDaily.month.toString().padLeft(2, '0')}-${todayForDaily.day.toString().padLeft(2, '0')}';

      Future<DailyResult> dailyFuture;
      if (_analyzingDaily.contains(dailyKeyAll)) {
        // v7.5: analyzeDailyOnly()에서 이미 분석 중 → 스킵
        print('[FortuneCoordinator] ⏭️ Daily 이미 분석 중 - 스킵 (analyzeAllFortunes): $dailyKeyAll');
        dailyFuture = Future.value(DailyResult.error('Daily가 이미 분석 중입니다.'));
      } else {
        _analyzingDaily.add(dailyKeyAll);
        print('[FortuneCoordinator] 🔒 Daily 분석 잠금 (analyzeAllFortunes): $dailyKeyAll');

        dailyFuture = _dailyService
            .analyze(
              userId: userId,
              profileId: profileId,
              inputData: inputData,
            )
            .then((result) {
          dailyResult = result;
          _analyzingDaily.remove(dailyKeyAll); // v7.4: 완료 시 잠금 해제
          print(
              '[FortuneCoordinator] ✅ 오늘의 일운 완료: ${result.success ? "성공" : "실패"}, 잠금 해제');
          return result;
        }).catchError((e, stackTrace) {
          print('[FortuneCoordinator] ❌ 오늘의 일운 에러: $e');
          _analyzingDaily.remove(dailyKeyAll); // v7.4: 에러 시에도 잠금 해제
          ErrorLoggingService.logError(
            operation: 'fortune_analysis',
            errorMessage: e.toString(),
            sourceFile: 'fortune_coordinator.dart',
            stackTrace: stackTrace.toString(),
            extraData: {'fortuneType': 'daily', 'profileId': profileId},
          );
          return DailyResult.error(e.toString());
        });
      }

      // v8.0: 모든 Future 완료 대기 (5분 타임아웃 - stuck task 방지)
      // 개별 서비스는 .then()에서 이미 저장 완료됨
      try {
        await Future.wait([
          yearly2026Future,
          monthlyFuture,
          yearly2025Future,
          dailyFuture,
        ]).timeout(const Duration(minutes: 5));
      } on TimeoutException {
        print('[FortuneCoordinator] ⚠️ Future.wait 타임아웃 (5분) - 일부 task가 stuck');
      }

      print('[FortuneCoordinator] 🏁 v8.0 모든 운세 분석 완료 (Daily 포함)');

      // 4. 결과 반환
      return FortuneAnalysisResults(
        success: true,
        yearly2026: yearly2026Result?.success == true
            ? yearly2026Result?.content
            : null,
        monthly:
            monthlyResult?.success == true ? monthlyResult?.content : null,
        yearly2025: yearly2025Result?.success == true
            ? yearly2025Result?.content
            : null,
        daily: dailyResult?.success == true ? dailyResult?.content : null,
      );
    } catch (e, stackTrace) {
      print('[FortuneCoordinator] ❌ 전체 에러: $e');
      ErrorLoggingService.logError(
        operation: 'fortune_analysis',
        errorMessage: e.toString(),
        sourceFile: 'fortune_coordinator.dart',
        stackTrace: stackTrace.toString(),
        extraData: {'method': 'analyzeAllFortunes', 'profileId': profileId},
      );
      return FortuneAnalysisResults.error(e.toString());
    } finally {
      // v6.1 분석 완료 시 목록에서 제거
      _analyzingProfiles.remove(profileId);
      print('[FortuneCoordinator] 🔓 분석 완료, 잠금 해제: $profileId');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 개별 분석 메서드
  // ═══════════════════════════════════════════════════════════════════════════

  /// 2026 신년운세만 분석
  Future<Yearly2026Result> analyzeYearly2026({
    required String userId,
    required String profileId,
    required FortuneInputData inputData,
    bool forceRefresh = false,
  }) {
    return _yearly2026Service.analyze(
      userId: userId,
      profileId: profileId,
      inputData: inputData,
      forceRefresh: forceRefresh,
    );
  }

  /// 이번달 운세만 분석
  Future<MonthlyResult> analyzeMonthly({
    required String userId,
    required String profileId,
    required FortuneInputData inputData,
    int? year,
    int? month,
    bool forceRefresh = false,
  }) {
    return _monthlyService.analyze(
      userId: userId,
      profileId: profileId,
      inputData: inputData,
      year: year,
      month: month,
      forceRefresh: forceRefresh,
    );
  }

  /// 2025 회고 운세만 분석
  Future<Yearly2025Result> analyzeYearly2025({
    required String userId,
    required String profileId,
    required FortuneInputData inputData,
    bool forceRefresh = false,
  }) {
    return _yearly2025Service.analyze(
      userId: userId,
      profileId: profileId,
      inputData: inputData,
      forceRefresh: forceRefresh,
    );
  }

  /// 오늘의 일운만 분석 (Gemini 3.0 Flash)
  ///
  /// ## v7.0 추가 (2026-01)
  /// - 일운은 프로필 저장 시가 아닌 온디맨드로 분석
  /// - Gemini 3.0 Flash 사용 (빠르고 저렴)
  /// - 캐시: 해당 날짜 23:59:59까지 유효
  Future<DailyResult> analyzeDaily({
    required String userId,
    required String profileId,
    required FortuneInputData inputData,
    DateTime? targetDate,
    bool forceRefresh = false,
    String locale = 'ko',
  }) {
    return _dailyService.analyze(
      userId: userId,
      profileId: profileId,
      inputData: inputData,
      targetDate: targetDate,
      forceRefresh: forceRefresh,
      locale: locale,
    );
  }

  /// 오늘의 일운 분석 (간편 버전 - Provider용)
  ///
  /// saju_analyses를 자동으로 조회하여 분석
  /// [profileId]만 있으면 분석 가능
  ///
  /// ## v7.4 개선 (2026-02)
  /// - Daily 전용 중복 분석 방지 추가 (_analyzingDaily Set)
  /// - analyzeFortuneOnly()와 동시 실행 시 중복 방지
  Future<DailyResult> analyzeDailyOnly({
    required String userId,
    required String profileId,
    DateTime? targetDate,
    bool forceRefresh = false,
    String locale = 'ko',
  }) async {
    // v7.4: Daily 전용 중복 분석 방지
    // 🔧 v7.4.1: DateTime.now() → KoreaDateUtils.today (한국 시간 기준!)
    final date = targetDate ?? KoreaDateUtils.today;
    final dailyKey = '${profileId}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    if (_analyzingDaily.contains(dailyKey)) {
      print('[FortuneCoordinator] ⏭️ Daily 이미 분석 중: $dailyKey (스킵)');
      return DailyResult.error('Daily 분석이 이미 진행 중입니다.');
    }

    // v7.4: analyzeFortuneOnly()에서 이미 daily를 분석 중이면 스킵
    if (_analyzingProfiles.contains(profileId)) {
      print('[FortuneCoordinator] ⏭️ analyzeFortuneOnly에서 이미 분석 중: $profileId (Daily 스킵)');
      return DailyResult.error('전체 운세 분석이 진행 중입니다.');
    }

    _analyzingDaily.add(dailyKey);
    print('[FortuneCoordinator] 🔒 Daily 분석 시작 잠금: $dailyKey');

    try {
      // 1. saju_analyses 조회
      final sajuAnalyses =
          await _sajuAnalysesQueries.getForFortuneInput(profileId);

      if (sajuAnalyses == null) {
        return DailyResult.error(
          'saju_analyses가 없습니다. 프로필 저장이 완료되어야 합니다.',
        );
      }

      // 2. 프로필 정보 조회
      final profileResponse = await _supabase
          .from('saju_profiles')
          .select('display_name, birth_date, birth_time_minutes, gender')
          .eq('id', profileId)
          .maybeSingle();

      if (profileResponse == null) {
        return DailyResult.error('프로필을 찾을 수 없습니다.');
      }

      final profileName = profileResponse['display_name'] as String? ?? '';
      final birthDate = profileResponse['birth_date'] as String? ?? '';
      final birthTimeMinutes = profileResponse['birth_time_minutes'] as int?;
      final gender = profileResponse['gender'] as String? ?? 'M';

      // birth_time_minutes → HH:mm 변환
      String? birthTime;
      if (birthTimeMinutes != null) {
        final hours = birthTimeMinutes ~/ 60;
        final minutes = birthTimeMinutes % 60;
        birthTime = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
      }

      // 3. FortuneInputData 구성
      final inputData = FortuneInputData.fromSajuAnalyses(
        profileName: profileName,
        birthDate: birthDate,
        birthTime: birthTime,
        gender: gender,
        sajuAnalyses: sajuAnalyses,
      );

      // 4. 일운 분석
      final result = await _dailyService.analyze(
        userId: userId,
        profileId: profileId,
        inputData: inputData,
        targetDate: targetDate,
        forceRefresh: forceRefresh,
        locale: locale,
      );
      return result;
    } catch (e) {
      return DailyResult.error(e.toString());
    } finally {
      // v7.4: Daily 분석 완료 시 잠금 해제
      _analyzingDaily.remove(dailyKey);
      print('[FortuneCoordinator] 🔓 Daily 분석 완료, 잠금 해제: $dailyKey');
    }
  }

  /// Daily 분석 중 여부 확인 (Provider에서 사용)
  static bool isDailyAnalyzing(String profileId, DateTime date) {
    final dailyKey = '${profileId}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _analyzingDaily.contains(dailyKey);
  }

  /// v7.5: 프로필 수정 시 분석 플래그 초기화 (외부 호출용)
  ///
  /// 프로필이 수정되면 기존 AI 캐시가 삭제되므로,
  /// _analyzingProfiles 및 _analyzingDaily 플래그도 초기화해야 함.
  ///
  /// [profileId] 초기화할 프로필 ID
  static void resetAnalyzingFlagForProfile(String profileId) {
    final today = KoreaDateUtils.today;
    final dailyKey = '${profileId}_${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final hadProfileFlag = _analyzingProfiles.contains(profileId);
    final hadDailyFlag = _analyzingDaily.contains(dailyKey);

    _analyzingProfiles.remove(profileId);
    _analyzingDaily.remove(dailyKey);

    if (hadProfileFlag || hadDailyFlag) {
      print('[FortuneCoordinator] 🔄 v7.5 프로필 수정 - 분석 플래그 초기화 (profile=$hadProfileFlag, daily=$hadDailyFlag)');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // v6.0 간편 분석 메서드 (Provider에서 직접 호출용)
  // - SajuAnalysisService 우회하여 Fortune만 즉시 분석!
  // - saju_base 대기 없이 바로 시작
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fortune만 분석 (saju_base 대기 없음!) - Provider용
  ///
  /// ## v6.0 추가 (2026-01-20) ⭐
  /// - SajuAnalysisService.analyzeOnProfileSave() 대신 이 메서드 사용!
  /// - saju_base(140초) 대기 없이 Fortune만 즉시 분석
  /// - Provider에서 직접 호출 가능
  ///
  /// ## 사용 예시
  /// ```dart
  /// // Fortune Provider에서:
  /// final coordinator = FortuneCoordinator(supabase: ..., aiApiService: ...);
  /// await coordinator.analyzeFortuneOnly(
  ///   userId: user.id,
  ///   profileId: profileId,
  /// );
  /// ```
  Future<FortuneAnalysisResults> analyzeFortuneOnly({
    required String userId,
    required String profileId,
    String locale = 'ko',
  }) async {
    // v6.1 중복 분석 방지
    if (_analyzingProfiles.contains(profileId)) {
      print('[FortuneCoordinator] ⏭️ 이미 분석 중: $profileId (스킵)');
      return FortuneAnalysisResults.error('이미 분석 중입니다.');
    }
    _analyzingProfiles.add(profileId);

    try {
      print('[FortuneCoordinator] 🚀 v6.0 Fortune만 분석 시작 (saju_base 대기 없음!)');

      // 1. saju_analyses 조회
      final sajuAnalyses =
          await _sajuAnalysesQueries.getForFortuneInput(profileId);

      if (sajuAnalyses == null) {
        print('[FortuneCoordinator] ❌ saju_analyses 없음');
        return FortuneAnalysisResults.error(
          'saju_analyses가 없습니다. 프로필 저장이 완료되어야 합니다.',
        );
      }

      // 2. 프로필 정보 조회
      final profileResponse = await _supabase
          .from('saju_profiles')
          .select('display_name, birth_date, birth_time_minutes, gender')
          .eq('id', profileId)
          .maybeSingle();

      if (profileResponse == null) {
        print('[FortuneCoordinator] ❌ 프로필 없음');
        return FortuneAnalysisResults.error('프로필을 찾을 수 없습니다.');
      }

      final profileName = profileResponse['display_name'] as String? ?? '';
      final birthDate = profileResponse['birth_date'] as String? ?? '';
      final birthTimeMinutes = profileResponse['birth_time_minutes'] as int?;
      final gender = profileResponse['gender'] as String? ?? 'M';

      // birth_time_minutes → HH:mm 변환
      String? birthTime;
      if (birthTimeMinutes != null) {
        final hours = birthTimeMinutes ~/ 60;
        final minutes = birthTimeMinutes % 60;
        birthTime = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
      }

      print('[FortuneCoordinator] 프로필 정보: $profileName, $birthDate, $gender');

      // 3. FortuneInputData 구성
      final inputData = FortuneInputData.fromSajuAnalyses(
        profileName: profileName,
        birthDate: birthDate,
        birthTime: birthTime,
        gender: gender,
        sajuAnalyses: sajuAnalyses,
      );

      // 4. 병렬 분석 실행 (v7.0: Daily 추가!)
      print('[FortuneCoordinator] 🎯 Fortune 병렬 분석 시작 (Daily 포함)...');

      Yearly2026Result? yearly2026Result;
      MonthlyResult? monthlyResult;
      Yearly2025Result? yearly2025Result;
      DailyResult? dailyResult;

      final yearly2026Future = _yearly2026Service
          .analyze(userId: userId, profileId: profileId, inputData: inputData, locale: locale)
          .then((result) {
        yearly2026Result = result;
        print('[FortuneCoordinator] ✅ 2026 신년운세 완료');
        return result;
      }).catchError((e, stackTrace) {
        print('[FortuneCoordinator] ❌ 2026 에러: $e');
        ErrorLoggingService.logError(
          operation: 'fortune_analysis',
          errorMessage: e.toString(),
          sourceFile: 'fortune_coordinator.dart',
          stackTrace: stackTrace.toString(),
          extraData: {'fortuneType': 'yearly_2026', 'method': 'analyzeFortuneOnly', 'profileId': profileId},
        );
        return Yearly2026Result.error(e.toString());
      });

      final monthlyFuture = _monthlyService
          .analyze(userId: userId, profileId: profileId, inputData: inputData, locale: locale)
          .then((result) {
        monthlyResult = result;
        print('[FortuneCoordinator] ✅ 이번달 운세 완료');
        return result;
      }).catchError((e, stackTrace) {
        print('[FortuneCoordinator] ❌ 월운 에러: $e');
        ErrorLoggingService.logError(
          operation: 'fortune_analysis',
          errorMessage: e.toString(),
          sourceFile: 'fortune_coordinator.dart',
          stackTrace: stackTrace.toString(),
          extraData: {'fortuneType': 'monthly', 'method': 'analyzeFortuneOnly', 'profileId': profileId},
        );
        return MonthlyResult.error(e.toString());
      });

      final yearly2025Future = _yearly2025Service
          .analyze(userId: userId, profileId: profileId, inputData: inputData, locale: locale)
          .then((result) {
        yearly2025Result = result;
        print('[FortuneCoordinator] ✅ 2025 회고운세 완료');
        return result;
      }).catchError((e, stackTrace) {
        print('[FortuneCoordinator] ❌ 2025 에러: $e');
        ErrorLoggingService.logError(
          operation: 'fortune_analysis',
          errorMessage: e.toString(),
          sourceFile: 'fortune_coordinator.dart',
          stackTrace: stackTrace.toString(),
          extraData: {'fortuneType': 'yearly_2025', 'method': 'analyzeFortuneOnly', 'profileId': profileId},
        );
        return Yearly2025Result.error(e.toString());
      });

      // v7.0: Daily Fortune 병렬 추가 (Gemini 3.0 Flash)
      // v7.4: _analyzingDaily에 등록하여 analyzeDailyOnly()와 중복 방지
      // v7.5: 먼저 체크! analyzeDailyOnly()에서 이미 분석 중이면 스킵
      final todayForDaily = KoreaDateUtils.today;
      final dailyKey = '${profileId}_${todayForDaily.year}-${todayForDaily.month.toString().padLeft(2, '0')}-${todayForDaily.day.toString().padLeft(2, '0')}';

      Future<DailyResult> dailyFuture;
      if (_analyzingDaily.contains(dailyKey)) {
        // v7.5: analyzeDailyOnly()에서 이미 분석 중 → 스킵
        print('[FortuneCoordinator] ⏭️ Daily 이미 분석 중 - 스킵 (analyzeFortuneOnly): $dailyKey');
        dailyFuture = Future.value(DailyResult.error('Daily가 이미 분석 중입니다.'));
      } else {
        _analyzingDaily.add(dailyKey);
        print('[FortuneCoordinator] 🔒 Daily 분석 잠금 (analyzeFortuneOnly): $dailyKey');

        dailyFuture = _dailyService
            .analyze(userId: userId, profileId: profileId, inputData: inputData, locale: locale)
            .then((result) {
          dailyResult = result;
          _analyzingDaily.remove(dailyKey); // v7.4: 완료 시 잠금 해제
          print('[FortuneCoordinator] ✅ 오늘의 일운 완료, 잠금 해제: $dailyKey');
          return result;
        }).catchError((e, stackTrace) {
          print('[FortuneCoordinator] ❌ 일운 에러: $e');
          _analyzingDaily.remove(dailyKey); // v7.4: 에러 시에도 잠금 해제
          ErrorLoggingService.logError(
            operation: 'fortune_analysis',
            errorMessage: e.toString(),
            sourceFile: 'fortune_coordinator.dart',
            stackTrace: stackTrace.toString(),
            extraData: {'fortuneType': 'daily', 'method': 'analyzeFortuneOnly', 'profileId': profileId},
          );
          return DailyResult.error(e.toString());
        });
      }

      // v8.0: 5분 타임아웃 - stuck task로 인한 무한 대기 방지
      try {
        await Future.wait([yearly2026Future, monthlyFuture, yearly2025Future, dailyFuture])
            .timeout(const Duration(minutes: 5));
      } on TimeoutException {
        print('[FortuneCoordinator] ⚠️ Future.wait 타임아웃 (5분) - 일부 task가 stuck');
      }

      print('[FortuneCoordinator] 🏁 v8.0 Fortune 분석 완료! (Daily 포함)');

      return FortuneAnalysisResults(
        success: true,
        yearly2026: yearly2026Result?.success == true ? yearly2026Result?.content : null,
        monthly: monthlyResult?.success == true ? monthlyResult?.content : null,
        yearly2025: yearly2025Result?.success == true ? yearly2025Result?.content : null,
        daily: dailyResult?.success == true ? dailyResult?.content : null,
      );
    } catch (e, stackTrace) {
      print('[FortuneCoordinator] ❌ 에러: $e');
      ErrorLoggingService.logError(
        operation: 'fortune_analysis',
        errorMessage: e.toString(),
        sourceFile: 'fortune_coordinator.dart',
        stackTrace: stackTrace.toString(),
        extraData: {'method': 'analyzeFortuneOnly', 'profileId': profileId},
      );
      return FortuneAnalysisResults.error(e.toString());
    } finally {
      // v6.1 분석 완료 시 목록에서 제거
      _analyzingProfiles.remove(profileId);
      print('[FortuneCoordinator] 🔓 분석 완료, 잠금 해제: $profileId');
    }
  }

  /// 분석 중 여부 확인 (Provider에서 사용)
  static bool isAnalyzing(String profileId) {
    return _analyzingProfiles.contains(profileId) ||
        _analyzingDaily.any((key) => key.startsWith('${profileId}_'));
  }

  /// v8.0: stuck 분석 플래그 강제 리셋 (Provider safety timeout용)
  ///
  /// Provider에서 _isAnalyzing 타임아웃 후 FortuneCoordinator의
  /// stuck 플래그도 함께 정리할 때 사용
  static void resetAnalyzingFlag(String profileId) {
    _analyzingProfiles.remove(profileId);
    _analyzingDaily.removeWhere((key) => key.startsWith('${profileId}_'));
    print('[FortuneCoordinator] 🔄 v8.0 stuck 플래그 강제 리셋: $profileId');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 캐시 확인 메서드
  // ═══════════════════════════════════════════════════════════════════════════

  /// 모든 운세 캐시 상태 확인
  Future<Map<String, bool>> checkAllCaches(String profileId) async {
    final results = await Future.wait([
      _yearly2026Service.hasCached(profileId),
      _monthlyService.hasCached(profileId),
      _yearly2025Service.hasCached(profileId),
      _dailyService.hasTodayCached(profileId),
    ]);

    return {
      'yearly_2026': results[0],
      'monthly': results[1],
      'yearly_2025': results[2],
      'daily': results[3],
    };
  }

  /// 모든 캐시된 운세 조회
  Future<Map<String, Map<String, dynamic>?>> getAllCached(
    String profileId,
  ) async {
    final results = await Future.wait([
      _yearly2026Service.getCached(profileId),
      _monthlyService.getCached(profileId),
      _yearly2025Service.getCached(profileId),
      _dailyService.getTodayCached(profileId),
    ]);

    return {
      'yearly_2026': results[0],
      'monthly': results[1],
      'yearly_2025': results[2],
      'daily': results[3],
    };
  }

  /// 오늘 일운 캐시 확인
  Future<bool> hasDailyCached(String profileId) {
    return _dailyService.hasTodayCached(profileId);
  }

  /// 오늘 일운 캐시 조회
  Future<Map<String, dynamic>?> getDailyCached(String profileId) {
    return _dailyService.getTodayCached(profileId);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 전역 인스턴스 (v6.0)
// ═══════════════════════════════════════════════════════════════════════════

/// 전역 FortuneCoordinator 인스턴스
///
/// ## v6.0 추가 (2026-01-20)
/// Provider에서 Fortune만 즉시 분석할 때 사용
///
/// ## 사용 예시
/// ```dart
/// import 'package:your_app/AI/fortune/fortune_coordinator.dart';
///
/// // Fortune만 분석 (saju_base 대기 없음!)
/// await fortuneCoordinator.analyzeFortuneOnly(
///   userId: user.id,
///   profileId: profileId,
/// );
/// ```
FortuneCoordinator? _fortuneCoordinatorInstance;

FortuneCoordinator get fortuneCoordinator {
  _fortuneCoordinatorInstance ??= FortuneCoordinator(
    supabase: Supabase.instance.client,
    aiApiService: AiApiService(),
  );
  return _fortuneCoordinatorInstance!;
}
