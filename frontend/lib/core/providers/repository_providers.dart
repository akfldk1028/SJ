import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/saju_profile_repository.dart';
import '../repositories/saju_analysis_repository.dart';
import '../repositories/chat_repository.dart';

part 'repository_providers.g.dart';

/// SajuProfileRepository Provider
@riverpod
SajuProfileRepository sajuProfileRepository(ref) {
  return SajuProfileRepository();
}

/// SajuAnalysisRepository Provider
@riverpod
SajuAnalysisRepository sajuAnalysisRepository(ref) {
  return SajuAnalysisRepository();
}

/// ChatRepository Provider
@riverpod
ChatRepository chatRepository(ref) {
  return ChatRepository();
}
