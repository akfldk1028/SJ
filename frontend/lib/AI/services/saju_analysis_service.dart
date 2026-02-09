/// # 사주 분석 서비스
///
/// ## 개요
/// 프로필 저장 시 AI 분석을 오케스트레이션합니다.
/// 두 가지 분석을 **병렬로** 실행하여 사용자 대기 시간을 최소화합니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/services/saju_analysis_service.dart`
///
/// ## 실행되는 분석
/// | 분석 유형 | 모델 | 캐시 | 설명 |
/// |----------|------|------|------|
/// | saju_base | GPT-5.2 | 무기한 | 평생 사주운세 (성격, 적성, 재물 등) |
/// | daily_fortune | Gemini 2.0 Flash | 24시간 | 오늘의 운세 |
///
/// ## 실행 패턴
///
/// ### Fire-and-forget (기본)
/// ```dart
/// // 프로필 저장 후 즉시 반환, 분석은 백그라운드
/// sajuAnalysisService.analyzeOnProfileSave(
///   userId: user.id,
///   profileId: profileId,
///   runInBackground: true,  // 기본값
/// );
/// // 사용자는 즉시 다음 화면으로
/// ```
///
/// ### 완료 대기
/// ```dart
/// // 분석 완료까지 대기
/// final result = await sajuAnalysisService.analyzeOnProfileSave(
///   userId: user.id,
///   profileId: profileId,
///   runInBackground: false,
/// );
/// if (result.allSuccess) {
///   print('두 분석 모두 성공!');
/// }
/// ```
///
/// ## 데이터 흐름
/// ```
/// profile_provider.dart
///   → _triggerAiAnalysis()
///     → SajuAnalysisService.analyzeOnProfileSave()
///       → _prepareInputData()
///         → AiQueries.getProfileWithAnalysis()
///         → AiQueries.convertToInputData()
///       → Future.wait([
///           _runSajuBaseAnalysis(),      // GPT-5.2
///           _runDailyFortuneAnalysis(),  // Gemini
///         ])
///       → AiMutations.saveSajuBaseSummary()
///       → AiMutations.saveDailyFortune()
/// ```
///
/// ## 캐시 처리
/// - 이미 분석된 결과가 있으면 API 호출 스킵
/// - saju_base: profile_id 기준 (변경 없으면 재사용)
/// - daily_fortune: profile_id + target_date 기준 (오늘 날짜)
///
/// ## 에러 처리
/// - 개별 분석 실패는 다른 분석에 영향 없음
/// - 실패한 분석만 AnalysisResult.failure() 반환
/// - 에러 로그 출력 (print)
///
/// ## 관련 파일
/// - `ai_api_service.dart`: API 호출
/// - `queries.dart`: 데이터 조회 및 변환
/// - `mutations.dart`: 결과 저장
/// - `saju_base_prompt.dart`: GPT 프롬프트
/// - `fortune/daily/daily_service.dart`: 일운 서비스 (v7.0)
/// - `fortune/daily/daily_prompt.dart`: 일운 프롬프트 (v7.0)

import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/error_logging_service.dart';
import '../../core/supabase/generated/saju_analyses.dart';
import '../../core/supabase/generated/saju_profiles.dart';
import '../core/ai_constants.dart';
import '../core/ai_logger.dart';
import '../data/mutations.dart';
import '../data/queries.dart';
import '../fortune/common/fortune_input_data.dart';
import '../fortune/daily/daily_service.dart';
import '../fortune/fortune_coordinator.dart';
import '../fortune/common/prompt_template.dart';
import '../fortune/lifetime/lifetime_prompt.dart';
import '../fortune/lifetime/lifetime_phase1_prompt.dart';
import '../fortune/lifetime/lifetime_phase2_prompt.dart';
import '../fortune/lifetime/lifetime_phase3_prompt.dart';
import '../fortune/lifetime/lifetime_phase4_prompt.dart';
import 'ai_api_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 결과 클래스
// ═══════════════════════════════════════════════════════════════════════════

/// 개별 분석 결과
///
/// ## 필드
/// - `success`: 분석 성공 여부
/// - `summaryId`: 저장된 ai_summaries.id (성공 시)
/// - `error`: 오류 메시지 (실패 시)
/// - `processingTimeMs`: 처리 시간 (밀리초)
class AnalysisResult {
  final bool success;
  final String? summaryId;
  final String? error;
  final int? processingTimeMs;

  const AnalysisResult({
    required this.success,
    this.summaryId,
    this.error,
    this.processingTimeMs,
  });

  factory AnalysisResult.success({
    required String summaryId,
    int? processingTimeMs,
  }) =>
      AnalysisResult(
        success: true,
        summaryId: summaryId,
        processingTimeMs: processingTimeMs,
      );

  factory AnalysisResult.failure(String error) => AnalysisResult(
        success: false,
        error: error,
      );
}

/// 전체 분석 결과 (평생 + 일운)
///
/// ## 편의 메서드
/// - `allSuccess`: 두 분석 모두 성공
/// - `anySuccess`: 하나 이상 성공
class ProfileAnalysisResult {
  final AnalysisResult? sajuBase;
  final AnalysisResult? dailyFortune;

  const ProfileAnalysisResult({
    this.sajuBase,
    this.dailyFortune,
  });

  bool get allSuccess =>
      (sajuBase?.success ?? false) && (dailyFortune?.success ?? false);

  bool get anySuccess =>
      (sajuBase?.success ?? false) || (dailyFortune?.success ?? false);
}

// ═══════════════════════════════════════════════════════════════════════════
// 메인 서비스
// ═══════════════════════════════════════════════════════════════════════════

/// 사주 분석 서비스
///
/// ## 의존성 주입
/// ```dart
/// // 기본 사용 (전역 인스턴스)
/// final result = await sajuAnalysisService.analyzeOnProfileSave(...);
///
/// // 테스트용 (Mock 주입)
/// final service = SajuAnalysisService(apiService: mockApiService);
/// ```
class SajuAnalysisService {
  /// AI API 서비스 (Edge Function 호출)
  final AiApiService _apiService;

  /// Fortune 분석 코디네이터 (연간/월간 운세)
  late final FortuneCoordinator _fortuneCoordinator;

  /// 현재 분석 중인 프로필 ID 추적 (중복 분석 방지)
  static final Set<String> _analyzingProfiles = {};

