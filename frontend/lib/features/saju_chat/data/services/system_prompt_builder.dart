import '../../../profile/domain/entities/saju_profile.dart';
import '../../../saju_chart/domain/entities/saju_analysis.dart';
import '../../../saju_chart/domain/entities/sinsal.dart';
import '../../../../core/services/ai_summary_service.dart';
import '../../domain/models/ai_persona.dart';

/// 궁합 분석 결과 (Gemini)
typedef CompatibilityAnalysis = Map<String, dynamic>;

/// 시스템 프롬프트 빌더
///
/// AI 채팅을 위한 시스템 프롬프트를 조립하는 클래스
/// - 현재 날짜
/// - 페르소나 설정
/// - 프로필 정보 (생년월일, 성별)
/// - 사주 분석 데이터
/// - 궁합 상대방 정보 (v3.5 Phase 44)
///
/// v3.3: chat_provider.dart에서 분리
/// v3.5 (Phase 44): 궁합 채팅을 위한 상대방 프로필/사주 지원
class SystemPromptBuilder {
  final StringBuffer _buffer = StringBuffer();

  /// 시스템 프롬프트 빌드
  ///
  /// [basePrompt] - 기본 프롬프트 (MD 파일에서 로드)
  /// [aiSummary] - AI Summary (GPT-5.2 분석 결과)
  /// [sajuAnalysis] - 로컬 사주 분석 데이터
  /// [profile] - 프로필 정보
  /// [persona] - AI 페르소나
  /// [isFirstMessage] - 첫 메시지 여부 (토큰 최적화)
  /// [targetProfile] - 궁합 채팅 상대방 프로필 (선택)
  /// [targetSajuAnalysis] - 궁합 채팅 상대방 사주 (선택)
  /// [compatibilityAnalysis] - Gemini 궁합 분석 결과 (선택)
  String build({
    required String basePrompt,
    AiSummary? aiSummary,
    SajuAnalysis? sajuAnalysis,
    SajuProfile? profile,
    AiPersona? persona,
    bool isFirstMessage = true,
    SajuProfile? targetProfile,
    SajuAnalysis? targetSajuAnalysis,
    CompatibilityAnalysis? compatibilityAnalysis,
  }) {
    _buffer.clear();

    // 궁합 모드 여부
    final isCompatibilityMode = targetProfile != null;

    // 1. 현재 날짜
    _addCurrentDate();

    // 2. 페르소나 지시문
    if (persona != null) {
      _addPersona(persona);
    }

    // 3. 기본 프롬프트
    _buffer.writeln(basePrompt);

    // 4. 프로필 정보 (첫 메시지만)
    if (isFirstMessage && profile != null) {
      _addProfileInfo(profile, isCompatibilityMode ? '나 (상담 요청자)' : null);
    }

    // 5. 사주 데이터 (첫 메시지만)
    if (isFirstMessage && sajuAnalysis != null) {
      _addSajuAnalysis(sajuAnalysis, isCompatibilityMode ? '나의 사주' : null);
    } else if (isFirstMessage && aiSummary?.sajuOrigin != null) {
      _addSajuOrigin(aiSummary!.sajuOrigin!);
    } else if (!isFirstMessage) {
      _buffer.writeln();
      _buffer.writeln('---');
      _buffer.writeln();
      _buffer.writeln('## 사주 정보');
      _buffer.writeln('(이전 대화에서 제공된 상세 사주 정보를 참조하세요)');
    }

    // 6. 상대방 정보 추가 (궁합 모드) - Phase 44 핵심
    if (isFirstMessage && isCompatibilityMode) {
      _addTargetProfileInfo(targetProfile);
      if (targetSajuAnalysis != null) {
        _addSajuAnalysis(targetSajuAnalysis, '상대방의 사주');
      }

      // 7. Gemini 궁합 분석 결과 추가 (있는 경우)
      if (compatibilityAnalysis != null) {
        _addCompatibilityAnalysisResult(compatibilityAnalysis);
      }

      _addCompatibilityInstructions();
    }

    // 7. 마무리 지시문
    _addClosingInstructions(isCompatibilityMode: isCompatibilityMode);

    return _buffer.toString();
  }

