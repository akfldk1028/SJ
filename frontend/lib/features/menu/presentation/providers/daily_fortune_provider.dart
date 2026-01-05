import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../AI/data/queries.dart';
import '../../../../AI/services/saju_analysis_service.dart';
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
/// 캐시가 없으면 AI 분석을 자동 트리거
@riverpod
class DailyFortune extends _$DailyFortune {
  /// 분석 진행 중 플래그 (중복 호출 방지)
  static bool _isAnalyzing = false;

  @override
  Future<DailyFortuneData?> build() async {
    final activeProfile = await ref.watch(activeProfileProvider.future);
    if (activeProfile == null) return null;

    final today = DateTime.now();
    final result = await aiQueries.getDailyFortune(activeProfile.id, today);

    // 캐시가 있으면 바로 반환
    if (result.isSuccess && result.data != null) {
      final aiSummary = result.data!;
      final content = aiSummary.content;
      if (content != null) {
        print('[DailyFortune] 캐시 히트 - 오늘의 운세 로드');
        return DailyFortuneData.fromJson(content as Map<String, dynamic>);
      }
    }

    // 캐시가 없으면 AI 분석 트리거
    print('[DailyFortune] 캐시 없음 - AI 분석 시작');
    await _triggerAnalysisIfNeeded(activeProfile.id);

    // 분석 완료 후 다시 조회 (null 반환하면 UI에서 "분석 중" 표시)
    return null;
  }

  /// AI 분석 트리거 (중복 호출 방지)
  Future<void> _triggerAnalysisIfNeeded(String profileId) async {
    if (_isAnalyzing) {
      print('[DailyFortune] 이미 분석 중 - 스킵');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('[DailyFortune] 사용자 없음 - 분석 스킵');
      return;
    }

    _isAnalyzing = true;
    print('[DailyFortune] AI 분석 백그라운드 시작...');

    // 백그라운드로 분석 실행
    sajuAnalysisService.analyzeOnProfileSave(
      userId: user.id,
      profileId: profileId,
      runInBackground: true,
      onComplete: (result) {
        _isAnalyzing = false;
        print('[DailyFortune] AI 분석 완료 - UI 갱신');
        print('  - 평생운세: ${result.sajuBase?.success ?? false}');
        print('  - 오늘운세: ${result.dailyFortune?.success ?? false}');
        // Provider 무효화하여 UI 갱신
        ref.invalidateSelf();
      },
    );
  }

  /// 운세 새로고침 (캐시 무효화)
  Future<void> refresh() async {
    _isAnalyzing = false; // 수동 새로고침 시 플래그 리셋
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