  /// 생성자
  ///
  /// [apiService] 테스트 시 Mock 주입 가능
  SajuAnalysisService({AiApiService? apiService})
      : _apiService = apiService ?? AiApiService() {
    _fortuneCoordinator = FortuneCoordinator(
      supabase: Supabase.instance.client,
      aiApiService: _apiService,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 메인 진입점
  // ─────────────────────────────────────────────────────────────────────────

  /// 프로필 저장 시 호출 - 두 분석 병렬 실행
  ///
  /// ## 파라미터
  /// - `userId`: 사용자 UUID (RLS 필수)
  /// - `profileId`: 프로필 UUID
  /// - `runInBackground`: Fire-and-forget 모드 (기본 true)
  /// - `onComplete`: 백그라운드 분석 완료 시 콜백 (UI 갱신용)
  ///
  /// ## 반환값
  /// - `runInBackground=true`: 빈 ProfileAnalysisResult 즉시 반환
  /// - `runInBackground=false`: 완료된 결과 반환
  Future<ProfileAnalysisResult> analyzeOnProfileSave({
    required String userId,
    required String profileId,
    bool runInBackground = true,
    void Function(ProfileAnalysisResult)? onComplete,
    String locale = 'ko',
  }) async {
    // 중복 분석 방지: 이미 분석 중인 프로필이면 스킵
    if (_analyzingProfiles.contains(profileId)) {
      print('[SajuAnalysisService] 이미 분석 중: $profileId (스킵)');
      return const ProfileAnalysisResult(); // 빈 결과 반환
    }

    // 분석 시작 등록
    _analyzingProfiles.add(profileId);
    print('[SajuAnalysisService] 프로필 분석 시작: $profileId (현재 분석 중: ${_analyzingProfiles.length}개)');

    // 1. 사주 데이터 조회
    final inputData = await _prepareInputData(profileId);
    if (inputData == null) {
      // 실패 시에도 Set에서 제거
      _analyzingProfiles.remove(profileId);
      print('[SajuAnalysisService] 사주 데이터 조회 실패');
      return ProfileAnalysisResult(
        sajuBase: AnalysisResult.failure('사주 데이터 조회 실패'),
        dailyFortune: AnalysisResult.failure('사주 데이터 조회 실패'),
      );
    }

    // 2. 두 분석 병렬 실행
    if (runInBackground) {
      // Fire-and-forget: 백그라운드에서 실행
      _runBothAnalysesInBackground(userId, profileId, inputData, onComplete, locale: locale);
      return const ProfileAnalysisResult(); // 즉시 반환
    } else {
      // 완료 대기
      try {
        return await _runBothAnalyses(userId, profileId, inputData, locale: locale);
      } finally {
        // 분석 완료 → Set에서 제거
        _analyzingProfiles.remove(profileId);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 데이터 준비
  // ─────────────────────────────────────────────────────────────────────────

  /// 사주 데이터 준비 (조회 + 변환)
  ///
  /// ## 처리 과정
  /// 1. saju_profiles + saju_analyses 조인 조회
  /// 2. JSON → 객체 변환
  /// 3. SajuInputData로 변환 (GPT 입력 형식)
  Future<SajuInputData?> _prepareInputData(String profileId) async {
    // 프로필 + 분석 데이터 조회
    final result = await aiQueries.getProfileWithAnalysis(profileId);

    if (!result.isSuccess || result.data == null) {
      print('[SajuAnalysisService] 프로필 조회 실패: ${result.errorMessage}');
      return null;
    }

    final data = result.data!;
    final profileJson = Map<String, dynamic>.from(data);
    final analysisJson = data['saju_analyses'] as Map<String, dynamic>?;

    if (analysisJson == null) {
      print('[SajuAnalysisService] 사주 분석 데이터 없음');
      return null;
    }

    // JSON → 객체 변환
    final profile = SajuProfiles.fromJson(profileJson);
    final analysis = SajuAnalyses.fromJson(analysisJson);

    // SajuInputData로 변환
    return aiQueries.convertToInputData(
      profile: profile,
      analysis: analysis,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 병렬 실행
  // ─────────────────────────────────────────────────────────────────────────

  /// 두 분석 백그라운드 실행 (Fire-and-forget)
  ///
  /// ## 특징
  /// - 즉시 반환 (사용자 대기 없음)
  /// - 결과는 DB에 저장됨
  /// - 에러 발생 시 로그만 출력
  /// - 완료 시 onComplete 콜백 호출 (UI 갱신용)
  void _runBothAnalysesInBackground(
    String userId,
    String profileId,
    SajuInputData inputData,
    void Function(ProfileAnalysisResult)? onComplete, {
    String locale = 'ko',
  }) {
    // 비동기로 실행, 결과는 DB에 저장됨
    _runBothAnalyses(userId, profileId, inputData, locale: locale).then((result) {
      // 분석 완료 → Set에서 제거
      _analyzingProfiles.remove(profileId);
      print('[SajuAnalysisService] 백그라운드 분석 완료');
      print('  - 평생운세: ${result.sajuBase?.success ?? false}');
      print('  - 오늘운세: ${result.dailyFortune?.success ?? false}');

      // UI 갱신 콜백 호출
      if (onComplete != null) {
        onComplete(result);
      }
    }).catchError((e, stackTrace) {
      // 에러 시에도 Set에서 제거
      _analyzingProfiles.remove(profileId);
      print('[SajuAnalysisService] 백그라운드 분석 오류: $e');
      ErrorLoggingService.logError(
        operation: 'saju_analysis',
        errorMessage: e.toString(),
        sourceFile: 'saju_analysis_service.dart',
        stackTrace: stackTrace.toString(),
        extraData: {'method': '_runBothAnalysesInBackground', 'profileId': profileId},
      );

      // v7.3: 에러 시에도 onComplete 콜백 호출 (_isAnalyzing 플래그 해제용)
      if (onComplete != null) {
        onComplete(ProfileAnalysisResult(
          sajuBase: AnalysisResult.failure(e.toString()),
        ));
      }
    });
  }

  /// 분석 실행 (v6.0 병렬 처리)
  ///
  /// ## v6.0 변경 (2026-01-20) ⭐
  /// - Fortune 분석이 **saju_base와 독립적으로** 실행됨
  /// - Fortune은 saju_analyses(즉시 사용 가능)만 사용
  /// - saju_base는 백그라운드에서 별도 실행
  ///
  /// ## 실행 순서 (병렬)
  /// 1. Fortune 분석 (saju_analyses 사용) - 즉시 시작! ⚡
  /// 2. GPT-5.2 평생사주 분석 (saju_base) - 백그라운드
  /// 3. Gemini 일운 분석 (daily_fortune)
  Future<ProfileAnalysisResult> _runBothAnalyses(
    String userId,
    String profileId,
    SajuInputData inputData, {
    String locale = 'ko',
  }) async {
    final inputJson = inputData.toJson();

    // ═══════════════════════════════════════════════════════════════════════
    // v6.0: Fortune 분석 먼저! (saju_base 대기 없이 즉시 시작)
    // ═══════════════════════════════════════════════════════════════════════
    print('[SajuAnalysisService] 🚀 v6.0 Fortune 분석 즉시 시작! (saju_base 대기 없음)');
    print('  - userId: $userId');
    print('  - profileId: $profileId');
    print('  - name: ${inputJson['name']}');
    print('  - birth_date: ${inputJson['birth_date']}');
    print('  - gender: ${inputJson['gender']}');

    // ═══════════════════════════════════════════════════════════════════════
    // v6.1: Fortune과 saju_base 진정한 병렬 실행! ⭐
    // ═══════════════════════════════════════════════════════════════════════

    // Fortune 분석 (yearly_2025, yearly_2026, monthly, daily) - Fire-and-forget!
    // await 없이 시작 → saju_base 블로킹 방지
    print('[SajuAnalysisService] 🔥 Fortune 분석 시작 (fire-and-forget)...');
    _fortuneCoordinator.analyzeAllFortunes(
      userId: userId,
      profileId: profileId,
      profileName: inputJson['name'] as String? ?? '',
      birthDate: inputJson['birth_date'] as String? ?? '',
      birthTime: inputJson['birth_time'] as String?,
      gender: inputJson['gender'] as String? ?? 'M',
    ).then((fortuneResults) {
      print('[SajuAnalysisService] ✅ Fortune 분석 완료:');
      print('  - completedCount: ${fortuneResults.completedCount}');
      print('  - yearly2026: ${fortuneResults.yearly2026 != null ? "성공" : "실패"}');
      print('  - monthly: ${fortuneResults.monthly != null ? "성공" : "실패"}');
      print('  - yearly2025: ${fortuneResults.yearly2025 != null ? "성공" : "실패"}');
    }).catchError((e, stackTrace) {
      print('[SajuAnalysisService] ❌ Fortune 분석 오류: $e');
      print('[SajuAnalysisService] StackTrace: $stackTrace');
      ErrorLoggingService.logError(
        operation: 'saju_analysis',
        errorMessage: e.toString(),
        sourceFile: 'saju_analysis_service.dart',
        stackTrace: stackTrace.toString(),
        extraData: {'method': 'analyzeAllFortunes', 'profileId': profileId},
      );
    });

    // ═══════════════════════════════════════════════════════════════════════
    // GPT-5.2 평생사주 분석 (Phase 분할 + Progressive Disclosure) ⭐
    // v8.2: 각 Phase 완료 시 ai_tasks.partial_result 업데이트 → UI 즉시 표시
    // ═══════════════════════════════════════════════════════════════════════

    // 캐시 확인 (이미 분석된 경우 스킵)
    // v50: Gemini/fallback 결과는 캐시 히트로 안 침 (GPT-5.2 결과만 유효)
    print('[SajuAnalysisService] 🔍 saju_base 캐시 확인 중...');
    final cached = await aiQueries.getSajuBaseSummary(profileId, locale: locale);
    AnalysisResult sajuBaseResult;

    // v50: model_provider='openai' 인 GPT 결과만 캐시 히트로 인정
    // Gemini/fallback(model_provider='google', model_name='fallback')은 무시
    final isGptCacheHit = cached.isSuccess &&
        cached.data != null &&
        cached.data!.modelProvider == 'openai';

    if (isGptCacheHit) {
      print('[SajuAnalysisService] ✅ saju_base 캐시 히트 (GPT) - 즉시 반환');
      sajuBaseResult = AnalysisResult.success(
        summaryId: cached.data!.id,
        processingTimeMs: 0,
      );
    } else {
      if (cached.isSuccess && cached.data != null) {
        print('[SajuAnalysisService] ⚠️ saju_base 존재하지만 Gemini/fallback (model=${cached.data!.modelName}) - GPT 분석 강행');
      }
      // v43: Phase 분할 분석 실행 (reasoning_effort: low → medium 폴백)
      print('[SajuAnalysisService] 📊 saju_base Phase 분할 분석 시작 (reasoning_effort: low)...');
      var phasedResult = await runSajuBaseAnalysisWithPhases(
        userId: userId,
        profileId: profileId,
        inputJson: inputJson,
        reasoningEffort: 'low',  // v43: 속도 우선
        locale: locale,
        onPhaseComplete: (phaseResult) {
          print('[SajuAnalysisService] 🎯 Phase ${phaseResult.phase} 완료 (${phaseResult.processingTimeMs}ms)');
        },
      );

      // v43: low 실패 시 medium으로 폴백
      if (!phasedResult.overall.success) {
        print('[SajuAnalysisService] ⚠️ reasoning_effort: low 실패 → medium으로 재시도');
        phasedResult = await runSajuBaseAnalysisWithPhases(
          userId: userId,
          profileId: profileId,
          inputJson: inputJson,
          reasoningEffort: 'medium',  // v43: 폴백
          locale: locale,
          onPhaseComplete: (phaseResult) {
            print('[SajuAnalysisService] 🎯 [medium 재시도] Phase ${phaseResult.phase} 완료 (${phaseResult.processingTimeMs}ms)');
          },
        );
      }
      sajuBaseResult = phasedResult.overall;
    }

    print('[SajuAnalysisService] 📊 saju_base 결과: success=${sajuBaseResult.success}');

    // GPT 결과를 Gemini 프롬프트에 포함
    Map<String, dynamic> enrichedInputJson = Map.from(inputJson);

    if (sajuBaseResult.success) {
      // GPT 분석 결과 조회하여 Gemini 입력에 추가
      print('[SajuAnalysisService] 🔍 saju_base 결과 조회 중...');
      final sajuBaseData = await aiQueries.getSajuBaseSummary(profileId, locale: locale);
      if (sajuBaseData.isSuccess && sajuBaseData.data != null) {
        enrichedInputJson['saju_base_analysis'] = sajuBaseData.data!.content;
        print('[SajuAnalysisService] ✅ GPT 분석 결과를 Gemini 입력에 추가');
      } else {
        print('[SajuAnalysisService] ⚠️ saju_base 조회 실패: ${sajuBaseData.errorMessage}');
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // NOTE: Gemini 일운 분석은 analyzeAllFortunes에서 이미 처리됨! (중복 제거)
    // _fortuneCoordinator.analyzeAllFortunes() 가 daily도 포함하고 있음
    // ═══════════════════════════════════════════════════════════════════════

    return ProfileAnalysisResult(
      sajuBase: sajuBaseResult,
      // dailyFortune은 analyzeAllFortunes에서 fire-and-forget으로 처리됨
      dailyFortune: null,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 개별 분석 메서드
  // ─────────────────────────────────────────────────────────────────────────

  /// 평생 사주 분석 (GPT-5.2)
  ///
  /// ## 처리 과정
  /// 1. 캐시 확인 (이미 분석됨?)
  /// 2. SajuBasePrompt로 메시지 생성
  /// 3. AiApiService.callOpenAI() 호출
  /// 4. AiMutations.saveSajuBaseSummary() 저장
  ///
  /// ## 예상 소요 시간
  /// - GPT-5.2: 5-20초 (추론 시간 포함)
  Future<AnalysisResult> _runSajuBaseAnalysis(
    String userId,
    String profileId,
    Map<String, dynamic> inputJson, {
    String locale = 'ko',
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      print('[SajuAnalysisService] 평생 사주 분석 시작...');

      // 1. L1 캐시 확인 (동일 프로필 - 이미 분석된 경우 스킵)
      final cached = await aiQueries.getSajuBaseSummary(profileId, locale: locale);
      if (cached.isSuccess && cached.data != null) {
        print('[SajuAnalysisService] ✅ L1 캐시 히트 - 즉시 반환');
        return AnalysisResult.success(
          summaryId: cached.data!.id,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      }

      // 2. L2 캐시 확인 (동일 사주팔자 - 다른 프로필에서 재사용)
      final saju = inputJson['saju'] as Map<String, dynamic>?;
      final gender = inputJson['gender'] as String?;
      if (saju != null && gender != null) {
        final l2Cached = await aiQueries.getSajuBaseBySajuKey(
          saju: saju,
          gender: gender,
          excludeProfileId: profileId,
        );
        if (l2Cached.isSuccess && l2Cached.data != null) {
          print('[SajuAnalysisService] ✅ L2 캐시 히트 - 동일 사주 결과 재사용');

          // L2 캐시 히트: 기존 분석 결과를 현재 프로필에 복사 저장
          final existingSummary = l2Cached.data!;
          final saveResult = await aiMutations.saveSajuBaseSummary(
            userId: userId,
            profileId: profileId,
            content: existingSummary.content,  // 기존 결과 재사용
            inputData: inputJson,  // 현재 프로필의 입력 데이터
            modelName: existingSummary.modelName,
            promptTokens: 0,  // 캐시 사용 - 토큰 소비 없음
            completionTokens: 0,
            cachedTokens: 0,
            totalCostUsd: 0,  // 비용 없음
            processingTimeMs: stopwatch.elapsedMilliseconds,
            systemPrompt: null,  // 캐시 재사용
            userPrompt: null,
            locale: locale,
          );

          if (saveResult.isSuccess) {
            print('[SajuAnalysisService] L2 캐시 결과 저장 완료');
            return AnalysisResult.success(
              summaryId: saveResult.data!.id,
              processingTimeMs: stopwatch.elapsedMilliseconds,
            );
          }
          // 저장 실패 시 GPT 호출로 폴백
          print('[SajuAnalysisService] ⚠️ L2 캐시 저장 실패 - GPT 호출로 진행');
        }
      }

      // 3. 진행 중인 task 확인 (중복 생성 방지)
      // ⚠️ model 필터 필수! Fortune(gpt-5-mini)과 saju_base(gpt-5.2) 구분
      final pendingTask = await aiQueries.getPendingTaskId(
        userId: userId,
        model: OpenAIModels.sajuAnalysis,  // gpt-5.2
        locale: locale,
      );
      if (pendingTask.isSuccess && pendingTask.data != null) {
        print('[SajuAnalysisService] ⏳ 이미 분석 진행 중: ${pendingTask.data}');
        // 기존 task 결과 대기
        return await _waitForExistingTask(pendingTask.data!, profileId);
      }

      // 4. 프롬프트 생성
      final prompt = SajuBasePrompt(locale: locale);
      final messages = prompt.buildMessages(inputJson);

      // 5. GPT API 호출 (userId 전달 → ai_tasks에 user_id 저장)
      // v43: reasoning_effort: low (속도 우선)
      final response = await _apiService.callOpenAI(
        messages: messages,
        model: prompt.modelName,
        maxTokens: prompt.maxTokens,
        temperature: prompt.temperature,
        logType: 'saju_base',
        userId: userId,  // 중복 task 방지용
        taskType: 'saju_base',  // v29: 병렬 실행 시 task 분리
        reasoningEffort: 'low',  // v43: 속도 우선
      );

      if (!response.success) {
        throw Exception(response.error ?? 'GPT API 호출 실패');
      }

      // 6. 결과 저장 (전체 프롬프트 포함)
      // NOTE: saju_origin은 제거됨 - 필요시 saju_analyses 테이블에서 직접 조회
      final saveResult = await aiMutations.saveSajuBaseSummary(
        userId: userId,
        profileId: profileId,
        content: response.content!,
        inputData: inputJson,
        modelName: prompt.modelName,
        promptTokens: response.promptTokens,
        completionTokens: response.completionTokens,
        cachedTokens: response.cachedTokens,
        totalCostUsd: response.totalCostUsd,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        systemPrompt: prompt.systemPrompt,
        userPrompt: prompt.buildUserPrompt(inputJson),
        locale: locale,
      );

      stopwatch.stop();

      if (saveResult.isSuccess) {
        // 상세 로그 출력 (프로필 분석 전용)
        final profileName = inputJson['name'] as String? ?? '알 수 없음';
        await AiLogger.logProfileAnalysis(
          profileId: profileId,
          profileName: profileName,
          analysisType: 'saju_base',
          provider: 'openai',
          model: prompt.modelName,
          success: true,
          content: response.content != null ? jsonEncode(response.content) : null,
          tokens: {
            'prompt': response.promptTokens,
            'completion': response.completionTokens,
            'cached': response.cachedTokens,
          },
          costUsd: response.totalCostUsd,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );

        return AnalysisResult.success(
          summaryId: saveResult.data!.id,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        throw Exception(saveResult.errorMessage ?? '저장 실패');
      }
    } catch (e, stackTrace) {
      stopwatch.stop();

      // 에러 로그 출력
      final profileName = inputJson['name'] as String? ?? '알 수 없음';
      await AiLogger.logProfileAnalysis(
        profileId: profileId,
        profileName: profileName,
        analysisType: 'saju_base',
        provider: 'openai',
        model: OpenAIModels.sajuAnalysis, // gpt-5.2-thinking
        success: false,
        error: e.toString(),
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );

      ErrorLoggingService.logError(
        operation: 'saju_analysis',
        errorMessage: e.toString(),
        sourceFile: 'saju_analysis_service.dart',
        stackTrace: stackTrace.toString(),
        extraData: {'method': '_runSajuBaseAnalysis', 'profileId': profileId},
      );

      return AnalysisResult.failure(e.toString());
    }
  }

  /// 오늘의 운세 분석 (Gemini 3.0 Flash)
  ///
  /// ## v7.0 변경사항
  /// - DailyFortunePrompt → FortuneCoordinator.analyzeDailyOnly() 사용
  /// - fortune/daily/ 폴더 패턴 통일
  ///
  /// ## 처리 과정
  /// 1. FortuneCoordinator.analyzeDailyOnly() 호출
  ///    - 내부적으로 캐시 확인
  ///    - saju_analyses 조회 → FortuneInputData 생성
  ///    - DailyService.analyze() → Gemini API 호출 → 저장
  ///
  /// ## 예상 소요 시간
  /// - Gemini 3.0 Flash: 1-3초 (매우 빠름)
  Future<AnalysisResult> _runDailyFortuneAnalysis(
    String userId,
    String profileId,
    Map<String, dynamic> inputJson, {
    String locale = 'ko',
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      print('[SajuAnalysisService] 오늘의 운세 분석 시작 (v7.0 DailyService)...');

      // FortuneCoordinator를 통해 일운 분석 (캐시 확인 포함)
      final result = await _fortuneCoordinator.analyzeDailyOnly(
        userId: userId,
        profileId: profileId,
        locale: locale,
      );

      stopwatch.stop();

      if (result.success) {
        // 상세 로그 출력
        final profileName = inputJson['name'] as String? ?? '알 수 없음';
        await AiLogger.logProfileAnalysis(
          profileId: profileId,
          profileName: profileName,
          analysisType: 'daily_fortune',
          provider: 'google',
          model: 'gemini-3.0-flash',
          success: true,
          content: result.content != null ? jsonEncode(result.content) : null,
          tokens: {
            'prompt': result.promptTokens ?? 0,
            'completion': result.completionTokens ?? 0,
          },
          costUsd: result.totalCost,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );

        return AnalysisResult.success(
          summaryId: result.summaryId ?? '',
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        throw Exception(result.errorMessage ?? '일운 분석 실패');
      }
    } catch (e, stackTrace) {
      stopwatch.stop();

      // 에러 로그 출력
      final profileName = inputJson['name'] as String? ?? '알 수 없음';
      await AiLogger.logProfileAnalysis(
        profileId: profileId,
        profileName: profileName,
        analysisType: 'daily_fortune',
        provider: 'google',
        model: 'gemini-3.0-flash',
        success: false,
        error: e.toString(),
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );

      ErrorLoggingService.logError(
        operation: 'saju_analysis',
        errorMessage: e.toString(),
        sourceFile: 'saju_analysis_service.dart',
        stackTrace: stackTrace.toString(),
        extraData: {'method': '_runDailyFortuneAnalysis', 'profileId': profileId},
      );

      return AnalysisResult.failure(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 개별 갱신 메서드
  // ─────────────────────────────────────────────────────────────────────────

  /// 일운만 갱신 (매일 자동 실행용)
  ///
  /// ## 용도
  /// - 스케줄러에서 매일 자정 호출
  /// - 사용자가 수동으로 갱신 요청
  ///
  /// ## 예시
  /// ```dart
  /// await sajuAnalysisService.refreshDailyFortune(
  ///   userId: user.id,
  ///   profileId: profileId,
  /// );
  /// ```
  Future<AnalysisResult> refreshDailyFortune({
    required String userId,
    required String profileId,
    String locale = 'ko',
  }) async {
    final inputData = await _prepareInputData(profileId);
    if (inputData == null) {
      return AnalysisResult.failure('사주 데이터 조회 실패');
    }

    return _runDailyFortuneAnalysis(userId, profileId, inputData.toJson(), locale: locale);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // saju_base 전용 분석 (Splash 화면에서 호출)
  // ─────────────────────────────────────────────────────────────────────────

  /// saju_base 분석 확인 및 실행 (GPT-5.2)
  ///
  /// ## 용도
  /// - Splash 화면에서 기존 사용자의 saju_base 존재 여부 확인
  /// - 없으면 GPT-5.2 분석 실행 (fire-and-forget)
  ///
  /// ## 호출 시점
  /// - Splash에서 프로필이 있지만 saju_base 분석이 없을 때 (기존 사용자)
  /// - 채팅 시작 전 saju_base 분석 필요할 때
  ///
  /// ## 특징
  /// - saju_base만 분석 (daily_fortune은 별도)
  /// - 캐시 존재 시 스킵
  /// - Fire-and-forget 지원
  ///
  /// ## 예시
  /// ```dart
  /// // Fire-and-forget (Splash 화면)
  /// sajuAnalysisService.ensureSajuBaseAnalysis(
  ///   userId: user.id,
  ///   profileId: profileId,
  ///   runInBackground: true,  // 즉시 반환
  /// );
  ///
  /// // 완료 대기 (채팅 시작 전)
  /// final result = await sajuAnalysisService.ensureSajuBaseAnalysis(
  ///   userId: user.id,
  ///   profileId: profileId,
  ///   runInBackground: false,
  /// );
  /// ```
  Future<AnalysisResult> ensureSajuBaseAnalysis({
    required String userId,
    required String profileId,
    bool runInBackground = true,
    void Function(AnalysisResult)? onComplete,
    String locale = 'ko',
  }) async {
    print('[SajuAnalysisService] 🚀 ensureSajuBaseAnalysis 시작: $profileId');

    // 1. 캐시 확인 (이미 분석된 경우 스킵)
    final cached = await aiQueries.getSajuBaseSummary(profileId, locale: locale);
    if (cached.isSuccess && cached.data != null) {
      print('[SajuAnalysisService] ✅ saju_base 캐시 존재 - 스킵');
      return AnalysisResult.success(
        summaryId: cached.data!.id,
        processingTimeMs: 0,
      );
    }

    // 2. 사주 데이터 준비
    final inputData = await _prepareInputData(profileId);
    if (inputData == null) {
      print('[SajuAnalysisService] ❌ 사주 데이터 조회 실패');
      return AnalysisResult.failure('사주 데이터 조회 실패');
    }

    // 3. 분석 실행 (v49: phased path 사용 — monolithic 대비 성공률 90% vs 40%)
    final inputJson = inputData.toJson();
    if (runInBackground) {
      // Fire-and-forget
      print('[SajuAnalysisService] 🔥 백그라운드 phased 분석 시작');
      _runPhasedAnalysisInBackground(userId, profileId, inputJson, onComplete, locale: locale);
      return AnalysisResult.success(summaryId: 'pending', processingTimeMs: 0);
    } else {
      // 완료 대기 (phased path + low→medium fallback)
      print('[SajuAnalysisService] ⏳ phased 분석 대기 중...');
      var phasedResult = await runSajuBaseAnalysisWithPhases(
        userId: userId,
        profileId: profileId,
        inputJson: inputJson,
        reasoningEffort: 'low',
        locale: locale,
      );
      if (!phasedResult.overall.success) {
        print('[SajuAnalysisService] ⚠️ low 실패 → medium 재시도');
        phasedResult = await runSajuBaseAnalysisWithPhases(
          userId: userId,
          profileId: profileId,
          inputJson: inputJson,
          reasoningEffort: 'medium',
          locale: locale,
        );
      }
      return phasedResult.overall;
    }
  }

  /// v49: phased 분석 백그라운드 실행 (monolithic 대비 성공률 90% vs 40%)
  void _runPhasedAnalysisInBackground(
    String userId,
    String profileId,
    Map<String, dynamic> inputJson,
    void Function(AnalysisResult)? onComplete, {
    String locale = 'ko',
  }) {
    () async {
      var phasedResult = await runSajuBaseAnalysisWithPhases(
        userId: userId,
        profileId: profileId,
        inputJson: inputJson,
        reasoningEffort: 'low',
        locale: locale,
      );
      if (!phasedResult.overall.success) {
        print('[SajuAnalysisService] ⚠️ 백그라운드 low 실패 → medium 재시도');
        phasedResult = await runSajuBaseAnalysisWithPhases(
          userId: userId,
          profileId: profileId,
          inputJson: inputJson,
          reasoningEffort: 'medium',
          locale: locale,
        );
      }
      return phasedResult.overall;
    }().then((result) {
      print('[SajuAnalysisService] ✅ 백그라운드 phased 분석 완료: ${result.success}');
      onComplete?.call(result);
    }).catchError((e) {
      print('[SajuAnalysisService] ❌ 백그라운드 phased 분석 오류: $e');
      onComplete?.call(AnalysisResult.failure(e.toString()));
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 인연(상대방) 사주 분석 (인연 등록 시 호출)
  // ─────────────────────────────────────────────────────────────────────────

  /// 인연(상대방) 프로필의 사주 분석
  ///
  /// ## 용도
  /// - 인연 등록 시 상대방 프로필의 만세력 분석
  /// - profile_relations.to_profile_analysis_id에 연결
  ///
  /// ## 특징
  /// - saju_base 분석만 실행 (daily_fortune은 생략)
  /// - 캐시 존재 시 스킵
  /// - Fire-and-forget 지원
  ///
  /// ## 예시
  /// ```dart
  /// // 인연 등록 후 호출
  /// final result = await sajuAnalysisService.analyzeRelationProfile(
  ///   userId: user.id,
  ///   profileId: targetProfileId,  // 상대방 프로필 ID
  ///   runInBackground: true,       // 즉시 반환
  /// );
  /// ```
  Future<AnalysisResult> analyzeRelationProfile({
    required String userId,
    required String profileId,
    bool runInBackground = true,
    void Function(AnalysisResult)? onComplete,
    String locale = 'ko',
  }) async {
    print('[SajuAnalysisService] 👫 인연 프로필 분석 시작: $profileId');

    // 1. 캐시 확인 (이미 분석된 경우 스킵)
    final cached = await aiQueries.getSajuBaseSummary(profileId, locale: locale);
    if (cached.isSuccess && cached.data != null) {
      print('[SajuAnalysisService] ✅ 인연 saju_base 캐시 존재 - 스킵');
      final result = AnalysisResult.success(
        summaryId: cached.data!.id,
        processingTimeMs: 0,
      );
      onComplete?.call(result);
      return result;
    }

    // 2. 사주 데이터 준비
    final inputData = await _prepareInputData(profileId);
    if (inputData == null) {
      print('[SajuAnalysisService] ❌ 인연 사주 데이터 조회 실패');
      final result = AnalysisResult.failure('인연 사주 데이터 조회 실패');
      onComplete?.call(result);
      return result;
    }

    // 3. 분석 실행 (v49: phased path — 성공률 90% vs monolithic 40%)
    final inputJson = inputData.toJson();
    if (runInBackground) {
      // Fire-and-forget
      print('[SajuAnalysisService] 🔥 인연 백그라운드 phased 분석 시작');
      _runPhasedAnalysisInBackground(userId, profileId, inputJson, onComplete, locale: locale);
      return AnalysisResult.success(summaryId: 'pending', processingTimeMs: 0);
    } else {
      // 완료 대기 (phased path + low→medium fallback)
      print('[SajuAnalysisService] ⏳ 인연 phased 분석 대기 중...');
      var phasedResult = await runSajuBaseAnalysisWithPhases(
        userId: userId,
        profileId: profileId,
        inputJson: inputJson,
        reasoningEffort: 'low',
        locale: locale,
      );
      if (!phasedResult.overall.success) {
        phasedResult = await runSajuBaseAnalysisWithPhases(
          userId: userId,
          profileId: profileId,
          inputJson: inputJson,
          reasoningEffort: 'medium',
          locale: locale,
        );
      }
      final result = phasedResult.overall;
      onComplete?.call(result);
      return result;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 중복 방지: 기존 task 대기
  // ─────────────────────────────────────────────────────────────────────────

  /// 기존 task 완료 대기 (중복 호출 시)
  ///
  /// ## 용도
  /// 이미 다른 곳에서 GPT-5.2 분석이 진행 중일 때,
  /// 새로 task를 생성하지 않고 기존 task 완료를 폴링으로 대기.
  ///
  /// ## 폴링 설정
  /// - 간격: 3초
  /// - 최대: 60회 (180초 = 3분)
  Future<AnalysisResult> _waitForExistingTask(
    String taskId,
    String profileId,
  ) async {
    const maxAttempts = 60;
    const pollInterval = Duration(seconds: 3);

    for (int i = 0; i < maxAttempts; i++) {
      // task 상태 조회
      final taskResult = await aiQueries.getTaskStatus(taskId);

      if (!taskResult.isSuccess || taskResult.data == null) {
        print('[SajuAnalysisService] Task 상태 조회 실패 - 폴링 계속');
        await Future.delayed(pollInterval);
        continue;
      }

      final status = taskResult.data!['status'] as String?;

      switch (status) {
        case 'completed':
          print('[SajuAnalysisService] ✅ 기존 task 완료됨! 결과 조회...');
          // 완료된 분석 결과 조회
          final cached = await aiQueries.getSajuBaseSummary(profileId);
          if (cached.isSuccess && cached.data != null) {
            return AnalysisResult.success(
              summaryId: cached.data!.id,
              processingTimeMs: i * 3000,
            );
          }
          // 캐시에 없으면 실패 처리
          return AnalysisResult.failure('분석 완료됐으나 결과 조회 실패');

        case 'failed':
          final error = taskResult.data!['error_message'] as String? ?? 'Unknown error';
          print('[SajuAnalysisService] ❌ 기존 task 실패: $error');
          return AnalysisResult.failure(error);

        case 'pending':
        case 'processing':
          if (i % 10 == 0) {
            print('[SajuAnalysisService] ⏳ 기존 task 대기 중... ($i/$maxAttempts)');
          }
          await Future.delayed(pollInterval);
          break;

        default:
          print('[SajuAnalysisService] ❓ 알 수 없는 상태: $status');
          await Future.delayed(pollInterval);
      }
    }

    // 타임아웃
    print('[SajuAnalysisService] ⏰ 기존 task 대기 타임아웃 (180초)');
    return AnalysisResult.failure('기존 분석 대기 타임아웃');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 전역 인스턴스
// ═══════════════════════════════════════════════════════════════════════════

/// 전역 서비스 인스턴스
///
/// ## 사용
/// ```dart
/// import 'package:your_app/AI/services/saju_analysis_service.dart';
///
/// sajuAnalysisService.analyzeOnProfileSave(
///   userId: user.id,
///   profileId: profileId,
/// );
/// ```
final sajuAnalysisService = SajuAnalysisService();

// ═══════════════════════════════════════════════════════════════════════════
// Phase 분할 분석 결과 클래스
// ═══════════════════════════════════════════════════════════════════════════

/// Phase별 분석 결과
class PhaseAnalysisResult {
  final int phase;
  final bool success;
  final Map<String, dynamic>? content;
  final String? error;
  final int processingTimeMs;

  const PhaseAnalysisResult({
    required this.phase,
    required this.success,
    this.content,
    this.error,
    this.processingTimeMs = 0,
  });

  factory PhaseAnalysisResult.success({
    required int phase,
    required Map<String, dynamic> content,
    int processingTimeMs = 0,
  }) =>
      PhaseAnalysisResult(
        phase: phase,
        success: true,
        content: content,
        processingTimeMs: processingTimeMs,
      );

  factory PhaseAnalysisResult.failure({
    required int phase,
    required String error,
    int processingTimeMs = 0,
  }) =>
      PhaseAnalysisResult(
        phase: phase,
        success: false,
        error: error,
        processingTimeMs: processingTimeMs,
      );
}

/// Phase 분할 분석 전체 결과
class PhasedAnalysisResult {
  final AnalysisResult overall;
  final List<PhaseAnalysisResult> phases;
  final int totalProcessingTimeMs;

  const PhasedAnalysisResult({
    required this.overall,
    required this.phases,
    required this.totalProcessingTimeMs,
  });

  /// 각 Phase 완료 상태
  bool get phase1Complete => phases.any((p) => p.phase == 1 && p.success);
  bool get phase2Complete => phases.any((p) => p.phase == 2 && p.success);
  bool get phase3Complete => phases.any((p) => p.phase == 3 && p.success);
  bool get phase4Complete => phases.any((p) => p.phase == 4 && p.success);
  bool get allPhasesComplete => phase1Complete && phase2Complete && phase3Complete && phase4Complete;
}

// ═══════════════════════════════════════════════════════════════════════════
// Phase 분할 분석 Extension
// ═══════════════════════════════════════════════════════════════════════════

/// SajuAnalysisService Phase 분할 Extension
extension SajuAnalysisServicePhasedExtension on SajuAnalysisService {

  /// Phase 분할 평생운세 분석 (Progressive Disclosure)
  ///
  /// ## 특징
  /// - 4개 Phase로 분할하여 점진적 결과 제공
  /// - Phase 1 완료 시 onPhaseComplete 콜백 → UI 즉시 표시
  /// - Phase 2+3 병렬 실행으로 시간 단축
  ///
  /// ## Phase 구성
  /// | Phase | 섹션 | 예상 시간 |
  /// |-------|------|----------|
  /// | 1 | 원국, 십성, 합충, 성격, 행운 | 60초 |
  /// | 2 | 재물, 직업, 사업, 애정, 결혼 | 45초 |
  /// | 3 | 신살, 건강, 대운상세 | 45초 |
  /// | 4 | 요약, 인생주기, 전성기, 현대해석 | 45초 |
  ///
  /// ## 실행 흐름
  /// ```
  /// Phase 1 (Foundation)
  ///     ↓
  /// Phase 2 (Fortune) ─┬─ 병렬 실행
  /// Phase 3 (Special) ─┘
  ///     ↓
  /// Phase 4 (Synthesis)
  ///     ↓
  /// 결과 병합 → ai_summaries 저장
  /// ```
  /// v43: reasoningEffort 파라미터 추가 (low → medium 폴백 지원)
  Future<PhasedAnalysisResult> runSajuBaseAnalysisWithPhases({
    required String userId,
    required String profileId,
    required Map<String, dynamic> inputJson,
    String reasoningEffort = 'low',  // v43: default "low" for saju_base
    String locale = 'ko',
    void Function(PhaseAnalysisResult)? onPhaseComplete,
  }) async {
    final totalStopwatch = Stopwatch()..start();
    final phases = <PhaseAnalysisResult>[];
    var partialResult = <String, dynamic>{};
    String? taskId;

    try {
      print('[SajuAnalysisService] 🚀 Phase 분할 분석 시작 (reasoning_effort: $reasoningEffort)');

      // Task 생성 (Progressive Disclosure 지원)
      final taskResult = await aiMutations.createPhasedTask(
        userId: userId,
        requestData: inputJson,
        totalPhases: 4,
      );
      if (taskResult.isSuccess) {
        taskId = taskResult.data;
        print('[SajuAnalysisService] 📋 Task 생성됨: $taskId');
      }

      // ═══════════════════════════════════════════════════════════════════════
      // Phase 1: Foundation (원국, 십성, 합충, 성격, 행운)
      // ═══════════════════════════════════════════════════════════════════════
      print('[SajuAnalysisService] 📊 Phase 1 시작 (Foundation, reasoning: $reasoningEffort)...');
      final phase1Result = await _runPhase1(userId, inputJson, reasoningEffort, locale);
      phases.add(phase1Result);

      if (phase1Result.success) {
        print('[SajuAnalysisService] ✅ Phase 1 완료 (${phase1Result.processingTimeMs}ms)');
        partialResult.addAll(phase1Result.content!);

        // DB에 부분 결과 저장 (UI에서 바로 표시 가능)
        if (taskId != null) {
          await aiMutations.updateTaskPhaseProgress(
            taskId: taskId,
            phase: 2,  // 다음 Phase로 표시
            partialResult: partialResult,
          );
        }
        onPhaseComplete?.call(phase1Result);
      } else {
        print('[SajuAnalysisService] ❌ Phase 1 실패: ${phase1Result.error}');
        return PhasedAnalysisResult(
          overall: AnalysisResult.failure('Phase 1 실패: ${phase1Result.error}'),
          phases: phases,
          totalProcessingTimeMs: totalStopwatch.elapsedMilliseconds,
        );
      }

      // ═══════════════════════════════════════════════════════════════════════
      // Phase 2 + 3: 병렬 실행
      // ═══════════════════════════════════════════════════════════════════════
      print('[SajuAnalysisService] 📊 Phase 2+3 병렬 시작 (reasoning: $reasoningEffort)...');
      final phase2And3Results = await Future.wait([
        _runPhase2(userId, inputJson, phase1Result.content!, reasoningEffort, locale),
        _runPhase3(userId, inputJson, phase1Result.content!, reasoningEffort, locale),
      ]);

      final phase2Result = phase2And3Results[0];
      final phase3Result = phase2And3Results[1];
      phases.add(phase2Result);
      phases.add(phase3Result);

      if (phase2Result.success) {
        print('[SajuAnalysisService] ✅ Phase 2 완료 (${phase2Result.processingTimeMs}ms)');
        partialResult.addAll(phase2Result.content!);
        onPhaseComplete?.call(phase2Result);
      } else {
        print('[SajuAnalysisService] ⚠️ Phase 2 실패: ${phase2Result.error}');
      }

      if (phase3Result.success) {
        print('[SajuAnalysisService] ✅ Phase 3 완료 (${phase3Result.processingTimeMs}ms)');
        partialResult.addAll(phase3Result.content!);
        onPhaseComplete?.call(phase3Result);
      } else {
        print('[SajuAnalysisService] ⚠️ Phase 3 실패: ${phase3Result.error}');
      }

      // DB에 Phase 2+3 부분 결과 저장
      if (taskId != null && (phase2Result.success || phase3Result.success)) {
        await aiMutations.updateTaskPhaseProgress(
          taskId: taskId,
          phase: 4,  // 다음 Phase로 표시
          partialResult: partialResult,
        );
      }

      // Phase 2 또는 3 실패 시 계속 진행 (부분 결과)
      if (!phase2Result.success && !phase3Result.success) {
        print('[SajuAnalysisService] ❌ Phase 2+3 모두 실패 - 중단');
        return PhasedAnalysisResult(
          overall: AnalysisResult.failure('Phase 2+3 모두 실패'),
          phases: phases,
          totalProcessingTimeMs: totalStopwatch.elapsedMilliseconds,
        );
      }

      // ═══════════════════════════════════════════════════════════════════════
      // Phase 4: Synthesis (요약, 인생주기, 전성기, 현대해석)
      // ═══════════════════════════════════════════════════════════════════════
      print('[SajuAnalysisService] 📊 Phase 4 시작 (Synthesis, reasoning: $reasoningEffort)...');
      final phase4Result = await _runPhase4(
        userId,
        inputJson,
        phase1Result.content!,
        phase2Result.content ?? {},
        phase3Result.content ?? {},
        reasoningEffort,
        locale,
      );
      phases.add(phase4Result);

      if (phase4Result.success) {
        print('[SajuAnalysisService] ✅ Phase 4 완료 (${phase4Result.processingTimeMs}ms)');
        partialResult.addAll(phase4Result.content!);
        onPhaseComplete?.call(phase4Result);
      } else {
        print('[SajuAnalysisService] ⚠️ Phase 4 실패: ${phase4Result.error}');
      }

      // ═══════════════════════════════════════════════════════════════════════
      // 결과 병합 및 저장
      // ═══════════════════════════════════════════════════════════════════════
      totalStopwatch.stop();

      // 모든 Phase 결과 병합
      final mergedContent = _mergePhaseResults(phases);

      // DB에 최종 결과 업데이트 (Phase 4 완료 표시)
      if (taskId != null) {
        await aiMutations.updateTaskPhaseProgress(
          taskId: taskId,
          phase: 4,  // 마지막 Phase
          partialResult: mergedContent,
        );
      }

      // v41: 저장 전 최종 검증 - 유효한 분석 결과인지 확인
      if (mergedContent.isEmpty || mergedContent.containsKey('raw') || mergedContent.containsKey('_parse_failed')) {
        print('[SajuAnalysisService] 유효한 분석 결과 없음 - 저장 스킵');
        ErrorLoggingService.logError(
          operation: 'saju_base_validation',
          errorMessage: '분석 결과 유효성 검증 실패 (empty=${mergedContent.isEmpty}, raw=${mergedContent.containsKey('raw')}, parse_failed=${mergedContent.containsKey('_parse_failed')})',
          errorType: 'validation',
          sourceFile: 'saju_analysis_service.dart',
          extraData: {
            'method': 'runSajuBaseAnalysisWithPhases',
            'profileId': profileId,
            'phase_results': phases.map((p) => {'phase': p.phase, 'success': p.success, 'error': p.error}).toList(),
          },
        );
        return PhasedAnalysisResult(
          overall: AnalysisResult.failure('분석 결과 유효성 검증 실패'),
          phases: phases,
          totalProcessingTimeMs: totalStopwatch.elapsedMilliseconds,
        );
      }

      // ai_summaries에 저장
      final saveResult = await aiMutations.saveSajuBaseSummary(
        userId: userId,
        profileId: profileId,
        content: mergedContent,
        inputData: inputJson,
        modelName: 'gpt-5.2-phased',
        promptTokens: 0,  // 개별 Phase에서 계산됨
        completionTokens: 0,
        cachedTokens: 0,
        totalCostUsd: 0,
        processingTimeMs: totalStopwatch.elapsedMilliseconds,
        systemPrompt: null,
        userPrompt: null,
        locale: locale,
      );

      if (saveResult.isSuccess) {
        print('[SajuAnalysisService] ✅ Phase 분할 분석 완료! (총 ${totalStopwatch.elapsedMilliseconds}ms)');

        // Task 완료 처리
        if (taskId != null) {
          await aiMutations.completeTask(
            taskId: taskId,
            resultData: {'summary_id': saveResult.data!.id},
          );
        }

        return PhasedAnalysisResult(
          overall: AnalysisResult.success(
            summaryId: saveResult.data!.id,
            processingTimeMs: totalStopwatch.elapsedMilliseconds,
          ),
          phases: phases,
          totalProcessingTimeMs: totalStopwatch.elapsedMilliseconds,
        );
      } else {
        return PhasedAnalysisResult(
          overall: AnalysisResult.failure('결과 저장 실패: ${saveResult.errorMessage}'),
          phases: phases,
          totalProcessingTimeMs: totalStopwatch.elapsedMilliseconds,
        );
      }
    } catch (e, stackTrace) {
      totalStopwatch.stop();
      print('[SajuAnalysisService] ❌ Phase 분할 분석 오류: $e');
      ErrorLoggingService.logError(
        operation: 'saju_analysis',
        errorMessage: e.toString(),
        sourceFile: 'saju_analysis_service.dart',
        stackTrace: stackTrace.toString(),
        extraData: {'method': 'runSajuBaseAnalysisWithPhases', 'profileId': profileId},
      );
      return PhasedAnalysisResult(
        overall: AnalysisResult.failure(e.toString()),
        phases: phases,
        totalProcessingTimeMs: totalStopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Phase 1 분석 (Foundation)
  /// v43: reasoningEffort 파라미터 추가
  Future<PhaseAnalysisResult> _runPhase1(
    String userId,
    Map<String, dynamic> inputJson,
    String reasoningEffort,
    String locale,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final prompt = SajuBasePhase1Prompt(locale: locale);
      final messages = prompt.buildMessages(inputJson);

      final response = await _apiService.callOpenAI(
        messages: messages,
        model: prompt.modelName,
        maxTokens: prompt.maxTokens,
        temperature: prompt.temperature,
        logType: 'saju_base_phase1',
        userId: userId,
        taskType: 'saju_base_phase1',  // v29: 병렬 실행 시 task 분리
        reasoningEffort: reasoningEffort,  // v43
      );

      stopwatch.stop();

      if (response.success && response.content != null) {
        final content = response.content as Map<String, dynamic>;

        // v41: raw fallback / parse_failed 체크
        if (content.containsKey('_parse_failed') || content.containsKey('raw')) {
          ErrorLoggingService.logError(
            operation: 'saju_base_phase1',
            errorMessage: 'Phase 1 JSON 파싱 실패',
            errorType: 'json_parse',
            sourceFile: 'saju_analysis_service.dart',
            extraData: {'parse_error': content['_parse_error']},
          );
          return PhaseAnalysisResult.failure(
            phase: 1,
            error: 'Phase 1 JSON 파싱 실패',
            processingTimeMs: stopwatch.elapsedMilliseconds,
          );
        }

        // 필수 키 검증 (로그만 - 부분 성공 허용)
        const requiredKeys = ['personality', 'lucky_elements'];
        final missingKeys = requiredKeys
            .where((key) => !content.containsKey(key) || content[key] == null)
            .toList();
        if (missingKeys.isNotEmpty) {
          print('[SajuAnalysis] Phase 1 필수 키 누락: $missingKeys');
        }

        return PhaseAnalysisResult.success(
          phase: 1,
          content: content,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        return PhaseAnalysisResult.failure(
          phase: 1,
          error: response.error ?? 'Phase 1 API 실패',
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      ErrorLoggingService.logError(
        operation: 'saju_analysis',
        errorMessage: e.toString(),
        sourceFile: 'saju_analysis_service.dart',
        stackTrace: stackTrace.toString(),
        extraData: {'method': '_runPhase1'},
      );
      return PhaseAnalysisResult.failure(
        phase: 1,
        error: e.toString(),
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Phase 2 분석 (Fortune)
  /// v43: reasoningEffort 파라미터 추가
  Future<PhaseAnalysisResult> _runPhase2(
    String userId,
    Map<String, dynamic> inputJson,
    Map<String, dynamic> phase1Result,
    String reasoningEffort,
    String locale,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final prompt = SajuBasePhase2Prompt(locale: locale);
      final userPrompt = prompt.buildUserPromptWithPhase1(inputJson, phase1Result);
      final messages = [
        {'role': 'system', 'content': prompt.systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ];

      final response = await _apiService.callOpenAI(
        messages: messages,
        model: prompt.modelName,
        maxTokens: prompt.maxTokens,
        temperature: prompt.temperature,
        logType: 'saju_base_phase2',
        userId: userId,
        taskType: 'saju_base_phase2',  // v29: 병렬 실행 시 task 분리
        reasoningEffort: reasoningEffort,  // v43
      );

      stopwatch.stop();

      if (response.success && response.content != null) {
        final content = response.content as Map<String, dynamic>;

        // v41: raw fallback / parse_failed 체크
        if (content.containsKey('_parse_failed') || content.containsKey('raw')) {
          ErrorLoggingService.logError(
            operation: 'saju_base_phase2',
            errorMessage: 'Phase 2 JSON 파싱 실패',
            errorType: 'json_parse',
            sourceFile: 'saju_analysis_service.dart',
            extraData: {'parse_error': content['_parse_error']},
          );
          return PhaseAnalysisResult.failure(
            phase: 2,
            error: 'Phase 2 JSON 파싱 실패',
            processingTimeMs: stopwatch.elapsedMilliseconds,
          );
        }

        return PhaseAnalysisResult.success(
          phase: 2,
          content: content,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        return PhaseAnalysisResult.failure(
          phase: 2,
          error: response.error ?? 'Phase 2 API 실패',
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      ErrorLoggingService.logError(
        operation: 'saju_analysis',
        errorMessage: e.toString(),
        sourceFile: 'saju_analysis_service.dart',
        stackTrace: stackTrace.toString(),
        extraData: {'method': '_runPhase2'},
      );
      return PhaseAnalysisResult.failure(
        phase: 2,
        error: e.toString(),
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Phase 3 분석 (Special)
  /// v43: reasoningEffort 파라미터 추가
  Future<PhaseAnalysisResult> _runPhase3(
    String userId,
    Map<String, dynamic> inputJson,
    Map<String, dynamic> phase1Result,
    String reasoningEffort,
    String locale,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final prompt = SajuBasePhase3Prompt(locale: locale);
      final userPrompt = prompt.buildUserPromptWithPhase1(inputJson, phase1Result);
      final messages = [
        {'role': 'system', 'content': prompt.systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ];

      final response = await _apiService.callOpenAI(
        messages: messages,
        model: prompt.modelName,
        maxTokens: prompt.maxTokens,
        temperature: prompt.temperature,
        logType: 'saju_base_phase3',
        userId: userId,
        taskType: 'saju_base_phase3',  // v29: 병렬 실행 시 task 분리
        reasoningEffort: reasoningEffort,  // v43
      );

      stopwatch.stop();

      if (response.success && response.content != null) {
        final content = response.content as Map<String, dynamic>;

        // v41: raw fallback / parse_failed 체크
        if (content.containsKey('_parse_failed') || content.containsKey('raw')) {
          ErrorLoggingService.logError(
            operation: 'saju_base_phase3',
            errorMessage: 'Phase 3 JSON 파싱 실패',
            errorType: 'json_parse',
            sourceFile: 'saju_analysis_service.dart',
            extraData: {'parse_error': content['_parse_error']},
          );
          return PhaseAnalysisResult.failure(
            phase: 3,
            error: 'Phase 3 JSON 파싱 실패',
            processingTimeMs: stopwatch.elapsedMilliseconds,
          );
        }

        return PhaseAnalysisResult.success(
          phase: 3,
          content: content,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        return PhaseAnalysisResult.failure(
          phase: 3,
          error: response.error ?? 'Phase 3 API 실패',
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      ErrorLoggingService.logError(
        operation: 'saju_analysis',
        errorMessage: e.toString(),
        sourceFile: 'saju_analysis_service.dart',
        stackTrace: stackTrace.toString(),
        extraData: {'method': '_runPhase3'},
      );
      return PhaseAnalysisResult.failure(
        phase: 3,
        error: e.toString(),
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Phase 4 분석 (Synthesis)
  /// v43: reasoningEffort 파라미터 추가
  Future<PhaseAnalysisResult> _runPhase4(
    String userId,
    Map<String, dynamic> inputJson,
    Map<String, dynamic> phase1Result,
    Map<String, dynamic> phase2Result,
    Map<String, dynamic> phase3Result,
    String reasoningEffort,
    String locale,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final prompt = SajuBasePhase4Prompt(locale: locale);
      final userPrompt = prompt.buildUserPromptWithAllPhases(
        inputJson,
        phase1Result,
        phase2Result,
        phase3Result,
      );
      final messages = [
        {'role': 'system', 'content': prompt.systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ];

      final response = await _apiService.callOpenAI(
        messages: messages,
        model: prompt.modelName,
        maxTokens: prompt.maxTokens,
        temperature: prompt.temperature,
        logType: 'saju_base_phase4',
        userId: userId,
        taskType: 'saju_base_phase4',  // v29: 병렬 실행 시 task 분리
        reasoningEffort: reasoningEffort,  // v43
      );

      stopwatch.stop();

      if (response.success && response.content != null) {
        final content = response.content as Map<String, dynamic>;

        // v41: raw fallback / parse_failed 체크
        if (content.containsKey('_parse_failed') || content.containsKey('raw')) {
          ErrorLoggingService.logError(
            operation: 'saju_base_phase4',
            errorMessage: 'Phase 4 JSON 파싱 실패',
            errorType: 'json_parse',
            sourceFile: 'saju_analysis_service.dart',
            extraData: {'parse_error': content['_parse_error']},
          );
          return PhaseAnalysisResult.failure(
            phase: 4,
            error: 'Phase 4 JSON 파싱 실패',
            processingTimeMs: stopwatch.elapsedMilliseconds,
          );
        }

        return PhaseAnalysisResult.success(
          phase: 4,
          content: content,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        return PhaseAnalysisResult.failure(
          phase: 4,
          error: response.error ?? 'Phase 4 API 실패',
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      ErrorLoggingService.logError(
        operation: 'saju_analysis',
        errorMessage: e.toString(),
        sourceFile: 'saju_analysis_service.dart',
        stackTrace: stackTrace.toString(),
        extraData: {'method': '_runPhase4'},
      );
      return PhaseAnalysisResult.failure(
        phase: 4,
        error: e.toString(),
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Phase 결과 병합
  ///
  /// 4개의 Phase 결과를 기존 saju_base JSON 스키마와 동일한 구조로 병합
  /// v41: raw/parse_failed Phase는 건너뜀, 최소 필수 키 검증
  Map<String, dynamic> _mergePhaseResults(List<PhaseAnalysisResult> phases) {
    final merged = <String, dynamic>{};

    for (final phase in phases) {
      if (phase.success && phase.content != null) {
        final content = phase.content!;

        // raw/parse_failed 키가 있는 phase는 건너뜀
        if (content.containsKey('raw') || content.containsKey('_parse_failed')) {
          print('[SajuAnalysis] Phase ${phase.phase} raw fallback 감지 → 스킵');
          continue;
        }

        merged.addAll(content);
      }
    }

    // 최소 필수 키 존재 확인
    if (!merged.containsKey('personality') && !merged.containsKey('summary')) {
      print('[SajuAnalysis] 병합 결과에 핵심 키 없음 (personality/summary 모두 부재)');
    }

    return merged;
  }
}

