/// Core Data Layer
///
/// Supabase 쿼리/뮤테이션을 위한 공통 인프라
///
/// 사용법:
/// ```dart
/// import 'package:saju_app/core/data/data.dart';
///
/// class ProfileQueries extends BaseQueries {
///   Future<QueryResult<Profile>> getById(String id) async {
///     return safeSingleQuery(
///       query: (client) => client.from('profiles').select().eq('id', id).maybeSingle(),
///       fromJson: Profile.fromJson,
///     );
///   }
/// }
/// ```

export 'query_result.dart';
export 'base_query.dart';
