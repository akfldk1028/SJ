import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../AI/data/queries.dart';
import '../../../../AI/fortune/fortune_coordinator.dart';
import '../../../../AI/fortune/common/korea_date_utils.dart';
import '../../../../core/supabase/generated/ai_summaries.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

part 'daily_fortune_provider.g.dart';

/// 오늘의 운세 데이터 모델
class DailyFortuneData {
  final int overallScore;
  final String overallMessage;
  final String overallMessageShort;  // 짧은 버전 (오늘의 한마디)
  final String date;
  final Map<String, CategoryScore> categories;
  final LuckyInfo lucky;
  final IdiomInfo idiom;  // 오늘의 사자성어
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

    // idiom 파싱 (오늘의 사자성어)
    final idiomJson = json['idiom'] as Map<String, dynamic>? ?? {};
    final idiom = IdiomInfo(
      chinese: idiomJson['chinese'] as String? ?? '',
      korean: idiomJson['korean'] as String? ?? '',
      meaning: idiomJson['meaning'] as String? ?? '',
      message: idiomJson['message'] as String? ?? '',
    );

    return DailyFortuneData(
      overallScore: (json['overall_score'] as num?)?.toInt() ?? 0,
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

/// 오늘의 사자성어 정보
class IdiomInfo {
  final String chinese;   // 한자 (예: 磨斧爲針)
  final String korean;    // 한글 (예: 마부위침)
  final String meaning;   // 뜻풀이 (예: 도끼를 갈아 바늘을 만든다)
  final String message;   // 오늘에 맞는 메시지 (2-3문장)

  const IdiomInfo({
    required this.chinese,
    required this.korean,
    required this.meaning,
    required this.message,
  });

  /// 빈 사자성어 정보
  static const empty = IdiomInfo(
    chinese: '',
    korean: '',
    meaning: '',
    message: '',
  );

  /// 유효한지 확인
  bool get isValid => korean.isNotEmpty && chinese.isNotEmpty;
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

    // 🔧 한국 시간 기준으로 조회해야 캐시 히트됨 (저장도 한국 시간 기준)
    final today = KoreaDateUtils.today;
    final result = await aiQueries.getDailyFortune(activeProfile.id, today);

    // 캐시가 있으면 바로 반환 + 플래그 리셋
    if (result.isSuccess && result.data != null) {
      final aiSummary = result.data!;
      final content = aiSummary.content;
      if (content != null) {
        // 캐시 히트 시 _isAnalyzing 플래그 리셋 (다른 provider가 분석 완료했을 수 있음)
        _isAnalyzing = false;

        final fortune = DailyFortuneData.fromJson(content as Map<String, dynamic>);
        print('[DailyFortune] idiom 파싱 결과: korean="${fortune.idiom.korean}", chinese="${fortune.idiom.chinese}", isValid=${fortune.idiom.isValid}');

        // idiom이 없는 오래된 캐시인 경우 재분석 필요
        if (!fortune.idiom.isValid) {
          print('[DailyFortune] 캐시 히트 but idiom 없음 - 재분석 필요');
          await _triggerAnalysisIfNeeded(activeProfile.id);
          // 일단 기존 데이터 반환 (idiom만 빠진 상태)
          return fortune;
        }

        print('[DailyFortune] 캐시 히트 - 오늘의 운세 로드');
        return fortune;
      }
    }

    // 캐시가 없으면 AI 분석 트리거
    print('[DailyFortune] 캐시 없음 - AI 분석 시작');
    await _triggerAnalysisIfNeeded(activeProfile.id);

    // 분석 완료 후 다시 조회 (null 반환하면 UI에서 "분석 중" 표시)
    return null;
  }

  /// AI 분석 트리거 (중복 호출 방지)
  ///
  /// FortuneCoordinator.analyzeDailyOnly()를 직접 호출하여
  /// 일운 분석 완료를 확실히 감지합니다.
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
    print('[DailyFortune] 🚀 일운 분석 시작 (FortuneCoordinator 직접 호출)');

    // FortuneCoordinator를 통해 일운만 분석 (sajuAnalysisService 우회)
    // 이렇게 하면 분석 완료를 확실히 감지할 수 있음
    fortuneCoordinator.analyzeDailyOnly(
      userId: user.id,
      profileId: profileId,
    ).then((result) {
      print('[DailyFortune] 📌 일운 분석 완료: success=${result.success}');
      _isAnalyzing = false;

      // Provider 무효화하여 UI 갱신
      ref.invalidateSelf();
    }).catchError((e) {
      print('[DailyFortune] ❌ 일운 분석 오류: $e');
      _isAnalyzing = false;
      ref.invalidateSelf();
    });
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

/// 프로필의 일운이 있는 날짜 목록 Provider (캘린더 마커용)
///
/// ## 용도
/// 캘린더에서 운세가 저장된 날에 마커(점)를 표시하기 위해
/// 해당 프로필의 모든 daily_fortune 날짜를 조회합니다.
///
/// ## 사용 예시
/// ```dart
/// final datesAsync = ref.watch(dailyFortuneDatesProvider);
/// datesAsync.when(
///   data: (dates) => dates.contains(day) ? ['fortune'] : [],
///   ...
/// );
/// ```
@riverpod
Future<List<DateTime>> dailyFortuneDates(Ref ref) async {
  final activeProfile = await ref.watch(activeProfileProvider.future);
  if (activeProfile == null) return [];

  final result = await aiQueries.getDailyFortuneDates(activeProfile.id);
  return result.data ?? [];
}
