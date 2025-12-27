import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../AI/data/queries.dart';
import '../../../../core/supabase/generated/ai_summaries.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

part 'daily_fortune_provider.g.dart';

/// 오늘의 운세 데이터 모델
class DailyFortuneData {
  final int overallScore;
  final String overallMessage;
  final String date;
  final Map<String, CategoryScore> categories;
  final LuckyInfo lucky;
  final String caution;
  final String affirmation;

  const DailyFortuneData({
    required this.overallScore,
    required this.overallMessage,
    required this.date,
    required this.categories,
    required this.lucky,
    required this.caution,
    required this.affirmation,
  });

  /// AI 응답 JSON에서 파싱
  factory DailyFortuneData.fromJson(Map<String, dynamic> json) {
    // categories 파싱
    final categoriesJson = json['categories'] as Map<String, dynamic>? ?? {};
    final categories = <String, CategoryScore>{};

    categoriesJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        categories[key] = CategoryScore(
          score: (value['score'] as num?)?.toInt() ?? 0,
          message: value['message'] as String? ?? '',
          tip: value['tip'] as String? ?? '',
        );
      }
    });

    // lucky 파싱
    final luckyJson = json['lucky'] as Map<String, dynamic>? ?? {};
    final lucky = LuckyInfo(
      time: luckyJson['time'] as String? ?? '',
      color: luckyJson['color'] as String? ?? '',
      number: (luckyJson['number'] as num?)?.toInt() ?? 0,
      direction: luckyJson['direction'] as String? ?? '',
    );

    return DailyFortuneData(
      overallScore: (json['overall_score'] as num?)?.toInt() ?? 0,
      overallMessage: json['overall_message'] as String? ?? '',
      date: json['date'] as String? ?? '',
      categories: categories,
      lucky: lucky,
      caution: json['caution'] as String? ?? '',
      affirmation: json['affirmation'] as String? ?? '',
    );
  }

  /// 카테고리 점수 가져오기
  int getCategoryScore(String category) {
    return categories[category]?.score ?? 0;
  }

  /// 카테고리 메시지 가져오기
  String getCategoryMessage(String category) {
    return categories[category]?.message ?? '';
  }

  /// 카테고리 팁 가져오기
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

/// 오늘의 운세 Provider
///
/// activeProfile의 오늘 운세를 DB에서 조회
@riverpod
class DailyFortune extends _$DailyFortune {
  @override
  Future<DailyFortuneData?> build() async {
    final activeProfile = await ref.watch(activeProfileProvider.future);
    if (activeProfile == null) return null;

    final today = DateTime.now();
    final result = await aiQueries.getDailyFortune(activeProfile.id, today);

    if (result.isFailure || result.data == null) {
      return null;
    }

    final aiSummary = result.data!;
    final content = aiSummary.content;

    if (content == null) return null;

    return DailyFortuneData.fromJson(content as Map<String, dynamic>);
  }

  /// 운세 새로고침 (캐시 무효화)
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// 특정 날짜의 운세 Provider
@riverpod
Future<DailyFortuneData?> dailyFortuneForDate(Ref ref, DateTime date) async {
  final activeProfile = await ref.watch(activeProfileProvider.future);
  if (activeProfile == null) return null;

  final result = await aiQueries.getDailyFortune(activeProfile.id, date);

  if (result.isFailure || result.data == null) {
    return null;
  }

  final aiSummary = result.data!;
  final content = aiSummary.content;

  if (content == null) return null;

  return DailyFortuneData.fromJson(content as Map<String, dynamic>);
}
