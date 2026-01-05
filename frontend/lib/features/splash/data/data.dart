/// Splash Data Layer
///
/// Pre-fetch 관련 데이터 접근 모듈
///
/// 사용법:
/// ```dart
/// import 'package:saju_app/features/splash/data/data.dart';
///
/// // Pre-fetch 상태 확인
/// final status = await splashQueries.checkPrefetchStatus(userId);
///
/// // 데이터 로드
/// final data = await splashQueries.prefetchPrimaryData(userId);
/// ```
library;

export 'schema.dart';
export 'queries.dart';
export 'mutations.dart';
