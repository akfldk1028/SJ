import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'quota_service.dart';
import '../../features/saju_chart/domain/entities/saju_analysis.dart';
import '../../features/saju_chart/data/constants/sipsin_relations.dart';
import '../supabase/generated/ai_summaries.dart';
import '../../AI/core/ai_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Intent Routing - 토큰 최적화
// ═══════════════════════════════════════════════════════════════════════════════

/// AI Summary 카테고리 (Semantic Intent Routing용)
enum SummaryCategory {
  personality('PERSONALITY', '성격'),
  love('LOVE', '연애'),
  marriage('MARRIAGE', '결혼'),
  career('CAREER', '진로/직장'),
  business('BUSINESS', '사업'),
  wealth('WEALTH', '재물'),
  health('HEALTH', '건강'),
  general('GENERAL', '종합');

  final String code;
  final String korean;
  const SummaryCategory(this.code, this.korean);
}

/// Intent 분류 결과
class IntentClassificationResult {
  final List<SummaryCategory> categories;
  final String reason;

  const IntentClassificationResult({
    required this.categories,
    this.reason = '',
  });

  bool shouldInclude(SummaryCategory category) {
    return categories.contains(category) ||
        categories.contains(SummaryCategory.general);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AiSummaryService - AI 요약 생성 & 캐싱 서비스
// ═══════════════════════════════════════════════════════════════════════════════
//
// ## 아키텍처 개요 (Option A)
// ┌─────────────────────────────────────────────────────────────────────────────┐
// │                        Flutter 앱 (이 서비스)                               │
// │  ┌─────────────┐    ┌─────────────────┐    ┌─────────────────┐            │
// │  │ 캐시 확인   │ → │ Edge Function   │ → │ DB 저장         │            │
// │  │ (DB 조회)   │    │ (AI 생성만)     │    │ (ai_summaries)  │            │
// │  └─────────────┘    └─────────────────┘    └─────────────────┘            │
// └─────────────────────────────────────────────────────────────────────────────┘
//
// ## 책임 분담
// ┌──────────────────┬──────────────────────────────────────────────────────────┐
// │ 컴포넌트          │ 역할                                                    │
// ├──────────────────┼──────────────────────────────────────────────────────────┤
// │ Flutter 앱       │ 캐시 확인 → Edge Function 호출 → DB 저장                 │
// │ Edge Function    │ Gemini 3.0으로 AI 요약 생성 (DB 접근 X)                  │
// │ ai_summaries     │ 단일 저장소 (summary_type='saju_base')                   │
// └──────────────────┴──────────────────────────────────────────────────────────┘
//
// ## AI 모델 역할 분담 (듀얼 파이프라인)
// ┌──────────────────┬─────────────────┬─────────────────────────────────────────┐
// │ 용도             │ 모델            │ 설명                                    │
// ├──────────────────┼─────────────────┼─────────────────────────────────────────┤
// │ 평생 사주 분석   │ GPT-5.2         │ 정확한 추론 특화 (ai-openai)            │
// │ AI 요약 생성     │ Gemini 3.0      │ 빠른 응답 (generate-ai-summary)         │
// │ 채팅 대화        │ Gemini 3.0      │ 자연스러운 대화 (ai-gemini)             │
// └──────────────────┴─────────────────┴─────────────────────────────────────────┘
//
// ## 데이터 흐름
// 1. generateSummary() 호출
// 2. ai_summaries 테이블에서 캐시 확인 (profile_id + summary_type)
// 3. 캐시 있으면 → 즉시 반환 (DB 비용만)
// 4. 캐시 없으면 → Edge Function 호출 → Gemini 3.0 생성
// 5. 생성 결과를 ai_summaries에 저장 (upsert)
// 6. 결과 반환
//
// ## 관련 파일
// - Edge Function: supabase/functions/generate-ai-summary/index.ts
// - DB 테이블: ai_summaries (profile_id, summary_type UNIQUE)
// - GPT 분석: frontend/lib/AI/services/saju_analysis_service.dart
//
// ═══════════════════════════════════════════════════════════════════════════════

/// AI Summary 서비스 - Supabase Edge Function 호출
///
/// Option A 아키텍처:
/// - Edge Function: AI 요약 생성만 (DB 저장 안함)
/// - Flutter: ai_summaries 테이블에서 캐시 조회/저장
class AiSummaryService {
  static const String _functionName = 'generate-ai-summary';
  static const String _summaryType = 'saju_base'; // 평생 사주 분석

  /// AI Summary 생성 또는 캐시된 데이터 조회
  ///
  /// Option A 흐름:
  /// 1. ai_summaries 테이블에서 캐시 확인
  /// 2. 캐시 있으면 반환
  /// 3. 없으면 Edge Function 호출 → AI 생성
  /// 4. 결과를 ai_summaries에 저장
  ///
  /// [profileId] - 프로필 UUID
  /// [profileName] - 프로필 이름
  /// [birthDate] - 생년월일시 (YYYY-MM-DD HH:mm)
  /// [sajuAnalysis] - 사주 분석 데이터
  /// [forceRegenerate] - 기존 요약 무시하고 재생성
  static Future<AiSummaryResult> generateSummary({
    required String profileId,
    required String profileName,
    required String birthDate,
    required SajuAnalysis sajuAnalysis,
    bool forceRegenerate = false,
  }) async {
    try {
      final client = SupabaseService.client;

      if (client == null) {
        return AiSummaryResult.failure(
          'Supabase not initialized. Please check your connection.',
        );
      }

      // 1. 캐시 확인 (forceRegenerate가 아닐 때)
      if (!forceRegenerate) {
        final cached = await getCachedSummary(profileId);
        if (cached != null) {
          if (kDebugMode) {
            print('[AiSummaryService] 캐시 반환: $profileId');
          }
          return AiSummaryResult.success(summary: cached, cached: true);
        }
      }

      // 2. Edge Function 호출 (AI 생성)
      final body = <String, dynamic>{
        'profile_id': profileId,
        'profile_name': profileName,
        'birth_date': birthDate,
        'saju_analysis': _convertSajuAnalysis(sajuAnalysis),
      };

      if (kDebugMode) {
        print('[AiSummaryService] Edge Function 호출: $_functionName');
        print('[AiSummaryService] Profile: $profileId');
      }

      final response = await client.functions.invoke(
        _functionName,
        body: body,
      );

      // QUOTA_EXCEEDED 처리 (HTTP 429)
      if (response.status == 429) {
        final errorData = response.data as Map<String, dynamic>?;
        final quotaInfo = QuotaService.parseQuotaExceededResponse(errorData);
        if (kDebugMode) {
          print('[AiSummaryService] QUOTA_EXCEEDED: $quotaInfo');
        }
        return AiSummaryResult.quotaExceeded(
          message: quotaInfo?.message ?? '오늘 토큰 사용량을 초과했습니다.',
          tokensUsed: quotaInfo?.tokensUsed ?? 0,
          quotaLimit: quotaInfo?.quotaLimit ?? QuotaService.dailyQuota,
        );
      }

      if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage = errorData?['error'] ?? 'Unknown error';
        if (kDebugMode) {
          print('[AiSummaryService] Error: $errorMessage');
        }
        return AiSummaryResult.failure(errorMessage);
      }

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        return AiSummaryResult.failure(data['error'] ?? 'Generation failed');
      }

      final aiSummaryJson = data['ai_summary'] as Map<String, dynamic>;
      final aiSummary = AiSummary.fromJson(aiSummaryJson);

      // 3. ai_summaries 테이블에 저장
      await _saveToDatabase(
        client: client,
        profileId: profileId,
        summaryJson: aiSummaryJson,
        model: aiSummary.model ?? 'gemini-3-flash-preview',
      );

      if (kDebugMode) {
        print('[AiSummaryService] 생성 완료 및 DB 저장: $profileId');
      }

      return AiSummaryResult.success(
        summary: aiSummary,
        cached: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[AiSummaryService] Exception: $e');
      }
      return AiSummaryResult.failure(e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DB 저장 (Option A의 핵심: Flutter에서 저장 담당)
  // ─────────────────────────────────────────────────────────────────────────────
  /// ai_summaries 테이블에 저장 (upsert)
  ///
  /// Edge Function은 AI 생성만 담당하고, DB 저장은 여기서 처리
  /// profile_id + summary_type 조합으로 UNIQUE 제약 → 중복 방지
  ///
  /// 저장 필드:
  /// - user_id: 인증된 사용자 ID
  /// - profile_id: 프로필 UUID
  /// - summary_type: 'saju_base' (평생 사주)
  /// - content: AI 생성 JSON 전체
  /// - model_provider: 'google'
  /// - model_name: 'gemini-3-flash-preview'
  /// - status: 'completed'
  static Future<void> _saveToDatabase({
    required SupabaseClient client,
    required String profileId,
    required Map<String, dynamic> summaryJson,
    required String model,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        if (kDebugMode) {
          print('[AiSummaryService] User not authenticated, skipping DB save');
        }
        return;
      }

      final data = AiSummaries.insert(
        userId: userId,
        profileId: profileId,
        summaryType: _summaryType,
        content: summaryJson,
        modelProvider: 'google',
        modelName: model,
        status: 'completed',
        promptVersion: PromptVersions.forSummaryType(_summaryType),
      );

      // saju_base 타입은 profile_id만으로 unique (idx_ai_summaries_unique_base)
      // partial index: UNIQUE (profile_id) WHERE (summary_type = 'saju_base')
      await client
          .from(AiSummaries.table_name)
          .upsert(data, onConflict: 'profile_id')
          .select()
          .single();

      if (kDebugMode) {
        print('[AiSummaryService] DB 저장 성공: $profileId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AiSummaryService] DB 저장 실패 (무시): $e');
      }
      // DB 저장 실패해도 AI 결과는 반환
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 캐시 조회 (Option A: DB 우선 확인)
  // ─────────────────────────────────────────────────────────────────────────────
  /// DB에서 기존 AI Summary 조회 (ai_summaries 테이블)
  ///
  /// Edge Function 호출 없이 DB에서 직접 조회
  /// 이미 생성된 요약이 있으면 API 비용 절약
  ///
  /// 조회 조건:
  /// - profile_id: 프로필 UUID
  /// - summary_type: 'saju_base'
  static Future<AiSummary?> getCachedSummary(String profileId) async {
    try {
      final client = SupabaseService.client;
      if (client == null) return null;

      final response = await client
          .from(AiSummaries.table_name)
          .select('content, model_name, prompt_version')
          .eq('profile_id', profileId)
          .eq('summary_type', _summaryType)
          .maybeSingle();

      if (response == null || response['content'] == null) {
        return null;
      }

      // prompt_version 비교 (캐시 무효화)
      final cachedVersion = response['prompt_version'];
      final expectedVersion = PromptVersions.forSummaryType(_summaryType);
      if (expectedVersion != null && cachedVersion != expectedVersion) {
        if (kDebugMode) {
          print('[AiSummaryService] 프롬프트 버전 불일치: cached=$cachedVersion, expected=$expectedVersion');
        }
        return null;
      }

      final content = response['content'] as Map<String, dynamic>;
      // model_name도 content에 추가
      if (response['model_name'] != null) {
        content['model'] = response['model_name'];
      }

      return AiSummary.fromJson(content);
    } catch (e) {
      if (kDebugMode) {
        print('[AiSummaryService] getCachedSummary error: $e');
      }
      return null;
    }
  }

  /// AI Summary가 있는지 확인
  static Future<bool> hasSummary(String profileId) async {
    try {
      final client = SupabaseService.client;
      if (client == null) return false;

      final response = await client
          .from(AiSummaries.table_name)
          .select('id')
          .eq('profile_id', profileId)
          .eq('summary_type', _summaryType)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 데이터 변환 (Flutter Entity → Edge Function JSON)
  // ─────────────────────────────────────────────────────────────────────────────
  /// SajuAnalysis 엔티티를 Edge Function 형식으로 변환
  ///
  /// Edge Function이 이해하는 JSON 구조로 변환:
  /// - saju: 사주팔자 (년월일시 각각 간/지)
  /// - oheng: 오행 분포 (목/화/토/금/수)
  /// - yongsin: 용신 정보 (용신/희신/기신/구신)
  /// - sipsin: 십신 정보 (년간/월간/시간 십신)
  /// - singang_singak: 신강/신약 (강약 점수 및 요인)
  ///
  /// 참고: GPT-5.2가 분석한 데이터가 여기로 전달됨
  static Map<String, dynamic> _convertSajuAnalysis(SajuAnalysis analysis) {
    final chart = analysis.chart;
    final oheng = analysis.ohengDistribution;
    final yongsin = analysis.yongsin;
    final sipsinInfo = analysis.sipsinInfo;
    final dayStrength = analysis.dayStrength;

    return {
      'saju': {
        'year': {
          'gan': chart.yearPillar.gan,
          'ji': chart.yearPillar.ji,
          'ganHanja': chart.yearPillar.ganHanja,
          'jiHanja': chart.yearPillar.jiHanja,
        },
        'month': {
          'gan': chart.monthPillar.gan,
          'ji': chart.monthPillar.ji,
          'ganHanja': chart.monthPillar.ganHanja,
          'jiHanja': chart.monthPillar.jiHanja,
        },
        'day': {
          'gan': chart.dayPillar.gan,
          'ji': chart.dayPillar.ji,
          'ganHanja': chart.dayPillar.ganHanja,
          'jiHanja': chart.dayPillar.jiHanja,
        },
        'hour': chart.hourPillar != null
            ? {
                'gan': chart.hourPillar!.gan,
                'ji': chart.hourPillar!.ji,
                'ganHanja': chart.hourPillar!.ganHanja,
                'jiHanja': chart.hourPillar!.jiHanja,
              }
            : {
                'gan': '?',
                'ji': '?',
              },
      },
      'oheng': {
        'wood': oheng.mok,
        'fire': oheng.hwa,
        'earth': oheng.to,
        'metal': oheng.geum,
        'water': oheng.su,
      },
      'yongsin': {
        'yongsin': _ohengToString(yongsin.yongsin),
        'huisin': _ohengToString(yongsin.heesin),
        'gisin': _ohengToString(yongsin.gisin),
        'gusin': _ohengToString(yongsin.gusin),
      },
      'sipsin': {
        'yearGan': sipsinInfo.yearGanSipsin.korean,
        'monthGan': sipsinInfo.monthGanSipsin.korean,
        if (sipsinInfo.hourGanSipsin != null)
          'hourGan': sipsinInfo.hourGanSipsin!.korean,
        'yearJi': sipsinInfo.yearJiSipsin.korean,
        'monthJi': sipsinInfo.monthJiSipsin.korean,
        'dayJi': sipsinInfo.dayJiSipsin.korean,
        if (sipsinInfo.hourJiSipsin != null)
          'hourJi': sipsinInfo.hourJiSipsin!.korean,
      },
      'singang_singak': {
        'is_singang': dayStrength.isStrong,
        'score': dayStrength.score,
        'factors': {
          'deukryeong': dayStrength.deukryeong,
          'deukji': dayStrength.deukji,
          'deuksi': dayStrength.deuksi,
          'deukse': dayStrength.deukse,
        },
      },
    };
  }

  /// 오행 enum을 문자열로 변환
  static String _ohengToString(Oheng oheng) {
    switch (oheng) {
      case Oheng.mok:
        return '목(木)';
      case Oheng.hwa:
        return '화(火)';
      case Oheng.to:
        return '토(土)';
      case Oheng.geum:
        return '금(金)';
      case Oheng.su:
        return '수(水)';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 결과 및 데이터 모델
// ═══════════════════════════════════════════════════════════════════════════════

/// AI Summary 결과
///
/// 성공/실패 상태와 캐시 여부를 포함
/// - isSuccess: 에러 없이 summary가 있으면 true
/// - cached: DB에서 가져온 경우 true, 새로 생성한 경우 false
class AiSummaryResult {
  final AiSummary? summary;
  final bool cached;
  final bool quotaExceeded;
  final int? tokensUsed;
  final int? quotaLimit;
  final String? error;

  AiSummaryResult._({
    this.summary,
    this.cached = false,
    this.quotaExceeded = false,
    this.tokensUsed,
    this.quotaLimit,
    this.error,
  });

  factory AiSummaryResult.success({
    required AiSummary summary,
    bool cached = false,
  }) {
    return AiSummaryResult._(
      summary: summary,
      cached: cached,
    );
  }

  factory AiSummaryResult.failure(String error) {
    return AiSummaryResult._(error: error);
  }

  /// Quota 초과 결과 생성
  factory AiSummaryResult.quotaExceeded({
    required String message,
    int? tokensUsed,
    int? quotaLimit,
  }) {
    return AiSummaryResult._(
      quotaExceeded: true,
      tokensUsed: tokensUsed,
      quotaLimit: quotaLimit,
      error: message,
    );
  }

  bool get isSuccess => error == null && summary != null && !quotaExceeded;

  /// Quota 초과로 광고 시청이 필요한지
  bool get needsAdWatch => quotaExceeded;
}

/// AI Summary 데이터 모델
///
/// GPT-5.2가 생성하는 평생 사주 분석 결과
/// Edge Function의 JSON 응답을 파싱하여 사용
///
/// ## 포함 정보 (v2.0)
/// - saju_origin: 원본 사주 데이터 (합충형파해, 십성, 신살 등)
/// - personality: 성격 분석
/// - wealth: 재물운
/// - love: 연애운
/// - marriage: 결혼운
/// - career: 진로/직장운
/// - business: 사업운
/// - health: 건강운
/// - lucky_elements: 행운 요소
///
/// ## Gemini 채팅이 참조하는 데이터
/// - saju_origin: 합충형파해 같은 어려운 정보 참조용
/// - 나머지 분석 결과: 상담 시 활용
class AiSummary {
  /// 사주 원본 데이터 (합충형파해, 십성, 신살 등)
  /// Gemini가 어려운 사주 용어를 까먹지 않도록 포함
  final Map<String, dynamic>? sajuOrigin;

  /// 한 문장 요약
  final String? summary;

  /// 원국 분석 (일간, 오행균형, 신강신약, 격국)
  final Map<String, dynamic>? wonGukAnalysis;

  /// 십성 분석
  final Map<String, dynamic>? sipsungAnalysis;

  /// 합충형파해 분석
  final Map<String, dynamic>? hapchungAnalysis;

  /// 성격 분석
  final AiPersonality personality;

  /// 강점 (하위 호환용)
  final List<String> strengths;

  /// 약점 (하위 호환용)
  final List<String> weaknesses;

  /// 재물운
  final AiWealth? wealth;

  /// 연애운
  final AiLove? love;

  /// 결혼운
  final AiMarriage? marriage;

  /// 진로/직장운
  final AiCareer career;

  /// 사업운
  final AiBusiness? business;

  /// 건강운
  final AiHealth? health;

  /// 신살/길성 분석
  final Map<String, dynamic>? sinsalGilseong;

  /// 인생 주기별 전망
  final Map<String, dynamic>? lifeCycles;

  /// 대인관계 (하위 호환용)
  final AiRelationships relationships;

  /// 종합 조언
  final String? overallAdvice;

  /// 행운 요소 (색상, 방향, 숫자 등)
  final AiLuckyElements? luckyElements;

  /// 개운법 (하위 호환용)
  final AiFortuneTips fortuneTips;

  final DateTime? generatedAt;
  final String? model;
  final String version;

  AiSummary({
    this.sajuOrigin,
    this.summary,
    this.wonGukAnalysis,
    this.sipsungAnalysis,
    this.hapchungAnalysis,
    required this.personality,
    required this.strengths,
    required this.weaknesses,
    this.wealth,
    this.love,
    this.marriage,
    required this.career,
    this.business,
    this.health,
    this.sinsalGilseong,
    this.lifeCycles,
    required this.relationships,
    this.overallAdvice,
    this.luckyElements,
    required this.fortuneTips,
    this.generatedAt,
    this.model,
    this.version = '2.0',
  });

  factory AiSummary.fromJson(Map<String, dynamic> json) {
    return AiSummary(
      sajuOrigin: json['saju_origin'] as Map<String, dynamic>?,
      summary: json['summary']?.toString(),
      wonGukAnalysis: json['wonGuk_analysis'] as Map<String, dynamic>?,
      sipsungAnalysis: json['sipsung_analysis'] as Map<String, dynamic>?,
      hapchungAnalysis: json['hapchung_analysis'] as Map<String, dynamic>?,
      personality: AiPersonality.fromJson(
        json['personality'] as Map<String, dynamic>? ?? {},
      ),
      strengths: (json['strengths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          // 하위 호환: personality.strengths에서 가져오기
          (json['personality']?['strengths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      weaknesses: (json['weaknesses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          // 하위 호환: personality.weaknesses에서 가져오기
          (json['personality']?['weaknesses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      wealth: json['wealth'] != null
          ? AiWealth.fromJson(json['wealth'] as Map<String, dynamic>)
          : null,
      love: json['love'] != null
          ? AiLove.fromJson(json['love'] as Map<String, dynamic>)
          : null,
      marriage: json['marriage'] != null
          ? AiMarriage.fromJson(json['marriage'] as Map<String, dynamic>)
          : null,
      career: AiCareer.fromJson(
        json['career'] as Map<String, dynamic>? ?? {},
      ),
      business: json['business'] != null
          ? AiBusiness.fromJson(json['business'] as Map<String, dynamic>)
          : null,
      health: json['health'] != null
          ? AiHealth.fromJson(json['health'] as Map<String, dynamic>)
          : null,
      sinsalGilseong: json['sinsal_gilseong'] as Map<String, dynamic>?,
      lifeCycles: json['life_cycles'] as Map<String, dynamic>?,
      relationships: AiRelationships.fromJson(
        json['relationships'] as Map<String, dynamic>? ?? {},
      ),
      overallAdvice: json['overall_advice']?.toString(),
      luckyElements: json['lucky_elements'] != null
          ? AiLuckyElements.fromJson(json['lucky_elements'] as Map<String, dynamic>)
          : null,
      fortuneTips: AiFortuneTips.fromJson(
        json['fortune_tips'] as Map<String, dynamic>? ??
        // 하위 호환: lucky_elements에서 변환
        _convertLuckyToFortuneTips(json['lucky_elements']),
      ),
      generatedAt: json['generated_at'] != null
          ? DateTime.tryParse(json['generated_at'].toString())
          : null,
      model: json['model']?.toString(),
      version: json['version']?.toString() ?? '2.0',
    );
  }

  /// lucky_elements를 fortune_tips 형식으로 변환 (하위 호환용)
  static Map<String, dynamic> _convertLuckyToFortuneTips(dynamic luckyElements) {
    if (luckyElements == null) return {};
    if (luckyElements is! Map) return {};

    return {
      'colors': luckyElements['colors'] ?? [],
      'directions': luckyElements['directions'] ?? [],
      'activities': [], // lucky_elements에는 activities가 없음
    };
  }

  Map<String, dynamic> toJson() {
    return {
      if (sajuOrigin != null) 'saju_origin': sajuOrigin,
      if (summary != null) 'summary': summary,
      if (wonGukAnalysis != null) 'wonGuk_analysis': wonGukAnalysis,
      if (sipsungAnalysis != null) 'sipsung_analysis': sipsungAnalysis,
      if (hapchungAnalysis != null) 'hapchung_analysis': hapchungAnalysis,
      'personality': personality.toJson(),
      'strengths': strengths,
      'weaknesses': weaknesses,
      if (wealth != null) 'wealth': wealth!.toJson(),
      if (love != null) 'love': love!.toJson(),
      if (marriage != null) 'marriage': marriage!.toJson(),
      'career': career.toJson(),
      if (business != null) 'business': business!.toJson(),
      if (health != null) 'health': health!.toJson(),
      if (sinsalGilseong != null) 'sinsal_gilseong': sinsalGilseong,
      if (lifeCycles != null) 'life_cycles': lifeCycles,
      'relationships': relationships.toJson(),
      if (overallAdvice != null) 'overall_advice': overallAdvice,
      if (luckyElements != null) 'lucky_elements': luckyElements!.toJson(),
      'fortune_tips': fortuneTips.toJson(),
      if (generatedAt != null) 'generated_at': generatedAt!.toIso8601String(),
      if (model != null) 'model': model,
      'version': version,
    };
  }
}

/// 성격 정보
class AiPersonality {
  final String core;
  final List<String> traits;

  AiPersonality({
    required this.core,
    required this.traits,
  });

  factory AiPersonality.fromJson(Map<String, dynamic> json) {
    return AiPersonality(
      core: json['core']?.toString() ?? '',
      traits: (json['traits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'core': core,
      'traits': traits,
    };
  }
}

/// 진로 정보
class AiCareer {
  final List<String> aptitude;
  final String advice;

  AiCareer({
    required this.aptitude,
    required this.advice,
  });

  factory AiCareer.fromJson(Map<String, dynamic> json) {
    return AiCareer(
      aptitude: (json['aptitude'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      advice: json['advice']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aptitude': aptitude,
      'advice': advice,
    };
  }
}

/// 대인관계 정보
class AiRelationships {
  final String style;
  final String tips;

  AiRelationships({
    required this.style,
    required this.tips,
  });

  factory AiRelationships.fromJson(Map<String, dynamic> json) {
    return AiRelationships(
      style: json['style']?.toString() ?? '',
      tips: json['tips']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'style': style,
      'tips': tips,
    };
  }
}

/// 개운법 정보
class AiFortuneTips {
  final List<String> colors;
  final List<String> directions;
  final List<String> activities;

  AiFortuneTips({
    required this.colors,
    required this.directions,
    required this.activities,
  });

  factory AiFortuneTips.fromJson(Map<String, dynamic> json) {
    return AiFortuneTips(
      colors: (json['colors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      directions: (json['directions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      activities: (json['activities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'colors': colors,
      'directions': directions,
      'activities': activities,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 확장 모델 클래스 (v2.0)
// ═══════════════════════════════════════════════════════════════════════════════

/// 재물운 정보
class AiWealth {
  final String? overallTendency;
  final String? earningStyle;
  final String? spendingTendency;
  final String? investmentAptitude;
  final String? wealthTiming;
  final List<String> cautions;
  final String? advice;

  AiWealth({
    this.overallTendency,
    this.earningStyle,
    this.spendingTendency,
    this.investmentAptitude,
    this.wealthTiming,
    this.cautions = const [],
    this.advice,
  });

  factory AiWealth.fromJson(Map<String, dynamic> json) {
    return AiWealth(
      overallTendency: json['overall_tendency']?.toString(),
      earningStyle: json['earning_style']?.toString(),
      spendingTendency: json['spending_tendency']?.toString(),
      investmentAptitude: json['investment_aptitude']?.toString(),
      wealthTiming: json['wealth_timing']?.toString(),
      cautions: (json['cautions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      advice: json['advice']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (overallTendency != null) 'overall_tendency': overallTendency,
      if (earningStyle != null) 'earning_style': earningStyle,
      if (spendingTendency != null) 'spending_tendency': spendingTendency,
      if (investmentAptitude != null) 'investment_aptitude': investmentAptitude,
      if (wealthTiming != null) 'wealth_timing': wealthTiming,
      'cautions': cautions,
      if (advice != null) 'advice': advice,
    };
  }
}

/// 연애운 정보
class AiLove {
  final String? attractionStyle;
  final String? datingPattern;
  final List<String> romanticStrengths;
  final List<String> romanticWeaknesses;
  final List<String> idealPartnerTraits;
  final String? loveTiming;
  final String? advice;

  AiLove({
    this.attractionStyle,
    this.datingPattern,
    this.romanticStrengths = const [],
    this.romanticWeaknesses = const [],
    this.idealPartnerTraits = const [],
    this.loveTiming,
    this.advice,
  });

  factory AiLove.fromJson(Map<String, dynamic> json) {
    return AiLove(
      attractionStyle: json['attraction_style']?.toString(),
      datingPattern: json['dating_pattern']?.toString(),
      romanticStrengths: (json['romantic_strengths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      romanticWeaknesses: (json['romantic_weaknesses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      idealPartnerTraits: (json['ideal_partner_traits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      loveTiming: json['love_timing']?.toString(),
      advice: json['advice']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (attractionStyle != null) 'attraction_style': attractionStyle,
      if (datingPattern != null) 'dating_pattern': datingPattern,
      'romantic_strengths': romanticStrengths,
      'romantic_weaknesses': romanticWeaknesses,
      'ideal_partner_traits': idealPartnerTraits,
      if (loveTiming != null) 'love_timing': loveTiming,
      if (advice != null) 'advice': advice,
    };
  }
}

/// 결혼운 정보
class AiMarriage {
  final String? spousePalaceAnalysis;
  final String? marriageTiming;
  final String? spouseCharacteristics;
  final String? marriedLifeTendency;
  final List<String> cautions;
  final String? advice;

  AiMarriage({
    this.spousePalaceAnalysis,
    this.marriageTiming,
    this.spouseCharacteristics,
    this.marriedLifeTendency,
    this.cautions = const [],
    this.advice,
  });

  factory AiMarriage.fromJson(Map<String, dynamic> json) {
    return AiMarriage(
      spousePalaceAnalysis: json['spouse_palace_analysis']?.toString(),
      marriageTiming: json['marriage_timing']?.toString(),
      spouseCharacteristics: json['spouse_characteristics']?.toString(),
      marriedLifeTendency: json['married_life_tendency']?.toString(),
      cautions: (json['cautions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      advice: json['advice']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (spousePalaceAnalysis != null) 'spouse_palace_analysis': spousePalaceAnalysis,
      if (marriageTiming != null) 'marriage_timing': marriageTiming,
      if (spouseCharacteristics != null) 'spouse_characteristics': spouseCharacteristics,
      if (marriedLifeTendency != null) 'married_life_tendency': marriedLifeTendency,
      'cautions': cautions,
      if (advice != null) 'advice': advice,
    };
  }
}

/// 사업운 정보
class AiBusiness {
  final String? entrepreneurshipAptitude;
  final List<String> suitableBusinessTypes;
  final String? businessPartnerTraits;
  final List<String> cautions;
  final List<String> successFactors;
  final String? advice;

  AiBusiness({
    this.entrepreneurshipAptitude,
    this.suitableBusinessTypes = const [],
    this.businessPartnerTraits,
    this.cautions = const [],
    this.successFactors = const [],
    this.advice,
  });

  factory AiBusiness.fromJson(Map<String, dynamic> json) {
    return AiBusiness(
      entrepreneurshipAptitude: json['entrepreneurship_aptitude']?.toString(),
      suitableBusinessTypes: (json['suitable_business_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      businessPartnerTraits: json['business_partner_traits']?.toString(),
      cautions: (json['cautions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      successFactors: (json['success_factors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      advice: json['advice']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (entrepreneurshipAptitude != null) 'entrepreneurship_aptitude': entrepreneurshipAptitude,
      'suitable_business_types': suitableBusinessTypes,
      if (businessPartnerTraits != null) 'business_partner_traits': businessPartnerTraits,
      'cautions': cautions,
      'success_factors': successFactors,
      if (advice != null) 'advice': advice,
    };
  }
}

/// 건강운 정보
class AiHealth {
  final List<String> vulnerableOrgans;
  final List<String> potentialIssues;
  final String? mentalHealth;
  final List<String> lifestyleAdvice;
  final String? cautionPeriods;

  AiHealth({
    this.vulnerableOrgans = const [],
    this.potentialIssues = const [],
    this.mentalHealth,
    this.lifestyleAdvice = const [],
    this.cautionPeriods,
  });

  factory AiHealth.fromJson(Map<String, dynamic> json) {
    return AiHealth(
      vulnerableOrgans: (json['vulnerable_organs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      potentialIssues: (json['potential_issues'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mentalHealth: json['mental_health']?.toString(),
      lifestyleAdvice: (json['lifestyle_advice'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      cautionPeriods: json['caution_periods']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vulnerable_organs': vulnerableOrgans,
      'potential_issues': potentialIssues,
      if (mentalHealth != null) 'mental_health': mentalHealth,
      'lifestyle_advice': lifestyleAdvice,
      if (cautionPeriods != null) 'caution_periods': cautionPeriods,
    };
  }
}

/// 행운 요소 정보
class AiLuckyElements {
  final List<String> colors;
  final List<String> directions;
  final List<int> numbers;
  final String? seasons;
  final List<String> partnerElements;

  AiLuckyElements({
    this.colors = const [],
    this.directions = const [],
    this.numbers = const [],
    this.seasons,
    this.partnerElements = const [],
  });

  factory AiLuckyElements.fromJson(Map<String, dynamic> json) {
    return AiLuckyElements(
      colors: (json['colors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      directions: (json['directions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      numbers: (json['numbers'] as List<dynamic>?)
              ?.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
              .toList() ??
          [],
      seasons: json['seasons']?.toString(),
      partnerElements: (json['partner_elements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'colors': colors,
      'directions': directions,
      'numbers': numbers,
      if (seasons != null) 'seasons': seasons,
      'partner_elements': partnerElements,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FilteredAiSummary - Intent Routing용 필터링
// ═══════════════════════════════════════════════════════════════════════════════

/// 필터링된 AI Summary (토큰 최적화)
///
/// 사용자 질문 의도에 따라 필요한 섹션만 포함
/// 예: "연애운" 질문 → love 섹션만 포함 (~85% 토큰 절약)
class FilteredAiSummary {
  final AiSummary original;
  final IntentClassificationResult classification;

  FilteredAiSummary({
    required this.original,
    required this.classification,
  });

  /// 필터링된 섹션만 JSON으로 변환
  Map<String, dynamic> toFilteredJson() {
    final result = <String, dynamic>{
      'version': original.version,
      'model': original.model,
    };

    // 사주 원본은 항상 포함 (합충형파해 등 기본 정보)
    if (original.sajuOrigin != null) {
      result['saju_origin'] = original.sajuOrigin;
    }

    // 원국 분석도 항상 포함 (기본 사주 구조)
    if (original.wonGukAnalysis != null) {
      result['wonGuk_analysis'] = original.wonGukAnalysis;
    }

    final intent = classification;

    // PERSONALITY 또는 GENERAL
    if (intent.shouldInclude(SummaryCategory.personality) ||
        intent.shouldInclude(SummaryCategory.general)) {
      result['personality'] = original.personality.toJson();
      result['strengths'] = original.strengths;
      result['weaknesses'] = original.weaknesses;
    }

    // LOVE
    if (intent.shouldInclude(SummaryCategory.love) && original.love != null) {
      result['love'] = original.love!.toJson();
    }

    // MARRIAGE
    if (intent.shouldInclude(SummaryCategory.marriage) &&
        original.marriage != null) {
      result['marriage'] = original.marriage!.toJson();
    }

    // CAREER
    if (intent.shouldInclude(SummaryCategory.career)) {
      result['career'] = original.career.toJson();
    }

    // BUSINESS
    if (intent.shouldInclude(SummaryCategory.business) &&
        original.business != null) {
      result['business'] = original.business!.toJson();
    }

    // WEALTH
    if (intent.shouldInclude(SummaryCategory.wealth) &&
        original.wealth != null) {
      result['wealth'] = original.wealth!.toJson();
    }

    // HEALTH
    if (intent.shouldInclude(SummaryCategory.health) &&
        original.health != null) {
      result['health'] = original.health!.toJson();
    }

    // GENERAL이면 종합 조언도 포함
    if (intent.shouldInclude(SummaryCategory.general)) {
      if (original.overallAdvice != null) {
        result['overall_advice'] = original.overallAdvice;
      }
      if (original.luckyElements != null) {
        result['lucky_elements'] = original.luckyElements!.toJson();
      }
    }

    return result;
  }

  /// 토큰 절약 예상치 (%)
  int get estimatedTokenSavings {
    const totalCategories = 7; // personality, love, marriage, career, business, wealth, health
    final includedCategories = classification.categories.length;

    if (classification.categories.contains(SummaryCategory.general)) {
      return 0; // 전체 포함
    }

    return ((totalCategories - includedCategories) / totalCategories * 100)
        .round();
  }
}
