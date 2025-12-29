/// AI Common Data Layer
///
/// AI 팀원 (JH_AI, Jina)이 데이터에 접근하기 위한 모듈
///
/// 사용법:
/// ```dart
/// import 'package:saju_app/AI/common/data/data.dart';
///
/// // Provider 사용 (권장)
/// final context = await ref.watch(aiContextProvider.future);
///
/// // Context 직접 사용
/// final prompt = context.basicInfoForPrompt;
/// ```

export 'ai_context.dart';
export 'ai_data_provider.dart';
