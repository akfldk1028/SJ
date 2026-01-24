import 'package:freezed_annotation/freezed_annotation.dart';
import '../compatibility_schema.dart';

part 'compatibility_analysis_model.freezed.dart';
part 'compatibility_analysis_model.g.dart';

/// 궁합 분석 데이터 모델
///
/// 두 프로필 간의 궁합 분석 결과
/// profile1 (나) → profile2 (인연)
@freezed
abstract class CompatibilityAnalysisModel with _$CompatibilityAnalysisModel {
  const factory CompatibilityAnalysisModel({
    required String id,
    required String profile1Id,
    required String profile2Id,
    required String analysisType,
    String? relationType,
    int? overallScore,
    Map<String, dynamic>? categoryScores,
    Map<String, dynamic>? sajuAnalysis,
    String? summary,
    String? analysisContent,
    List<String>? strengths,
    List<String>? challenges,
    String? advice,
    required DateTime createdAt,
    required DateTime updatedAt,

    // AI 모델 정보
    String? modelProvider,
    String? modelName,
    int? tokensUsed,
    int? processingTimeMs,

    // 합충형해파
    Map<String, dynamic>? ownerHapchung,
    Map<String, dynamic>? pairHapchung,

    // JOIN된 프로필 정보 (optional)
    CompatibilityProfileInfo? profile1,
    CompatibilityProfileInfo? profile2,
  }) = _CompatibilityAnalysisModel;

  const CompatibilityAnalysisModel._();

  /// JSON 직렬화
  factory CompatibilityAnalysisModel.fromJson(Map<String, dynamic> json) =>
      _$CompatibilityAnalysisModelFromJson(json);

  /// Supabase 응답에서 생성
  static CompatibilityAnalysisModel fromSupabaseMap(Map<String, dynamic> map) {
    CompatibilityProfileInfo? profile1;
    CompatibilityProfileInfo? profile2;

    if (map['profile1'] != null) {
      profile1 = CompatibilityProfileInfo.fromSupabaseMap(
        map['profile1'] as Map<String, dynamic>,
      );
    }
    if (map['profile2'] != null) {
      profile2 = CompatibilityProfileInfo.fromSupabaseMap(
        map['profile2'] as Map<String, dynamic>,
      );
    }

    return CompatibilityAnalysisModel(
      id: map['id'] as String,
      profile1Id: map['profile1_id'] as String,
      profile2Id: map['profile2_id'] as String,
      analysisType: map['analysis_type'] as String? ?? 'general',
      relationType: map['relation_type'] as String?,
      overallScore: map['overall_score'] as int?,
      categoryScores: map['category_scores'] as Map<String, dynamic>?,
      sajuAnalysis: map['saju_analysis'] as Map<String, dynamic>?,
      summary: map['summary'] as String?,
      analysisContent: map['analysis_content'] as String?,
      strengths: (map['strengths'] as List<dynamic>?)?.cast<String>(),
      challenges: (map['challenges'] as List<dynamic>?)?.cast<String>(),
      advice: map['advice'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      modelProvider: map['model_provider'] as String?,
      modelName: map['model_name'] as String?,
      tokensUsed: map['tokens_used'] as int?,
      processingTimeMs: map['processing_time_ms'] as int?,
      ownerHapchung: map['owner_hapchung'] as Map<String, dynamic>?,
      pairHapchung: map['pair_hapchung'] as Map<String, dynamic>?,
      profile1: profile1,
      profile2: profile2,
    );
  }

  /// Supabase INSERT/UPDATE용 Map
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'profile1_id': profile1Id,
      'profile2_id': profile2Id,
      'analysis_type': analysisType,
      'relation_type': relationType,
      'overall_score': overallScore,
      'category_scores': categoryScores,
      'saju_analysis': sajuAnalysis,
      'summary': summary,
      'analysis_content': analysisContent,
      'strengths': strengths,
      'challenges': challenges,
      'advice': advice,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'model_provider': modelProvider,
      'model_name': modelName,
      'tokens_used': tokensUsed,
      'processing_time_ms': processingTimeMs,
      'owner_hapchung': ownerHapchung,
      'pair_hapchung': pairHapchung,
    };
  }

  /// 분석 유형 Enum
  CompatibilityAnalysisType get analysisTypeEnum =>
      CompatibilityAnalysisType.fromValue(analysisType);

  /// 분석 유형 표시명
  String get analysisTypeLabel => analysisTypeEnum.displayName;

  /// 점수 등급 (최상/상/중/하)
  String get scoreGrade {
    final score = overallScore ?? 0;
    if (score >= 80) return '최상';
    if (score >= 60) return '상';
    if (score >= 40) return '중';
    return '하';
  }

  /// 점수 색상 (UI용)
  /// 80+ = 핑크, 60+ = 파랑, 40+ = 노랑, 그 외 = 회색
  String get scoreColorCode {
    final score = overallScore ?? 0;
    if (score >= 80) return '#EC4899'; // pink
    if (score >= 60) return '#3B82F6'; // blue
    if (score >= 40) return '#F59E0B'; // amber
    return '#6B7280'; // gray
  }

  // === 합충형해파 헬퍼 ===

  /// 긍정적 요소 개수 (합)
  int get positiveCount => pairHapchung?['positive_count'] as int? ?? 0;

  /// 부정적 요소 개수 (충/형/해/파/원진)
  int get negativeCount => pairHapchung?['negative_count'] as int? ?? 0;

  /// 합 목록
  List<String> get hapList =>
      (pairHapchung?['hap'] as List<dynamic>?)?.cast<String>() ?? [];

  /// 충 목록
  List<String> get chungList =>
      (pairHapchung?['chung'] as List<dynamic>?)?.cast<String>() ?? [];

  /// 형 목록
  List<String> get hyungList =>
      (pairHapchung?['hyung'] as List<dynamic>?)?.cast<String>() ?? [];

  /// 해 목록
  List<String> get haeList =>
      (pairHapchung?['hae'] as List<dynamic>?)?.cast<String>() ?? [];

  /// 파 목록
  List<String> get paList =>
      (pairHapchung?['pa'] as List<dynamic>?)?.cast<String>() ?? [];

  /// 원진 목록
  List<String> get wonjinList =>
      (pairHapchung?['wonjin'] as List<dynamic>?)?.cast<String>() ?? [];
}

/// JOIN된 프로필 정보 (profile1, profile2)
@freezed
abstract class CompatibilityProfileInfo with _$CompatibilityProfileInfo {
  const factory CompatibilityProfileInfo({
    required String id,
    required String displayName,
    required DateTime birthDate,
    required String gender,
  }) = _CompatibilityProfileInfo;

  const CompatibilityProfileInfo._();

  factory CompatibilityProfileInfo.fromJson(Map<String, dynamic> json) =>
      _$CompatibilityProfileInfoFromJson(json);

  static CompatibilityProfileInfo fromSupabaseMap(Map<String, dynamic> map) {
    return CompatibilityProfileInfo(
      id: map['id'] as String,
      displayName: map['display_name'] as String,
      birthDate: DateTime.parse(map['birth_date'] as String),
      gender: map['gender'] as String,
    );
  }

  /// 생년월일 포맷팅 (yyyy.MM.dd)
  String get birthDateFormatted {
    return '${birthDate.year}.${birthDate.month.toString().padLeft(2, '0')}.${birthDate.day.toString().padLeft(2, '0')}';
  }

  /// 성별 표시명
  String get genderLabel => gender == 'male' ? '남' : '여';
}
