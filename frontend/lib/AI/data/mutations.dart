/// # AI 모듈 뮤테이션
///
/// ## 개요
/// AI 분석 결과를 `ai_summaries` 테이블에 저장/업데이트합니다.
/// RLS(Row Level Security) 정책으로 사용자별 데이터 격리 보장.
///
/// ## 파일 위치
/// `frontend/lib/AI/data/mutations.dart`
///
/// ## 주요 기능
/// 1. **분석 결과 저장**: API 응답 → DB 저장
/// 2. **캐시 관리**: expires_at 기반 만료 처리
/// 3. **Upsert**: 동일 조건 데이터 덮어쓰기
/// 4. **상태 관리**: pending → processing → completed/failed
///
/// ## 데이터 흐름
/// ```
/// GPT/Gemini API 응답
///       ↓
/// AiMutations.saveSajuBaseSummary() / saveDailyFortune()
///       ↓
/// ai_summaries 테이블 (INSERT/UPSERT)
///       ↓
/// 다음 조회 시 캐시 반환
/// ```
///
/// ## ai_summaries 테이블 구조
/// ```sql
/// CREATE TABLE ai_summaries (
///   id UUID PRIMARY KEY,
///   user_id UUID REFERENCES auth.users,
///   profile_id UUID REFERENCES saju_profiles,
///   summary_type VARCHAR(50),      -- 분석 유형
///   content JSONB,                 -- AI 응답 (구조화된 JSON)
///   input_data JSONB,              -- GPT에 전달한 입력 데이터
///   target_date DATE,              -- 일운 대상 날짜
///   target_period VARCHAR(20),     -- 월운/년운 대상 기간
///   model_provider VARCHAR(20),    -- openai/google
///   model_name VARCHAR(50),        -- gpt-5.2/gemini-2.0-flash
///   prompt_tokens INT,             -- 입력 토큰 수
///   completion_tokens INT,         -- 출력 토큰 수
///   cached_tokens INT,             -- 캐시된 토큰 수
///   total_cost_usd DECIMAL(10,6),  -- 비용 (USD)
///   processing_time_ms INT,        -- 처리 시간
///   status VARCHAR(20),            -- pending/processing/completed/failed
///   expires_at TIMESTAMPTZ,        -- 캐시 만료 시간
///   created_at TIMESTAMPTZ
/// );
/// ```
///
/// ## 사용 예시
/// ```dart
/// // 평생 사주 분석 저장
/// final result = await aiMutations.saveSajuBaseSummary(
///   userId: user.id,
///   profileId: profileId,
///   content: gptResponse.content!,
///   promptTokens: gptResponse.promptTokens,
///   completionTokens: gptResponse.completionTokens,
///   totalCostUsd: gptResponse.totalCostUsd,
/// );
/// ```
///
/// ## 관련 파일
/// - `queries.dart`: 캐시 조회
/// - `ai_api_service.dart`: API 호출 및 응답 파싱
/// - `saju_analysis_service.dart`: 분석 오케스트레이션

import '../../core/data/data.dart';
import '../../core/supabase/generated/ai_summaries.dart';
import '../core/ai_constants.dart';

/// AI 관련 뮤테이션
///
/// ## BaseMutations 상속
/// - `safeMutation()`: 트랜잭션 안전 실행 + 에러 처리
/// - 자동 로깅 및 에러 리포팅
///
/// ## 전역 인스턴스
/// ```dart
/// const aiMutations = AiMutations();
/// await aiMutations.saveSajuBaseSummary(...);
/// ```
class AiMutations extends BaseMutations {
  const AiMutations();

  // ═══════════════════════════════════════════════════════════════════════════
  // 범용 저장
  // ═══════════════════════════════════════════════════════════════════════════

