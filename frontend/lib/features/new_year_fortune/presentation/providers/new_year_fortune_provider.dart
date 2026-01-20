import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../AI/fortune/fortune_coordinator.dart';
import '../../../../AI/fortune/yearly_2026/yearly_2026_queries.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

part 'new_year_fortune_provider.g.dart';

/// 2026년 신년운세 데이터 모델 (AI 프롬프트 JSON 구조 일치)
class NewYearFortuneData {
  final int year;
  final String yearGanji;
  final MySajuIntroSection? mySajuIntro;  // v7.0: 나의 사주 소개 추가
  final YearInfoSection yearInfo;
  final PersonalAnalysisSection personalAnalysis;
  final OverviewSection overview;
  final Map<String, CategorySection> categories;
  final TimelineSection timeline;
  final LuckySection lucky;
  final ClosingSection closing;

  const NewYearFortuneData({
    required this.year,
    required this.yearGanji,
    this.mySajuIntro,
    required this.yearInfo,
    required this.personalAnalysis,
    required this.overview,
    required this.categories,
    required this.timeline,
    required this.lucky,
    required this.closing,
  });

  /// AI 응답 JSON에서 파싱
  factory NewYearFortuneData.fromJson(Map<String, dynamic> json) {
    // v7.0: mySajuIntro 파싱
    MySajuIntroSection? mySajuIntro;
    final mySajuIntroJson = json['mySajuIntro'] as Map<String, dynamic>?;
    if (mySajuIntroJson != null) {
      mySajuIntro = MySajuIntroSection(
        title: mySajuIntroJson['title'] as String? ?? '나의 사주, 나는 누구인가요?',
        reading: mySajuIntroJson['reading'] as String? ?? '',
      );
    }

    // yearInfo 파싱
    final yearInfoJson = json['yearInfo'] as Map<String, dynamic>? ?? {};
    final yearInfo = YearInfoSection(
      alias: yearInfoJson['alias'] as String? ?? '붉은 말의 해',
      napeum: yearInfoJson['napeum'] as String? ?? '',
      napeumExplain: yearInfoJson['napeumExplain'] as String? ?? '',
      twelveUnsung: yearInfoJson['twelveUnsung'] as String? ?? '',
      unsungExplain: yearInfoJson['unsungExplain'] as String? ?? '',
      mainSinsal: yearInfoJson['mainSinsal'] as String? ?? '',
      sinsalExplain: yearInfoJson['sinsalExplain'] as String? ?? '',
    );

    // personalAnalysis 파싱
    final personalJson = json['personalAnalysis'] as Map<String, dynamic>? ?? {};
    final personalAnalysis = PersonalAnalysisSection(
      ilgan: personalJson['ilgan'] as String? ?? '',
      ilganExplain: personalJson['ilganExplain'] as String? ?? '',
      fireEffect: personalJson['fireEffect'] as String? ?? '',
      yongshinMatch: personalJson['yongshinMatch'] as String? ?? '',
      hapchungEffect: personalJson['hapchungEffect'] as String? ?? '',
      sinsalEffect: personalJson['sinsalEffect'] as String? ?? '',
    );

    // overview 파싱
    final overviewJson = json['overview'] as Map<String, dynamic>? ?? {};
    final overview = OverviewSection(
      keyword: overviewJson['keyword'] as String? ?? '',
      score: (overviewJson['score'] as num?)?.toInt() ?? 0,
      summary: overviewJson['summary'] as String? ?? '',
      keyPoint: overviewJson['keyPoint'] as String? ?? '',
    );

    // categories 파싱
    final categoriesJson = json['categories'] as Map<String, dynamic>? ?? {};
    final categories = <String, CategorySection>{};
    for (final key in ['career', 'business', 'wealth', 'love', 'marriage', 'study', 'health']) {
      final catJson = categoriesJson[key] as Map<String, dynamic>?;
      if (catJson != null) {
        categories[key] = CategorySection(
          title: catJson['title'] as String? ?? '',
          icon: catJson['icon'] as String? ?? '',
          score: (catJson['score'] as num?)?.toInt() ?? 0,
          summary: catJson['summary'] as String? ?? '',
          reading: catJson['reading'] as String? ?? '',
          bestMonths: _parseIntList(catJson['bestMonths']),
          cautionMonths: _parseIntList(catJson['cautionMonths']),
          actionTip: catJson['actionTip'] as String? ?? '',
          focusAreas: _parseStringList(catJson['focusAreas']),
        );
      }
    }

    // timeline 파싱
    final timelineJson = json['timeline'] as Map<String, dynamic>? ?? {};
    final timeline = TimelineSection(
      q1: _parseQuarter(timelineJson['q1']),
      q2: _parseQuarter(timelineJson['q2']),
      q3: _parseQuarter(timelineJson['q3']),
      q4: _parseQuarter(timelineJson['q4']),
    );

    // lucky 파싱
    final luckyJson = json['lucky'] as Map<String, dynamic>? ?? {};
    final lucky = LuckySection(
      colors: _parseStringList(luckyJson['colors']),
      numbers: _parseIntList(luckyJson['numbers']),
      direction: luckyJson['direction'] as String? ?? '',
      items: _parseStringList(luckyJson['items']),
    );

    // closing 파싱
    final closingJson = json['closing'] as Map<String, dynamic>? ?? {};
    final closing = ClosingSection(
      yearMessage: closingJson['yearMessage'] as String? ?? '',
      finalAdvice: closingJson['finalAdvice'] as String? ?? '',
    );

    return NewYearFortuneData(
      year: (json['year'] as num?)?.toInt() ?? 2026,
      yearGanji: json['yearGanji'] as String? ?? '병오(丙午)',
      mySajuIntro: mySajuIntro,
      yearInfo: yearInfo,
      personalAnalysis: personalAnalysis,
      overview: overview,
      categories: categories,
      timeline: timeline,
      lucky: lucky,
      closing: closing,
    );
  }

