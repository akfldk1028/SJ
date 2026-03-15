import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../AI/fortune/fortune_coordinator.dart';
import '../../../../AI/fortune/yearly_2025/yearly_2025_queries.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

part 'yearly_2025_fortune_provider.g.dart';

/// 안전한 int 파싱 (num, String 모두 지원)
int _safeInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

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

    // overview 파싱 (DB 구조 일치 - 2026-01-24)
    final overviewJson = json['overview'] as Map<String, dynamic>? ?? {};
    final overview = OverviewSection(
      keyword: overviewJson['keyword'] as String? ?? '',
      score: _safeInt(overviewJson['score']),
      opening: overviewJson['opening'] as String? ?? '',
      // DB 필드 (신규)
      ilganAnalysis: overviewJson['ilganAnalysis'] as String? ?? '',
      sinsalAnalysis: overviewJson['sinsalAnalysis'] as String? ?? '',
      hapchungAnalysis: overviewJson['hapchungAnalysis'] as String? ?? '',
      yongshinAnalysis: overviewJson['yongshinAnalysis'] as String? ?? '',
      yearEnergyConclusion: overviewJson['yearEnergyConclusion'] as String? ?? '',
      // 레거시 호환성 (기존 필드)
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
          score: _safeInt(catJson['score']),
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
      year: _safeInt(json['year'], 2025),
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

/// 개요 섹션 (DB 구조 일치 - 2026-01-24)
class OverviewSection {
  final String keyword;
  final int score;
  final String opening;           // 총운 오프닝
  final String ilganAnalysis;     // 일간 분석 (DB 필드)
  final String sinsalAnalysis;    // 신살 분석 (DB 필드)
  final String hapchungAnalysis;  // 합충 분석 (DB 필드)
  final String yongshinAnalysis;  // 용신 분석 (DB 필드)
  final String yearEnergyConclusion; // 연도 에너지 결론 (DB 필드)
  // 레거시 호환성 (기존 필드)
  final String yearEnergy;
  final String hapchungEffect;
  final String conclusion;

  const OverviewSection({
    required this.keyword,
    required this.score,
    required this.opening,
    this.ilganAnalysis = '',
    this.sinsalAnalysis = '',
    this.hapchungAnalysis = '',
    this.yongshinAnalysis = '',
    this.yearEnergyConclusion = '',
    this.yearEnergy = '',
    this.hapchungEffect = '',
    this.conclusion = '',
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

  /// 분석 시작 시각 (safety timeout용)
  static DateTime? _analyzeStartTime;

  /// 분석 타임아웃 (6분 - OpenAI polling 4분 + 여유)
  static const Duration _analyzeTimeout = Duration(minutes: 6);

  /// 폴링 활성화 플래그
  bool _isPolling = false;

  @override
  Future<Yearly2025FortuneData?> build() async {
    // Dispose 시 폴링 중단 (Future.delayed 체인 정리)
    ref.onDispose(() {
      _isPolling = false;
      _isStalePolling = false;
    });

    // Safety: stuck _isAnalyzing 리셋 (타임아웃 초과 시)
    if (_isAnalyzing && _analyzeStartTime != null &&
        DateTime.now().difference(_analyzeStartTime!) > _analyzeTimeout) {
      print('[Yearly2025Fortune] ⚠️ _isAnalyzing 타임아웃 리셋 (${_analyzeTimeout.inMinutes}분 초과)');
      _isAnalyzing = false;
      _analyzeStartTime = null;
    }

    final activeProfile = await ref.read(activeProfileProvider.future);
    if (activeProfile == null) return null;

    // 오프라인 모드 - 더미 데이터 반환 (UI 테스트용)
    if (!SupabaseService.isConnected) {
      print('[Yearly2025Fortune] 오프라인 모드 - 더미 데이터 반환');
      return _getDummyData();
    }

    final queries = Yearly2025Queries(SupabaseService.client!);
    final result = await queries.getCached(activeProfile.id, includeStale: true);

    // 캐시가 있으면 바로 반환
    if (result != null) {
      final content = result['content'];
      final isStale = result['_isStale'] == true;
      if (content is Map<String, dynamic>) {
        if (isStale) {
          print('[Yearly2025Fortune] stale 캐시 - 기존 데이터 표시 + 백그라운드 재생성');
          _triggerAnalysisIfNeeded(activeProfile.id);
          _startStalePolling(activeProfile.id);
        } else {
          print('[Yearly2025Fortune] 캐시 히트 - 2025 운세 로드');
        }
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

  /// 폴링 시도 횟수
  int _pollAttempts = 0;

  /// 최대 폴링 횟수 (3초 × 100 = 5분)
  static const int _maxPollAttempts = 100;

  /// DB 폴링 시작 (AI 분석 완료 감지)
  void _startPolling(String profileId) {
    if (_isPolling) return;
    _isPolling = true;
    _pollAttempts = 0;

    print('[Yearly2025Fortune] 폴링 시작 - 3초마다 DB 확인 (최대 ${_maxPollAttempts}회)');
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

    final queries = Yearly2025Queries(SupabaseService.client!);
    final result = await queries.getCached(profileId);

    if (result != null && result['content'] != null) {
      print('[Yearly2025Fortune] 폴링 성공 - 데이터 발견! UI 자동 갱신 (${_pollAttempts}회)');
      _isPolling = false;
      _isAnalyzing = false;
      _analyzeStartTime = null;
      ref.invalidateSelf();
    } else if (_pollAttempts >= _maxPollAttempts) {
      // v8.0: 타임아웃 시 invalidateSelf()로 재시도 (무한 로딩 수정)
      print('[Yearly2025Fortune] ⚠️ 폴링 타임아웃 (${_maxPollAttempts}회 초과) - 재시도');
      _isPolling = false;
      _isAnalyzing = false;
      _analyzeStartTime = null;
      ref.invalidateSelf();
    } else {
      // 데이터 없으면 계속 폴링 (로그 10회마다)
      if (_pollAttempts % 10 == 0) {
        print('[Yearly2025Fortune] 폴링 중 - 데이터 아직 없음 ($_pollAttempts/$_maxPollAttempts)');
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
      print('[Yearly2025Fortune] ⏭️ FortuneCoordinator에서 이미 분석 중 - 스킵');
      return;
    }

    if (_isAnalyzing) {
      print('[Yearly2025Fortune] 이미 분석 중 - 스킵');
      return;
    }

    // 오프라인 모드 체크
    if (!SupabaseService.isConnected) {
      print('[Yearly2025Fortune] 오프라인 모드 - 분석 스킵');
      return;
    }

    final user = SupabaseService.currentUser;
    if (user == null) {
      print('[Yearly2025Fortune] 사용자 없음 - 분석 스킵');
      return;
    }

    _isAnalyzing = true;
    _analyzeStartTime = DateTime.now();
    print('[Yearly2025Fortune] 🚀 v6.0 Fortune만 즉시 분석 시작! (saju_base 대기 없음)');

    // v6.0: Fortune만 직접 분석 (saju_base 대기 없음!)
    fortuneCoordinator.analyzeFortuneOnly(
      userId: user.id,
      profileId: profileId,
    ).then((result) {
      _isAnalyzing = false;
      _analyzeStartTime = null;
      print('[Yearly2025Fortune] ✅ Fortune 분석 완료');
      print('  - yearly2025: ${result.yearly2025 != null ? "성공" : "실패"}');
      print('  - yearly2026: ${result.yearly2026 != null ? "성공" : "실패"}');
      print('  - monthly: ${result.monthly != null ? "성공" : "실패"}');
      // 폴링이 데이터를 감지하고 UI를 갱신할 것임
    }).catchError((e) {
      _isAnalyzing = false;
      _analyzeStartTime = null;
      print('[Yearly2025Fortune] ❌ Fortune 분석 오류: $e');
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
    print('[Yearly2025Fortune] stale 폴링 시작 - 5초마다 fresh 데이터 확인');
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

    final queries = Yearly2025Queries(SupabaseService.client!);
    final result = await queries.getCached(profileId);

    if (result != null && result['content'] != null) {
      print('[Yearly2025Fortune] fresh 데이터 발견! UI 자동 갱신 ($_stalePollAttempts회)');
      _isStalePolling = false;
      ref.invalidateSelf();
    } else if (_stalePollAttempts >= _maxStalePollAttempts) {
      print('[Yearly2025Fortune] stale 폴링 타임아웃 - 중지');
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
    _analyzeStartTime = null;
    ref.invalidateSelf();
  }

  /// UI 테스트용 더미 데이터
  Yearly2025FortuneData _getDummyData() {
    return Yearly2025FortuneData(
      year: 2025,
      yearGanji: '을사(乙巳)',
      mySajuIntro: const MySajuIntroSection(
        title: '나의 사주, 나는 누구인가요?',
        reading: '당신은 타고난 창의력과 직관력을 가진 사람입니다. 목(木)의 기운이 강해 성장과 발전을 향한 열망이 크며, 새로운 것에 대한 호기심이 남다릅니다. 다만 때로는 너무 앞서나가려는 성향이 있어 주변과의 조화를 이루는 것이 중요합니다.',
      ),
      overview: const OverviewSection(
        keyword: '도약의 해',
        score: 78,
        opening: '2025년 을사년은 당신에게 새로운 시작과 도약의 기회가 열리는 해입니다. 지난 몇 년간 쌓아온 경험과 노력이 빛을 발할 시기이며, 특히 상반기에 중요한 전환점이 찾아올 수 있습니다.',
        ilganAnalysis: '을목 일간에게 2025년의 화는 명확히 식신의 자리입니다. 식신은 재능을 밖으로 펼치고 표현하는 기운이라 발표·창작·프로젝트 실행에서 성과가 나왔을 가능성이 높습니다.',
        sinsalAnalysis: '원국에 도화살과 역마 기운이 있어 2025년의 화 기운과 만나면 사람을 끌어들이는 표현력과 이동·변화의 기회가 함께 작용했을 수 있습니다.',
        hapchungAnalysis: '사주 내 인목(寅木)과 사화(巳火)가 형(刑)을 이루어 예상치 못한 변화가 있을 수 있으나, 이를 잘 활용하면 오히려 성장의 발판이 됩니다.',
        yongshinAnalysis: '용신이 토(土)인 당신에게 을사년의 화는 궁극적으로 도움되는 기운이었습니다. 화는 토를 생해(火生土) 용신을 돕기 때문입니다.',
        yearEnergyConclusion: '종합하면 2025년은 표현으로 기반을 다진 해였습니다. 식신(화)이 활동을 촉진해 아이디어를 결과로 만드는 힘을 줬고, 그 결과가 용신 토와 좋은 상생으로 연결되었습니다.',
        yearEnergy: '을목(乙木)과 사화(巳火)의 조합은 나무가 불의 기운을 받아 활활 타오르는 형상입니다.',
        hapchungEffect: '',
        conclusion: '전반적으로 긍정적인 흐름이 예상되며, 적극적인 자세로 기회를 잡는다면 뜻깊은 한 해가 될 것입니다.',
      ),
      achievements: const AchievementsSection(
        title: '2025년의 빛나는 순간들',
        reading: '올해는 그동안 준비해온 일들이 결실을 맺는 시기입니다. 특히 창의적인 프로젝트나 새로운 도전에서 좋은 성과를 거둘 수 있습니다.',
        highlights: [
          '3월~5월 사이 중요한 성과 달성',
          '인간관계에서의 의미 있는 만남',
          '재정적 안정 기반 마련',
        ],
      ),
      challenges: const ChallengesSection(
        title: '2025년의 시련, 그리고 성장',
        reading: '성장에는 언제나 도전이 따릅니다. 올해 마주할 어려움들은 당신을 더 강하게 만들어 줄 것입니다.',
        growthPoints: [
          '인내심을 기르는 것이 중요',
          '건강 관리에 더 신경 쓸 필요',
          '재정 관리에 있어 신중함 필요',
        ],
      ),
      categories: {
        'career': const CategorySection(
          title: '직장/취업운',
          icon: '💼',
          score: 82,
          reading: '직장에서의 인정과 승진 기회가 높아지는 해입니다. 특히 하반기에 좋은 소식이 있을 수 있으며, 이직을 고려 중이라면 신중하게 판단하세요.',
        ),
        'wealth': const CategorySection(
          title: '재물운',
          icon: '💰',
          score: 75,
          reading: '안정적인 재정 흐름이 예상됩니다. 큰 투자보다는 착실한 저축이 유리하며, 하반기에 예상치 못한 수입이 있을 수 있습니다.',
        ),
        'love': const CategorySection(
          title: '연애운',
          icon: '💕',
          score: 80,
          reading: '싱글이라면 봄에 좋은 인연을 만날 수 있습니다. 연인이 있다면 관계가 더욱 깊어지는 해가 될 것입니다.',
        ),
        'health': const CategorySection(
          title: '건강운',
          icon: '🏥',
          score: 70,
          reading: '전반적으로 양호하나, 과로를 피하고 규칙적인 생활 습관을 유지하는 것이 중요합니다. 특히 소화기 건강에 신경 쓰세요.',
        ),
      },
      timeline: const TimelineSection(
        q1: QuarterSection(
          period: '1~3월',
          theme: '준비와 계획',
          reading: '새해의 시작과 함께 철저한 계획을 세우는 것이 좋습니다. 급하게 서두르기보다 차근차근 준비하세요.',
        ),
        q2: QuarterSection(
          period: '4~6월',
          theme: '도약과 실행',
          reading: '준비한 것들을 실행에 옮기기 좋은 시기입니다. 적극적으로 행동하면 좋은 결과를 얻을 수 있습니다.',
        ),
        q3: QuarterSection(
          period: '7~9월',
          theme: '수확과 조정',
          reading: '상반기 노력의 결실을 거두는 시기입니다. 다만 지나친 욕심은 금물, 적절한 조정이 필요합니다.',
        ),
        q4: QuarterSection(
          period: '10~12월',
          theme: '정리와 준비',
          reading: '한 해를 마무리하며 다음 해를 준비하는 시기입니다. 성찰과 반성을 통해 더 나은 내년을 계획하세요.',
        ),
      ),
      lessons: const LessonsSection(
        title: '2025년이 가르쳐준 것들',
        reading: '올해를 통해 얻게 될 소중한 교훈들입니다.',
        keyLessons: [
          '꾸준함의 가치',
          '인간관계의 소중함',
          '자기 자신에 대한 믿음',
        ],
      ),
      to2026: const To2026Section(
        title: '2026년으로 가져가세요',
        reading: '2025년의 경험을 바탕으로 2026년을 준비하세요.',
        strengths: [
          '쌓아온 경험과 지식',
          '강화된 인적 네트워크',
          '성장한 자신감',
        ],
        watchOut: [
          '과도한 자만심 주의',
          '건강 관리 지속',
          '재정 계획 재검토',
        ],
      ),
      closingMessage: '2025년 을사년은 당신에게 성장과 도약의 해가 될 것입니다. 어려움이 있더라도 포기하지 마세요. 당신의 노력은 반드시 빛을 발할 것입니다. 행복하고 의미 있는 한 해가 되길 바랍니다.',
    );
  }
}
