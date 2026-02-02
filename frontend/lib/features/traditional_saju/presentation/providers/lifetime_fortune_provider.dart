import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../AI/data/queries.dart';
import '../../../../AI/fortune/lifetime/lifetime_queries.dart';
import '../../../../AI/services/saju_analysis_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

part 'lifetime_fortune_provider.g.dart';

/// 안전한 int 파싱 (num, String 모두 지원)
int _safeInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// 평생운세 데이터 모델 (saju_base AI 응답 JSON 구조)
class LifetimeFortuneData {
  final MySajuIntroSection? mySajuIntro;  // v7.0: 나의 사주 소개 추가
  final MySajuCharactersSection? mySajuCharacters;  // v8.0: 사주팔자 8글자 설명 추가
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
  // v7.3: 상세 분석 섹션 추가
  final WonGukAnalysisSection? wonGukAnalysis;
  final SipsungAnalysisSection? sipsungAnalysis;
  final HapchungAnalysisSection? hapchungAnalysis;
  final ModernInterpretationSection? modernInterpretation;
  // v8.1: 누락된 섹션 추가
  final PeakYearsSection? peakYears;
  final DaeunDetailSection? daeunDetail;
  final SinsalGilseongSection? sinsalGilseong;

  const LifetimeFortuneData({
    this.mySajuIntro,
    this.mySajuCharacters,
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
    this.wonGukAnalysis,
    this.sipsungAnalysis,
    this.hapchungAnalysis,
    this.modernInterpretation,
    this.peakYears,
    this.daeunDetail,
    this.sinsalGilseong,
  });