  /// 현재 날짜 추가
  void _addCurrentDate() {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[now.weekday - 1];

    _buffer.writeln('## 현재 날짜');
    _buffer.writeln('오늘은 ${now.year}년 ${now.month}월 ${now.day}일 (${weekday}요일)입니다.');
    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
  }

  /// 페르소나 지시문 추가
  void _addPersona(AiPersona persona) {
    _buffer.writeln('## 캐릭터 설정');
    _buffer.writeln();
    _buffer.writeln(persona.systemPromptInstruction);
    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
  }

  /// 프로필 정보 추가
  /// [label] - 궁합 모드에서 '나 (상담 요청자)' 등 커스텀 라벨
  void _addProfileInfo(SajuProfile profile, [String? label]) {
    final now = DateTime.now();
    final age = now.year - profile.birthDate.year;
    final koreanAge = age + 1;

    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
    _buffer.writeln('## ${label ?? '상담 대상자 정보'}');
    _buffer.writeln('- 이름: ${profile.displayName}');
    _buffer.writeln('- 성별: ${profile.gender.displayName}');
    _buffer.writeln('- 생년월일: ${profile.birthDateFormatted} (${profile.calendarTypeLabel})');

    if (profile.birthTimeFormatted != null) {
      _buffer.writeln('- 출생시간: ${profile.birthTimeFormatted}');
    } else if (profile.birthTimeUnknown) {
      _buffer.writeln('- 출생시간: 모름');
    }

    _buffer.writeln('- 출생지역: ${profile.birthCity}');
    _buffer.writeln('- 만 나이: $age세 (한국 나이: ${koreanAge}세)');
  }

  /// 상대방 프로필 정보 추가 (궁합 모드)
  void _addTargetProfileInfo(SajuProfile targetProfile) {
    final now = DateTime.now();
    final age = now.year - targetProfile.birthDate.year;
    final koreanAge = age + 1;

    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
    _buffer.writeln('## 상대방 (궁합 대상자) 정보');
    _buffer.writeln('- 이름: ${targetProfile.displayName}');
    _buffer.writeln('- 성별: ${targetProfile.gender.displayName}');
    _buffer.writeln('- 생년월일: ${targetProfile.birthDateFormatted} (${targetProfile.calendarTypeLabel})');

    if (targetProfile.birthTimeFormatted != null) {
      _buffer.writeln('- 출생시간: ${targetProfile.birthTimeFormatted}');
    } else if (targetProfile.birthTimeUnknown) {
      _buffer.writeln('- 출생시간: 모름');
    }

    _buffer.writeln('- 출생지역: ${targetProfile.birthCity}');
    _buffer.writeln('- 만 나이: $age세 (한국 나이: ${koreanAge}세)');
  }

