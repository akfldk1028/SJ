import '../../../profile/domain/entities/saju_profile.dart';
import '../../../saju_chart/domain/entities/saju_analysis.dart';
import '../../../saju_chart/domain/entities/sinsal.dart';
import '../../../../core/services/ai_summary_service.dart';
import '../../domain/models/ai_persona.dart';

/// 시스템 프롬프트 빌더
///
/// AI 채팅을 위한 시스템 프롬프트를 조립하는 클래스
/// - 현재 날짜
/// - 페르소나 설정
/// - 프로필 정보 (생년월일, 성별)
/// - 사주 분석 데이터
///
/// v3.3: chat_provider.dart에서 분리
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
  String build({
    required String basePrompt,
    AiSummary? aiSummary,
    SajuAnalysis? sajuAnalysis,
    SajuProfile? profile,
    AiPersona? persona,
    bool isFirstMessage = true,
  }) {
    _buffer.clear();

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
      _addProfileInfo(profile);
    }

    // 5. 사주 데이터 (첫 메시지만)
    if (isFirstMessage && sajuAnalysis != null) {
      _addSajuAnalysis(sajuAnalysis);
    } else if (isFirstMessage && aiSummary?.sajuOrigin != null) {
      _addSajuOrigin(aiSummary!.sajuOrigin!);
    } else if (!isFirstMessage) {
      _buffer.writeln();
      _buffer.writeln('---');
      _buffer.writeln();
      _buffer.writeln('## 사주 정보');
      _buffer.writeln('(이전 대화에서 제공된 상세 사주 정보를 참조하세요)');
    }

    // 6. 마무리 지시문
    _addClosingInstructions();

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
  void _addProfileInfo(SajuProfile profile) {
    final now = DateTime.now();
    final age = now.year - profile.birthDate.year;
    final koreanAge = age + 1;

    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
    _buffer.writeln('## 상담 대상자 정보');
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

  /// 사주 분석 데이터 추가 (로컬 계산)
  void _addSajuAnalysis(SajuAnalysis sajuAnalysis) {
    final chart = sajuAnalysis.chart;

    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
    _buffer.writeln('## 사주 기본 데이터');
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

  /// 마무리 지시문 추가
  void _addClosingInstructions() {
    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
    _buffer.writeln('위 사용자 정보를 참고하여 맞춤형 상담을 제공하세요.');
    _buffer.writeln('사용자가 생년월일을 다시 물어볼 필요 없이, 이미 알고 있는 정보를 활용하세요.');
    _buffer.writeln('합충형파해, 십성, 신살 정보를 적극 활용하여 깊이 있는 상담을 제공하세요.');
  }
}