  static QuarterSection _parseQuarter(dynamic value) {
    if (value is Map<String, dynamic>) {
      return QuarterSection(
        period: value['period'] as String? ?? '',
        theme: value['theme'] as String? ?? '',
        score: (value['score'] as num?)?.toInt() ?? 0,
        reading: value['reading'] as String? ?? '',
      );
    }
    return const QuarterSection(period: '', theme: '', score: 0, reading: '');
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
}

/// 연도 정보 섹션
class YearInfoSection {
  final String alias;
  final String napeum;
  final String napeumExplain;
  final String twelveUnsung;
  final String unsungExplain;
  final String mainSinsal;
  final String sinsalExplain;

  const YearInfoSection({
    required this.alias,
    required this.napeum,
    required this.napeumExplain,
    required this.twelveUnsung,
    required this.unsungExplain,
    required this.mainSinsal,
    required this.sinsalExplain,
  });
}

/// 개인 분석 섹션
class PersonalAnalysisSection {
  final String ilgan;
  final String ilganExplain;
  final String fireEffect;
  final String yongshinMatch;
  final String hapchungEffect;
  final String sinsalEffect;

  const PersonalAnalysisSection({
    required this.ilgan,
    required this.ilganExplain,
    required this.fireEffect,
    required this.yongshinMatch,
    required this.hapchungEffect,
    required this.sinsalEffect,
  });
}

/// 개요 섹션
class OverviewSection {
  final String keyword;
  final int score;
  final String summary;
  final String keyPoint;

  const OverviewSection({
    required this.keyword,
    required this.score,
    required this.summary,
    required this.keyPoint,
  });
}

/// 분기 섹션
class QuarterSection {
  final String period;
  final String theme;
  final int score;
  final String reading;

  const QuarterSection({
    required this.period,
    required this.theme,
    required this.score,
    required this.reading,
  });
}

/// 타임라인 섹션
class TimelineSection {
  final QuarterSection q1;
  final QuarterSection q2;
  final QuarterSection q3;
  final QuarterSection q4;

  const TimelineSection({
    required this.q1,
    required this.q2,
    required this.q3,
    required this.q4,
  });

  QuarterSection getQuarter(int index) {
    switch (index) {
      case 0: return q1;
      case 1: return q2;
      case 2: return q3;
      case 3: return q4;
      default: return q1;
    }
  }
}

/// 카테고리 섹션
class CategorySection {
  final String title;
  final String icon;
  final int score;
  final String summary;
  final String reading;
  final List<int> bestMonths;
  final List<int> cautionMonths;
  final String actionTip;
  final List<String> focusAreas;

