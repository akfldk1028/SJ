import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/query_result.dart';
import '../../../../AI/data/queries.dart';
import '../../../../AI/fortune/fortune_coordinator.dart';
import '../../../../AI/fortune/common/korea_date_utils.dart';
import '../../../../core/supabase/generated/ai_summaries.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

part 'daily_fortune_provider.g.dart';

/// 안전한 int 파싱 (num, String 모두 지원)
int _safeInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// 오늘의 운세 데이터 모델
class DailyFortuneData {
  final int overallScore;
  final String overallMessage;
  final String overallMessageShort;
  final String date;
  final Map<String, CategoryScore> categories;
  final LuckyInfo lucky;
  final IdiomInfo idiom;
  final String caution;
  final String affirmation;

  const DailyFortuneData({
    required this.overallScore,
    required this.overallMessage,
    this.overallMessageShort = '',
    required this.date,
    required this.categories,
    required this.lucky,
    this.idiom = IdiomInfo.empty,
    required this.caution,
    required this.affirmation,
  });

  /// AI 응답 JSON에서 파싱
  factory DailyFortuneData.fromJson(Map<String, dynamic> json) {
    final categoriesJson = json['categories'] as Map<String, dynamic>? ?? {};
    final categories = <String, CategoryScore>{};

    categoriesJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        categories[key] = CategoryScore(
          score: _safeInt(value['score']),
          message: value['message'] as String? ?? '',
          tip: value['tip'] as String? ?? '',
        );
      }
    });

    final luckyJson = json['lucky'] as Map<String, dynamic>? ?? {};
    final lucky = LuckyInfo(
      time: luckyJson['time'] as String? ?? '',
      color: luckyJson['color'] as String? ?? '',
      number: _safeInt(luckyJson['number']),
      direction: luckyJson['direction'] as String? ?? '',
    );

    final idiomJson = json['idiom'] as Map<String, dynamic>? ?? {};
    final idiom = IdiomInfo(
      chinese: idiomJson['chinese'] as String? ?? '',
      korean: idiomJson['korean'] as String? ?? '',
      meaning: idiomJson['meaning'] as String? ?? '',
      message: idiomJson['message'] as String? ?? '',
    );

    return DailyFortuneData(
      overallScore: _safeInt(json['overall_score']),
      overallMessage: json['overall_message'] as String? ?? '',
      overallMessageShort: json['overall_message_short'] as String? ?? '',
      date: json['date'] as String? ?? '',
      categories: categories,
      lucky: lucky,
      idiom: idiom,
      caution: json['caution'] as String? ?? '',
      affirmation: json['affirmation'] as String? ?? '',
    );
  }

  int getCategoryScore(String category) {
    return categories[category]?.score ?? 0;
  }

  String getCategoryMessage(String category) {
    return categories[category]?.message ?? '';
  }

  String getCategoryTip(String category) {
    return categories[category]?.tip ?? '';
  }
}

/// 카테고리별 점수
class CategoryScore {
  final int score;
  final String message;
  final String tip;

  const CategoryScore({
    required this.score,
    required this.message,
    required this.tip,
  });
}

/// 행운 정보
class LuckyInfo {
  final String time;
  final String color;
  final int number;
  final String direction;

  const LuckyInfo({
    required this.time,
    required this.color,
    required this.number,
    required this.direction,
  });
}

/// 오늘의 사자성어 정보
class IdiomInfo {
  final String chinese;
  final String korean;
  final String meaning;
  final String message;

  const IdiomInfo({
    required this.chinese,
    required this.korean,
    required this.meaning,
    required this.message,
  });

  static const empty = IdiomInfo(
    chinese: '',
    korean: '',
    meaning: '',
    message: '',
  );

  bool get isValid => korean.isNotEmpty && chinese.isNotEmpty;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Provider
// ═══════════════════════════════════════════════════════════════════════════════

/// 오늘의 운세 Provider
///
/// 로직:
///   1. 활성 프로필로 DB 조회
///   2. 캐시 히트 → 반환
///   3. 캐시 미스 → AI 분석 트리거 (fire-and-forget) → 완료 시 자동 갱신
///
/// 갱신 시점:
///   - 프로필 변경 → profile_provider가 ref.invalidate(dailyFortuneProvider)
///   - 날짜 변경 → app.dart가 ref.invalidate(dailyFortuneProvider)
///   - 수동 → 사용자 탭 → refresh()
///
/// 중복 분석 방지: FortuneCoordinator가 전담 (_analyzingProfiles, _analyzingDaily)
@riverpod
class DailyFortune extends _$DailyFortune {
  @override
  Future<DailyFortuneData?> build() async {
    ref.keepAlive();

    // 1. 프로필 (ref.read: profile 변경 시 profile_provider가 invalidate해줌)
    final profile = await ref.read(activeProfileProvider.future);
    if (profile == null) return null;

    // 2. DB 조회 (한국 시간 기준)
    final today = KoreaDateUtils.today;
    final result = await aiQueries.getDailyFortune(profile.id, today);

    // 3. 캐시 히트 → 반환
    if ((result.isSuccess || result.isOffline) &&
        result.data != null &&
        result.data!.content.isNotEmpty) {
      return DailyFortuneData.fromJson(result.data!.content);
    }

    // 4. 캐시 미스 → 분석 트리거
    _triggerAnalysis(profile.id);
    return null;
  }

  /// AI 분석 트리거 (fire-and-forget)
  ///
  /// FortuneCoordinator가 중복 분석 방지 담당:
  /// - _analyzingProfiles: analyzeFortuneOnly() 실행 중 (profile_provider)
  /// - _analyzingDaily: analyzeDailyOnly() 실행 중
  void _triggerAnalysis(String profileId) {
    // profile_provider에서 이미 분석 중이면 스킵
    // → 완료 시 profile_provider가 ref.invalidate(dailyFortuneProvider) 호출
    if (FortuneCoordinator.isAnalyzing(profileId)) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    fortuneCoordinator.analyzeDailyOnly(
      userId: user.id,
      profileId: profileId,
    ).then((result) {
      if (result.success) {
        ref.invalidateSelf();
      }
    }).catchError((e) {
      print('[DailyFortune] 분석 오류: $e');
    });
  }

  /// 수동 새로고침 (탭하면 재시도)
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// 프로필 변경 시 호출 (profile_provider 호환)
  /// FortuneCoordinator.resetAnalyzingFlagForProfile()이 실제 리셋 처리
  static void resetAnalyzedFlagForProfile(String profileId) {
    // 별도 static 상태 없으므로 no-op
  }
}

/// 특정 날짜의 운세 Provider (캘린더용)
@riverpod
Future<DailyFortuneData?> dailyFortuneForDate(Ref ref, DateTime date) async {
  final activeProfile = await ref.read(activeProfileProvider.future);
  if (activeProfile == null) return null;

  final result = await aiQueries.getDailyFortune(activeProfile.id, date);
  if (result.isFailure || result.data == null) return null;

  final content = result.data!.content;
  if (content.isEmpty) return null;

  return DailyFortuneData.fromJson(content);
}

/// 프로필의 일운이 있는 날짜 목록 Provider (캘린더 마커용)
@riverpod
Future<List<DateTime>> dailyFortuneDates(Ref ref) async {
  final activeProfile = await ref.read(activeProfileProvider.future);
  if (activeProfile == null) return [];

  final result = await aiQueries.getDailyFortuneDates(activeProfile.id);
  return result.data ?? [];
}
