import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../AI/fortune/fortune_coordinator.dart';
import '../../../../AI/fortune/yearly_2026/yearly_2026_queries.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

part 'new_year_fortune_provider.g.dart';

/// 안전한 int 파싱 (num, String 모두 지원)
int _safeInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

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
  // DB 구조에 맞는 추가 섹션들
  final LessonsSection? lessons;
  final AchievementsSection? achievements;
  final ChallengesSection? challenges;
  final To2027Section? to2027;

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
    this.lessons,
    this.achievements,
    this.challenges,
    this.to2027,
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

    // overview 파싱 (DB 구조 일치)
    final overviewJson = json['overview'] as Map<String, dynamic>? ?? {};
    final overview = OverviewSection(
      keyword: overviewJson['keyword'] as String? ?? '',
      score: _safeInt(overviewJson['score']),
      opening: overviewJson['opening'] as String? ?? '',
      ilganAnalysis: overviewJson['ilganAnalysis'] as String? ?? '',
      sinsalAnalysis: overviewJson['sinsalAnalysis'] as String? ?? '',
      hapchungAnalysis: overviewJson['hapchungAnalysis'] as String? ?? '',
      yongshinAnalysis: overviewJson['yongshinAnalysis'] as String? ?? '',
      yearEnergyConclusion: overviewJson['yearEnergyConclusion'] as String? ?? '',
      // 레거시 호환성
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
          score: _safeInt(catJson['score']),
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

    // lessons 파싱
    LessonsSection? lessons;
    final lessonsJson = json['lessons'] as Map<String, dynamic>?;
    if (lessonsJson != null) {
      lessons = LessonsSection(
        title: lessonsJson['title'] as String? ?? '',
        reading: lessonsJson['reading'] as String? ?? '',
        keyLessons: _parseStringList(lessonsJson['keyLessons']),
      );
    }

    // achievements 파싱
    AchievementsSection? achievements;
    final achievementsJson = json['achievements'] as Map<String, dynamic>?;
    if (achievementsJson != null) {
      achievements = AchievementsSection(
        title: achievementsJson['title'] as String? ?? '',
        reading: achievementsJson['reading'] as String? ?? '',
        highlights: _parseStringList(achievementsJson['highlights']),
      );
    }

    // challenges 파싱
    ChallengesSection? challenges;
    final challengesJson = json['challenges'] as Map<String, dynamic>?;
    if (challengesJson != null) {
      challenges = ChallengesSection(
        title: challengesJson['title'] as String? ?? '',
        reading: challengesJson['reading'] as String? ?? '',
        growthPoints: _parseStringList(challengesJson['growthPoints']),
      );
    }

    // to2027 파싱
    To2027Section? to2027;
    final to2027Json = json['to2027'] as Map<String, dynamic>?;
    if (to2027Json != null) {
      to2027 = To2027Section(
        title: to2027Json['title'] as String? ?? '',
        reading: to2027Json['reading'] as String? ?? '',
        strengths: _parseStringList(to2027Json['strengths']),
        watchOut: _parseStringList(to2027Json['watchOut']),
      );
    }

    return NewYearFortuneData(
      year: _safeInt(json['year'], 2026),
      yearGanji: json['yearGanji'] as String? ?? '병오(丙午)',
      mySajuIntro: mySajuIntro,
      yearInfo: yearInfo,
      personalAnalysis: personalAnalysis,
      overview: overview,
      categories: categories,
      timeline: timeline,
      lucky: lucky,
      closing: closing,
      lessons: lessons,
      achievements: achievements,
      challenges: challenges,
      to2027: to2027,
    );
  }

  static QuarterSection _parseQuarter(dynamic value) {
    if (value is Map<String, dynamic>) {
      return QuarterSection(
        period: value['period'] as String? ?? '',
        theme: value['theme'] as String? ?? '',
        score: _safeInt(value['score']),
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
      return value.map((e) => _safeInt(e)).toList();
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

/// 개요 섹션 (DB 구조 일치)
class OverviewSection {
  final String keyword;
  final int score;
  final String opening;           // 총운 오프닝
  final String ilganAnalysis;     // 일간 분석
  final String sinsalAnalysis;    // 신살 분석
  final String hapchungAnalysis;  // 합충 분석
  final String yongshinAnalysis;  // 용신 분석
  final String yearEnergyConclusion; // 연도 에너지 결론
  // 레거시 호환성 (있으면 사용)
  final String summary;
  final String keyPoint;

  const OverviewSection({
    required this.keyword,
    required this.score,
    this.opening = '',
    this.ilganAnalysis = '',
    this.sinsalAnalysis = '',
    this.hapchungAnalysis = '',
    this.yongshinAnalysis = '',
    this.yearEnergyConclusion = '',
    this.summary = '',
    this.keyPoint = '',
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

/// 교훈 섹션 (lessons)
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

/// 성취 섹션 (achievements)
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

/// 도전 섹션 (challenges)
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

/// 2027년으로 이어가기 섹션 (to2027)
class To2027Section {
  final String title;
  final String reading;
  final List<String> strengths;
  final List<String> watchOut;

  const To2027Section({
    required this.title,
    required this.reading,
    required this.strengths,
    required this.watchOut,
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

    // 오프라인 모드 - 더미 데이터 반환 (UI 테스트용)
    if (!SupabaseService.isConnected) {
      print('[NewYearFortune] 오프라인 모드 - 더미 데이터 반환');
      return _getDummyData();
    }

    final queries = Yearly2026Queries(SupabaseService.client!);
    final result = await queries.getCached(activeProfile.id, includeStale: true);

    // 캐시가 있으면 바로 반환
    if (result != null) {
      final content = result['content'];
      final isStale = result['_isStale'] == true;
      if (content is Map<String, dynamic>) {
        if (isStale) {
          print('[NewYearFortune] stale 캐시 - 기존 데이터 표시 + 백그라운드 재생성');
          _triggerAnalysisIfNeeded(activeProfile.id);
          _startStalePolling(activeProfile.id);
        } else {
          print('[NewYearFortune] 캐시 히트 - 2026 신년운세 로드');
        }
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

  /// 폴링 시도 횟수
  int _pollAttempts = 0;

  /// 최대 폴링 횟수 (3초 × 100 = 5분)
  static const int _maxPollAttempts = 100;

  /// DB 폴링 시작 (AI 분석 완료 감지)
  void _startPolling(String profileId) {
    if (_isPolling) return;
    _isPolling = true;
    _pollAttempts = 0;

    print('[NewYearFortune] 폴링 시작 - 3초마다 DB 확인 (최대 ${_maxPollAttempts}회)');
    _pollForData(profileId);
  }

  /// 주기적으로 DB 확인 (최대 _maxPollAttempts 회)
  Future<void> _pollForData(String profileId) async {
    if (!_isPolling) return;

    await Future.delayed(const Duration(seconds: 3));
    if (!_isPolling) return;

    _pollAttempts++;

    // 오프라인 모드 체크
    if (!SupabaseService.isConnected) {
      _isPolling = false;
      return;
    }

    final queries = Yearly2026Queries(SupabaseService.client!);
    final result = await queries.getCached(profileId);

    if (result != null && result['content'] != null) {
      print('[NewYearFortune] 폴링 성공 - 데이터 발견! UI 자동 갱신 (${_pollAttempts}회)');
      _isPolling = false;
      _isAnalyzing = false;
      ref.invalidateSelf();
    } else if (_pollAttempts >= _maxPollAttempts) {
      // v8.0: 타임아웃 시 invalidateSelf()로 재시도 (무한 로딩 수정)
      print('[NewYearFortune] ⚠️ 폴링 타임아웃 (${_maxPollAttempts}회 초과) - 재시도');
      _isPolling = false;
      _isAnalyzing = false;
      ref.invalidateSelf();
    } else {
      // 데이터 없으면 계속 폴링 (로그 10회마다)
      if (_pollAttempts % 10 == 0) {
        print('[NewYearFortune] 폴링 중 - 데이터 아직 없음 ($_pollAttempts/$_maxPollAttempts)');
      }
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

    // 오프라인 모드 체크
    if (!SupabaseService.isConnected) {
      print('[NewYearFortune] 오프라인 모드 - 분석 스킵');
      return;
    }

    final user = SupabaseService.currentUser;
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

  /// stale 데이터 폴링 (백그라운드 재생성 완료 감지)
  bool _isStalePolling = false;
  int _stalePollAttempts = 0;
  static const int _maxStalePollAttempts = 60;

  void _startStalePolling(String profileId) {
    if (_isStalePolling) return;
    _isStalePolling = true;
    _stalePollAttempts = 0;
    print('[NewYearFortune] stale 폴링 시작 - 5초마다 fresh 데이터 확인');
    _pollForFreshData(profileId);
  }

  Future<void> _pollForFreshData(String profileId) async {
    if (!_isStalePolling) return;

    await Future.delayed(const Duration(seconds: 5));
    if (!_isStalePolling) return;

    _stalePollAttempts++;

    if (!SupabaseService.isConnected) {
      _isStalePolling = false;
      return;
    }

    final queries = Yearly2026Queries(SupabaseService.client!);
    final result = await queries.getCached(profileId);

    if (result != null && result['content'] != null) {
      print('[NewYearFortune] fresh 데이터 발견! UI 자동 갱신 ($_stalePollAttempts회)');
      _isStalePolling = false;
      ref.invalidateSelf();
    } else if (_stalePollAttempts >= _maxStalePollAttempts) {
      print('[NewYearFortune] stale 폴링 타임아웃 - 중지');
      _isStalePolling = false;
    } else {
      _pollForFreshData(profileId);
    }
  }

  /// 운세 새로고침 (캐시 무효화)
  Future<void> refresh() async {
    _isPolling = false;
    _isStalePolling = false;
    _isAnalyzing = false;
    ref.invalidateSelf();
  }

  /// UI 테스트용 더미 데이터
  NewYearFortuneData _getDummyData() {
    return NewYearFortuneData(
      year: 2026,
      yearGanji: '병오(丙午)',
      mySajuIntro: const MySajuIntroSection(
        title: '나의 사주, 나는 누구인가요?',
        reading: '당신은 타고난 창의력과 직관력을 가진 사람입니다. 목(木)의 기운이 강해 성장과 발전을 향한 열망이 크며, 새로운 것에 대한 호기심이 남다릅니다.',
      ),
      yearInfo: const YearInfoSection(
        alias: '붉은 말의 해',
        napeum: '천하수(天河水)',
        napeumExplain: '하늘에서 내리는 은하수처럼 맑고 순수한 기운을 상징합니다.',
        twelveUnsung: '관대(冠帶)',
        unsungExplain: '성인이 되어 관을 쓰는 시기로, 사회적 인정과 성장의 시기입니다.',
        mainSinsal: '역마(驛馬)',
        sinsalExplain: '이동과 변화가 많은 해로, 여행이나 이사, 직장 변동의 기회가 있습니다.',
      ),
      personalAnalysis: const PersonalAnalysisSection(
        ilgan: '무토(戊土)',
        ilganExplain: '산처럼 듬직하고 안정감 있는 성격으로, 신뢰를 주는 타입입니다.',
        fireEffect: '병오년의 화(火) 기운이 토(土)를 생하여 전반적으로 긍정적인 영향을 줍니다.',
        yongshinMatch: '용신인 금(金) 기운이 화(火)에 의해 약화될 수 있어 조절이 필요합니다.',
        hapchungEffect: '일지와 연지 사이에 특별한 충돌은 없으나, 오월에 주의가 필요합니다.',
        sinsalEffect: '역마살로 인해 이동이 잦을 수 있으며, 이를 기회로 삼으면 좋습니다.',
      ),
      overview: const OverviewSection(
        keyword: '열정의 해',
        score: 82,
        summary: '2026년 병오년은 붉은 말의 해로, 열정과 활력이 넘치는 한 해가 될 것입니다. 당신의 사주와 조화를 이루어 새로운 도전에 유리한 시기입니다.',
        keyPoint: '상반기에 기회를 잡고, 하반기에는 안정을 추구하세요.',
      ),
      categories: {
        'career': const CategorySection(
          title: '직장/취업운',
          icon: '💼',
          score: 85,
          summary: '승진과 인정의 기회',
          reading: '직장에서 능력을 인정받고 승진의 기회가 있습니다. 특히 봄에 좋은 소식이 기대됩니다.',
          bestMonths: [3, 4, 9],
          cautionMonths: [6, 7],
          actionTip: '상사와의 관계를 잘 유지하고, 팀워크를 중시하세요.',
          focusAreas: ['리더십 개발', '전문성 강화'],
        ),
        'wealth': const CategorySection(
          title: '재물운',
          icon: '💰',
          score: 78,
          summary: '안정적인 재정 흐름',
          reading: '큰 횡재보다는 꾸준한 수입이 예상됩니다. 투자는 신중하게 접근하세요.',
          bestMonths: [2, 5, 11],
          cautionMonths: [8],
          actionTip: '저축을 늘리고 충동 구매를 자제하세요.',
          focusAreas: ['저축 습관', '재테크 공부'],
        ),
        'love': const CategorySection(
          title: '연애운',
          icon: '💕',
          score: 80,
          summary: '로맨틱한 만남',
          reading: '싱글이라면 봄에 좋은 인연을 만날 수 있습니다. 연인이 있다면 관계가 더욱 깊어집니다.',
          bestMonths: [3, 5, 10],
          cautionMonths: [7],
          actionTip: '적극적으로 표현하고, 상대방의 이야기에 귀 기울이세요.',
          focusAreas: ['소통 능력', '감정 표현'],
        ),
        'health': const CategorySection(
          title: '건강운',
          icon: '🏥',
          score: 72,
          summary: '규칙적인 생활 필요',
          reading: '화(火) 기운이 강해 심장과 혈압 관리에 신경 쓰세요. 규칙적인 운동이 도움됩니다.',
          bestMonths: [4, 9, 12],
          cautionMonths: [6, 7],
          actionTip: '충분한 수면과 균형 잡힌 식단을 유지하세요.',
          focusAreas: ['심혈관 건강', '스트레스 관리'],
        ),
      },
      timeline: const TimelineSection(
        q1: QuarterSection(
          period: '1~3월',
          theme: '새로운 시작',
          score: 80,
          reading: '새해의 포부를 세우고 실행에 옮기기 좋은 시기입니다. 새로운 프로젝트를 시작하세요.',
        ),
        q2: QuarterSection(
          period: '4~6월',
          theme: '성장과 발전',
          score: 85,
          reading: '노력의 결실을 보기 시작하는 시기입니다. 인간관계도 넓어집니다.',
        ),
        q3: QuarterSection(
          period: '7~9월',
          theme: '조정과 휴식',
          score: 70,
          reading: '무리하지 말고 휴식을 취하세요. 건강 관리에 특히 신경 쓰세요.',
        ),
        q4: QuarterSection(
          period: '10~12월',
          theme: '수확의 계절',
          score: 82,
          reading: '한 해의 노력이 결실을 맺는 시기입니다. 감사하는 마음으로 마무리하세요.',
        ),
      ),
      lucky: const LuckySection(
        colors: ['빨강', '주황', '보라'],
        numbers: [3, 7, 9],
        direction: '남쪽',
        items: ['말 장식품', '붉은 액세서리', '삼각형 모양'],
      ),
      closing: const ClosingSection(
        yearMessage: '2026년 병오년은 당신에게 열정과 도전의 해가 될 것입니다. 붉은 말의 기운을 받아 힘차게 달려나가세요!',
        finalAdvice: '변화를 두려워하지 말고, 새로운 기회를 적극적으로 잡으세요. 당신의 노력은 반드시 좋은 결과로 이어질 것입니다.',
      ),
    );
  }
}
