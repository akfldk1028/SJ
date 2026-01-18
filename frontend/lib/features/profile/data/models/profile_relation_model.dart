import 'package:freezed_annotation/freezed_annotation.dart';
import '../relation_schema.dart';

part 'profile_relation_model.freezed.dart';
part 'profile_relation_model.g.dart';

/// 프로필 관계 데이터 모델
///
/// 두 프로필 간의 관계를 나타냄 (from_profile → to_profile)
/// 예: 나의 프로필 → 엄마 프로필 (relation_type: family_parent)
@freezed
abstract class ProfileRelationModel with _$ProfileRelationModel {
  const factory ProfileRelationModel({
    required String id,
    required String userId,
    required String fromProfileId,
    required String toProfileId,
    required String relationType,
    String? displayName,
    String? memo,
    @Default(false) bool isFavorite,
    @Default(0) int sortOrder,
    required DateTime createdAt,
    required DateTime updatedAt,

    /// JOIN된 to_profile 정보 (optional)
    ProfileRelationTarget? toProfile,

    // === 사주 분석 연결 ===
    /// 나(from_profile)의 사주 분석 ID
    String? fromProfileAnalysisId,

    /// 상대방(to_profile)의 사주 분석 ID
    String? toProfileAnalysisId,

    /// 분석 상태: pending, processing, completed, failed, skipped
    @Default('pending') String analysisStatus,

    /// 분석 요청 시간
    DateTime? analysisRequestedAt,

    // === Phase 51: 궁합 분석 연결 ===
    /// 궁합 분석 결과 ID (compatibility_analyses FK)
    String? compatibilityAnalysisId,

    /// 궁합 분석 완료 시간
    DateTime? analysisCompletedAt,

    /// 두 사람 간 합충형해파 분석 결과 (JSONB)
    /// 구조: {hap: [], chung: [], hyung: [], hae: [], pa: [], wonjin: [],
    ///        overall_score: int, positive_count: int, negative_count: int}
    Map<String, dynamic>? pairHapchung,
  }) = _ProfileRelationModel;

  const ProfileRelationModel._();

  /// JSON 직렬화
  factory ProfileRelationModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileRelationModelFromJson(json);