  /// 사주 분석 데이터 추가 (로컬 계산)
  /// [label] - 궁합 모드에서 '나의 사주', '상대방의 사주' 등 커스텀 라벨
  void _addSajuAnalysis(SajuAnalysis sajuAnalysis, [String? label]) {
    final chart = sajuAnalysis.chart;

    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
    _buffer.writeln('## ${label ?? '사주 기본 데이터'}');
    _buffer.writeln();

    // 사주팔자 테이블
    _buffer.writeln('### 사주팔자');
    _buffer.writeln('| 구분 | 년주 | 월주 | 일주 | 시주 |');
    _buffer.writeln('|------|------|------|------|------|');

    final yearGan = chart.yearPillar.gan;
    final yearJi = chart.yearPillar.ji;
    final monthGan = chart.monthPillar.gan;
    final monthJi = chart.monthPillar.ji;
    final dayGan = chart.dayPillar.gan;
    final dayJi = chart.dayPillar.ji;
    final hourGan = chart.hourPillar?.gan ?? '?';
    final hourJi = chart.hourPillar?.ji ?? '?';

    _buffer.writeln('| 천간 | $yearGan | $monthGan | $dayGan | $hourGan |');
    _buffer.writeln('| 지지 | $yearJi | $monthJi | $dayJi | $hourJi |');
    _buffer.writeln();

    // 일주
    _buffer.writeln('### 일주 (나의 본질)');
    _buffer.writeln('- 일간: $dayGan');
    _buffer.writeln('- 일지: $dayJi');
    _buffer.writeln('- 일주: $dayGan$dayJi');
    _buffer.writeln();

    // 오행 분포
    final oheng = sajuAnalysis.ohengDistribution;
    _buffer.writeln('### 오행 분포');
    _buffer.writeln('- 목: ${oheng.mok}');
    _buffer.writeln('- 화: ${oheng.hwa}');
    _buffer.writeln('- 토: ${oheng.to}');
    _buffer.writeln('- 금: ${oheng.geum}');
    _buffer.writeln('- 수: ${oheng.su}');
    if (oheng.missingOheng.isNotEmpty) {
      _buffer.writeln('- 부족: ${oheng.missingOheng.map((o) => o.korean).join(', ')}');
    }
    _buffer.writeln();

    // 용신
    final yongsin = sajuAnalysis.yongsin;
    _buffer.writeln('### 용신');
    _buffer.writeln('- 용신: ${yongsin.yongsin.korean}');
    _buffer.writeln('- 희신: ${yongsin.heesin.korean}');
    _buffer.writeln('- 기신: ${yongsin.gisin.korean}');
    _buffer.writeln('- 구신: ${yongsin.gusin.korean}');
    _buffer.writeln();

    // 신강/신약
    final dayStrength = sajuAnalysis.dayStrength;
    _buffer.writeln('### 신강/신약');
    _buffer.writeln('- 상태: ${dayStrength.level.korean}');
    _buffer.writeln('- 점수: ${dayStrength.score}/100');
    _buffer.writeln('- 득령: ${dayStrength.deukryeong ? 'O' : 'X'}');
    _buffer.writeln('- 득지: ${dayStrength.deukji ? 'O' : 'X'}');
    _buffer.writeln('- 득세: ${dayStrength.deukse ? 'O' : 'X'}');
    _buffer.writeln();

    // 격국
    final gyeokguk = sajuAnalysis.gyeokguk;
    _buffer.writeln('### 격국');
    _buffer.writeln('- 격국: ${gyeokguk.gyeokguk.korean}');
    _buffer.writeln('- 강도: ${gyeokguk.strength}/100');
    _buffer.writeln('- 설명: ${gyeokguk.reason}');
    _buffer.writeln();

    // 십성
    final sipsin = sajuAnalysis.sipsinInfo;
    _buffer.writeln('### 십성 배치');
    _buffer.writeln('| 구분 | 년주 | 월주 | 일주 | 시주 |');
    _buffer.writeln('|------|------|------|------|------|');
    final yearGanSipsin = sipsin.yearGanSipsin.korean;
    final monthGanSipsin = sipsin.monthGanSipsin.korean;
    final hourGanSipsin = sipsin.hourGanSipsin?.korean ?? '-';
    _buffer.writeln('| 천간 | $yearGanSipsin | $monthGanSipsin | (일간) | $hourGanSipsin |');
    final yearJiSipsin = sipsin.yearJiSipsin.korean;
    final monthJiSipsin = sipsin.monthJiSipsin.korean;
    final dayJiSipsin = sipsin.dayJiSipsin.korean;
    final hourJiSipsin = sipsin.hourJiSipsin?.korean ?? '-';
    _buffer.writeln('| 지지 | $yearJiSipsin | $monthJiSipsin | $dayJiSipsin | $hourJiSipsin |');
    _buffer.writeln();

    // 신살
    final sinsalList = sajuAnalysis.sinsalList;
    if (sinsalList.isNotEmpty) {
      _buffer.writeln('### 신살');
      final luckySinsals = sinsalList.where((s) => s.sinsal.type == SinSalType.lucky).toList();
      final unluckySinsals = sinsalList.where((s) => s.sinsal.type == SinSalType.unlucky).toList();

      if (luckySinsals.isNotEmpty) {
        _buffer.writeln('**길신**: ${luckySinsals.map((s) => s.sinsal.korean).join(', ')}');
      }
      if (unluckySinsals.isNotEmpty) {
        _buffer.writeln('**흉신**: ${unluckySinsals.map((s) => s.sinsal.korean).join(', ')}');
      }
      _buffer.writeln();
    }
  }

