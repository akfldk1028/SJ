/// Profile Data Layer
///
/// 사주 프로필 및 프로필 관계 데이터 접근 모듈
///
/// 사용법:
/// ```dart
/// import 'package:saju_app/features/profile/data/data.dart';
///
/// // 프로필 조회
/// final profiles = await profileQueries.getAllByUserId(userId);
///
/// // 관계 조회
/// final relations = await relationQueries.getByFromProfile(profileId);
///
/// // 관계 생성
/// final relation = await relationMutations.create(
///   userId: userId,
///   fromProfileId: myProfileId,
///   toProfileId: friendProfileId,
///   relationType: 'friend_close',
/// );
/// ```
library;

// Profile
export 'schema.dart';
export 'queries.dart';
export 'mutations.dart';

// Profile Relations
export 'relation_schema.dart';
export 'relation_queries.dart';
export 'relation_mutations.dart';

// Models
export 'models/saju_profile_model.dart';
export 'models/profile_relation_model.dart';
