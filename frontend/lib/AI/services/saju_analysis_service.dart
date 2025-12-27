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

import '../../core/supabase/generated/saju_analyses.dart';
import '../../core/supabase/generated/saju_profiles.dart';
import '../data/mutations.dart';
import '../data/queries.dart';
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

  /// 생성자
  ///
  /// [apiService] 테스트 시 Mock 주입 가능
  SajuAnalysisService({AiApiService? apiService})
      : _apiService = apiService ?? AiApiService();

  // ─────────────────────────────────────────────────────────────────────────
  // 메인 진입점
  // ─────────────────────────────────────────────────────────────────────────

  /// 프로필 저장 시 호출 - 두 분석 병렬 실행
  ///
  /// ## 파라미터
  /// - `userId`: 사용자 UUID (RLS 필수)
  /// - `profileId`: 프로필 UUID
  /// - `runInBackground`: Fire-and-forget 모드 (기본 true)
  ///
  /// ## 반환값
  /// - `runInBackground=true`: 빈 ProfileAnalysisResult 즉시 반환
  /// - `runInBackground=false`: 완료된 결과 반환
  Future<ProfileAnalysisResult> analyzeOnProfileSave({
    required String userId,
    required String profileId,
    bool runInBackground = true,
  }) async {
    print('[SajuAnalysisService] 프로필 분석 시작: $profileId');

    // 1. 사주 데이터 조회
    final inputData = await _prepareInputData(profileId);
    if (inputData == null) {
      print('[SajuAnalysisService] 사주 데이터 조회 실패');
      return ProfileAnalysisResult(
        sajuBase: AnalysisResult.failure('사주 데이터 조회 실패'),
        dailyFortune: AnalysisResult.failure('사주 데이터 조회 실패'),
      );
    }

    // 2. 두 분석 병렬 실행
    if (runInBackground) {
      // Fire-and-forget: 백그라운드에서 실행
      _runBothAnalysesInBackground(userId, profileId, inputData);
      return const ProfileAnalysisResult(); // 즉시 반환
    } else {
      // 완료 대기
      return await _runBothAnalyses(userId, profileId, inputData);
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
  void _runBothAnalysesInBackground(
    String userId,
    String profileId,
    SajuInputData inputData,
  ) {
    // 비동기로 실행, 결과는 DB에 저장됨
    _runBothAnalyses(userId, profileId, inputData).then((result) {
      print('[SajuAnalysisService] 백그라운드 분석 완료');
      print('  - 평생운세: ${result.sajuBase?.success ?? false}');
      print('  - 오늘운세: ${result.dailyFortune?.success ?? false}');
    }).catchError((e) {
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

    if (sajuBaseResult.success) {
      // GPT 분석 결과 조회하여 Gemini 입력에 추가
      final sajuBaseData = await aiQueries.getSajuBaseSummary(profileId);
      if (sajuBaseData.isSuccess && sajuBaseData.data != null) {
        enrichedInputJson['saju_base_analysis'] = sajuBaseData.data!.content;
        print('[SajuAnalysisService] GPT 분석 결과를 Gemini 입력에 추가');
      }
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

      // 2. 프롬프트 생성
      final prompt = SajuBasePrompt();
      final messages = prompt.buildMessages(inputJson);

      // 3. GPT API 호출
      final response = await _apiService.callOpenAI(
        messages: messages,
        model: prompt.modelName,
        maxTokens: prompt.maxTokens,
        temperature: prompt.temperature,
        logType: 'saju_base',
      );

      if (!response.success) {
        throw Exception(response.error ?? 'GPT API 호출 실패');
      }

      // 4. 결과 저장
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
      );

      stopwatch.stop();

      if (saveResult.isSuccess) {
        print('[SajuAnalysisService] 평생 사주 분석 완료: ${stopwatch.elapsedMilliseconds}ms');
        return AnalysisResult.success(
          summaryId: saveResult.data!.id,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        throw Exception(saveResult.errorMessage ?? '저장 실패');
      }
    } catch (e) {
      stopwatch.stop();
      print('[SajuAnalysisService] 평생 사주 분석 오류: $e');
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

      // 4. 결과 저장
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
      );

      stopwatch.stop();

      if (saveResult.isSuccess) {
        print('[SajuAnalysisService] 오늘의 운세 분석 완료: ${stopwatch.elapsedMilliseconds}ms');
        return AnalysisResult.success(
          summaryId: saveResult.data!.id,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        throw Exception(saveResult.errorMessage ?? '저장 실패');
      }
    } catch (e) {
      stopwatch.stop();
      print('[SajuAnalysisService] 오늘의 운세 분석 오류: $e');
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
