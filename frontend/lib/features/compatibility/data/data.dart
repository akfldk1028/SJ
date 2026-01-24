/// Compatibility Data Layer
///
/// 궁합 분석 데이터 접근 모듈
///
/// 사용법:
/// ```dart
/// import 'package:saju_app/features/compatibility/data/data.dart';
///
/// // 궁합 분석 조회
/// final result = await compatibilityQueries.getByProfilePair(
///   myProfileId,
///   targetProfileId,
/// );
///
/// // 궁합 분석 생성
/// final created = await compatibilityMutations.create(
///   profile1Id: myProfileId,
///   profile2Id: targetProfileId,
///   analysisType: 'love',
///   overallScore: 85,
/// );
/// ```
library;

// Schema
export 'compatibility_schema.dart';

// Queries & Mutations
export 'compatibility_queries.dart';
export 'compatibility_mutations.dart';

// Models
export 'models/compatibility_analysis_model.dart';
