/// # Fortune Coordinator (운세 통합 조율 서비스)
///
/// ## 개요
/// saju_base(평생운세)를 기반으로 하는 모든 파생 운세 분석을 조율
/// - saju_base 존재 확인
/// - saju_base 완료 대기
/// - 전체 운세 일괄 분석
///
/// ## 핵심 원칙
/// ```
/// saju_base 없음 → 로딩/대기 상태 → saju_base 완료 대기
/// saju_base 있음 → 운세 분석 실행
/// ```
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/fortune_coordinator.dart`

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/ai_constants.dart';
import '../services/ai_api_service.dart';
import 'common/fortune_input_data.dart';
import 'common/fortune_state.dart';
import 'monthly/monthly_service.dart';
import 'yearly_2025/yearly_2025_service.dart';
import 'yearly_2026/yearly_2026_service.dart';

/// 전체 운세 분석 결과
class FortuneAnalysisResults {
  final bool success;
  final Map<String, dynamic>? yearly2026;
  final Map<String, dynamic>? monthly;
  final Map<String, dynamic>? yearly2025;
  final String? errorMessage;

  const FortuneAnalysisResults({
    required this.success,
    this.yearly2026,
    this.monthly,
    this.yearly2025,
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
      yearly2026 != null && monthly != null && yearly2025 != null;

  /// 완료된 분석 개수
  int get completedCount {
    int count = 0;
    if (yearly2026 != null) count++;
    if (monthly != null) count++;
    if (yearly2025 != null) count++;
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
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // saju_base 관련 메서드
  // ═══════════════════════════════════════════════════════════════════════════

  /// saju_base 준비 상태 확인
  ///
  /// [profileId] 프로필 UUID
  /// 반환: FortuneState (waitingForSajuBase 또는 ready)
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
  ///
  /// [profileId] 프로필 UUID
  /// [maxWaitSeconds] 최대 대기 시간 (초), 기본 300초 (5분)
  /// [pollIntervalSeconds] 폴링 간격 (초), 기본 5초
  ///
  /// 반환: saju_base content 또는 null (타임아웃)
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

  /// 전체 운세 일괄 분석
  ///
  /// ## 플로우
  /// 1. saju_base 확인 (없으면 에러)
  /// 2. FortuneInputData 구성
  /// 3. 각 운세 독립적 병렬 분석 (하나 완료되면 바로 저장)
  /// 4. 결과 반환
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
    try {
      // 1. saju_base 확인
      final sajuBaseContent = await _getSajuBase(profileId);
      if (sajuBaseContent == null) {
        return FortuneAnalysisResults.error(
          'saju_base가 없습니다. 평생 운세 분석이 먼저 필요합니다.',
        );
      }

      // 2. FortuneInputData 구성
      final inputData = FortuneInputData.fromSajuBase(
        profileName: profileName,
        birthDate: birthDate,
        birthTime: birthTime,
        gender: gender,
        sajuBaseContent: sajuBaseContent,
      );

      // 3. 독립적 병렬 분석 - 각각 완료되면 바로 저장됨 (실패해도 다른 것에 영향 없음)
      print('[FortuneCoordinator] 🚀 운세 분석 시작 (3개 독립 실행)');

      Yearly2026Result? yearly2026Result;
      MonthlyResult? monthlyResult;
      Yearly2025Result? yearly2025Result;

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
      }).catchError((e) {
        print('[FortuneCoordinator] ❌ 2026 신년운세 에러: $e');
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
      }).catchError((e) {
        print('[FortuneCoordinator] ❌ 이번달 운세 에러: $e');
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
      }).catchError((e) {
        print('[FortuneCoordinator] ❌ 2025 회고운세 에러: $e');
        return Yearly2025Result.error(e.toString());
      });

      // 모든 Future 완료 대기 (개별 저장은 이미 완료됨)
      await Future.wait([
        yearly2026Future,
        monthlyFuture,
        yearly2025Future,
      ]);

      print('[FortuneCoordinator] 🏁 모든 운세 분석 완료');

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
      );
    } catch (e) {
      print('[FortuneCoordinator] ❌ 전체 에러: $e');
      return FortuneAnalysisResults.error(e.toString());
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 캐시 확인 메서드
  // ═══════════════════════════════════════════════════════════════════════════

  /// 모든 운세 캐시 상태 확인
  Future<Map<String, bool>> checkAllCaches(String profileId) async {
    final results = await Future.wait([
      _yearly2026Service.hasCached(profileId),
      _monthlyService.hasCached(profileId),
      _yearly2025Service.hasCached(profileId),
    ]);

    return {
      'yearly_2026': results[0],
      'monthly': results[1],
      'yearly_2025': results[2],
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
    ]);

    return {
      'yearly_2026': results[0],
      'monthly': results[1],
      'yearly_2025': results[2],
    };
  }
}
