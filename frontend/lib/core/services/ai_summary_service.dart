import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import '../../features/saju_chart/domain/entities/saju_analysis.dart';
import '../../features/saju_chart/data/constants/sipsin_relations.dart';

/// AI Summary 서비스 - Supabase Edge Function 호출
///
/// generate-ai-summary Edge Function을 통해 Gemini AI로 사주 요약 생성
class AiSummaryService {
  static const String _functionName = 'generate-ai-summary';

  /// AI Summary 생성 또는 캐시된 데이터 조회
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

      // 요청 바디 구성
      final body = <String, dynamic>{
        'profile_id': profileId,
        'profile_name': profileName,
        'birth_date': birthDate,
        'saju_analysis': _convertSajuAnalysis(sajuAnalysis),
        'force_regenerate': forceRegenerate,
      };

      if (kDebugMode) {
        print('[AiSummaryService] Edge Function 호출: $_functionName');
        print('[AiSummaryService] Profile: $profileId');
      }

      // Edge Function 호출
      final response = await client.functions.invoke(
        _functionName,
        body: body,
      );

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

      final aiSummary = AiSummary.fromJson(
        data['ai_summary'] as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print('[AiSummaryService] 생성 완료 (cached: ${data['cached']})');
      }

      return AiSummaryResult.success(
        summary: aiSummary,
        cached: data['cached'] == true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[AiSummaryService] Exception: $e');
      }
      return AiSummaryResult.failure(e.toString());
    }
  }

  /// DB에서 기존 AI Summary 조회
  ///
  /// Edge Function 호출 없이 DB에서 직접 조회
  static Future<AiSummary?> getCachedSummary(String profileId) async {
    try {
      final client = SupabaseService.client;
      if (client == null) return null;

      final response = await client
          .from('saju_analyses')
          .select('ai_summary')
          .eq('profile_id', profileId)
          .maybeSingle();

      if (response == null || response['ai_summary'] == null) {
        return null;
      }

      return AiSummary.fromJson(response['ai_summary'] as Map<String, dynamic>);
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
          .from('saju_analyses')
          .select('ai_summary')
          .eq('profile_id', profileId)
          .maybeSingle();

      return response != null && response['ai_summary'] != null;
    } catch (e) {
      return false;
    }
  }

  /// SajuAnalysis 엔티티를 Edge Function 형식으로 변환
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

/// AI Summary 결과
class AiSummaryResult {
  final AiSummary? summary;
  final bool cached;
  final String? error;

  AiSummaryResult._({
    this.summary,
    this.cached = false,
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

  bool get isSuccess => error == null && summary != null;
}

/// AI Summary 데이터 모델
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
