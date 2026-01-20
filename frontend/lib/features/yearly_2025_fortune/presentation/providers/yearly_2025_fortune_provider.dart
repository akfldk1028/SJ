import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../AI/fortune/fortune_coordinator.dart';
import '../../../../AI/fortune/yearly_2025/yearly_2025_queries.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

part 'yearly_2025_fortune_provider.g.dart';

/// 2025년 운세 데이터 모델 (AI 프롬프트 JSON 구조 일치)
class Yearly2025FortuneData {
  final int year;
  final String yearGanji;
  final MySajuIntroSection? mySajuIntro;  // v7.0: 나의 사주 소개 추가
  final OverviewSection overview;
  final AchievementsSection achievements;
  final ChallengesSection challenges;
  final Map<String, CategorySection> categories;
  final TimelineSection timeline;
  final LessonsSection lessons;
  final To2026Section to2026;
  final String closingMessage;

  const Yearly2025FortuneData({
    required this.year,
    required this.yearGanji,
    this.mySajuIntro,
    required this.overview,
    required this.achievements,
    required this.challenges,
    required this.categories,
    required this.timeline,
    required this.lessons,
    required this.to2026,
    required this.closingMessage,
  });

  /// AI 응답 JSON에서 파싱
  factory Yearly2025FortuneData.fromJson(Map<String, dynamic> json) {
    // v7.0: mySajuIntro 파싱
    MySajuIntroSection? mySajuIntro;
    final mySajuIntroJson = json['mySajuIntro'] as Map<String, dynamic>?;
    if (mySajuIntroJson != null) {
      mySajuIntro = MySajuIntroSection(
        title: mySajuIntroJson['title'] as String? ?? '나의 사주, 나는 누구인가요?',
        reading: mySajuIntroJson['reading'] as String? ?? '',
      );
    }

    // overview 파싱
    final overviewJson = json['overview'] as Map<String, dynamic>? ?? {};
    final overview = OverviewSection(
      keyword: overviewJson['keyword'] as String? ?? '',
      score: (overviewJson['score'] as num?)?.toInt() ?? 0,
      opening: overviewJson['opening'] as String? ?? '',
      yearEnergy: overviewJson['yearEnergy'] as String? ?? '',
      hapchungEffect: overviewJson['hapchungEffect'] as String? ?? '',
      conclusion: overviewJson['conclusion'] as String? ?? '',
    );

    // achievements 파싱
    final achievementsJson = json['achievements'] as Map<String, dynamic>? ?? {};
    final achievements = AchievementsSection(
      title: achievementsJson['title'] as String? ?? '2025년의 빛나는 순간들',
      reading: achievementsJson['reading'] as String? ?? '',
      highlights: _parseStringList(achievementsJson['highlights']),
    );

    // challenges 파싱
    final challengesJson = json['challenges'] as Map<String, dynamic>? ?? {};
    final challenges = ChallengesSection(
      title: challengesJson['title'] as String? ?? '2025년의 시련, 그리고 성장',
      reading: challengesJson['reading'] as String? ?? '',
      growthPoints: _parseStringList(challengesJson['growthPoints']),
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
          reading: catJson['reading'] as String? ?? '',
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

    // lessons 파싱
    final lessonsJson = json['lessons'] as Map<String, dynamic>? ?? {};
    final lessons = LessonsSection(
      title: lessonsJson['title'] as String? ?? '2025년이 가르쳐준 것들',
      reading: lessonsJson['reading'] as String? ?? '',
      keyLessons: _parseStringList(lessonsJson['keyLessons']),
    );

    // to2026 파싱
    final to2026Json = json['to2026'] as Map<String, dynamic>? ?? {};
    final to2026 = To2026Section(
      title: to2026Json['title'] as String? ?? '2026년으로 가져가세요',
      reading: to2026Json['reading'] as String? ?? '',
      strengths: _parseStringList(to2026Json['strengths']),
      watchOut: _parseStringList(to2026Json['watchOut']),
    );

    // closing 파싱
    final closingJson = json['closing'] as Map<String, dynamic>? ?? {};
    final closingMessage = closingJson['message'] as String? ?? '';

    return Yearly2025FortuneData(
      year: (json['year'] as num?)?.toInt() ?? 2025,
      yearGanji: json['yearGanji'] as String? ?? '을사(乙巳)',
      mySajuIntro: mySajuIntro,
      overview: overview,
      achievements: achievements,
      challenges: challenges,
      categories: categories,
      timeline: timeline,
      lessons: lessons,
      to2026: to2026,
      closingMessage: closingMessage,
    );
  }

  static QuarterSection _parseQuarter(dynamic value) {
    if (value is Map<String, dynamic>) {
      return QuarterSection(
        period: value['period'] as String? ?? '',
        theme: value['theme'] as String? ?? '',
        reading: value['reading'] as String? ?? '',
      );
    }
    return const QuarterSection(period: '', theme: '', reading: '');
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// 카테고리 점수 가져오기
  int getCategoryScore(String category) {
    return categories[category]?.score ?? 0;
  }
}

/// 개요 섹션
class OverviewSection {
  final String keyword;
  final int score;
  final String opening;
  final String yearEnergy;
  final String hapchungEffect;
  final String conclusion;

  const OverviewSection({
    required this.keyword,
    required this.score,
    required this.opening,
    required this.yearEnergy,
    required this.hapchungEffect,
    required this.conclusion,
  });

  /// summary getter (opening을 반환) - 호환성 유지
  String get summary => opening;
}

/// 성취 섹션
class AchievementsSection {
  final String title;
  final String reading;
  final List<String> highlights;

  const AchievementsSection({
    required this.title,
    required this.reading,
    required this.highlights,
  });
}

/// 도전 섹션
class ChallengesSection {
  final String title;
  final String reading;
  final List<String> growthPoints;

  const ChallengesSection({
    required this.title,
    required this.reading,
    required this.growthPoints,
  });
}

/// 분기 섹션
class QuarterSection {
  final String period;
  final String theme;
  final String reading;

  const QuarterSection({
    required this.period,
    required this.theme,
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
  final String reading;

  const CategorySection({
    required this.title,
    required this.icon,
    required this.score,
    required this.reading,
  });
}

/// 교훈 섹션
class LessonsSection {
  final String title;
  final String reading;
  final List<String> keyLessons;

  const LessonsSection({
    required this.title,
    required this.reading,
    required this.keyLessons,
  });
}

/// 2026년 연결 섹션
class To2026Section {
  final String title;
  final String reading;
  final List<String> strengths;
  final List<String> watchOut;

  const To2026Section({
    required this.title,
    required this.reading,
    required this.strengths,
    required this.watchOut,
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

/// 2025년 운세 Provider
///
/// activeProfile의 2025년 운세를 DB에서 조회
/// 캐시가 없으면 AI 분석을 자동 트리거하고 폴링으로 완료 감지
@riverpod
class Yearly2025Fortune extends _$Yearly2025Fortune {
  /// 분석 진행 중 플래그 (중복 호출 방지)
  static bool _isAnalyzing = false;

  /// 폴링 활성화 플래그
  bool _isPolling = false;

  @override
  Future<Yearly2025FortuneData?> build() async {
    final activeProfile = await ref.watch(activeProfileProvider.future);
    if (activeProfile == null) return null;

    final queries = Yearly2025Queries(Supabase.instance.client);
    final result = await queries.getCached(activeProfile.id);

    // 캐시가 있으면 바로 반환
    if (result != null) {
      final content = result['content'];
      if (content is Map<String, dynamic>) {
        print('[Yearly2025Fortune] 캐시 히트 - 2025 운세 로드');
        _isPolling = false;
        return Yearly2025FortuneData.fromJson(content);
      }
    }

    // 캐시가 없으면 AI 분석 트리거
    print('[Yearly2025Fortune] 캐시 없음 - AI 분석 시작');
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

    print('[Yearly2025Fortune] 폴링 시작 - 3초마다 DB 확인');
    _pollForData(profileId);
  }

  /// 주기적으로 DB 확인
  Future<void> _pollForData(String profileId) async {
    if (!_isPolling) return;

    await Future.delayed(const Duration(seconds: 3));
    if (!_isPolling) return;

    final queries = Yearly2025Queries(Supabase.instance.client);
    final result = await queries.getCached(profileId);

    if (result != null && result['content'] != null) {
      print('[Yearly2025Fortune] 폴링 성공 - 데이터 발견! UI 자동 갱신');
      _isPolling = false;
      _isAnalyzing = false;
      ref.invalidateSelf();
    } else {
      // 데이터 없으면 계속 폴링
      print('[Yearly2025Fortune] 폴링 중 - 데이터 아직 없음');
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
      print('[Yearly2025Fortune] ⏭️ FortuneCoordinator에서 이미 분석 중 - 스킵');
      return;
    }

    if (_isAnalyzing) {
      print('[Yearly2025Fortune] 이미 분석 중 - 스킵');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('[Yearly2025Fortune] 사용자 없음 - 분석 스킵');
      return;
    }

    _isAnalyzing = true;
    print('[Yearly2025Fortune] 🚀 v6.0 Fortune만 즉시 분석 시작! (saju_base 대기 없음)');

    // v6.0: Fortune만 직접 분석 (saju_base 대기 없음!)
    fortuneCoordinator.analyzeFortuneOnly(
      userId: user.id,
      profileId: profileId,
    ).then((result) {
      _isAnalyzing = false;
      print('[Yearly2025Fortune] ✅ Fortune 분석 완료');
      print('  - yearly2025: ${result.yearly2025 != null ? "성공" : "실패"}');
      print('  - yearly2026: ${result.yearly2026 != null ? "성공" : "실패"}');
      print('  - monthly: ${result.monthly != null ? "성공" : "실패"}');
      // 폴링이 데이터를 감지하고 UI를 갱신할 것임
    }).catchError((e) {
      _isAnalyzing = false;
      print('[Yearly2025Fortune] ❌ Fortune 분석 오류: $e');
    });
  }

  /// 운세 새로고침 (캐시 무효화)
  Future<void> refresh() async {
    _isPolling = false;
    _isAnalyzing = false;
    ref.invalidateSelf();
  }
}