  /// sajuOrigin 데이터 추가 (Edge Function fallback)
  void _addSajuOrigin(Map<String, dynamic> sajuOrigin) {
    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
    _buffer.writeln('## 사주 원본 데이터 (GPT-5.2 분석용)');
    _buffer.writeln();

    // 기본 사주 정보
    final saju = sajuOrigin['saju'] as Map<String, dynamic>?;
    if (saju != null) {
      _buffer.writeln('### 사주팔자');
      _buffer.writeln('| 구분 | 년주 | 월주 | 일주 | 시주 |');
      _buffer.writeln('|------|------|------|------|------|');
      final yearGan = saju['year']?['gan'] ?? '?';
      final yearJi = saju['year']?['ji'] ?? '?';
      final monthGan = saju['month']?['gan'] ?? '?';
      final monthJi = saju['month']?['ji'] ?? '?';
      final dayGan = saju['day']?['gan'] ?? '?';
      final dayJi = saju['day']?['ji'] ?? '?';
      final hourGan = saju['hour']?['gan'] ?? '?';
      final hourJi = saju['hour']?['ji'] ?? '?';
      _buffer.writeln('| 천간 | $yearGan | $monthGan | $dayGan | $hourGan |');
      _buffer.writeln('| 지지 | $yearJi | $monthJi | $dayJi | $hourJi |');
      _buffer.writeln();
    }

    // 오행 분포
    final oheng = sajuOrigin['oheng'] as Map<String, dynamic>?;
    if (oheng != null) {
      _buffer.writeln('### 오행 분포');
      _buffer.writeln('- 목(木): ${oheng['wood'] ?? 0}');
      _buffer.writeln('- 화(火): ${oheng['fire'] ?? 0}');
      _buffer.writeln('- 토(土): ${oheng['earth'] ?? 0}');
      _buffer.writeln('- 금(金): ${oheng['metal'] ?? 0}');
      _buffer.writeln('- 수(水): ${oheng['water'] ?? 0}');
      _buffer.writeln();
    }

    // 용신
    final yongsin = sajuOrigin['yongsin'] as Map<String, dynamic>?;
    if (yongsin != null) {
      _buffer.writeln('### 용신');
      _buffer.writeln('- 용신: ${yongsin['yongsin'] ?? '미정'}');
      _buffer.writeln('- 희신: ${yongsin['huisin'] ?? '미정'}');
      _buffer.writeln('- 기신: ${yongsin['gisin'] ?? '미정'}');
      _buffer.writeln('- 구신: ${yongsin['gusin'] ?? '미정'}');
      _buffer.writeln();
    }

    // 신강/신약
    final singang = sajuOrigin['singang'] as Map<String, dynamic>?;
    if (singang != null) {
      final isSingang = singang['is_singang'] == true;
      _buffer.writeln('### 신강/신약');
      _buffer.writeln('- ${isSingang ? '신강' : '신약'} (점수: ${singang['score'] ?? 50})');
      _buffer.writeln();
    }

    // 격국
    final gyeokguk = sajuOrigin['gyeokguk'] as Map<String, dynamic>?;
    if (gyeokguk != null) {
      _buffer.writeln('### 격국');
      _buffer.writeln('- ${gyeokguk['name'] ?? '미정'}');
      if (gyeokguk['reason'] != null) {
        _buffer.writeln('- 사유: ${gyeokguk['reason']}');
      }
      _buffer.writeln();
    }

    // 십성
    final sipsin = sajuOrigin['sipsin'] as Map<String, dynamic>?;
    if (sipsin != null) {
      _buffer.writeln('### 십성 배치');
      _buffer.writeln('- 년간: ${sipsin['yearGan'] ?? '?'}');
      _buffer.writeln('- 월간: ${sipsin['monthGan'] ?? '?'}');
      _buffer.writeln('- 시간: ${sipsin['hourGan'] ?? '?'}');
      _buffer.writeln('- 년지: ${sipsin['yearJi'] ?? '?'}');
      _buffer.writeln('- 월지: ${sipsin['monthJi'] ?? '?'}');
      _buffer.writeln('- 일지: ${sipsin['dayJi'] ?? '?'}');
      _buffer.writeln('- 시지: ${sipsin['hourJi'] ?? '?'}');
      _buffer.writeln();
    }

    // 합충형파해
    final hapchung = sajuOrigin['hapchung'] as Map<String, dynamic>?;
    if (hapchung != null) {
      _buffer.writeln('### 합충형파해');
      _addHapchungSection(hapchung, 'chungan_haps', '천간합');
      _addHapchungSection(hapchung, 'jiji_yukhaps', '지지육합');
      _addHapchungSection(hapchung, 'jiji_samhaps', '지지삼합');
      _addHapchungSection(hapchung, 'chungs', '충');
      _addHapchungSection(hapchung, 'hyungs', '형');
      _addHapchungSection(hapchung, 'pas', '파');
      _addHapchungSection(hapchung, 'haes', '해');
      _buffer.writeln();
    }

    // 신살
    final sinsal = sajuOrigin['sinsal'] as List?;
    if (sinsal != null && sinsal.isNotEmpty) {
      _buffer.writeln('### 신살');
      for (final s in sinsal) {
        final name = s['name'] ?? s['sinsal'] ?? '?';
        final type = s['type'] ?? s['fortuneType'] ?? '';
        final pillar = s['pillar'] ?? '';
        _buffer.writeln('- $pillar: $name ($type)');
      }
      _buffer.writeln();
    }

    // 길성
    final gilseong = sajuOrigin['gilseong'] as List?;
    if (gilseong != null && gilseong.isNotEmpty) {
      _buffer.writeln('### 길성');
      for (final g in gilseong) {
        final name = g['name'] ?? g;
        _buffer.writeln('- $name');
      }
      _buffer.writeln();
    }

    // 12운성
    final twelveUnsung = sajuOrigin['twelve_unsung'] as List?;
    if (twelveUnsung != null && twelveUnsung.isNotEmpty) {
      _buffer.writeln('### 12운성');
      for (final u in twelveUnsung) {
        final pillar = u['pillar'] ?? '?';
        final unsung = u['unsung'] ?? '?';
        _buffer.writeln('- $pillar: $unsung');
      }
      _buffer.writeln();
    }

    // 대운
    final daeun = sajuOrigin['daeun'] as Map<String, dynamic>?;
    if (daeun != null) {
      _buffer.writeln('### 대운');
      final current = daeun['current'] as Map<String, dynamic>?;
      if (current != null) {
        final pillar = current['pillar'] ?? '${current['gan'] ?? ''}${current['ji'] ?? ''}';
        final startAge = current['start_age'] ?? current['startAge'] ?? '?';
        final endAge = current['end_age'] ?? current['endAge'] ?? '?';
        _buffer.writeln('- 현재: $pillar (${startAge}세 ~ ${endAge}세)');
      }
      _buffer.writeln();
    }
  }