  /// AI 분석 결과 저장 (범용)
  ///
  /// ## 파라미터
  /// - `userId`: 사용자 UUID (RLS 필수)
  /// - `profileId`: 프로필 UUID
  /// - `summaryType`: 분석 유형 (SummaryType 상수)
  /// - `content`: AI 응답 JSON
  /// - `inputData`: GPT에 전달한 입력 (디버깅용)
  /// - `targetDate`: 일운 대상 날짜
  /// - `targetPeriod`: 월운/년운 대상 기간
  /// - `cacheExpiry`: 캐시 만료 Duration (null = 무기한)
  Future<QueryResult<AiSummaries>> saveSummary({
    required String userId,
    required String profileId,
    required String summaryType,
    required Map<String, dynamic> content,
    Map<String, dynamic>? inputData,
    DateTime? targetDate,
    String? targetPeriod,
    String? modelProvider,
    String? modelName,
    int? promptTokens,
    int? completionTokens,
    int? cachedTokens,
    double? totalCostUsd,
    int? processingTimeMs,
    Duration? cacheExpiry,
  }) async {
    return safeMutation(
      mutation: (client) async {
        final expiresAt = cacheExpiry != null
            ? DateTime.now().add(cacheExpiry).toUtc()
            : null;

        final data = AiSummaries.insert(
          userId: userId,
          profileId: profileId,
          summaryType: summaryType,
          content: content,
          inputData: inputData,
          targetDate: targetDate,
          targetPeriod: targetPeriod,
          modelProvider: modelProvider ?? ModelProvider.openai,
          modelName: modelName,
          promptTokens: promptTokens,
          completionTokens: completionTokens,
          totalTokens:
              (promptTokens ?? 0) + (completionTokens ?? 0),
          cachedTokens: cachedTokens ?? 0,
          totalCostUsd: totalCostUsd,
          processingTimeMs: processingTimeMs,
          status: 'completed',
          expiresAt: expiresAt,
        );

        // UPSERT: 같은 (profile_id, target_date, summary_type) 조합이면 업데이트
        // idx_ai_summaries_unique_daily constraint 충돌 방지 (409 Conflict 해결)
        final response = await client
            .from(AiSummaries.table_name)
            .upsert(
              data,
              onConflict: 'profile_id,target_date,summary_type',
            )
            .select()
            .single();

        return AiSummaries.fromJson(response);
      },
      errorPrefix: 'AI 분석 결과 저장 실패',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 특화 저장 메서드
  // ═══════════════════════════════════════════════════════════════════════════

  /// 기본 사주 분석 저장 (삭제 후 삽입)
  ///
  /// ## 특징
  /// - **Delete + Insert**: Partial UNIQUE INDEX 호환
  /// - **무기한 캐시**: expires_at = null
  /// - **모델**: GPT-5.2 (가장 정확한 분석)
  ///
  /// ## UNIQUE INDEX
  /// `idx_ai_summaries_unique_base`: (profile_id) WHERE summary_type = 'saju_base'
  /// Partial index는 Supabase upsert와 호환되지 않으므로 삭제 후 삽입 방식 사용
  ///
  /// ## 호출 시점
  /// - 프로필 최초 저장 시
  /// - 프로필 정보 수정 시 (재분석)
  ///
  /// ## 파라미터
  /// - [systemPrompt] AI에게 전달된 시스템 프롬프트 (선택)
  /// - [userPrompt] AI에게 전달된 사용자 프롬프트 (선택)
  Future<QueryResult<AiSummaries>> saveSajuBaseSummary({
    required String userId,
    required String profileId,
    required Map<String, dynamic> content,
    Map<String, dynamic>? inputData,
    String? modelName,
    int? promptTokens,
    int? completionTokens,
    int? cachedTokens,
    double? totalCostUsd,
    int? processingTimeMs,
    String? systemPrompt,
    String? userPrompt,
  }) async {
    return safeMutation(
      mutation: (client) async {
        // 1. 기존 saju_base 레코드 삭제 (있으면)
        // Partial UNIQUE INDEX: (profile_id) WHERE summary_type = 'saju_base'
        await client
            .from(AiSummaries.table_name)
            .delete()
            .eq(AiSummaries.c_profileId, profileId)
            .eq(AiSummaries.c_summaryType, SummaryType.sajuBase);

        // input_data에 전체 프롬프트 포함
        final inputDataJson = <String, dynamic>{};
        if (systemPrompt != null) {
          inputDataJson['system_prompt'] = systemPrompt;
        }
        if (userPrompt != null) {
          inputDataJson['user_prompt'] = userPrompt;
        }
        if (inputData != null) {
          inputDataJson['input_params'] = inputData;
        }

        // 2. 새 레코드 삽입
        final data = AiSummaries.insert(
          userId: userId,
          profileId: profileId,
          summaryType: SummaryType.sajuBase,
          content: content,
          inputData: inputDataJson.isNotEmpty ? inputDataJson : null,
          // saju_base는 target_date 없음 (NULL)
          modelProvider: ModelProvider.openai,
          modelName: modelName ?? OpenAIModels.sajuAnalysis, // GPT-5.2
          promptTokens: promptTokens,
          completionTokens: completionTokens,
          totalTokens: (promptTokens ?? 0) + (completionTokens ?? 0),
          cachedTokens: cachedTokens ?? 0,
          totalCostUsd: totalCostUsd,
          processingTimeMs: processingTimeMs,
          status: 'completed',
        );

        final response = await client
            .from(AiSummaries.table_name)
            .insert(data)
            .select()
            .single();

        return AiSummaries.fromJson(response);
      },
      errorPrefix: '기본 사주 분석 저장 실패',
    );
  }

  /// 일운 저장
  ///
  /// ## 특징
  /// - **24시간 캐시**: 자정 이후 자동 만료
  /// - **모델**: Gemini 2.0 Flash (빠르고 저렴)
  /// - **날짜 기반**: target_date로 조회
  ///
  /// ## 호출 시점
  /// - 프로필 저장 시 (평생 사주와 함께)
  /// - 매일 자정 스케줄러
  /// - 사용자가 오늘의 운세 조회 시 (캐시 없으면)
  ///
  /// ## 파라미터
  /// - [systemPrompt] AI에게 전달된 시스템 프롬프트 (선택)
  /// - [userPrompt] AI에게 전달된 사용자 프롬프트 (선택)
  Future<QueryResult<AiSummaries>> saveDailyFortune({
    required String userId,
    required String profileId,
    required DateTime targetDate,
    required Map<String, dynamic> content,
    Map<String, dynamic>? inputData,
    String? modelName,
    int? promptTokens,
    int? completionTokens,
    double? totalCostUsd,
    int? processingTimeMs,
    String? systemPrompt,
    String? userPrompt,
  }) async {
    // input_data에 전체 프롬프트 포함
    final inputDataJson = <String, dynamic>{};
    if (systemPrompt != null) {
      inputDataJson['system_prompt'] = systemPrompt;
    }
    if (userPrompt != null) {
      inputDataJson['user_prompt'] = userPrompt;
    }
    if (inputData != null) {
      inputDataJson['input_params'] = inputData;
    }

    return saveSummary(
      userId: userId,
      profileId: profileId,
      summaryType: SummaryType.dailyFortune,
      content: content,
      inputData: inputDataJson.isNotEmpty ? inputDataJson : null,
      targetDate: targetDate,
      modelProvider: ModelProvider.google,
      modelName: modelName ?? GoogleModels.dailyFortune,  // Gemini 3.0 Flash
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalCostUsd: totalCostUsd,
      processingTimeMs: processingTimeMs,
      cacheExpiry: CacheExpiry.dailyFortune,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 상태 관리
  // ═══════════════════════════════════════════════════════════════════════════

  /// 분석 상태 업데이트
  ///
  /// ## 상태 값
  /// - `pending`: 분석 요청됨, 아직 시작 안함
  /// - `processing`: 분석 중
  /// - `completed`: 분석 완료
  /// - `failed`: 분석 실패 (errorMessage, errorCode 포함)
  Future<QueryResult<void>> updateStatus({
    required String summaryId,
    required String status,
    String? errorMessage,
    String? errorCode,
  }) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from(AiSummaries.table_name)
            .update({
              AiSummaries.c_status: status,
              if (errorMessage != null)
                AiSummaries.c_errorMessage: errorMessage,
              if (errorCode != null) AiSummaries.c_errorCode: errorCode,
            })
            .eq(AiSummaries.c_id, summaryId);
      },
      errorPrefix: '분석 상태 업데이트 실패',
    );
  }

  /// pending 상태로 분석 요청 생성
  ///
  /// ## 용도
  /// - 비동기 분석 요청 추적
  /// - 중복 요청 방지 (pending 있으면 스킵)
  /// - 분석 큐 관리
  Future<QueryResult<AiSummaries>> createPendingAnalysis({
    required String userId,
    required String profileId,
    required String summaryType,
    Map<String, dynamic>? inputData,
    DateTime? targetDate,
    String? targetPeriod,
  }) async {
    return safeMutation(
      mutation: (client) async {
        final data = AiSummaries.insert(
          userId: userId,
          profileId: profileId,
          summaryType: summaryType,
          content: {'status': 'pending'},
          inputData: inputData,
          targetDate: targetDate,
          targetPeriod: targetPeriod,
          status: 'pending',
        );

        final response = await client
            .from(AiSummaries.table_name)
            .insert(data)
            .select()
            .single();

        return AiSummaries.fromJson(response);
      },
      errorPrefix: 'pending 분석 생성 실패',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 캐시 관리
  // ═══════════════════════════════════════════════════════════════════════════

  /// 만료된 캐시 삭제
  ///
  /// ## 용도
  /// - 주기적 정리 (크론잡)
  /// - 저장 공간 최적화
  ///
  /// ## 주의
  /// - expires_at IS NOT NULL인 레코드만 삭제
  /// - 무기한 캐시(saju_base)는 삭제 안됨
  Future<QueryResult<int>> deleteExpiredCache() async {
    return safeMutation(
      mutation: (client) async {
        final response = await client
            .from(AiSummaries.table_name)
            .delete()
            .lt(AiSummaries.c_expiresAt, DateTime.now().toUtc().toIso8601String())
            .select('id');

        return (response as List).length;
      },
      errorPrefix: '만료 캐시 삭제 실패',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Phase 분할 분석 (ai_tasks)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Phase 진행상황 업데이트
  ///
  /// ## v7.2: Phase 분할 분석 지원
  /// - phase: 현재 진행 중인 Phase (1-4)
  /// - partial_result: 완료된 Phase 결과 병합
  ///
  /// ## 용도
  /// Progressive Disclosure - Phase 완료 시마다 UI 업데이트
  Future<QueryResult<void>> updateTaskPhaseProgress({
    required String taskId,
    required int phase,
    required Map<String, dynamic> partialResult,
  }) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from('ai_tasks')
            .update({
              'phase': phase,
              'partial_result': partialResult,
            })
            .eq('id', taskId);
      },
      errorPrefix: 'Phase 진행상황 업데이트 실패',
    );
  }

  /// Phase 분할 분석 Task 생성
  ///
  /// ## v7.2: Phase 분할 분석용 Task 생성
  /// - total_phases: 4
  /// - phase: 1 (시작)
  Future<QueryResult<String>> createPhasedTask({
    required String userId,
    required Map<String, dynamic> requestData,
    String model = 'gpt-5.2-thinking',
    int totalPhases = 4,
  }) async {
    return safeMutation(
      mutation: (client) async {
        final response = await client
            .from('ai_tasks')
            .insert({
              'user_id': userId,
              'task_type': 'saju_analysis',
              'status': 'processing',
              'request_data': requestData,
              'model': model,
              'phase': 1,
              'total_phases': totalPhases,
              'partial_result': {},
            })
            .select('id')
            .single();

        return response['id'] as String;
      },
      errorPrefix: 'Phase 분할 Task 생성 실패',
    );
  }

  /// Task 완료 처리
  ///
  /// ## v7.2: Phase 분할 분석 완료 시 호출
  Future<QueryResult<void>> completeTask({
    required String taskId,
    Map<String, dynamic>? resultData,
  }) async {
    return safeMutation(
      mutation: (client) async {
        await client
            .from('ai_tasks')
            .update({
              'status': 'completed',
              'result_data': resultData,
              'completed_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', taskId);
      },
      errorPrefix: 'Task 완료 처리 실패',
    );
  }
}

/// 전역 인스턴스
const aiMutations = AiMutations();