  /// Supabase 응답에서 생성
  static ProfileRelationModel fromSupabaseMap(Map<String, dynamic> map) {
    ProfileRelationTarget? toProfile;
    if (map['to_profile'] != null) {
      toProfile = ProfileRelationTarget.fromSupabaseMap(
        map['to_profile'] as Map<String, dynamic>,
      );
    }

    return ProfileRelationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      fromProfileId: map['from_profile_id'] as String,
      toProfileId: map['to_profile_id'] as String,
      relationType: map['relation_type'] as String,
      displayName: map['display_name'] as String?,
      memo: map['memo'] as String?,
      isFavorite: map['is_favorite'] as bool? ?? false,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      toProfile: toProfile,
      // 사주 분석 연결
      fromProfileAnalysisId: map['from_profile_analysis_id'] as String?,
      toProfileAnalysisId: map['to_profile_analysis_id'] as String?,
      analysisStatus: map['analysis_status'] as String? ?? 'pending',
      analysisRequestedAt: map['analysis_requested_at'] != null
          ? DateTime.parse(map['analysis_requested_at'] as String)
          : null,
      // Phase 51: 궁합 분석 연결
      compatibilityAnalysisId: map['compatibility_analysis_id'] as String?,
      analysisCompletedAt: map['analysis_completed_at'] != null
          ? DateTime.parse(map['analysis_completed_at'] as String)
          : null,
      pairHapchung: map['pair_hapchung'] as Map<String, dynamic>?,
    );
  }

  /// Supabase INSERT/UPDATE용 Map
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'user_id': userId,
      'from_profile_id': fromProfileId,
      'to_profile_id': toProfileId,
      'relation_type': relationType,
      'display_name': displayName,
      'memo': memo,
      'is_favorite': isFavorite,
      'sort_order': sortOrder,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      // 사주 분석 연결
      'from_profile_analysis_id': fromProfileAnalysisId,
      'to_profile_analysis_id': toProfileAnalysisId,
      'analysis_status': analysisStatus,
      'analysis_requested_at': analysisRequestedAt?.toUtc().toIso8601String(),
      // Phase 51: 궁합 분석 연결
      'compatibility_analysis_id': compatibilityAnalysisId,
      'analysis_completed_at': analysisCompletedAt?.toUtc().toIso8601String(),
      'pair_hapchung': pairHapchung,
    };
  }

  /// INSERT용 Map (id, created_at 제외)
  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'from_profile_id': fromProfileId,
      'to_profile_id': toProfileId,
      'relation_type': relationType,
      'display_name': displayName,
      'memo': memo,
      'is_favorite': isFavorite,
      'sort_order': sortOrder,
      // 사주 분석 연결 (초기값)
      'analysis_status': analysisStatus,
    };
  }

  /// 관계 유형 Enum
  ProfileRelationType get relationTypeEnum =>
      ProfileRelationType.fromValue(relationType);

  /// UI 표시용 이름
  /// displayName이 있으면 그걸, 없으면 toProfile.displayName 사용
  String get effectiveDisplayName =>
      displayName ?? toProfile?.displayName ?? '알 수 없음';

  /// 카테고리 라벨 (가족, 연인, 친구, 직장, 기타)
  String get categoryLabel => relationTypeEnum.categoryLabel;

  /// 관계 유형 표시명
  String get relationLabel => relationTypeEnum.displayName;

  /// 궁합 분석용 타입
  String get compatibilityType => relationTypeEnum.compatibilityType;

  // === 분석 상태 헬퍼 ===

  /// 분석 대기 중
  bool get isAnalysisPending => analysisStatus == 'pending';

  /// 분석 처리 중
  bool get isAnalysisProcessing => analysisStatus == 'processing';

  /// 분석 완료
  bool get isAnalysisCompleted => analysisStatus == 'completed';

  /// 분석 실패
  bool get isAnalysisFailed => analysisStatus == 'failed';

  /// 분석 건너뜀
  bool get isAnalysisSkipped => analysisStatus == 'skipped';

  /// 상대방 분석이 있는지
  bool get hasToProfileAnalysis => toProfileAnalysisId != null;

  /// 나의 분석이 있는지
  bool get hasFromProfileAnalysis => fromProfileAnalysisId != null;

  /// 둘 다 분석이 있는지 (궁합 분석 가능)
  bool get canDoCompatibilityAnalysis =>
      hasFromProfileAnalysis && hasToProfileAnalysis;

  // === Phase 51: 궁합 분석 헬퍼 ===

  /// 궁합 분석 결과가 있는지
  bool get hasCompatibilityAnalysis => compatibilityAnalysisId != null;

  /// 두 사람 간 합충형해파가 있는지
  bool get hasPairHapchung => pairHapchung != null;

  /// 궁합 종합 점수 (없으면 null)
  int? get compatibilityScore => pairHapchung?['overall_score'] as int?;

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

/// JOIN된 프로필 정보 (to_profile)
@freezed
abstract class ProfileRelationTarget with _$ProfileRelationTarget {
  const factory ProfileRelationTarget({
    required String id,
    required String displayName,
    required DateTime birthDate,
    required String gender,
    String? relationType,
  }) = _ProfileRelationTarget;

  const ProfileRelationTarget._();

  factory ProfileRelationTarget.fromJson(Map<String, dynamic> json) =>
      _$ProfileRelationTargetFromJson(json);

  static ProfileRelationTarget fromSupabaseMap(Map<String, dynamic> map) {
    return ProfileRelationTarget(
      id: map['id'] as String,
      displayName: map['display_name'] as String,
      birthDate: DateTime.parse(map['birth_date'] as String),
      gender: map['gender'] as String,
      relationType: map['relation_type'] as String?,
    );
  }
}