  /// 합충형파해 섹션 헬퍼
  void _addHapchungSection(Map<String, dynamic> hapchung, String key, String label) {
    final items = hapchung[key] as List?;
    if (items != null && items.isNotEmpty) {
      _buffer.writeln('**$label**:');
      for (final item in items) {
        _buffer.writeln('- ${item is Map ? (item['description'] ?? item) : item}');
      }
    }
  }

  /// 궁합 모드 지시문 추가
  void _addCompatibilityInstructions() {
    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
    _buffer.writeln('## 궁합 분석 가이드');
    _buffer.writeln();
    _buffer.writeln('이 상담은 **궁합 분석** 모드입니다. 두 사람의 사주를 비교 분석해주세요.');
    _buffer.writeln();
    _buffer.writeln('### 분석 포인트');
    _buffer.writeln('1. **일간 궁합**: 두 사람의 일간(日干) 오행 관계 분석');
    _buffer.writeln('2. **지지 궁합**: 년지, 일지 등 지지 간의 합/충/형/파/해 관계');
    _buffer.writeln('3. **오행 보완**: 서로 부족한 오행을 채워주는지');
    _buffer.writeln('4. **용신 관계**: 상대방이 나의 용신을 강화하는지');
    _buffer.writeln('5. **성격 궁합**: 십성 배치로 본 성격 조화');
    _buffer.writeln();
    _buffer.writeln('### 응답 형식');
    _buffer.writeln('- 두 사람의 사주를 비교하며 설명');
    _buffer.writeln('- 긍정적인 면과 주의할 점 균형 있게 제시');
    _buffer.writeln('- 구체적인 조언과 함께 희망적인 메시지 포함');
  }

