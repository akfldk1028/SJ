import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../AI/fortune/lifetime/lifetime_queries.dart';
import '../../../../AI/services/saju_analysis_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

part 'lifetime_fortune_provider.g.dart';

/// 평생운세 데이터 모델 (saju_base AI 응답 JSON 구조)
class LifetimeFortuneData {
  final MySajuIntroSection? mySajuIntro;  // v7.0: 나의 사주 소개 추가
  final String summary;
  final PersonalitySection personality;
  final WealthSection wealth;
  final LoveSection love;
  final MarriageSection marriage;
  final CareerSection career;
  final BusinessSection business;
  final HealthSection health;
  final Map<String, CategoryFortuneData> categories;
  final LifeCyclesSection lifeCycles;
  final String overallAdvice;
  final LuckyElementsSection luckyElements;

  const LifetimeFortuneData({
    this.mySajuIntro,
    required this.summary,
    required this.personality,
    required this.wealth,
    required this.love,
    required this.marriage,
    required this.career,
    required this.business,
    required this.health,
    required this.categories,
    required this.lifeCycles,
    required this.overallAdvice,
    required this.luckyElements,
  });

  /// AI 응답 JSON에서 파싱
  factory LifetimeFortuneData.fromJson(Map<String, dynamic> json) {
    // v7.0: mySajuIntro 파싱
    MySajuIntroSection? mySajuIntro;
    final mySajuIntroJson = json['mySajuIntro'] as Map<String, dynamic>?;
    if (mySajuIntroJson != null) {
      mySajuIntro = MySajuIntroSection(
        title: mySajuIntroJson['title'] as String? ?? '나의 사주, 나는 누구인가요?',
        reading: mySajuIntroJson['reading'] as String? ?? '',
      );
    }

    // personality 파싱
    final personalityJson = json['personality'] as Map<String, dynamic>? ?? {};
    final personality = PersonalitySection(
      coreTraits: _parseStringList(personalityJson['core_traits']),
      strengths: _parseStringList(personalityJson['strengths']),
      weaknesses: _parseStringList(personalityJson['weaknesses']),
      socialStyle: personalityJson['social_style'] as String? ?? '',
      description: personalityJson['description'] as String? ?? '',
    );

    // wealth 파싱
    final wealthJson = json['wealth'] as Map<String, dynamic>? ?? {};
    final wealth = WealthSection(
      overallTendency: wealthJson['overall_tendency'] as String? ?? '',
      earningStyle: wealthJson['earning_style'] as String? ?? '',
      spendingTendency: wealthJson['spending_tendency'] as String? ?? '',
      investmentAptitude: wealthJson['investment_aptitude'] as String? ?? '',
      wealthTiming: wealthJson['wealth_timing'] as String? ?? '',
      cautions: _parseStringList(wealthJson['cautions']),
      advice: wealthJson['advice'] as String? ?? '',
    );

    // love 파싱
    final loveJson = json['love'] as Map<String, dynamic>? ?? {};
    final love = LoveSection(
      attractionStyle: loveJson['attraction_style'] as String? ?? '',
      datingPattern: loveJson['dating_pattern'] as String? ?? '',
      romanticStrengths: _parseStringList(loveJson['romantic_strengths']),
      romanticWeaknesses: _parseStringList(loveJson['romantic_weaknesses']),
      idealPartnerTraits: _parseStringList(loveJson['ideal_partner_traits']),
      loveTiming: loveJson['love_timing'] as String? ?? '',
      advice: loveJson['advice'] as String? ?? '',
    );

    // marriage 파싱
    final marriageJson = json['marriage'] as Map<String, dynamic>? ?? {};
    final marriage = MarriageSection(
      spousePalaceAnalysis: marriageJson['spouse_palace_analysis'] as String? ?? '',
      marriageTiming: marriageJson['marriage_timing'] as String? ?? '',
      spouseCharacteristics: marriageJson['spouse_characteristics'] as String? ?? '',
      marriedLifeTendency: marriageJson['married_life_tendency'] as String? ?? '',
      cautions: _parseStringList(marriageJson['cautions']),
      advice: marriageJson['advice'] as String? ?? '',
    );

    // career 파싱
    final careerJson = json['career'] as Map<String, dynamic>? ?? {};
    final career = CareerSection(
      suitableFields: _parseStringList(careerJson['suitable_fields']),
      unsuitableFields: _parseStringList(careerJson['unsuitable_fields']),
      workStyle: careerJson['work_style'] as String? ?? '',
      leadershipPotential: careerJson['leadership_potential'] as String? ?? '',
      careerTiming: careerJson['career_timing'] as String? ?? '',
      advice: careerJson['advice'] as String? ?? '',
    );

    // business 파싱
    final businessJson = json['business'] as Map<String, dynamic>? ?? {};
    final business = BusinessSection(
      entrepreneurshipAptitude: businessJson['entrepreneurship_aptitude'] as String? ?? '',
      suitableBusinessTypes: _parseStringList(businessJson['suitable_business_types']),
      businessPartnerTraits: businessJson['business_partner_traits'] as String? ?? '',
      cautions: _parseStringList(businessJson['cautions']),
      successFactors: _parseStringList(businessJson['success_factors']),
      advice: businessJson['advice'] as String? ?? '',
    );

    // health 파싱
    final healthJson = json['health'] as Map<String, dynamic>? ?? {};
    final health = HealthSection(
      vulnerableOrgans: _parseStringList(healthJson['vulnerable_organs']),
      potentialIssues: _parseStringList(healthJson['potential_issues']),
      mentalHealth: healthJson['mental_health'] as String? ?? '',
      lifestyleAdvice: _parseStringList(healthJson['lifestyle_advice']),
      cautionPeriods: healthJson['caution_periods'] as String? ?? '',
    );

    // categories 빌드 (FortuneCategoryChipSection용)
    final categories = <String, CategoryFortuneData>{
      'career': CategoryFortuneData(
        title: '직업운',
        score: _calculateScore(careerJson),
        reading: _buildCareerReading(career),
      ),
      'business': CategoryFortuneData(
        title: '사업운',
        score: _calculateScore(businessJson),
        reading: _buildBusinessReading(business),
      ),
      'wealth': CategoryFortuneData(
        title: '재물운',
        score: _calculateScore(wealthJson),
        reading: _buildWealthReading(wealth),
      ),
      'love': CategoryFortuneData(
        title: '연애운',
        score: _calculateScore(loveJson),
        reading: _buildLoveReading(love),
      ),
      'marriage': CategoryFortuneData(
        title: '결혼운',
        score: _calculateScore(marriageJson),
        reading: _buildMarriageReading(marriage),
      ),
      'health': CategoryFortuneData(
        title: '건강운',
        score: _calculateScore(healthJson),
        reading: _buildHealthReading(health),
      ),
    };

    // lifeCycles 파싱
    final lifeCyclesJson = json['life_cycles'] as Map<String, dynamic>? ?? {};
    final lifeCycles = LifeCyclesSection(
      youth: lifeCyclesJson['youth'] as String? ?? '',
      middleAge: lifeCyclesJson['middle_age'] as String? ?? '',
      laterYears: lifeCyclesJson['later_years'] as String? ?? '',
      keyYears: _parseStringList(lifeCyclesJson['key_years']),
    );

    // luckyElements 파싱
    final luckyJson = json['lucky_elements'] as Map<String, dynamic>? ?? {};
    final luckyElements = LuckyElementsSection(
      colors: _parseStringList(luckyJson['colors']),
      directions: _parseStringList(luckyJson['directions']),
      numbers: _parseIntList(luckyJson['numbers']),
      seasons: luckyJson['seasons'] as String? ?? '',
      partnerElements: _parseStringList(luckyJson['partner_elements']),
    );

    return LifetimeFortuneData(
      mySajuIntro: mySajuIntro,
      summary: json['summary'] as String? ?? '',
      personality: personality,
      wealth: wealth,
      love: love,
      marriage: marriage,
      career: career,
      business: business,
      health: health,
      categories: categories,
      lifeCycles: lifeCycles,
      overallAdvice: json['overall_advice'] as String? ?? '',
      luckyElements: luckyElements,
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

  /// 점수 계산 (텍스트 분석 기반 추정)
  static int _calculateScore(Map<String, dynamic> section) {
    // AI 응답에 score가 있으면 사용
    if (section['score'] != null) {
      return (section['score'] as num).toInt();
    }
    // 없으면 기본값 70 (양호)
    return 70;
  }

  static String _buildCareerReading(CareerSection career) {
    final buffer = StringBuffer();
    if (career.workStyle.isNotEmpty) {
      buffer.writeln(career.workStyle);
    }
    if (career.suitableFields.isNotEmpty) {
      buffer.writeln('\n적합한 분야: ${career.suitableFields.join(', ')}');
    }
    if (career.advice.isNotEmpty) {
      buffer.writeln('\n${career.advice}');
    }
    return buffer.toString().trim();
  }

  static String _buildBusinessReading(BusinessSection business) {
    final buffer = StringBuffer();
    if (business.entrepreneurshipAptitude.isNotEmpty) {
      buffer.writeln(business.entrepreneurshipAptitude);
    }
    if (business.suitableBusinessTypes.isNotEmpty) {
      buffer.writeln('\n적합한 사업: ${business.suitableBusinessTypes.join(', ')}');
    }
    if (business.advice.isNotEmpty) {
      buffer.writeln('\n${business.advice}');
    }
    return buffer.toString().trim();
  }

  static String _buildWealthReading(WealthSection wealth) {
    final buffer = StringBuffer();
    if (wealth.overallTendency.isNotEmpty) {
      buffer.writeln(wealth.overallTendency);
    }
    if (wealth.earningStyle.isNotEmpty) {
      buffer.writeln('\n돈 버는 방식: ${wealth.earningStyle}');
    }
    if (wealth.advice.isNotEmpty) {
      buffer.writeln('\n${wealth.advice}');
    }
    return buffer.toString().trim();
  }

  static String _buildLoveReading(LoveSection love) {
    final buffer = StringBuffer();
    if (love.datingPattern.isNotEmpty) {
      buffer.writeln(love.datingPattern);
    }
    if (love.attractionStyle.isNotEmpty) {
      buffer.writeln('\n끌리는 유형: ${love.attractionStyle}');
    }
    if (love.advice.isNotEmpty) {
      buffer.writeln('\n${love.advice}');
    }
    return buffer.toString().trim();
  }

  static String _buildMarriageReading(MarriageSection marriage) {
    final buffer = StringBuffer();
    if (marriage.spousePalaceAnalysis.isNotEmpty) {
      buffer.writeln(marriage.spousePalaceAnalysis);
    }
    if (marriage.marriedLifeTendency.isNotEmpty) {
      buffer.writeln('\n${marriage.marriedLifeTendency}');
    }
    if (marriage.advice.isNotEmpty) {
      buffer.writeln('\n${marriage.advice}');
    }
    return buffer.toString().trim();
  }

  static String _buildHealthReading(HealthSection health) {
    final buffer = StringBuffer();
    if (health.vulnerableOrgans.isNotEmpty) {
      buffer.writeln('취약 부위: ${health.vulnerableOrgans.join(', ')}');
    }
    if (health.mentalHealth.isNotEmpty) {
      buffer.writeln('\n정신 건강: ${health.mentalHealth}');
    }
    if (health.lifestyleAdvice.isNotEmpty) {
      buffer.writeln('\n생활 습관: ${health.lifestyleAdvice.join(', ')}');
    }
    return buffer.toString().trim();
  }
}

/// 성격 섹션
class PersonalitySection {
  final List<String> coreTraits;
  final List<String> strengths;
  final List<String> weaknesses;
  final String socialStyle;
  final String description;

  const PersonalitySection({
    required this.coreTraits,
    required this.strengths,
    required this.weaknesses,
    required this.socialStyle,
    required this.description,
  });
}

/// 재물운 섹션
class WealthSection {
  final String overallTendency;
  final String earningStyle;
  final String spendingTendency;
  final String investmentAptitude;
  final String wealthTiming;
  final List<String> cautions;
  final String advice;

  const WealthSection({
    required this.overallTendency,
    required this.earningStyle,
    required this.spendingTendency,
    required this.investmentAptitude,
    required this.wealthTiming,
    required this.cautions,
    required this.advice,
  });
}

/// 연애운 섹션
class LoveSection {
  final String attractionStyle;
  final String datingPattern;
  final List<String> romanticStrengths;
  final List<String> romanticWeaknesses;
  final List<String> idealPartnerTraits;
  final String loveTiming;
  final String advice;

  const LoveSection({
    required this.attractionStyle,
    required this.datingPattern,
    required this.romanticStrengths,
    required this.romanticWeaknesses,
    required this.idealPartnerTraits,
    required this.loveTiming,
    required this.advice,
  });
}

/// 결혼운 섹션
class MarriageSection {
  final String spousePalaceAnalysis;
  final String marriageTiming;
  final String spouseCharacteristics;
  final String marriedLifeTendency;
  final List<String> cautions;
  final String advice;

  const MarriageSection({
    required this.spousePalaceAnalysis,
    required this.marriageTiming,
    required this.spouseCharacteristics,
    required this.marriedLifeTendency,
    required this.cautions,
    required this.advice,
  });
}

/// 직업운 섹션
class CareerSection {
  final List<String> suitableFields;
  final List<String> unsuitableFields;
  final String workStyle;
  final String leadershipPotential;
  final String careerTiming;
  final String advice;

  const CareerSection({
    required this.suitableFields,
    required this.unsuitableFields,
    required this.workStyle,
    required this.leadershipPotential,
    required this.careerTiming,
    required this.advice,
  });
}

/// 사업운 섹션
class BusinessSection {
  final String entrepreneurshipAptitude;
  final List<String> suitableBusinessTypes;
  final String businessPartnerTraits;
  final List<String> cautions;
  final List<String> successFactors;
  final String advice;

  const BusinessSection({
    required this.entrepreneurshipAptitude,
    required this.suitableBusinessTypes,
    required this.businessPartnerTraits,
    required this.cautions,
    required this.successFactors,
    required this.advice,
  });
}

/// 건강운 섹션
class HealthSection {
  final List<String> vulnerableOrgans;
  final List<String> potentialIssues;
  final String mentalHealth;
  final List<String> lifestyleAdvice;
  final String cautionPeriods;

  const HealthSection({
    required this.vulnerableOrgans,
    required this.potentialIssues,
    required this.mentalHealth,
    required this.lifestyleAdvice,
    required this.cautionPeriods,
  });
}

/// 인생 주기 섹션
class LifeCyclesSection {
  final String youth;
  final String middleAge;
  final String laterYears;
  final List<String> keyYears;

  const LifeCyclesSection({
    required this.youth,
    required this.middleAge,
    required this.laterYears,
    required this.keyYears,
  });
}

/// 행운 요소 섹션
class LuckyElementsSection {
  final List<String> colors;
  final List<String> directions;
  final List<int> numbers;
  final String seasons;
  final List<String> partnerElements;

  const LuckyElementsSection({
    required this.colors,
    required this.directions,
    required this.numbers,
    required this.seasons,
    required this.partnerElements,
  });
}

/// 카테고리별 운세 데이터 (칩 표시용)
class CategoryFortuneData {
  final String title;
  final int score;
  final String reading;

  const CategoryFortuneData({
    required this.title,
    required this.score,
    required this.reading,
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

/// 평생운세 Provider
///
/// activeProfile의 saju_base 운세를 DB에서 조회
/// 캐시가 없으면 AI 분석을 자동 트리거하고 폴링으로 완료 감지
@riverpod
class LifetimeFortune extends _$LifetimeFortune {
  /// 분석 진행 중 플래그 (중복 호출 방지)
  /// v7.1: 인스턴스 변수로 변경 (hot reload 시 초기화 문제 해결)
  bool _isAnalyzing = false;

  /// 폴링 활성화 플래그
  bool _isPolling = false;

  /// 폴링 최대 시도 횟수 (타임아웃 방지)
  static const int _maxPollingAttempts = 60; // 3초 x 60 = 3분
  int _pollingAttempts = 0;

  @override
  Future<LifetimeFortuneData?> build() async {
    // Provider 재빌드 시 상태 초기화
    _isPolling = false;
    _pollingAttempts = 0;

    final activeProfile = await ref.watch(activeProfileProvider.future);
    if (activeProfile == null) {
      print('[LifetimeFortune] 활성 프로필 없음');
      return null;
    }

    final queries = LifetimeQueries(Supabase.instance.client);

    try {
      final result = await queries.getCached(activeProfile.id);

      // 캐시가 있으면 바로 반환
      if (result != null) {
        final content = result['content'];
        if (content is Map<String, dynamic>) {
          print('[LifetimeFortune] ✅ 캐시 히트 - 평생운세 로드');
          return LifetimeFortuneData.fromJson(content);
        }
      }
    } catch (e) {
      print('[LifetimeFortune] ⚠️ 캐시 조회 오류: $e');
    }

    // 캐시가 없으면 AI 분석 트리거
    print('[LifetimeFortune] 캐시 없음 - AI 분석 시작');
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
    _pollingAttempts = 0;

    print('[LifetimeFortune] 폴링 시작 - 3초마다 DB 확인 (최대 ${_maxPollingAttempts}회)');
    _pollForData(profileId);
  }

  /// 주기적으로 DB 확인 (타임아웃 및 에러 핸들링 강화)
  Future<void> _pollForData(String profileId) async {
    if (!_isPolling) return;

    // 타임아웃 체크
    _pollingAttempts++;
    if (_pollingAttempts > _maxPollingAttempts) {
      print('[LifetimeFortune] ⏰ 폴링 타임아웃 (${_maxPollingAttempts}회 시도)');
      _isPolling = false;
      _isAnalyzing = false;
      return;
    }

    await Future.delayed(const Duration(seconds: 3));
    if (!_isPolling) return;

    try {
      final queries = LifetimeQueries(Supabase.instance.client);
      final result = await queries.getCached(profileId);

      if (result != null && result['content'] != null) {
        print('[LifetimeFortune] ✅ 폴링 성공 - 데이터 발견! UI 자동 갱신');
        _isPolling = false;
        _isAnalyzing = false;
        ref.invalidateSelf();
      } else {
        // 데이터 없으면 계속 폴링
        print('[LifetimeFortune] 폴링 중 ($_pollingAttempts/$_maxPollingAttempts) - 데이터 아직 없음');
        _pollForData(profileId);
      }
    } catch (e) {
      print('[LifetimeFortune] ⚠️ 폴링 오류: $e');
      _pollForData(profileId);
    }
  }

  /// AI 분석 트리거 (중복 호출 방지)
  Future<void> _triggerAnalysisIfNeeded(String profileId) async {
    if (_isAnalyzing) {
      print('[LifetimeFortune] 이미 분석 중 - 스킵');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('[LifetimeFortune] 사용자 없음 - 분석 스킵');
      return;
    }

    _isAnalyzing = true;
    print('[LifetimeFortune] 🚀 AI 분석 백그라운드 시작...');

    // 백그라운드로 분석 실행
    sajuAnalysisService.analyzeOnProfileSave(
      userId: user.id,
      profileId: profileId,
      runInBackground: true,
      onComplete: (result) {
        _isAnalyzing = false;
        print('[LifetimeFortune] ✅ AI 분석 완료');
        print('  - saju_base: ${result.sajuBase?.success ?? false}');
        // 폴링이 데이터를 감지하고 UI를 갱신할 것임
      },
    );
  }

  /// 운세 새로고침 (캐시 무효화)
  Future<void> refresh() async {
    _isPolling = false;
    _isAnalyzing = false;
    ref.invalidateSelf();
  }
}