  const CategorySection({
    required this.title,
    required this.icon,
    required this.score,
    required this.summary,
    required this.reading,
    required this.bestMonths,
    required this.cautionMonths,
    required this.actionTip,
    this.focusAreas = const [],
  });
}

/// 행운 섹션
class LuckySection {
  final List<String> colors;
  final List<int> numbers;
  final String direction;
  final List<String> items;

  const LuckySection({
    required this.colors,
    required this.numbers,
    required this.direction,
    required this.items,
  });
}

/// 마무리 섹션
class ClosingSection {
  final String yearMessage;
  final String finalAdvice;

  const ClosingSection({
    required this.yearMessage,
    required this.finalAdvice,
  });
}

/// v7.0: 나의 사주 소개 섹션
class MySajuIntroSection {
  final String title;
  final String reading;

  const MySajuIntroSection({
    required this.title,
    required this.reading,
  });
}

/// 2026년 신년운세 Provider
///
/// activeProfile의 2026년 신년운세를 DB에서 조회
/// 캐시가 없으면 AI 분석을 자동 트리거하고 폴링으로 완료 감지
@riverpod
class NewYearFortune extends _$NewYearFortune {
  /// 분석 진행 중 플래그 (중복 호출 방지)
  static bool _isAnalyzing = false;

  /// 폴링 활성화 플래그
  bool _isPolling = false;

  @override
  Future<NewYearFortuneData?> build() async {
    final activeProfile = await ref.watch(activeProfileProvider.future);
    if (activeProfile == null) return null;

    final queries = Yearly2026Queries(Supabase.instance.client);
    final result = await queries.getCached(activeProfile.id);

    // 캐시가 있으면 바로 반환
    if (result != null) {
      final content = result['content'];
      if (content is Map<String, dynamic>) {
        print('[NewYearFortune] 캐시 히트 - 2026 신년운세 로드');
        _isPolling = false;
        return NewYearFortuneData.fromJson(content);
      }
    }

    // 캐시가 없으면 AI 분석 트리거
    print('[NewYearFortune] 캐시 없음 - AI 분석 시작');
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

    print('[NewYearFortune] 폴링 시작 - 3초마다 DB 확인');
    _pollForData(profileId);
  }

  /// 주기적으로 DB 확인
  Future<void> _pollForData(String profileId) async {
    if (!_isPolling) return;

    await Future.delayed(const Duration(seconds: 3));
    if (!_isPolling) return;

    final queries = Yearly2026Queries(Supabase.instance.client);
    final result = await queries.getCached(profileId);

    if (result != null && result['content'] != null) {
      print('[NewYearFortune] 폴링 성공 - 데이터 발견! UI 자동 갱신');
      _isPolling = false;
      _isAnalyzing = false;
      ref.invalidateSelf();
    } else {
      // 데이터 없으면 계속 폴링
      print('[NewYearFortune] 폴링 중 - 데이터 아직 없음');
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
      print('[NewYearFortune] ⏭️ FortuneCoordinator에서 이미 분석 중 - 스킵');
      return;
    }

    if (_isAnalyzing) {
      print('[NewYearFortune] 이미 분석 중 - 스킵');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('[NewYearFortune] 사용자 없음 - 분석 스킵');
      return;
    }

    _isAnalyzing = true;
    print('[NewYearFortune] 🚀 v6.0 Fortune만 즉시 분석 시작! (saju_base 대기 없음)');

    // v6.0: Fortune만 직접 분석 (saju_base 대기 없음!)
    fortuneCoordinator.analyzeFortuneOnly(
      userId: user.id,
      profileId: profileId,
    ).then((result) {
      _isAnalyzing = false;
      print('[NewYearFortune] ✅ Fortune 분석 완료');
      print('  - yearly2026: ${result.yearly2026 != null ? "성공" : "실패"}');
      print('  - yearly2025: ${result.yearly2025 != null ? "성공" : "실패"}');
      print('  - monthly: ${result.monthly != null ? "성공" : "실패"}');
      // 폴링이 데이터를 감지하고 UI를 갱신할 것임
    }).catchError((e) {
      _isAnalyzing = false;
      print('[NewYearFortune] ❌ Fortune 분석 오류: $e');
    });
  }

  /// 운세 새로고침 (캐시 무효화)
  Future<void> refresh() async {
    _isPolling = false;
    _isAnalyzing = false;
    ref.invalidateSelf();
  }
}