  /// 마무리 지시문 추가
  void _addClosingInstructions({bool isCompatibilityMode = false}) {
    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
    if (isCompatibilityMode) {
      _buffer.writeln('위 두 사람의 정보를 참고하여 맞춤형 궁합 상담을 제공하세요.');
      _buffer.writeln('두 사람의 생년월일과 사주 정보를 이미 알고 있으니, 다시 물어보지 마세요.');
      _buffer.writeln('합충형파해 관계를 적극 활용하여 깊이 있는 궁합 분석을 제공하세요.');
    } else {
      _buffer.writeln('위 사용자 정보를 참고하여 맞춤형 상담을 제공하세요.');
      _buffer.writeln('사용자가 생년월일을 다시 물어볼 필요 없이, 이미 알고 있는 정보를 활용하세요.');
      _buffer.writeln('합충형파해, 십성, 신살 정보를 적극 활용하여 깊이 있는 상담을 제공하세요.');
    }
  }

  /// Gemini 궁합 분석 결과 추가
  void _addCompatibilityAnalysisResult(CompatibilityAnalysis analysis) {
    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
    _buffer.writeln('## 🎯 AI 궁합 분석 결과 (Gemini)');
    _buffer.writeln();

    // 종합 점수
    final overallScore = analysis['overall_score'];
    final overallGrade = analysis['overall_grade'];
    final summary = analysis['summary'];

    if (overallScore != null) {
      _buffer.writeln('### 종합 궁합 점수');
      _buffer.writeln('- **점수**: $overallScore점 / 100점');
      if (overallGrade != null) {
        _buffer.writeln('- **등급**: $overallGrade');
      }
      _buffer.writeln();
    }

    if (summary != null) {
      _buffer.writeln('### 한줄 요약');
      _buffer.writeln('> $summary');
      _buffer.writeln();
    }

    // 카테고리별 점수
    final categoryScores = analysis['category_scores'] as Map<String, dynamic>?;
    if (categoryScores != null && categoryScores.isNotEmpty) {
      _buffer.writeln('### 세부 분석 점수');
      _addCategoryScore(categoryScores, 'oheng_harmony', '오행 조화');
      _addCategoryScore(categoryScores, 'hapchung_interaction', '합충형해파 상호작용');
      _addCategoryScore(categoryScores, 'yongsin_compatibility', '용신 호환성');
      _addCategoryScore(categoryScores, 'sinsal_synergy', '신살 시너지');
      _addCategoryScore(categoryScores, 'energy_balance', '에너지 균형');
      _buffer.writeln();
    }

    // 상세 분석
    final detailedAnalysis = analysis['detailed_analysis'] as Map<String, dynamic>?;
    if (detailedAnalysis != null) {
      _buffer.writeln('### 상세 분석');

      // 오행 분석
      final oheng = detailedAnalysis['oheng'] as Map<String, dynamic>?;
      if (oheng != null) {
        _buffer.writeln('**오행 관계**');
        _buffer.writeln('- 나의 일간: ${oheng['my_day_master'] ?? '?'}');
        _buffer.writeln('- 상대 일간: ${oheng['target_day_master'] ?? '?'}');
        _buffer.writeln('- 관계: ${oheng['relationship'] ?? '?'}');
        if (oheng['interpretation'] != null) {
          _buffer.writeln('- 해석: ${oheng['interpretation']}');
        }
        _buffer.writeln();
      }

      // 합충 분석
      final hapchung = detailedAnalysis['hapchung'] as Map<String, dynamic>?;
      if (hapchung != null) {
        _buffer.writeln('**합충형해파 상호작용**');
        final haps = hapchung['haps'] as List?;
        if (haps != null && haps.isNotEmpty) {
          _buffer.writeln('- 합(合): ${haps.join(', ')}');
        }
        final chungs = hapchung['chungs'] as List?;
        if (chungs != null && chungs.isNotEmpty) {
          _buffer.writeln('- 충(沖): ${chungs.join(', ')}');
        }
        final others = hapchung['others'] as List?;
        if (others != null && others.isNotEmpty) {
          _buffer.writeln('- 형/파/해: ${others.join(', ')}');
        }
        if (hapchung['interpretation'] != null) {
          _buffer.writeln('- 해석: ${hapchung['interpretation']}');
        }
        _buffer.writeln();
      }

      // 용신 분석
      final yongsin = detailedAnalysis['yongsin'] as Map<String, dynamic>?;
      if (yongsin != null) {
        _buffer.writeln('**용신 호환성**');
        if (yongsin['my_yongsin_effect'] != null) {
          _buffer.writeln('- 나의 영향: ${yongsin['my_yongsin_effect']}');
        }
        if (yongsin['target_yongsin_effect'] != null) {
          _buffer.writeln('- 상대의 영향: ${yongsin['target_yongsin_effect']}');
        }
        if (yongsin['synergy'] != null) {
          _buffer.writeln('- 시너지: ${yongsin['synergy']}');
        }
        _buffer.writeln();
      }
    }

    // 장점과 주의점
    final strengths = analysis['strengths'] as List?;
    if (strengths != null && strengths.isNotEmpty) {
      _buffer.writeln('### 💚 장점');
      for (final strength in strengths) {
        _buffer.writeln('- $strength');
      }
      _buffer.writeln();
    }

    final challenges = analysis['challenges'] as List?;
    if (challenges != null && challenges.isNotEmpty) {
      _buffer.writeln('### ⚠️ 주의점');
      for (final challenge in challenges) {
        _buffer.writeln('- $challenge');
      }
      _buffer.writeln();
    }

    // 조언
    final advice = analysis['advice'];
    if (advice != null) {
      _buffer.writeln('### 💡 조언');
      if (advice is Map) {
        if (advice['for_requester'] != null) {
          _buffer.writeln('- 나에게: ${advice['for_requester']}');
        }
        if (advice['for_target'] != null) {
          _buffer.writeln('- 상대에게: ${advice['for_target']}');
        }
        if (advice['together'] != null) {
          _buffer.writeln('- 함께: ${advice['together']}');
        }
      } else if (advice is String) {
        _buffer.writeln('$advice');
      }
      _buffer.writeln();
    }

    // 추천 활동
    final bestActivities = analysis['best_activities'] as List?;
    if (bestActivities != null && bestActivities.isNotEmpty) {
      _buffer.writeln('### 🎉 함께 하면 좋은 활동');
      for (final activity in bestActivities) {
        _buffer.writeln('- $activity');
      }
      _buffer.writeln();
    }

    _buffer.writeln('---');
    _buffer.writeln();
    _buffer.writeln('**위 AI 분석 결과를 참고하여 대화를 진행하세요.**');
    _buffer.writeln('사용자의 질문에 맞춰 분석 결과를 자연스럽게 활용하고,');
    _buffer.writeln('추가적인 통찰과 조언을 제공하세요.');
  }

  /// 카테고리별 점수 추가 헬퍼
  void _addCategoryScore(Map<String, dynamic> scores, String key, String label) {
    final category = scores[key] as Map<String, dynamic>?;
    if (category != null) {
      final score = category['score'];
      final grade = category['grade'];
      final description = category['description'];

      _buffer.write('- **$label**: ');
      if (score != null) _buffer.write('$score점');
      if (grade != null) _buffer.write(' ($grade)');
      _buffer.writeln();

      if (description != null) {
        _buffer.writeln('  - $description');
      }
    }
  }
}
