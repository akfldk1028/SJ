import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'quota_service.dart';
import '../../features/saju_chart/domain/entities/saju_analysis.dart';
import '../../features/saju_chart/data/constants/sipsin_relations.dart';
import '../supabase/generated/ai_summaries.dart';

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
      );

      await client
          .from(AiSummaries.table_name)
          .upsert(data, onConflict: 'profile_id,summary_type')
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
          .select('content, model_name')
          .eq('profile_id', profileId)
          .eq('summary_type', _summaryType)
          .maybeSingle();

      if (response == null || response['content'] == null) {
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
/// Gemini 3.0이 생성하는 AI 요약 구조
/// Edge Function의 JSON 응답을 파싱하여 사용
///
/// 포함 정보:
/// - personality: 성격 (핵심 + 특성 목록)
/// - strengths/weaknesses: 강점/약점 목록
/// - career: 진로 적성 + 조언
/// - relationships: 대인관계 스타일 + 팁
/// - fortuneTips: 개운법 (색상/방위/활동)
class AiSummary {
  final AiPersonality personality;
  final List<String> strengths;
  final List<String> weaknesses;
  final AiCareer career;
  final AiRelationships relationships;
  final AiFortuneTips fortuneTips;
  final DateTime? generatedAt;
  final String? model;
  final String version;

  AiSummary({
    required this.personality,
    required this.strengths,
    required this.weaknesses,
    required this.career,
    required this.relationships,
    required this.fortuneTips,
    this.generatedAt,
    this.model,
    this.version = '1.0',
  });

  factory AiSummary.fromJson(Map<String, dynamic> json) {
    return AiSummary(
      personality: AiPersonality.fromJson(
        json['personality'] as Map<String, dynamic>? ?? {},
      ),
      strengths: (json['strengths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      weaknesses: (json['weaknesses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      career: AiCareer.fromJson(
        json['career'] as Map<String, dynamic>? ?? {},
      ),
      relationships: AiRelationships.fromJson(
        json['relationships'] as Map<String, dynamic>? ?? {},
      ),
      fortuneTips: AiFortuneTips.fromJson(
        json['fortune_tips'] as Map<String, dynamic>? ?? {},
      ),
      generatedAt: json['generated_at'] != null
          ? DateTime.tryParse(json['generated_at'].toString())
          : null,
      model: json['model']?.toString(),
      version: json['version']?.toString() ?? '1.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personality': personality.toJson(),
      'strengths': strengths,
      'weaknesses': weaknesses,
      'career': career.toJson(),
      'relationships': relationships.toJson(),
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
