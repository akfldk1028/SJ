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
/// - `daily_fortune_prompt.dart`: Gemini 프롬프트

import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/generated/saju_analyses.dart';
import '../../core/supabase/generated/saju_profiles.dart';
import '../core/ai_constants.dart';
import '../core/ai_logger.dart';
import '../data/mutations.dart';
import '../data/queries.dart';
import '../fortune/fortune_coordinator.dart';
import '../prompts/daily_fortune_prompt.dart';
import '../prompts/prompt_template.dart';
import '../prompts/saju_base_prompt.dart';
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
      _runBothAnalysesInBackground(userId, profileId, inputData, onComplete);
      return const ProfileAnalysisResult(); // 즉시 반환
    } else {
      // 완료 대기
      try {
        return await _runBothAnalyses(userId, profileId, inputData);
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
    void Function(ProfileAnalysisResult)? onComplete,
  ) {
    // 비동기로 실행, 결과는 DB에 저장됨
    _runBothAnalyses(userId, profileId, inputData).then((result) {
      // 분석 완료 → Set에서 제거
      _analyzingProfiles.remove(profileId);
      print('[SajuAnalysisService] 백그라운드 분석 완료');
      print('  - 평생운세: ${result.sajuBase?.success ?? false}');
      print('  - 오늘운세: ${result.dailyFortune?.success ?? false}');

      // UI 갱신 콜백 호출
      if (onComplete != null) {
        onComplete(result);
      }
    }).catchError((e) {
      // 에러 시에도 Set에서 제거
      _analyzingProfiles.remove(profileId);
      print('[SajuAnalysisService] 백그라운드 분석 오류: $e');
    });
  }

  /// 두 분석 순차 실행 (GPT 먼저 → Gemini)
  ///
  /// ## 순차 실행 이유
  /// GPT-5.2 평생사주 분석 결과를 Gemini 일운 프롬프트에 포함시켜
  /// 정확도를 높임. GPT가 기본 분석 제공, Gemini가 참조.
  ///
  /// ## 실행 순서
  /// 1. GPT-5.2 평생사주 분석 (saju_base)
  /// 2. Gemini 일운 분석 (GPT 결과 참조)
  Future<ProfileAnalysisResult> _runBothAnalyses(
    String userId,
    String profileId,
    SajuInputData inputData,
  ) async {
    final inputJson = inputData.toJson();

    // 1. GPT 평생사주 분석 먼저 (기본)
    final sajuBaseResult = await _runSajuBaseAnalysis(userId, profileId, inputJson);

    // 2. GPT 결과를 Gemini 프롬프트에 포함
    Map<String, dynamic> enrichedInputJson = Map.from(inputJson);

    print('[SajuAnalysisService] 📊 saju_base 결과: success=${sajuBaseResult.success}');

    if (sajuBaseResult.success) {
      // GPT 분석 결과 조회하여 Gemini 입력에 추가
      print('[SajuAnalysisService] 🔍 saju_base 결과 조회 중...');
      final sajuBaseData = await aiQueries.getSajuBaseSummary(profileId);
      if (sajuBaseData.isSuccess && sajuBaseData.data != null) {
        enrichedInputJson['saju_base_analysis'] = sajuBaseData.data!.content;
        print('[SajuAnalysisService] ✅ GPT 분석 결과를 Gemini 입력에 추가');
      } else {
        print('[SajuAnalysisService] ⚠️ saju_base 조회 실패: ${sajuBaseData.errorMessage}');
      }

      // Fortune 분석 (yearly_2025, yearly_2026, monthly) - 동기 실행
      print('[SajuAnalysisService] 🎯 Fortune 분석 시작 (연간/월간)...');
      print('  - userId: $userId');
      print('  - profileId: $profileId');
      print('  - name: ${inputJson['name']}');
      print('  - birth_date: ${inputJson['birth_date']}');
      print('  - gender: ${inputJson['gender']}');
      try {
        final fortuneResults = await _fortuneCoordinator.analyzeAllFortunes(
          userId: userId,
          profileId: profileId,
          profileName: inputJson['name'] as String? ?? '',
          birthDate: inputJson['birth_date'] as String? ?? '',
          birthTime: inputJson['birth_time'] as String?,
          gender: inputJson['gender'] as String? ?? 'M',
        );
        print('[SajuAnalysisService] ✅ Fortune 분석 완료:');
        print('  - completedCount: ${fortuneResults.completedCount}');
        print('  - yearly2026: ${fortuneResults.yearly2026 != null ? "성공" : "실패"}');
        print('  - monthly: ${fortuneResults.monthly != null ? "성공" : "실패"}');
        print('  - yearly2025: ${fortuneResults.yearly2025 != null ? "성공" : "실패"}');
      } catch (e, stackTrace) {
        print('[SajuAnalysisService] ❌ Fortune 분석 오류: $e');
        print('[SajuAnalysisService] StackTrace: $stackTrace');
      }
    } else {
      print('[SajuAnalysisService] ⚠️ saju_base 실패로 Fortune 분석 스킵');
      print('  - error: ${sajuBaseResult.error}');
    }

    // 3. Gemini 일운 분석 (GPT 결과 참조)
    final dailyFortuneResult = await _runDailyFortuneAnalysis(
      userId, profileId, enrichedInputJson,
    );

    return ProfileAnalysisResult(
      sajuBase: sajuBaseResult,
      dailyFortune: dailyFortuneResult,
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
    Map<String, dynamic> inputJson,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      print('[SajuAnalysisService] 평생 사주 분석 시작...');

      // 1. 캐시 확인 (이미 분석된 경우 스킵)
      final cached = await aiQueries.getSajuBaseSummary(profileId);
      if (cached.isSuccess && cached.data != null) {
        print('[SajuAnalysisService] 평생 사주 분석 캐시 존재 - 스킵');
        return AnalysisResult.success(
          summaryId: cached.data!.id,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      }

      // 2. 진행 중인 task 확인 (중복 생성 방지)
      final pendingTask = await aiQueries.getPendingTaskId(userId: userId);
      if (pendingTask.isSuccess && pendingTask.data != null) {
        print('[SajuAnalysisService] ⏳ 이미 분석 진행 중: ${pendingTask.data}');
        // 기존 task 결과 대기
        return await _waitForExistingTask(pendingTask.data!, profileId);
      }

      // 3. 프롬프트 생성
      final prompt = SajuBasePrompt();
      final messages = prompt.buildMessages(inputJson);

      // 3. GPT API 호출 (userId 전달 → ai_tasks에 user_id 저장)
      final response = await _apiService.callOpenAI(
        messages: messages,
        model: prompt.modelName,
        maxTokens: prompt.maxTokens,
        temperature: prompt.temperature,
        logType: 'saju_base',
        userId: userId,  // 중복 task 방지용
      );

      if (!response.success) {
        throw Exception(response.error ?? 'GPT API 호출 실패');
      }

      // 4. saju_origin 추가 (만세력 원본 데이터 - 채팅 시 참조용)
      // GPT-5.2 응답에 saju_origin이 없을 수 있으므로 inputJson에서 직접 추출
      final contentWithOrigin = Map<String, dynamic>.from(response.content!);
      if (!contentWithOrigin.containsKey('saju_origin')) {
        contentWithOrigin['saju_origin'] = _buildSajuOrigin(inputJson);
        print('[SajuAnalysisService] saju_origin 추가됨 (from inputJson)');
      }

      // 5. 결과 저장 (전체 프롬프트 포함)
      final saveResult = await aiMutations.saveSajuBaseSummary(
        userId: userId,
        profileId: profileId,
        content: contentWithOrigin,
        inputData: inputJson,
        modelName: prompt.modelName,
        promptTokens: response.promptTokens,
        completionTokens: response.completionTokens,
        cachedTokens: response.cachedTokens,
        totalCostUsd: response.totalCostUsd,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        systemPrompt: prompt.systemPrompt,
        userPrompt: prompt.buildUserPrompt(inputJson),
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
    } catch (e) {
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

      return AnalysisResult.failure(e.toString());
    }
  }

  /// 오늘의 운세 분석 (Gemini)
  ///
  /// ## 처리 과정
  /// 1. 오늘 날짜 캐시 확인
  /// 2. DailyFortunePrompt로 메시지 생성
  /// 3. AiApiService.callGemini() 호출
  /// 4. AiMutations.saveDailyFortune() 저장
  ///
  /// ## 예상 소요 시간
  /// - Gemini 2.0 Flash: 1-3초 (매우 빠름)
  Future<AnalysisResult> _runDailyFortuneAnalysis(
    String userId,
    String profileId,
    Map<String, dynamic> inputJson,
  ) async {
    final stopwatch = Stopwatch()..start();
    final today = DateTime.now();

    try {
      print('[SajuAnalysisService] 오늘의 운세 분석 시작...');

      // 1. 캐시 확인 (오늘 이미 분석된 경우 스킵)
      final cached = await aiQueries.getDailyFortune(profileId, today);
      if (cached.isSuccess && cached.data != null) {
        print('[SajuAnalysisService] 오늘의 운세 캐시 존재 - 스킵');
        return AnalysisResult.success(
          summaryId: cached.data!.id,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      }

      // 2. 프롬프트 생성
      final prompt = DailyFortunePrompt(targetDate: today);
      final messages = prompt.buildMessages(inputJson);

      // 3. Gemini API 호출
      final response = await _apiService.callGemini(
        messages: messages,
        model: prompt.modelName,
        maxTokens: prompt.maxTokens,
        temperature: prompt.temperature,
        logType: 'daily_fortune',
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Gemini API 호출 실패');
      }

      // 4. 결과 저장 (전체 프롬프트 포함)
      final saveResult = await aiMutations.saveDailyFortune(
        userId: userId,
        profileId: profileId,
        targetDate: today,
        content: response.content!,
        inputData: inputJson,
        modelName: prompt.modelName,
        promptTokens: response.promptTokens,
        completionTokens: response.completionTokens,
        totalCostUsd: response.totalCostUsd,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        systemPrompt: prompt.systemPrompt,
        userPrompt: prompt.buildUserPrompt(inputJson),
      );

      stopwatch.stop();

      if (saveResult.isSuccess) {
        // 상세 로그 출력 (프로필 분석 전용)
        final profileName = inputJson['name'] as String? ?? '알 수 없음';
        await AiLogger.logProfileAnalysis(
          profileId: profileId,
          profileName: profileName,
          analysisType: 'daily_fortune',
          provider: 'google',
          model: prompt.modelName,
          success: true,
          content: response.content != null ? jsonEncode(response.content) : null,
          tokens: {
            'prompt': response.promptTokens,
            'completion': response.completionTokens,
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
    } catch (e) {
      stopwatch.stop();

      // 에러 로그 출력
      final profileName = inputJson['name'] as String? ?? '알 수 없음';
      await AiLogger.logProfileAnalysis(
        profileId: profileId,
        profileName: profileName,
        analysisType: 'daily_fortune',
        provider: 'google',
        model: 'gemini-2.0-flash',
        success: false,
        error: e.toString(),
        processingTimeMs: stopwatch.elapsedMilliseconds,
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
  }) async {
    final inputData = await _prepareInputData(profileId);
    if (inputData == null) {
      return AnalysisResult.failure('사주 데이터 조회 실패');
    }

    return _runDailyFortuneAnalysis(userId, profileId, inputData.toJson());
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
  /// - 채팅 시작 전 saju_origin 필요할 때
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
  }) async {
    print('[SajuAnalysisService] 🚀 ensureSajuBaseAnalysis 시작: $profileId');

    // 1. 캐시 확인 (이미 분석된 경우 스킵)
    final cached = await aiQueries.getSajuBaseSummary(profileId);
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

    // 3. 분석 실행
    if (runInBackground) {
      // Fire-and-forget
      print('[SajuAnalysisService] 🔥 백그라운드 GPT-5.2 분석 시작');
      _runSajuBaseAnalysisInBackground(userId, profileId, inputData.toJson(), onComplete);
      return AnalysisResult.success(summaryId: 'pending', processingTimeMs: 0);
    } else {
      // 완료 대기
      print('[SajuAnalysisService] ⏳ GPT-5.2 분석 대기 중...');
      return await _runSajuBaseAnalysis(userId, profileId, inputData.toJson());
    }
  }

  /// saju_base 분석 백그라운드 실행
  void _runSajuBaseAnalysisInBackground(
    String userId,
    String profileId,
    Map<String, dynamic> inputJson,
    void Function(AnalysisResult)? onComplete,
  ) {
    _runSajuBaseAnalysis(userId, profileId, inputJson).then((result) {
      print('[SajuAnalysisService] ✅ 백그라운드 GPT-5.2 분석 완료: ${result.success}');
      if (onComplete != null) {
        onComplete(result);
      }
    }).catchError((e) {
      print('[SajuAnalysisService] ❌ 백그라운드 GPT-5.2 분석 오류: $e');
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
  }) async {
    print('[SajuAnalysisService] 👫 인연 프로필 분석 시작: $profileId');

    // 1. 캐시 확인 (이미 분석된 경우 스킵)
    final cached = await aiQueries.getSajuBaseSummary(profileId);
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

    // 3. 분석 실행
    if (runInBackground) {
      // Fire-and-forget
      print('[SajuAnalysisService] 🔥 인연 백그라운드 GPT-5.2 분석 시작');
      _runSajuBaseAnalysisInBackground(userId, profileId, inputData.toJson(), onComplete);
      return AnalysisResult.success(summaryId: 'pending', processingTimeMs: 0);
    } else {
      // 완료 대기
      print('[SajuAnalysisService] ⏳ 인연 GPT-5.2 분석 대기 중...');
      final result = await _runSajuBaseAnalysis(userId, profileId, inputData.toJson());
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
// 헬퍼 함수
// ═══════════════════════════════════════════════════════════════════════════

/// inputJson에서 saju_origin 구조 생성
///
/// GPT-5.2가 saju_origin을 응답에 포함하지 않을 경우,
/// 이 함수로 inputJson(만세력 계산 결과)에서 직접 추출하여 DB에 저장
///
/// ## 포함 데이터
/// - saju: 사주팔자 (년월일시 간지)
/// - oheng: 오행 분포
/// - yongsin: 용신
/// - hapchung: 합충형파해 관계
/// - sinsal: 신살 목록
/// - gilseong: 길성 목록
/// - sipsin_info: 십성 정보
/// - twelve_unsung: 십이운성
/// - gyeokguk: 격국
Map<String, dynamic> _buildSajuOrigin(Map<String, dynamic> inputJson) {
  return {
    // 기본 사주 정보
    'saju': {
      'year': {
        'gan': inputJson['saju']?['year_gan'],
        'ji': inputJson['saju']?['year_ji'],
      },
      'month': {
        'gan': inputJson['saju']?['month_gan'],
        'ji': inputJson['saju']?['month_ji'],
      },
      'day': {
        'gan': inputJson['saju']?['day_gan'],
        'ji': inputJson['saju']?['day_ji'],
      },
      'hour': {
        'gan': inputJson['saju']?['hour_gan'],
        'ji': inputJson['saju']?['hour_ji'],
      },
    },

    // 오행 분포 (영문 → 한글 변환)
    'oheng': {
      '목': inputJson['oheng']?['wood'] ?? 0,
      '화': inputJson['oheng']?['fire'] ?? 0,
      '토': inputJson['oheng']?['earth'] ?? 0,
      '금': inputJson['oheng']?['metal'] ?? 0,
      '수': inputJson['oheng']?['water'] ?? 0,
    },

    // 용신 정보
    'yongsin': inputJson['yongsin'],
    'day_strength': inputJson['day_strength'],

    // 합충형파해 (가장 중요한 관계 분석)
    'hapchung': inputJson['hapchung'],

    // 신살 및 길성
    'sinsal': inputJson['sinsal'],
    'gilseong': inputJson['gilseong'],

    // 십성, 십이운성, 격국
    'sipsin_info': inputJson['sipsin_info'],
    'twelve_unsung': inputJson['twelve_unsung'],
    'gyeokguk': inputJson['gyeokguk'],

    // 지장간 정보
    'jijanggan_info': inputJson['jijanggan_info'],

    // 대운 정보
    'daeun': inputJson['daeun'],

    // 특수 신살 (12신살 등)
    'twelve_sinsal': inputJson['twelve_sinsal'],
  };
}