  /// AI 응답 JSON에서 파싱
  factory LifetimeFortuneData.fromJson(Map<String, dynamic> json) {
    // v9.0: raw 필드 파싱 (AI 응답이 raw 문자열로 저장된 경우)
    Map<String, dynamic> parsedJson = json;
    if (json.containsKey('raw') && json['raw'] is String) {
      try {
        final rawString = json['raw'] as String;
        final rawParsed = Map<String, dynamic>.from(
          (rawString.startsWith('{') ?
            _parseJsonSafely(rawString) :
            {}) as Map
        );
        // raw에서 파싱한 데이터와 기존 json 병합 (raw 내용 우선)
        parsedJson = {...json, ...rawParsed};
        print('[LifetimeFortuneData] raw 필드 파싱 성공: ${rawParsed.keys.take(5)}...');
      } catch (e) {
        print('[LifetimeFortuneData] raw 파싱 실패: $e');
      }
    }

    // v7.0: mySajuIntro 파싱
    // v9.0: ilju (일주설명) 필드 추가
    MySajuIntroSection? mySajuIntro;
    final mySajuIntroJson = parsedJson['mySajuIntro'] as Map<String, dynamic>?;
    if (mySajuIntroJson != null) {
      mySajuIntro = MySajuIntroSection(
        title: mySajuIntroJson['title'] as String? ?? '나의 사주, 나는 누구인가요?',
        ilju: mySajuIntroJson['ilju'] as String? ?? '',
        reading: mySajuIntroJson['reading'] as String? ?? '',
      );
    }

    // v8.0: mySajuCharacters 파싱 (8글자 설명)
    MySajuCharactersSection? mySajuCharacters;
    final mySajuCharsJson = parsedJson['my_saju_characters'] as Map<String, dynamic>?;
    if (mySajuCharsJson != null) {
      mySajuCharacters = MySajuCharactersSection(
        description: mySajuCharsJson['description'] as String? ?? '',
        yearGan: SajuCharacterInfo.fromJson(mySajuCharsJson['year_gan'] as Map<String, dynamic>? ?? {}),
        yearJi: SajuCharacterInfo.fromJson(mySajuCharsJson['year_ji'] as Map<String, dynamic>? ?? {}),
        monthGan: SajuCharacterInfo.fromJson(mySajuCharsJson['month_gan'] as Map<String, dynamic>? ?? {}),
        monthJi: SajuCharacterInfo.fromJson(mySajuCharsJson['month_ji'] as Map<String, dynamic>? ?? {}),
        dayGan: SajuCharacterInfo.fromJson(mySajuCharsJson['day_gan'] as Map<String, dynamic>? ?? {}),
        dayJi: SajuCharacterInfo.fromJson(mySajuCharsJson['day_ji'] as Map<String, dynamic>? ?? {}),
        hourGan: SajuCharacterInfo.fromJson(mySajuCharsJson['hour_gan'] as Map<String, dynamic>? ?? {}),
        hourJi: SajuCharacterInfo.fromJson(mySajuCharsJson['hour_ji'] as Map<String, dynamic>? ?? {}),
        overallReading: mySajuCharsJson['overall_reading'] as String? ?? '',
      );
    }

    // personality 파싱
    final personalityJson = parsedJson['personality'] as Map<String, dynamic>? ?? {};
    final personality = PersonalitySection(
      coreTraits: _parseStringList(personalityJson['core_traits']),
      strengths: _parseStringList(personalityJson['strengths']),
      weaknesses: _parseStringList(personalityJson['weaknesses']),
      socialStyle: personalityJson['social_style'] as String? ?? '',
      description: personalityJson['description'] as String? ?? '',
    );

    // wealth 파싱
    final wealthJson = parsedJson['wealth'] as Map<String, dynamic>? ?? {};
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
    final loveJson = parsedJson['love'] as Map<String, dynamic>? ?? {};
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
    final marriageJson = parsedJson['marriage'] as Map<String, dynamic>? ?? {};
    final marriage = MarriageSection(
      spousePalaceAnalysis: marriageJson['spouse_palace_analysis'] as String? ?? '',
      marriageTiming: marriageJson['marriage_timing'] as String? ?? '',
      spouseCharacteristics: marriageJson['spouse_characteristics'] as String? ?? '',
      marriedLifeTendency: marriageJson['married_life_tendency'] as String? ?? '',
      cautions: _parseStringList(marriageJson['cautions']),
      advice: marriageJson['advice'] as String? ?? '',
    );

    // career 파싱
    final careerJson = parsedJson['career'] as Map<String, dynamic>? ?? {};
    final career = CareerSection(
      suitableFields: _parseStringList(careerJson['suitable_fields']),
      unsuitableFields: _parseStringList(careerJson['unsuitable_fields']),
      workStyle: careerJson['work_style'] as String? ?? '',
      leadershipPotential: careerJson['leadership_potential'] as String? ?? '',
      careerTiming: careerJson['career_timing'] as String? ?? '',
      advice: careerJson['advice'] as String? ?? '',
    );

    // business 파싱
    final businessJson = parsedJson['business'] as Map<String, dynamic>? ?? {};
    final business = BusinessSection(
      entrepreneurshipAptitude: businessJson['entrepreneurship_aptitude'] as String? ?? '',
      suitableBusinessTypes: _parseStringList(businessJson['suitable_business_types']),
      businessPartnerTraits: businessJson['business_partner_traits'] as String? ?? '',
      cautions: _parseStringList(businessJson['cautions']),
      successFactors: _parseStringList(businessJson['success_factors']),
      advice: businessJson['advice'] as String? ?? '',
    );

    // health 파싱
    final healthJson = parsedJson['health'] as Map<String, dynamic>? ?? {};
    final health = HealthSection(
      vulnerableOrgans: _parseStringList(healthJson['vulnerable_organs']),
      potentialIssues: _parseStringList(healthJson['potential_issues']),
      mentalHealth: healthJson['mental_health'] as String? ?? '',
      lifestyleAdvice: _parseStringList(healthJson['lifestyle_advice']),
      cautionPeriods: healthJson['caution_periods'] as String? ?? '',
    );

    // categories 빌드 (FortuneCategoryChipSection용)
    // v8.2: 모든 상세 필드 (advice, cautions, strengths 등) 포함
    // v9.4: 카테고리별 상세 필드 전체 추가 (DB 필드 100% 매핑)
    // NOTE: reading은 AI 응답에 없으므로 _buildXxxReading() 함수로 생성
    final categories = <String, CategoryFortuneData>{
      'career': CategoryFortuneData(
        title: '직업운',
        score: _calculateScore(careerJson),
        reading: careerJson['reading'] as String? ?? _buildCareerReading(career),
        advice: career.advice.isNotEmpty ? career.advice : null,
        timing: career.careerTiming.isNotEmpty ? career.careerTiming : null,
        suitableFields: career.suitableFields,
        unsuitableFields: career.unsuitableFields,
        // v9.4: 직업운 상세 필드
        workStyle: career.workStyle.isNotEmpty ? career.workStyle : null,
        leadershipPotential: career.leadershipPotential.isNotEmpty ? career.leadershipPotential : null,
      ),
      'business': CategoryFortuneData(
        title: '사업운',
        score: _calculateScore(businessJson),
        reading: businessJson['reading'] as String? ?? _buildBusinessReading(business),
        advice: business.advice.isNotEmpty ? business.advice : null,
        cautions: business.cautions,
        strengths: business.successFactors,  // 성공 요인 → 강점으로 표시
        suitableFields: business.suitableBusinessTypes,
        // v9.4: 사업운 상세 필드
        entrepreneurshipAptitude: business.entrepreneurshipAptitude.isNotEmpty ? business.entrepreneurshipAptitude : null,
        businessPartnerTraits: business.businessPartnerTraits.isNotEmpty ? business.businessPartnerTraits : null,
      ),
      'wealth': CategoryFortuneData(
        title: '재물운',
        score: _calculateScore(wealthJson),
        reading: wealthJson['reading'] as String? ?? _buildWealthReading(wealth),
        advice: wealth.advice.isNotEmpty ? wealth.advice : null,
        cautions: wealth.cautions,
        timing: wealth.wealthTiming.isNotEmpty ? wealth.wealthTiming : null,
        // v9.4: 재물운 상세 필드
        overallTendency: wealth.overallTendency.isNotEmpty ? wealth.overallTendency : null,
        earningStyle: wealth.earningStyle.isNotEmpty ? wealth.earningStyle : null,
        spendingTendency: wealth.spendingTendency.isNotEmpty ? wealth.spendingTendency : null,
        investmentAptitude: wealth.investmentAptitude.isNotEmpty ? wealth.investmentAptitude : null,
      ),
      'love': CategoryFortuneData(
        title: '연애운',
        score: _calculateScore(loveJson),
        reading: loveJson['reading'] as String? ?? _buildLoveReading(love),
        advice: love.advice.isNotEmpty ? love.advice : null,
        strengths: love.romanticStrengths,
        weaknesses: love.romanticWeaknesses,
        timing: love.loveTiming.isNotEmpty ? love.loveTiming : null,
        // v9.4: 연애운 상세 필드
        datingPattern: love.datingPattern.isNotEmpty ? love.datingPattern : null,
        attractionStyle: love.attractionStyle.isNotEmpty ? love.attractionStyle : null,
        idealPartnerTraits: love.idealPartnerTraits,
      ),
      'marriage': CategoryFortuneData(
        title: '결혼운',
        score: _calculateScore(marriageJson),
        reading: marriageJson['reading'] as String? ?? _buildMarriageReading(marriage),
        advice: marriage.advice.isNotEmpty ? marriage.advice : null,
        cautions: marriage.cautions,
        timing: marriage.marriageTiming.isNotEmpty ? marriage.marriageTiming : null,
        // v9.4: 결혼운 상세 필드
        spousePalaceAnalysis: marriage.spousePalaceAnalysis.isNotEmpty ? marriage.spousePalaceAnalysis : null,
        spouseCharacteristics: marriage.spouseCharacteristics.isNotEmpty ? marriage.spouseCharacteristics : null,
        marriedLifeTendency: marriage.marriedLifeTendency.isNotEmpty ? marriage.marriedLifeTendency : null,
      ),
      'health': CategoryFortuneData(
        title: '건강운',
        score: _calculateScore(healthJson),
        reading: healthJson['reading'] as String? ?? _buildHealthReading(health),
        cautions: health.potentialIssues,            // 잠재적 문제 → 주의사항
        weaknesses: health.vulnerableOrgans,         // 취약 부위 → 약점
        timing: health.cautionPeriods.isNotEmpty ? health.cautionPeriods : null,
        // v9.4: 건강운 상세 필드
        mentalHealth: health.mentalHealth.isNotEmpty ? health.mentalHealth : null,
        lifestyleAdvice: health.lifestyleAdvice,
      ),
    };

    // lifeCycles 파싱
    final lifeCyclesJson = parsedJson['life_cycles'] as Map<String, dynamic>? ?? {};
    final lifeCycles = LifeCyclesSection(
      youth: lifeCyclesJson['youth'] as String? ?? '',
      youthDetail: LifeCycleDetail.fromJson(
        lifeCyclesJson['youth_detail'] as Map<String, dynamic>?,
      ),
      middleAge: lifeCyclesJson['middle_age'] as String? ?? '',
      middleAgeDetail: LifeCycleDetail.fromJson(
        lifeCyclesJson['middle_age_detail'] as Map<String, dynamic>?,
      ),
      laterYears: lifeCyclesJson['later_years'] as String? ?? '',
      laterYearsDetail: LifeCycleDetail.fromJson(
        lifeCyclesJson['later_years_detail'] as Map<String, dynamic>?,
      ),
      keyYears: _parseStringList(lifeCyclesJson['key_years']),
    );

    // luckyElements 파싱
    final luckyJson = parsedJson['lucky_elements'] as Map<String, dynamic>? ?? {};
    final luckyElements = LuckyElementsSection(
      colors: _parseStringList(luckyJson['colors']),
      directions: _parseStringList(luckyJson['directions']),
      numbers: _parseIntList(luckyJson['numbers']),
      seasons: luckyJson['seasons'] as String? ?? '',
      partnerElements: _parseStringList(luckyJson['partner_elements']),
    );

    // v7.3: wonGuk_analysis 파싱
    WonGukAnalysisSection? wonGukAnalysis;
    final wonGukJson = parsedJson['wonGuk_analysis'] as Map<String, dynamic>?;
    if (wonGukJson != null) {
      wonGukAnalysis = WonGukAnalysisSection(
        gyeokguk: wonGukJson['gyeokguk'] as String? ?? '',
        dayMaster: wonGukJson['day_master'] as String? ?? '',
        ohengBalance: wonGukJson['oheng_balance'] as String? ?? '',
        singangSingak: wonGukJson['singang_singak'] as String? ?? '',
      );
    }

    // v7.3: sipsung_analysis 파싱
    SipsungAnalysisSection? sipsungAnalysis;
    final sipsungJson = parsedJson['sipsung_analysis'] as Map<String, dynamic>?;
    if (sipsungJson != null) {
      sipsungAnalysis = SipsungAnalysisSection(
        weakSipsung: _parseStringList(sipsungJson['weak_sipsung']),
        dominantSipsung: _parseStringList(sipsungJson['dominant_sipsung']),
        keyInteractions: sipsungJson['key_interactions'] as String? ?? '',
        lifeImplications: sipsungJson['life_implications'] as String? ?? '',
      );
    }

    // v7.3: hapchung_analysis 파싱
    HapchungAnalysisSection? hapchungAnalysis;
    final hapchungJson = parsedJson['hapchung_analysis'] as Map<String, dynamic>?;
    if (hapchungJson != null) {
      hapchungAnalysis = HapchungAnalysisSection(
        majorHaps: _parseStringList(hapchungJson['major_haps']),
        majorChungs: _parseStringList(hapchungJson['major_chungs']),
        overallImpact: hapchungJson['overall_impact'] as String? ?? '',
        otherInteractions: hapchungJson['other_interactions'] as String? ?? '',
      );
    }

    // v7.3: modern_interpretation 파싱
    ModernInterpretationSection? modernInterpretation;
    final modernJson = parsedJson['modern_interpretation'] as Map<String, dynamic>?;
    if (modernJson != null) {
      // career_in_ai_era 파싱
      ModernCareerSection? careerInAiEra;
      final careerAiJson = modernJson['career_in_ai_era'] as Map<String, dynamic>?;
      if (careerAiJson != null) {
        careerInAiEra = ModernCareerSection(
          traditionalPath: careerAiJson['traditional_path'] as String? ?? '',
          digitalStrengths: careerAiJson['digital_strengths'] as String? ?? '',
          modernOpportunities: _parseStringList(careerAiJson['modern_opportunities']),
        );
      }

      // wealth_in_ai_era 파싱
      ModernWealthSection? wealthInAiEra;
      final wealthAiJson = modernJson['wealth_in_ai_era'] as Map<String, dynamic>?;
      if (wealthAiJson != null) {
        wealthInAiEra = ModernWealthSection(
          traditionalView: wealthAiJson['traditional_view'] as String? ?? '',
          riskFactors: wealthAiJson['risk_factors'] as String? ?? '',
          modernOpportunities: _parseStringList(wealthAiJson['modern_opportunities']),
        );
      }

      // relationships_in_ai_era 파싱
      ModernRelationshipsSection? relationshipsInAiEra;
      final relAiJson = modernJson['relationships_in_ai_era'] as Map<String, dynamic>?;
      if (relAiJson != null) {
        relationshipsInAiEra = ModernRelationshipsSection(
          traditionalView: relAiJson['traditional_view'] as String? ?? '',
          modernNetworking: relAiJson['modern_networking'] as String? ?? '',
          collaborationStyle: relAiJson['collaboration_style'] as String? ?? '',
        );
      }

      modernInterpretation = ModernInterpretationSection(
        careerInAiEra: careerInAiEra,
        wealthInAiEra: wealthInAiEra,
        relationshipsInAiEra: relationshipsInAiEra,
      );
    }

    // v8.1: peak_years 파싱
    PeakYearsSection? peakYears;
    final peakYearsJson = parsedJson['peak_years'] as Map<String, dynamic>?;
    if (peakYearsJson != null) {
      peakYears = PeakYearsSection(
        period: peakYearsJson['period'] as String? ?? '',
        ageRange: _parseIntList(peakYearsJson['age_range']),
        why: peakYearsJson['why'] as String? ?? '',
        whatToDo: peakYearsJson['what_to_do'] as String? ?? '',
        whatToPrepare: peakYearsJson['what_to_prepare'] as String? ?? '',
        cautions: peakYearsJson['cautions'] as String? ?? '',
      );
    }

    // v8.1: daeun_detail 파싱
    DaeunDetailSection? daeunDetail;
    final daeunDetailJson = parsedJson['daeun_detail'] as Map<String, dynamic>?;
    if (daeunDetailJson != null) {
      final cyclesJson = daeunDetailJson['cycles'] as List<dynamic>? ?? [];
      final cycles = cyclesJson
          .map((e) => DaeunCycleItem.fromJson(e as Map<String, dynamic>))
          .toList();

      final bestDaeun = daeunDetailJson['best_daeun'] as Map<String, dynamic>? ?? {};
      final worstDaeun = daeunDetailJson['worst_daeun'] as Map<String, dynamic>? ?? {};

      daeunDetail = DaeunDetailSection(
        intro: daeunDetailJson['intro'] as String? ?? '',
        cycles: cycles,
        bestDaeunPeriod: bestDaeun['period'] as String? ?? '',
        bestDaeunWhy: bestDaeun['why'] as String? ?? '',
        worstDaeunPeriod: worstDaeun['period'] as String? ?? '',
        worstDaeunWhy: worstDaeun['why'] as String? ?? '',
      );
    }

    // v8.1: sinsal_gilseong 파싱
    SinsalGilseongSection? sinsalGilseong;
    final sinsalJson = parsedJson['sinsal_gilseong'] as Map<String, dynamic>?;
    if (sinsalJson != null) {
      sinsalGilseong = SinsalGilseongSection(
        majorSinsal: _parseStringList(sinsalJson['major_sinsal']),
        majorGilseong: _parseStringList(sinsalJson['major_gilseong']),
        practicalImplications: sinsalJson['practical_implications'] as String? ?? '',
        reading: sinsalJson['reading'] as String? ?? '',
      );
    }

    return LifetimeFortuneData(
      mySajuIntro: mySajuIntro,
      mySajuCharacters: mySajuCharacters,
      summary: parsedJson['summary'] as String? ?? '',
      personality: personality,
      wealth: wealth,
      love: love,
      marriage: marriage,
      career: career,
      business: business,
      health: health,
      categories: categories,
      lifeCycles: lifeCycles,
      overallAdvice: parsedJson['overall_advice'] as String? ?? '',
      luckyElements: luckyElements,
      wonGukAnalysis: wonGukAnalysis,
      sipsungAnalysis: sipsungAnalysis,
      hapchungAnalysis: hapchungAnalysis,
      modernInterpretation: modernInterpretation,
      // v8.1: 누락된 필드 추가
      peakYears: peakYears,
      daeunDetail: daeunDetail,
      sinsalGilseong: sinsalGilseong,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// JSON 문자열 안전 파싱 (raw 필드용)
  static dynamic _parseJsonSafely(String jsonString) {
    if (jsonString.isEmpty) return {};
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      print('[LifetimeFortuneData] JSON 파싱 실패: $e');
      return {};
    }
  }

  static List<int> _parseIntList(dynamic value) {
    if (value is List) {
      return value.map((e) => _safeInt(e)).toList();
    }
    return [];
  }

  /// 점수 계산 (텍스트 분석 기반 추정)
  static int _calculateScore(Map<String, dynamic> section) {
    // AI 응답에 score가 있으면 사용
    if (section['score'] != null) {
      return _safeInt(section['score']);
    }
    // 없으면 기본값 70 (양호)
    return 70;
  }

  /// v9.8: 서술형 내러티브 필드만 사용하여 reading 생성
  ///
  /// 중복 방지 원칙:
  /// - advice → 위젯 "조언" 카드에서 별도 표시 → reading 제외
  /// - timing → 위젯 "타이밍" 섹션 → reading 제외
  /// - strengths/weaknesses → 위젯 리스트 → reading 제외
  /// - cautions → 위젯 "주의사항" 카드 → reading 제외
  /// - suitableFields/unsuitableFields → 위젯 리스트 → reading 제외
  ///
  /// reading에는 서술형 분석 텍스트만 포함
  /// (v9.4 개별 필드로도 표시되지만, reading은 내러티브 맥락으로 제공)
  static String _buildCareerReading(CareerSection career) {
    final parts = <String>[];
    if (career.workStyle.isNotEmpty) parts.add(career.workStyle);
    if (career.leadershipPotential.isNotEmpty) parts.add(career.leadershipPotential);
    return parts.join('\n\n');
  }

  static String _buildBusinessReading(BusinessSection business) {
    final parts = <String>[];
    if (business.entrepreneurshipAptitude.isNotEmpty) parts.add(business.entrepreneurshipAptitude);
    if (business.businessPartnerTraits.isNotEmpty) parts.add(business.businessPartnerTraits);
    return parts.join('\n\n');
  }

  static String _buildWealthReading(WealthSection wealth) {
    final parts = <String>[];
    if (wealth.overallTendency.isNotEmpty) parts.add(wealth.overallTendency);
    if (wealth.earningStyle.isNotEmpty) parts.add(wealth.earningStyle);
    if (wealth.spendingTendency.isNotEmpty) parts.add(wealth.spendingTendency);
    if (wealth.investmentAptitude.isNotEmpty) parts.add(wealth.investmentAptitude);
    return parts.join('\n\n');
  }

  static String _buildLoveReading(LoveSection love) {
    final parts = <String>[];
    if (love.datingPattern.isNotEmpty) parts.add(love.datingPattern);
    if (love.attractionStyle.isNotEmpty) parts.add(love.attractionStyle);
    return parts.join('\n\n');
  }

  static String _buildMarriageReading(MarriageSection marriage) {
    final parts = <String>[];
    if (marriage.spousePalaceAnalysis.isNotEmpty) parts.add(marriage.spousePalaceAnalysis);
    if (marriage.spouseCharacteristics.isNotEmpty) parts.add(marriage.spouseCharacteristics);
    if (marriage.marriedLifeTendency.isNotEmpty) parts.add(marriage.marriedLifeTendency);
    return parts.join('\n\n');
  }

  static String _buildHealthReading(HealthSection health) {
    final parts = <String>[];
    if (health.mentalHealth.isNotEmpty) parts.add(health.mentalHealth);
    return parts.join('\n\n');
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

/// 인생 주기 상세 (v9.6)
class LifeCycleDetail {
  final String career;
  final String wealth;
  final String love;
  final String health;
  final String tip;
  final String bestPeriod;
  final String cautionPeriod;

  const LifeCycleDetail({
    this.career = '',
    this.wealth = '',
    this.love = '',
    this.health = '',
    this.tip = '',
    this.bestPeriod = '',
    this.cautionPeriod = '',
  });

  bool get hasContent =>
      career.isNotEmpty ||
      wealth.isNotEmpty ||
      love.isNotEmpty ||
      health.isNotEmpty;

  static LifeCycleDetail fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LifeCycleDetail();
    return LifeCycleDetail(
      career: json['career'] as String? ?? '',
      wealth: json['wealth'] as String? ?? '',
      love: json['love'] as String? ?? '',
      health: json['health'] as String? ?? '',
      tip: json['tip'] as String? ?? '',
      bestPeriod: json['best_period'] as String? ?? '',
      cautionPeriod: json['caution_period'] as String? ?? '',
    );
  }
}

/// 인생 주기 섹션
class LifeCyclesSection {
  final String youth;
  final LifeCycleDetail youthDetail;
  final String middleAge;
  final LifeCycleDetail middleAgeDetail;
  final String laterYears;
  final LifeCycleDetail laterYearsDetail;
  final List<String> keyYears;

  const LifeCyclesSection({
    required this.youth,
    this.youthDetail = const LifeCycleDetail(),
    required this.middleAge,
    this.middleAgeDetail = const LifeCycleDetail(),
    required this.laterYears,
    this.laterYearsDetail = const LifeCycleDetail(),
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
/// v8.2: advice, cautions, strengths 등 상세 필드 추가
/// v9.4: 카테고리별 상세 필드 전체 추가 (DB 필드 100% 매핑)
class CategoryFortuneData {
  final String title;
  final int score;
  final String reading;

  // v8.2: 상세 필드 추가
  final String? advice;                    // 조언
  final List<String> cautions;             // 주의사항
  final List<String> strengths;            // 강점
  final List<String> weaknesses;           // 약점
  final String? timing;                    // 타이밍 (love_timing, career_timing 등)
  final List<String> suitableFields;       // 적합 분야
  final List<String> unsuitableFields;     // 비적합 분야

  // v9.4: 카테고리별 상세 필드 추가
  // 직업운
  final String? workStyle;                 // 업무 스타일
  final String? leadershipPotential;       // 리더십 잠재력

  // 연애운
  final String? datingPattern;             // 연애 패턴
  final String? attractionStyle;           // 끌리는 유형
  final List<String> idealPartnerTraits;   // 이상형 특성

  // 재물운
  final String? overallTendency;           // 전반적 경향
  final String? earningStyle;              // 돈 버는 방식
  final String? spendingTendency;          // 소비 성향
  final String? investmentAptitude;        // 투자 적성

  // 사업운
  final String? entrepreneurshipAptitude;  // 창업 적성
  final String? businessPartnerTraits;     // 사업 파트너 특성

  // 결혼운
  final String? spousePalaceAnalysis;      // 배우자궁 분석
  final String? spouseCharacteristics;     // 배우자 특성
  final String? marriedLifeTendency;       // 결혼 생활 경향

  // 건강운
  final String? mentalHealth;              // 정신 건강
  final List<String> lifestyleAdvice;      // 생활 습관 조언

  const CategoryFortuneData({
    required this.title,
    required this.score,
    required this.reading,
    this.advice,
    this.cautions = const [],
    this.strengths = const [],
    this.weaknesses = const [],
    this.timing,
    this.suitableFields = const [],
    this.unsuitableFields = const [],
    // v9.4: 카테고리별 상세 필드
    this.workStyle,
    this.leadershipPotential,
    this.datingPattern,
    this.attractionStyle,
    this.idealPartnerTraits = const [],
    this.overallTendency,
    this.earningStyle,
    this.spendingTendency,
    this.investmentAptitude,
    this.entrepreneurshipAptitude,
    this.businessPartnerTraits,
    this.spousePalaceAnalysis,
    this.spouseCharacteristics,
    this.marriedLifeTendency,
    this.mentalHealth,
    this.lifestyleAdvice = const [],
  });
}

/// v7.0: 나의 사주 소개 섹션
/// v9.0: ilju (일주설명) 필드 추가
class MySajuIntroSection {
  final String title;
  final String ilju;     // v9.0: 일주(日柱) 설명
  final String reading;

  const MySajuIntroSection({
    required this.title,
    required this.ilju,
    required this.reading,
  });

  /// 표시할 콘텐츠가 있는지 확인 (ilju 또는 reading)
  bool get hasContent => ilju.isNotEmpty || reading.isNotEmpty;
}

/// v8.0: 사주팔자 8글자 설명 섹션 (my_saju_characters)
class MySajuCharactersSection {
  final String description;
  final SajuCharacterInfo yearGan;
  final SajuCharacterInfo yearJi;
  final SajuCharacterInfo monthGan;
  final SajuCharacterInfo monthJi;
  final SajuCharacterInfo dayGan;
  final SajuCharacterInfo dayJi;
  final SajuCharacterInfo hourGan;
  final SajuCharacterInfo hourJi;
  final String overallReading;

  const MySajuCharactersSection({
    required this.description,
    required this.yearGan,
    required this.yearJi,
    required this.monthGan,
    required this.monthJi,
    required this.dayGan,
    required this.dayJi,
    required this.hourGan,
    required this.hourJi,
    required this.overallReading,
  });

  bool get hasContent => overallReading.isNotEmpty;
}

/// 사주 한 글자 정보
class SajuCharacterInfo {
  final String character;    // 한자 (예: 甲)
  final String reading;      // 읽는 법 (예: 갑)
  final String oheng;        // 오행 (목/화/토/금/수)
  final String yinYang;      // 음양 (양/음)
  final String meaning;      // 쉬운 설명
  final String? animal;      // 띠 동물 (지지만)
  final String? season;      // 계절 (월지만)

  const SajuCharacterInfo({
    required this.character,
    required this.reading,
    required this.oheng,
    required this.yinYang,
    required this.meaning,
    this.animal,
    this.season,
  });

  factory SajuCharacterInfo.fromJson(Map<String, dynamic> json) {
    return SajuCharacterInfo(
      character: json['character'] as String? ?? '',
      reading: json['reading'] as String? ?? '',
      oheng: json['oheng'] as String? ?? '',
      yinYang: json['yin_yang'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      animal: json['animal'] as String?,
      season: json['season'] as String?,
    );
  }
}

/// 원국 분석 섹션 (wonGuk_analysis)
class WonGukAnalysisSection {
  final String gyeokguk;       // 격국 설명
  final String dayMaster;      // 일간 설명
  final String ohengBalance;   // 오행 균형
  final String singangSingak;  // 신강/신약 설명

  const WonGukAnalysisSection({
    required this.gyeokguk,
    required this.dayMaster,
    required this.ohengBalance,
    required this.singangSingak,
  });

  bool get hasContent =>
      gyeokguk.isNotEmpty || dayMaster.isNotEmpty ||
      ohengBalance.isNotEmpty || singangSingak.isNotEmpty;
}

/// 십성 분석 섹션 (sipsung_analysis)
class SipsungAnalysisSection {
  final List<String> weakSipsung;      // 약한 십성
  final List<String> dominantSipsung;  // 강한 십성
  final String keyInteractions;        // 핵심 상호작용
  final String lifeImplications;       // 삶에 대한 함의

  const SipsungAnalysisSection({
    required this.weakSipsung,
    required this.dominantSipsung,
    required this.keyInteractions,
    required this.lifeImplications,
  });

  bool get hasContent =>
      weakSipsung.isNotEmpty || dominantSipsung.isNotEmpty ||
      keyInteractions.isNotEmpty || lifeImplications.isNotEmpty;
}

/// 합충 분석 섹션 (hapchung_analysis)
class HapchungAnalysisSection {
  final List<String> majorHaps;        // 주요 합
  final List<String> majorChungs;      // 주요 충
  final String overallImpact;          // 종합 영향
  final String otherInteractions;      // 기타 상호작용

  const HapchungAnalysisSection({
    required this.majorHaps,
    required this.majorChungs,
    required this.overallImpact,
    required this.otherInteractions,
  });

  bool get hasContent =>
      majorHaps.isNotEmpty || majorChungs.isNotEmpty ||
      overallImpact.isNotEmpty || otherInteractions.isNotEmpty;
}

/// 현대적 해석 - 커리어 섹션
class ModernCareerSection {
  final String traditionalPath;
  final String digitalStrengths;
  final List<String> modernOpportunities;

  const ModernCareerSection({
    required this.traditionalPath,
    required this.digitalStrengths,
    required this.modernOpportunities,
  });
}

/// 현대적 해석 - 재물 섹션
class ModernWealthSection {
  final String traditionalView;
  final String riskFactors;
  final List<String> modernOpportunities;

  const ModernWealthSection({
    required this.traditionalView,
    required this.riskFactors,
    required this.modernOpportunities,
  });
}

/// 현대적 해석 - 관계 섹션
class ModernRelationshipsSection {
  final String traditionalView;
  final String modernNetworking;
  final String collaborationStyle;

  const ModernRelationshipsSection({
    required this.traditionalView,
    required this.modernNetworking,
    required this.collaborationStyle,
  });
}

/// 현대적 해석 섹션 (modern_interpretation)
class ModernInterpretationSection {
  final ModernCareerSection? careerInAiEra;
  final ModernWealthSection? wealthInAiEra;
  final ModernRelationshipsSection? relationshipsInAiEra;

  const ModernInterpretationSection({
    this.careerInAiEra,
    this.wealthInAiEra,
    this.relationshipsInAiEra,
  });

  bool get hasContent =>
      careerInAiEra != null || wealthInAiEra != null || relationshipsInAiEra != null;
}

/// v8.1: 전성기 섹션 (peak_years)
class PeakYearsSection {
  final String period;           // "31-41세"
  final List<int> ageRange;      // [31, 41]
  final String why;              // 왜 이 시기가 전성기인지
  final String whatToDo;         // 무엇을 해야 하는지
  final String whatToPrepare;    // 무엇을 준비해야 하는지
  final String cautions;         // 주의사항

  const PeakYearsSection({
    required this.period,
    required this.ageRange,
    required this.why,
    required this.whatToDo,
    required this.whatToPrepare,
    required this.cautions,
  });

  bool get hasContent =>
      period.isNotEmpty || why.isNotEmpty || whatToDo.isNotEmpty;
}

/// v8.1: 대운 사이클 항목 (daeun_detail.cycles[])
class DaeunCycleItem {
  final int order;               // 순서 (1, 2, 3...)
  final String pillar;           // 대운 간지
  final String ageRange;         // "현재 나이 구간: 미상"
  final String mainTheme;        // 주제
  final String fortuneLevel;     // 운세 수준 (상/중상/중/중하/하)
  final String reading;          // 상세 해석
  final List<String> opportunities;  // 기회들
  final List<String> challenges;     // 도전들

  const DaeunCycleItem({
    required this.order,
    required this.pillar,
    required this.ageRange,
    required this.mainTheme,
    required this.fortuneLevel,
    required this.reading,
    required this.opportunities,
    required this.challenges,
  });

  factory DaeunCycleItem.fromJson(Map<String, dynamic> json) {
    return DaeunCycleItem(
      order: (json['order'] as int?) ?? 0,
      pillar: json['pillar'] as String? ?? '',
      ageRange: json['age_range'] as String? ?? '',
      mainTheme: json['main_theme'] as String? ?? '',
      fortuneLevel: json['fortune_level'] as String? ?? '',
      reading: json['reading'] as String? ?? '',
      opportunities: _parseStringListStatic(json['opportunities']),
      challenges: _parseStringListStatic(json['challenges']),
    );
  }

  static List<String> _parseStringListStatic(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}

/// v8.1: 대운 상세 섹션 (daeun_detail)
class DaeunDetailSection {
  final String intro;                    // 대운 소개
  final List<DaeunCycleItem> cycles;     // 대운 사이클 목록
  final String bestDaeunPeriod;          // 최고 대운 시기
  final String bestDaeunWhy;             // 최고 대운 이유
  final String worstDaeunPeriod;         // 최악 대운 시기
  final String worstDaeunWhy;            // 최악 대운 이유

  const DaeunDetailSection({
    required this.intro,
    required this.cycles,
    required this.bestDaeunPeriod,
    required this.bestDaeunWhy,
    required this.worstDaeunPeriod,
    required this.worstDaeunWhy,
  });

  bool get hasContent =>
      intro.isNotEmpty || cycles.isNotEmpty || bestDaeunPeriod.isNotEmpty;
}

/// v8.1: 신살/길성 섹션 (sinsal_gilseong)
class SinsalGilseongSection {
  final List<String> majorSinsal;        // 주요 신살
  final List<String> majorGilseong;      // 주요 길성
  final String practicalImplications;    // 실질적 의미
  final String reading;                  // 전체 해석

  const SinsalGilseongSection({
    required this.majorSinsal,
    required this.majorGilseong,
    required this.practicalImplications,
    required this.reading,
  });

  bool get hasContent =>
      majorSinsal.isNotEmpty || majorGilseong.isNotEmpty || reading.isNotEmpty;
}

/// Phase 진행 상황 데이터 (Progressive Disclosure용)
///
/// v7.2: Phase 분할 분석의 진행 상황 표시
class PhaseProgressData {
  final int currentPhase;
  final int totalPhases;
  final Map<String, dynamic>? partialResult;
  final String status;

  const PhaseProgressData({
    required this.currentPhase,
    required this.totalPhases,
    this.partialResult,
    required this.status,
  });

  /// 진행률 (0.0 ~ 1.0)
  double get progress => totalPhases > 0 ? currentPhase / totalPhases : 0.0;

  /// Phase별 설명
  String get phaseDescription {
    switch (currentPhase) {
      case 1:
        return '기본 성격 분석 중...';
      case 2:
        return '재물/직업/애정운 분석 중...';
      case 3:
        return '건강/대운 분석 중...';
      case 4:
        return '종합 분석 중...';
      default:
        return '분석 준비 중...';
    }
  }

  /// 완료된 Phase 표시
  bool isPhaseComplete(int phase) => currentPhase > phase;

  /// 완료된 섹션 목록 (Phase 1 이후부터)
  List<String> get completedSections {
    if (partialResult == null) return [];
    final sections = <String>[];

    // Phase 1 결과
    if (partialResult!.containsKey('personality')) sections.add('성격');
    if (partialResult!.containsKey('lucky_elements')) sections.add('행운요소');

    // Phase 2 결과
    if (partialResult!.containsKey('wealth')) sections.add('재물운');
    if (partialResult!.containsKey('career')) sections.add('직업운');
    if (partialResult!.containsKey('love')) sections.add('연애운');

    // Phase 3 결과
    if (partialResult!.containsKey('health')) sections.add('건강운');

    // Phase 4 결과
    if (partialResult!.containsKey('summary')) sections.add('종합');

    return sections;
  }

  /// 부분 운세 데이터로 변환 (완료된 Phase 결과만 포함)
  LifetimeFortuneData? get partialFortuneData {
    if (partialResult == null || partialResult!.isEmpty) return null;

    try {
      return LifetimeFortuneData.fromJson(partialResult!);
    } catch (e) {
      print('[PhaseProgressData] partial 파싱 실패: $e');
      return null;
    }
  }

  /// 현재 분석 중인 섹션 설명 (더 상세하게)
  String get currentAnalysisDetail {
    switch (currentPhase) {
      case 1:
        return '원국 분석 → 성격/행운요소 도출 중';
      case 2:
        return '재물/직업/연애/결혼운 분석 중';
      case 3:
        return '건강/대운 상세 분석 중';
      case 4:
        return '인생주기/전성기/종합조언 작성 중';
      default:
        return '사주 분석 시작 준비 중';
    }
  }
}

/// Phase 진행 상황 Provider
///
/// v7.2: Phase 분할 분석 시 실시간 진행 상황 표시
/// - 3초마다 ai_tasks 테이블의 phase/partial_result 조회
/// - UI에서 진행률 표시용
@riverpod
class LifetimeFortuneProgress extends _$LifetimeFortuneProgress {
  bool _isPolling = false;

  @override
  PhaseProgressData? build() {
    return null;
  }

  /// 폴링 시작
  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    _pollProgress();
  }

  /// 폴링 중지
  void stopPolling() {
    _isPolling = false;
  }

  /// Phase 진행 상황 폴링
  Future<void> _pollProgress() async {
    while (_isPolling) {
      await Future.delayed(const Duration(seconds: 2));
      if (!_isPolling) break;

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) continue;

      try {
        final result = await aiQueries.getSajuBaseTaskProgress(userId: user.id);

        if (result.isSuccess && result.data != null) {
          final data = result.data!;
          final newProgress = PhaseProgressData(
            currentPhase: (data['phase'] as int?) ?? 1,
            totalPhases: (data['total_phases'] as int?) ?? 4,
            partialResult: data['partial_result'] as Map<String, dynamic>?,
            status: (data['status'] as String?) ?? 'pending',
          );

          state = newProgress;
          print('[LifetimeFortuneProgress] Phase ${newProgress.currentPhase}/${newProgress.totalPhases}');

          // 완료되면 폴링 중지
          if (newProgress.status == 'completed' || newProgress.currentPhase >= newProgress.totalPhases) {
            _isPolling = false;
          }
        }
      } catch (e) {
        print('[LifetimeFortuneProgress] 폴링 오류: $e');
      }
    }
  }
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
      final result = await queries.getCached(activeProfile.id, includeStale: true);

      // 캐시가 있으면 반환
      if (result != null) {
        final content = result['content'];
        final isStale = result['_isStale'] == true;

        if (content is Map<String, dynamic>) {
          if (isStale) {
            // v9.8: 버전 불일치 → 기존 데이터 즉시 표시 + 백그라운드 재생성
            print('[LifetimeFortune] ⚠️ stale 캐시 - 기존 데이터 표시 + 백그라운드 재생성');
            _triggerAnalysisIfNeeded(activeProfile.id);
            _startStalePolling(activeProfile.id);
          } else {
            print('[LifetimeFortune] ✅ 캐시 히트 - 평생운세 로드');
          }
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

  /// stale 데이터 백그라운드 갱신용 폴링
  /// 기존 데이터를 보여주면서 백그라운드에서 새 데이터 생성 완료 시 자동 갱신
  void _startStalePolling(String profileId) {
    if (_isPolling) return;
    _isPolling = true;
    _pollingAttempts = 0;

    print('[LifetimeFortune] stale 폴링 시작 - 백그라운드 갱신 감지');
    _pollForFreshData(profileId);
  }

  /// 새 버전 데이터가 생성될 때까지 폴링
  Future<void> _pollForFreshData(String profileId) async {
    if (!_isPolling) return;

    _pollingAttempts++;
    if (_pollingAttempts > _maxPollingAttempts) {
      print('[LifetimeFortune] ⏰ stale 폴링 타임아웃');
      _isPolling = false;
      _isAnalyzing = false;
      return;
    }

    await Future.delayed(const Duration(seconds: 5));
    if (!_isPolling) return;

    try {
      final queries = LifetimeQueries(Supabase.instance.client);
      final result = await queries.getCached(profileId);

      // _isStale가 아닌 새 버전 데이터가 존재하면 갱신
      if (result != null && result['_isStale'] != true && result['content'] != null) {
        print('[LifetimeFortune] ✅ 새 버전 데이터 감지 - UI 자동 갱신');
        _isPolling = false;
        _isAnalyzing = false;
        ref.invalidateSelf();
      } else {
        _pollForFreshData(profileId);
      }
    } catch (e) {
      print('[LifetimeFortune] ⚠️ stale 폴링 오류: $e');
      _pollForFreshData(profileId);
    }
  }

  /// 운세 새로고침 (캐시 무효화)
  Future<void> refresh() async {
    _isPolling = false;
    _isAnalyzing = false;
    ref.invalidateSelf();
  }
}

/// 사주팔자 8글자 데이터 모델 (로딩 애니메이션용)
class SajuPaljaData {
  final String? yearGan;
  final String? yearJi;
  final String? monthGan;
  final String? monthJi;
  final String? dayGan;
  final String? dayJi;
  final String? hourGan;
  final String? hourJi;

  const SajuPaljaData({
    this.yearGan,
    this.yearJi,
    this.monthGan,
    this.monthJi,
    this.dayGan,
    this.dayJi,
    this.hourGan,
    this.hourJi,
  });

  factory SajuPaljaData.fromJson(Map<String, dynamic> json) {
    return SajuPaljaData(
      yearGan: json['year_gan'] as String?,
      yearJi: json['year_ji'] as String?,
      monthGan: json['month_gan'] as String?,
      monthJi: json['month_ji'] as String?,
      dayGan: json['day_gan'] as String?,
      dayJi: json['day_ji'] as String?,
      hourGan: json['hour_gan'] as String?,
      hourJi: json['hour_ji'] as String?,
    );
  }

  /// 모든 8글자가 존재하는지 확인
  bool get hasAllCharacters =>
      yearGan != null && yearJi != null &&
      monthGan != null && monthJi != null &&
      dayGan != null && dayJi != null &&
      hourGan != null && hourJi != null;
}

/// 사주팔자 8글자 Provider
///
/// saju_analyses 테이블에서 현재 프로필의 8글자 조회
/// 로딩 애니메이션에 사용
@riverpod
class SajuPalja extends _$SajuPalja {
  @override
  Future<SajuPaljaData?> build() async {
    final activeProfile = await ref.watch(activeProfileProvider.future);
    if (activeProfile == null) return null;

    try {
      final result = await Supabase.instance.client
          .from('saju_analyses')
          .select('year_gan, year_ji, month_gan, month_ji, day_gan, day_ji, hour_gan, hour_ji')
          .eq('profile_id', activeProfile.id)
          .maybeSingle();

      if (result != null) {
        print('[SajuPalja] 8글자 로드 성공: ${result['year_gan']} ${result['month_gan']} ${result['day_gan']} ${result['hour_gan']}');
        return SajuPaljaData.fromJson(result);
      }
    } catch (e) {
      print('[SajuPalja] 조회 오류: $e');
    }

    return null;
  }
}
