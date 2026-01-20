import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../AI/fortune/fortune_coordinator.dart';
import '../../../../AI/fortune/monthly/monthly_queries.dart';
import '../../../../AI/fortune/common/korea_date_utils.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

part 'monthly_fortune_provider.g.dart';

/// 월별 운세 데이터 모델 (v4.0: 12개월 통합)
class MonthlyFortuneData {
  final int year;
  final int month;
  final String monthGanji;
  final OverviewSection overview;
  final Map<String, CategorySection> categories;
  final LuckySection lucky;
  final String closingMessage;
  /// v4.0: 12개월 요약 데이터
  final Map<String, MonthSummary> months;

  const MonthlyFortuneData({
    required this.year,
    required this.month,
    required this.monthGanji,
    required this.overview,
    required this.categories,
    required this.lucky,
    required this.closingMessage,
    required this.months,
  });

  /// AI 응답 JSON에서 파싱 (v4.0: 12개월 통합 구조)
  factory MonthlyFortuneData.fromJson(Map<String, dynamic> json) {
    // v4.0: current 섹션에서 현재 월 데이터 파싱
    final currentJson = json['current'] as Map<String, dynamic>? ?? json;
    final overviewJson = currentJson['overview'] as Map<String, dynamic>? ?? json['overview'] as Map<String, dynamic>? ?? {};

    final overview = OverviewSection(
      score: (overviewJson['score'] as num?)?.toInt() ?? 0,
      keyword: overviewJson['keyword'] as String? ?? '',
      // v4.0: opening, monthEnergy 등이 reading으로 통합됨
      opening: overviewJson['reading'] as String? ?? overviewJson['opening'] as String? ?? '',
      monthEnergy: overviewJson['monthEnergy'] as String? ?? '',
      hapchungEffect: overviewJson['hapchungEffect'] as String? ?? '',
      conclusion: overviewJson['conclusion'] as String? ?? '',
    );

    // v4.0: categories가 current.categories 안에 있거나 루트에 있음
    final categoriesJson = currentJson['categories'] as Map<String, dynamic>? ?? {};
    final categories = <String, CategorySection>{};
    for (final key in ['career', 'business', 'wealth', 'love', 'marriage', 'study', 'health']) {
      // v4.0 구조 또는 기존 구조 모두 지원
      final catJson = categoriesJson[key] as Map<String, dynamic>? ?? json[key] as Map<String, dynamic>? ?? {};
      categories[key] = CategorySection(
        score: (catJson['score'] as num?)?.toInt() ?? 0,
        title: catJson['title'] as String? ?? '',
        reading: catJson['reading'] as String? ?? '',
      );
    }

    // v4.0: lucky가 current.lucky 안에 있거나 루트에 있음
    final luckyJson = currentJson['lucky'] as Map<String, dynamic>? ?? json['lucky'] as Map<String, dynamic>? ?? {};
    final lucky = LuckySection(
      colors: _parseStringList(luckyJson['colors']),
      numbers: _parseIntList(luckyJson['numbers']),
      foods: _parseStringList(luckyJson['foods']),
      tip: luckyJson['tip'] as String? ?? '',
    );

    // v4.0: 12개월 요약 데이터 파싱
    final monthsJson = json['months'] as Map<String, dynamic>? ?? {};
    final months = <String, MonthSummary>{};
    for (int i = 1; i <= 12; i++) {
      final monthKey = 'month$i';
      final monthJson = monthsJson[monthKey] as Map<String, dynamic>?;
      if (monthJson != null) {
        months[monthKey] = MonthSummary(
          keyword: monthJson['keyword'] as String? ?? '',
          score: (monthJson['score'] as num?)?.toInt() ?? 0,
          reading: monthJson['reading'] as String? ?? '',
        );
      }
    }

    // closing 파싱 (v4.0: closingMessage가 루트에 있거나 closing.message에 있음)
    final closingMessage = json['closingMessage'] as String? ??
        (json['closing'] as Map<String, dynamic>?)?['message'] as String? ?? '';

    return MonthlyFortuneData(
      year: (json['year'] as num?)?.toInt() ?? KoreaDateUtils.currentYear,
      month: (json['currentMonth'] as num?)?.toInt() ?? (json['month'] as num?)?.toInt() ?? KoreaDateUtils.currentMonth,
      monthGanji: currentJson['monthGanji'] as String? ?? json['monthGanji'] as String? ?? '',
      overview: overview,
      categories: categories,
      lucky: lucky,
      closingMessage: closingMessage,
      months: months,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static List<int> _parseIntList(dynamic value) {
    if (value is List) {
      return value.map((e) => (e as num).toInt()).toList();
    }
    return [];
  }

  /// 카테고리 점수 가져오기
  int getCategoryScore(String category) {
    return categories[category]?.score ?? 0;
  }

  /// 월 이름 (한글)
  String get monthName => '$month월';
}

/// 개요 섹션
class OverviewSection {
  final int score;
  final String keyword;
  final String opening;
  final String monthEnergy;
  final String hapchungEffect;
  final String conclusion;

  const OverviewSection({
    required this.score,
    required this.keyword,
    required this.opening,
    required this.monthEnergy,
    required this.hapchungEffect,
    required this.conclusion,
  });
}

/// 카테고리별 운세 섹션
class CategorySection {
  final int score;
  final String title;
  final String reading;

  const CategorySection({
    required this.score,
    required this.title,
    required this.reading,
  });
}

/// 월별 요약 데이터 (v4.0: 12개월 통합)
class MonthSummary {
  final String keyword;
  final int score;
  final String reading;

  const MonthSummary({
    required this.keyword,
    required this.score,
    required this.reading,
  });
}

/// 행운 섹션
class LuckySection {
  final List<String> colors;
  final List<int> numbers;
  final List<String> foods;
  final String tip;

  const LuckySection({
    required this.colors,
    required this.numbers,
    required this.foods,
    required this.tip,
  });
}

/// 월별 운세 Provider
///
/// activeProfile의 이번 달 운세를 DB에서 조회
/// 캐시가 없으면 AI 분석을 자동 트리거하고 폴링으로 완료 감지
@riverpod
class MonthlyFortune extends _$MonthlyFortune {
  /// 분석 진행 중 플래그 (중복 호출 방지)
  static bool _isAnalyzing = false;

  /// 폴링 활성화 플래그
  bool _isPolling = false;

  @override
  Future<MonthlyFortuneData?> build() async {
    final activeProfile = await ref.watch(activeProfileProvider.future);
    if (activeProfile == null) return null;

    final queries = MonthlyQueries(Supabase.instance.client);
    final result = await queries.getCurrentMonth(activeProfile.id);

    // 캐시가 있으면 바로 반환
    if (result != null) {
      final content = result['content'];
      if (content is Map<String, dynamic>) {
        print('[MonthlyFortune] 캐시 히트 - 월운 로드');
        _isPolling = false;
        return MonthlyFortuneData.fromJson(content);
      }
    }

    // 캐시가 없으면 AI 분석 트리거
    print('[MonthlyFortune] 캐시 없음 - AI 분석 시작');
    await _triggerAnalysisIfNeeded(activeProfile.id);

    // 폴링 시작 (3초마다 DB 확인)
    _startPolling(activeProfile.id);

    // 분석 완료 후 다시 조회 (null 반환하면 UI에서 "분석 중" 표시)
    return null;
  }

  /// DB 폴링 시작 (AI 분석 완료 감지)
  void _startPolling(String profileId) {
    if (_isPolling) return;
    _isPolling = true;

    print('[MonthlyFortune] 폴링 시작 - 3초마다 DB 확인');
    _pollForData(profileId);
  }

  /// 주기적으로 DB 확인
  Future<void> _pollForData(String profileId) async {
    if (!_isPolling) return;

    await Future.delayed(const Duration(seconds: 3));
    if (!_isPolling) return;

    final queries = MonthlyQueries(Supabase.instance.client);
    final result = await queries.getCurrentMonth(profileId);

    if (result != null && result['content'] != null) {
      print('[MonthlyFortune] 폴링 성공 - 데이터 발견! UI 자동 갱신');
      _isPolling = false;
      _isAnalyzing = false;
      ref.invalidateSelf();
    } else {
      // 데이터 없으면 계속 폴링
      print('[MonthlyFortune] 폴링 중 - 데이터 아직 없음');
      _pollForData(profileId);
    }
  }

  /// AI 분석 트리거 (v6.1: 전역 중복 방지!)
  ///
  /// ## v6.0 변경 (2026-01-20) ⭐
  /// - sajuAnalysisService.analyzeOnProfileSave() → fortuneCoordinator.analyzeFortuneOnly()
  /// - saju_base(140초) 대기 없이 Fortune만 즉시 분석!
  ///
  /// ## v6.1 변경 (2026-01-20) ⭐
  /// - FortuneCoordinator.isAnalyzing() 전역 중복 체크 추가
  /// - SajuAnalysisService와 Provider 간 중복 호출 방지
  Future<void> _triggerAnalysisIfNeeded(String profileId) async {
    // v6.1 전역 중복 체크 (FortuneCoordinator에서 이미 분석 중인지)
    if (FortuneCoordinator.isAnalyzing(profileId)) {
      print('[MonthlyFortune] ⏭️ FortuneCoordinator에서 이미 분석 중 - 스킵');
      return;
    }

    if (_isAnalyzing) {
      print('[MonthlyFortune] 이미 분석 중 - 스킵');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('[MonthlyFortune] 사용자 없음 - 분석 스킵');
      return;
    }

    _isAnalyzing = true;
    print('[MonthlyFortune] 🚀 v6.0 Fortune만 즉시 분석 시작! (saju_base 대기 없음)');

    // v6.0: Fortune만 직접 분석 (saju_base 대기 없음!)
    fortuneCoordinator.analyzeFortuneOnly(
      userId: user.id,
      profileId: profileId,
    ).then((result) {
      _isAnalyzing = false;
      print('[MonthlyFortune] ✅ Fortune 분석 완료');
      print('  - monthly: ${result.monthly != null ? "성공" : "실패"}');
      print('  - yearly2025: ${result.yearly2025 != null ? "성공" : "실패"}');
      print('  - yearly2026: ${result.yearly2026 != null ? "성공" : "실패"}');
      // 폴링이 데이터를 감지하고 UI를 갱신할 것임
    }).catchError((e) {
      _isAnalyzing = false;
      print('[MonthlyFortune] ❌ Fortune 분석 오류: $e');
    });
  }

  /// 운세 새로고침 (캐시 무효화)
  Future<void> refresh() async {
    _isPolling = false;
    _isAnalyzing = false;
    ref.invalidateSelf();
  }
}
