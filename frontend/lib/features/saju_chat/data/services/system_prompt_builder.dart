import 'dart:convert';
import '../../../profile/domain/entities/saju_profile.dart';
import '../../../profile/data/relation_schema.dart';
import '../../../saju_chart/domain/entities/saju_analysis.dart';
import '../../../saju_chart/domain/entities/sinsal.dart';
import '../../../saju_chart/data/constants/cheongan_jiji.dart';
import '../../../../core/services/ai_summary_service.dart';
// 페르소나 프롬프트는 최종 문자열을 주입받아 사용

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
  /// [intentClassification] - Intent 분류 결과 (토큰 최적화용)
  /// [sajuAnalysis] - 로컬 사주 분석 데이터
  /// [profile] - 프로필 정보
  /// [personaPrompt] - AI 페르소나 프롬프트 (최종 문자열)
  /// [isFirstMessage] - 첫 메시지 여부 (토큰 최적화)
  /// [targetProfile] - 궁합 채팅 상대방 프로필 (선택)
  /// [targetSajuAnalysis] - 궁합 채팅 상대방 사주 (선택)
  /// [compatibilityAnalysis] - Gemini 궁합 분석 결과 (선택)
  /// [isThirdPartyCompatibility] - v6.0 (Phase 57): "나 제외" 궁합 모드 여부
  ///   - true: 두 사람 모두 제3자 (예: 신선우 ↔ 박재현)
  ///   - false: 상담 요청자 본인 + 상대방 (예: 나 ↔ 엄마)
  /// [additionalParticipants] - v10.0: 3번째 이후 추가 참가자 목록
  ///   - 궁합은 여전히 person1 vs person2 1:1 (합충형해파)
  ///   - 추가 참가자는 프로필+사주 데이터만 시스템 프롬프트에 포함
  String build({
    required String basePrompt,
    AiSummary? aiSummary,
    IntentClassificationResult? intentClassification,
    SajuAnalysis? sajuAnalysis,
    SajuProfile? profile,
    String? personaPrompt,
    bool isFirstMessage = true,
    SajuProfile? targetProfile,
    SajuAnalysis? targetSajuAnalysis,
    CompatibilityAnalysis? compatibilityAnalysis,
    bool isThirdPartyCompatibility = false,
    String? relationType,  // v8.1: 관계 유형 (family_parent, romantic_partner 등)
    List<({SajuProfile profile, SajuAnalysis? sajuAnalysis})>? additionalParticipants,
    String locale = 'ko',  // v13.0: 다국어 채팅 지원
  }) {
    _buffer.clear();

    // v5.0: 다중 궁합 제거됨 - 궁합은 항상 2명만 (합충형해파는 1:1 관계)
    // 궁합 모드 여부 (상대방이 있는 경우)
    final isCompatibilityMode = targetProfile != null;

    // 0. 다국어 언어 지시 (프롬프트 최상단에 배치 — AI가 한국어 데이터를 보기 전에 언어 인지)
    if (locale != 'ko') {
      _addTopLanguageInstruction(locale);
    }

    // 1. 현재 날짜
    _addCurrentDate();

    // 2. 페르소나 지시문
    if (personaPrompt != null && personaPrompt.isNotEmpty) {
      _addPersona(personaPrompt, locale: locale);
    }

    // 3. 기본 프롬프트
    _buffer.writeln(basePrompt);

    // 3-1. 사주 명리학 핵심 규칙 (v39: AI 해석 정확도 향상)
    _addSajuCoreRules();

    // v6.0 (Phase 57): 라벨 결정
    // - 나 제외 모드: "첫 번째 사람" / "두 번째 사람"
    // - 나 포함 모드: "나 (상담 요청자)" / "상대방 (궁합 대상자)"
    final person1Label = isThirdPartyCompatibility
        ? '첫 번째 사람 (${profile?.displayName ?? ''})'
        : (isCompatibilityMode ? '나 (상담 요청자)' : null);
    final person1SajuLabel = isThirdPartyCompatibility
        ? '${profile?.displayName ?? '첫 번째 사람'}의 사주'
        : (isCompatibilityMode ? '나의 사주' : null);
    final person2Label = isThirdPartyCompatibility
        ? '두 번째 사람 (${targetProfile?.displayName ?? ''})'
        : null;  // 기존 _addTargetProfileInfo 사용
    final person2SajuLabel = isThirdPartyCompatibility
        ? '${targetProfile?.displayName ?? '두 번째 사람'}의 사주'
        : '상대방의 사주';

    // 4. 프로필 정보
    // v8.0: 항상 포함 (Gemini는 stateless이므로 매 호출마다 필요)
    if (profile != null) {
      _addProfileInfo(profile, person1Label);
    }

    // 5. 사주 원국 데이터 (saju_analyses 테이블 - 만세력 계산 결과)
    // v8.0: 항상 포함 (Gemini는 stateless이므로 매 호출마다 사주 데이터 필요)
    if (sajuAnalysis != null) {
      _addSajuAnalysis(sajuAnalysis, person1SajuLabel);
    }

    // 6. GPT-5.2 AI Summary 추가 (평생 운세 분석 - Intent Routing 적용)
    if (isFirstMessage && aiSummary != null) {
      _addAiSummary(aiSummary, intentClassification);
    }

    // 7. 상대방 정보 추가 (궁합 또는 단일 멘션 모드) - Phase 44
    // v9.0: isFirstMessage 조건 제거 (Gemini는 stateless이므로 매 호출마다 필요)
    if (targetProfile != null) {
      if (isThirdPartyCompatibility) {
        // v6.0: 나 제외 모드 - 커스텀 라벨 사용
        _addProfileInfo(targetProfile, person2Label);
      } else {
        // 기존: 나 포함 모드 - 기존 메서드 사용
        _addTargetProfileInfo(targetProfile);
      }
      if (targetSajuAnalysis != null) {
        _addSajuAnalysis(targetSajuAnalysis, person2SajuLabel);
      }
    }

    // 7-1. 추가 참가자 정보 (3번째 이후) - v10.0
    if (additionalParticipants != null && additionalParticipants.isNotEmpty) {
      for (int i = 0; i < additionalParticipants.length; i++) {
        final p = additionalParticipants[i];
        final personNum = i + 3;
        _addProfileInfo(p.profile, '$personNum번째 사람 (${p.profile.displayName})');
        if (p.sajuAnalysis != null) {
          _addSajuAnalysis(p.sajuAnalysis!, '${p.profile.displayName}의 사주');
        }
      }
    }

    // 8. 궁합 분석 결과 추가 (있는 경우) - Phase 44
    // v5.0: 다중 궁합 제거 - 항상 단일 궁합 (2명)만 처리
    if (isFirstMessage && compatibilityAnalysis != null) {
      _addCompatibilityAnalysisResult(compatibilityAnalysis, isThirdPartyCompatibility, profile, targetProfile);
    }

    // 9. 궁합 지시문 추가 (궁합 모드인 경우)
    if (isFirstMessage && isCompatibilityMode) {
      _addCompatibilityInstructions(isThirdPartyCompatibility, profile, targetProfile);
      // 10. 관계 유형별 분석 지시문 추가 (v8.1)
      if (relationType != null) {
        _addRelationTypeContext(relationType);
      }
    }

    // 11. 마무리 지시문 (v12.1: 전체 참가자 수 전달)
    final totalParticipants = (isCompatibilityMode ? 2 : 0) +
        (additionalParticipants?.length ?? 0);
    _addClosingInstructions(
      isCompatibilityMode: isCompatibilityMode,
      totalParticipants: totalParticipants,
      locale: locale,
    );

    return _buffer.toString();
  }

  /// 현재 날짜 추가
  void _addCurrentDate() {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[now.weekday - 1];

    // 현재 년도의 간지 계산 (입춘 고려 안 함 - 단순화)
    final year = now.year;
    final ganIndex = (year - 4) % 10;
    final jiIndex = (year - 4) % 12;
    final gan = cheongan[ganIndex < 0 ? ganIndex + 10 : ganIndex];
    final ji = jiji[jiIndex < 0 ? jiIndex + 12 : jiIndex];
    final ganHanja = cheonganHanja[gan] ?? '';
    final jiHanja = jijiHanja[ji] ?? '';

    _buffer.writeln('## 현재 날짜');
    _buffer.writeln('오늘은 ${now.year}년 ${now.month}월 ${now.day}일 (${weekday}요일)입니다.');
    _buffer.writeln('올해는 ${gan}${ji}년(${ganHanja}${jiHanja}年)입니다.');
    _buffer.writeln();
    _buffer.writeln('**중요: 현재 연도는 ${now.year}년입니다. 모든 답변에서 반드시 ${now.year}년 기준으로 이야기하세요. 절대 다른 연도를 현재로 언급하지 마세요.**');
    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
  }

  /// 페르소나 지시문 추가
  void _addPersona(String personaPrompt, {String locale = 'ko'}) {
    if (locale != 'ko') {
      final langMap = {
        'en': 'English', 'ja': '日本語', 'zh': '中文(简体)', 'vi': 'Tiếng Việt',
        'th': 'ภาษาไทย', 'id': 'Bahasa Indonesia', 'ms': 'Bahasa Melayu',
        'my': 'မြန်မာဘာသာ', 'fr': 'Français', 'de': 'Deutsch',
        'es': 'Español', 'pt': 'Português', 'it': 'Italiano',
        'ru': 'Русский', 'hi': 'हिन्दी', 'ar': 'العربية',
      };
      final langName = langMap[locale] ?? locale;
      _buffer.writeln('## Character & Personality Setting');
      _buffer.writeln('> The following character instructions are written in Korean for reference.');
      _buffer.writeln('> Follow the personality and tone described below, but you MUST respond in **$langName**.');
      _buffer.writeln();
      _buffer.writeln(personaPrompt);
      _buffer.writeln();
      _buffer.writeln('> END CHARACTER SETTING — Remember: respond in **$langName**, not Korean.');
      _buffer.writeln('---');
    } else {
      _buffer.writeln('## 캐릭터 설정');
      _buffer.writeln();
      _buffer.writeln(personaPrompt);
      _buffer.writeln();
      _buffer.writeln('---');
    }
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

    // 디버깅 로그: saju_analyses 데이터 확인
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 [5] SAJU_ANALYSES 데이터 (만세력 계산 원본)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔹 사주팔자: ${chart.yearPillar.gan}${chart.yearPillar.ji} ${chart.monthPillar.gan}${chart.monthPillar.ji} ${chart.dayPillar.gan}${chart.dayPillar.ji} ${chart.hourPillar?.gan ?? '?'}${chart.hourPillar?.ji ?? '?'}');
    print('🔹 일간: ${chart.dayPillar.gan}');
    print('🔹 오행: 목${sajuAnalysis.ohengDistribution.mok} 화${sajuAnalysis.ohengDistribution.hwa} 토${sajuAnalysis.ohengDistribution.to} 금${sajuAnalysis.ohengDistribution.geum} 수${sajuAnalysis.ohengDistribution.su}');
    print('🔹 용신: ${sajuAnalysis.yongsin.yongsin.korean}');
    print('🔹 일간 강약: ${sajuAnalysis.dayStrength.level.korean} (${sajuAnalysis.dayStrength.score}점)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');

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
    _buffer.writeln('- 목(木): ${oheng.mok}');
    _buffer.writeln('- 화(火): ${oheng.hwa}');
    _buffer.writeln('- 토(土): ${oheng.to}');
    _buffer.writeln('- 금(金): ${oheng.geum}');
    _buffer.writeln('- 수(水): ${oheng.su}');
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

    // 지장간
    final jijanggan = sajuAnalysis.jijangganInfo;
    _buffer.writeln('### 지장간');
    _buffer.writeln('| 위치 | 지장간 |');
    _buffer.writeln('|------|--------|');
    _buffer.writeln('| 년지 | ${_formatJiJangGan(jijanggan.yearJi)} |');
    _buffer.writeln('| 월지 | ${_formatJiJangGan(jijanggan.monthJi)} |');
    _buffer.writeln('| 일지 | ${_formatJiJangGan(jijanggan.dayJi)} |');
    if (jijanggan.hourJi.isNotEmpty) {
      _buffer.writeln('| 시지 | ${_formatJiJangGan(jijanggan.hourJi)} |');
    }
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

    // 대운 (10년 단위 운의 흐름)
    final daeun = sajuAnalysis.daeun;
    if (daeun != null && daeun.daeUnList.isNotEmpty) {
      _buffer.writeln('### 대운 (大運)');
      _buffer.writeln('- 대운 시작 나이: ${daeun.startAge}세');
      _buffer.writeln('- 진행 방향: ${daeun.isForward ? '순행' : '역행'}');
      _buffer.writeln();
      _buffer.writeln('| 순서 | 대운 | 기간 | 천간오행 | 지지오행 |');
      _buffer.writeln('|------|------|------|---------|---------|');
      for (final d in daeun.daeUnList) {
        _buffer.writeln('| ${d.order} | ${d.pillar.fullName} | ${d.ageRange} | ${d.pillar.ganOheng} | ${d.pillar.jiOheng} |');
      }
      _buffer.writeln();
    }

    // 현재 세운 (올해의 운)
    final seun = sajuAnalysis.currentSeun;
    if (seun != null) {
      _buffer.writeln('### 세운 (歲運) — ${seun.year}년');
      _buffer.writeln('- 세운: ${seun.pillar.fullName}');
      _buffer.writeln('- 천간: ${seun.pillar.gan} (${seun.pillar.ganOheng})');
      _buffer.writeln('- 지지: ${seun.pillar.ji} (${seun.pillar.jiOheng})');
      _buffer.writeln();
    }
  }


  /// 지장간 포맷 헬퍼: "갑(정기·정인) 을(중기·편인) 병(여기·상관)"
  String _formatJiJangGan(List<JiJangGanItem> items) {
    if (items.isEmpty) return '-';
    return items.map((i) => '${i.gan}(${i.type}·${i.sipsin.korean})').join(' ');
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
  /// v6.0 (Phase 57): isThirdPartyCompatibility 지원
  void _addCompatibilityInstructions(bool isThirdPartyCompatibility, SajuProfile? person1, SajuProfile? person2) {
    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
    _buffer.writeln('## 궁합 분석 가이드');
    _buffer.writeln();

    if (isThirdPartyCompatibility && person1 != null && person2 != null) {
      // 나 제외 모드: 두 사람 모두 제3자
      _buffer.writeln('이 상담은 **제3자 궁합 분석** 모드입니다.');
      _buffer.writeln('**${person1.displayName}**님과 **${person2.displayName}**님, 두 사람의 사주를 비교 분석해주세요.');
      _buffer.writeln('상담 요청자는 이 두 사람의 궁합이 궁금한 것이며, 요청자 본인의 궁합이 아닙니다.');
    } else {
      _buffer.writeln('이 상담은 **궁합 분석** 모드입니다. 두 사람의 사주를 비교 분석해주세요.');
    }
    _buffer.writeln();
    _buffer.writeln('### 데이터 활용 지시');
    _buffer.writeln('- 위에 제공된 **모든 참가자**의 **사주팔자 8글자, 오행 분포, 용신, 십성, 합충형해파** 데이터를 반드시 활용하세요.');
    _buffer.writeln('- 사용자가 특정 인물을 언급하면 해당 인물의 사주 데이터를 즉시 활용하세요.');
    _buffer.writeln('- 두 사람의 일간(日干)을 비교하여 천간합 여부와 오행 관계를 먼저 분석하세요.');
    _buffer.writeln('- 구체적인 글자를 인용하며 분석하세요 (예: "경금 일간과 을목 일간이 을경합을 이루어...").');
    _buffer.writeln('- 위에 사주 데이터가 제공된 참가자는 바로 분석하세요. 데이터가 없는 인물이 언급되면 생년월일시를 요청하세요.');
    _buffer.writeln();
    _buffer.writeln('### 분석 핵심 원칙 (v4.1)');
    _buffer.writeln('- **합이 다 좋은 게 아님**: 합화 결과가 용신 방향이면 좋은 합, 기신 방향이면 나쁜 합');
    _buffer.writeln('- **충이 다 나쁜 게 아님**: 신강 사주에서 충은 막힌 기운을 뚫어주는 약이 될 수 있음');
    _buffer.writeln('- **충의 강도 구분**: 왕지충(자오,묘유) > 생지충(인신,사해) > 고지충(진술,축미) 순 파괴력. 단, 지속시간은 고지충이 가장 길음');
    _buffer.writeln('- **삼형과 충은 근본적으로 다름**: 삼형은 질기게 지속되며 합으로 해소 어려움');
    _buffer.writeln('- **쌍방 분석 필수**: 상대→나 도움뿐 아니라 나→상대 도움도 반드시 분석');
    _buffer.writeln('- **오행 순환 확인**: 두 사람 합쳐서 금→수→목→화→토 순환 여부 체크');
    _buffer.writeln('- **비겁 양면성**: 비겁이 많다고 무조건 나쁘지 않음 — 재성을 극하면 돈 버는 능력');
    _buffer.writeln('- **객관적 분석**: 나쁜 결과도 사실대로 전달하되 개선 방안 함께 제시');
  }

  /// v8.2: 관계 유형별 분석 지시문 — 세분류 19종 대응
  ///
  /// AI가 구체적 관계 유형에 맞는 분석과 후속 질문을 생성하도록 지시
  /// 예: 부모 vs 자녀 vs 배우자 → 완전히 다른 상담 방향
  void _addRelationTypeContext(String relationType) {
    final type = ProfileRelationType.fromValue(relationType);

    _buffer.writeln();
    _buffer.writeln('## 관계 유형별 분석 지침');
    _buffer.writeln('두 사람의 관계: **${type.displayName}** (${type.localizedCategoryLabel})');
    _buffer.writeln();

    switch (type) {
      // ═══════════════════════════════════════
      // 가족 관계 (공통: 연애/성적/속궁합 절대 금지)
      // ═══════════════════════════════════════
      case ProfileRelationType.familyParent:
        _buffer.writeln('### 분석 초점 — 부모');
        _buffer.writeln('- 부모의 양육 스타일과 자녀의 기질 궁합');
        _buffer.writeln('- 세대 간 가치관 차이, 효도 방향, 부모 건강운');
        _buffer.writeln('- 부모가 자녀에게 미치는 운세적 영향 (대운/세운 흐름)');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 부모님과의 소통법, 효도 방향, 부모 건강운, 노후 지원 시기');
        _buffer.writeln('- **절대 금지**: 연애/성적/속궁합 관련 질문 유도 금지');

      case ProfileRelationType.familyChild:
        _buffer.writeln('### 분석 초점 — 자녀');
        _buffer.writeln('- 자녀의 타고난 기질, 적성, 재능 분석');
        _buffer.writeln('- 자녀 양육 방향, 교육 적합 분야, 진로 운');
        _buffer.writeln('- 부모-자녀 간 오행 상생/상극 관계');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 자녀 교육법, 적합 진로, 사춘기 대처, 자녀와 소통법');
        _buffer.writeln('- **절대 금지**: 연애/성적/속궁합 관련 질문 유도 금지');

      case ProfileRelationType.familySibling:
        _buffer.writeln('### 분석 초점 — 형제/자매');
        _buffer.writeln('- 형제자매 간 성격 차이와 보완 관계');
        _buffer.writeln('- 우애, 경쟁심, 재산/상속 관련 갈등 요소');
        _buffer.writeln('- 함께 사업/투자 가능성');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 형제 화합법, 공동 투자, 가업 승계, 부모 부양 역할 분담');
        _buffer.writeln('- **절대 금지**: 연애/성적/속궁합 관련 질문 유도 금지');

      case ProfileRelationType.familySpouse:
        _buffer.writeln('### 분석 초점 — 배우자');
        _buffer.writeln('- 부부 궁합의 핵심: 일주 궁합, 오행 균형, 합충 관계');
        _buffer.writeln('- 결혼 생활 만족도, 갈등 요인, 재물운 시너지');
        _buffer.writeln('- 배우자 덕, 해로 가능성, 중년/노년 운세 변화');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 부부 갈등 해소, 재물운, 자녀운, 노후 계획, 속궁합');
        _buffer.writeln('- 배우자이므로 속궁합/잠자리 궁합 질문 자연스럽게 허용');

      case ProfileRelationType.familyGrandparent:
        _buffer.writeln('### 분석 초점 — 조부모');
        _buffer.writeln('- 조부모의 운세가 손자녀에게 미치는 영향 (유전적 오행)');
        _buffer.writeln('- 세대 간 유대감, 조부모 건강운, 가문의 기운');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 조부모 건강운, 가문 기운, 손자녀와의 유대 강화법');
        _buffer.writeln('- **절대 금지**: 연애/성적/속궁합 관련 질문 유도 금지');

      case ProfileRelationType.familyInLaw:
        _buffer.writeln('### 분석 초점 — 시댁/처가 (인척)');
        _buffer.writeln('- 시부모/장인장모와의 궁합, 갈등 요인');
        _buffer.writeln('- 며느리/사위로서의 역할과 기대치 차이');
        _buffer.writeln('- 명절/가족 행사에서의 관계 개선 방향');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 시댁/처가 관계 개선, 명절 스트레스 해소, 역할 갈등');
        _buffer.writeln('- **절대 금지**: 연애/성적/속궁합 관련 질문 유도 금지');

      case ProfileRelationType.familyOther:
        _buffer.writeln('### 분석 초점 — 기타 가족');
        _buffer.writeln('- 가족 관계 내에서의 역할과 상호 영향');
        _buffer.writeln('- 가족 화합, 갈등 해소, 건강운 상호영향');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 가족 소통법, 화합 방안, 건강운');
        _buffer.writeln('- **절대 금지**: 연애/성적/속궁합 관련 질문 유도 금지');

      // ═══════════════════════════════════════
      // 연인 관계 (속궁합/친밀감 허용)
      // ═══════════════════════════════════════
      case ProfileRelationType.romanticPartner:
        _buffer.writeln('### 분석 초점 — 현재 연인/파트너');
        _buffer.writeln('- 감정 교감, 일주 궁합, 결혼 적합성, 속궁합');
        _buffer.writeln('- 관계 발전 가능성, 결혼 시기, 동거/결혼 후 변화');
        _buffer.writeln('- 상대방의 바람기, 충성심, 장기 인연 여부');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 결혼 시기, 속궁합, 성격 차이 극복, 장기 전망, 프러포즈 시기');
        _buffer.writeln('- 속궁합, 잠자리 궁합, 육체적 케미 등 친밀감 관련 자연스럽게 허용');

      case ProfileRelationType.romanticCrush:
        _buffer.writeln('### 분석 초점 — 짝사랑/관심 상대');
        _buffer.writeln('- 상대방의 이상형과 나의 사주 부합도');
        _buffer.writeln('- 고백 적기, 상대방의 연애 성향, 인연 가능성');
        _buffer.writeln('- 상대방이 나에게 호감을 느낄 운세 시기');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 고백 시기, 어필 방법, 상대 마음 읽기, 인연 여부');
        _buffer.writeln('- 아직 사귀지 않으므로 속궁합보다는 감정 교류 중심');

      case ProfileRelationType.romanticEx:
        _buffer.writeln('### 분석 초점 — 전 연인');
        _buffer.writeln('- 이별 원인의 사주적 해석 (충/형/파 관계)');
        _buffer.writeln('- 재회 가능성, 재회 시 반복될 갈등 요인');
        _buffer.writeln('- 미련을 놓아야 할지, 다시 시도할지 운세 판단');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 재회 가능성, 미련 정리, 다음 인연 시기, 이별 교훈');
        _buffer.writeln('- 감정 회복과 새 출발에 초점');

      // ═══════════════════════════════════════
      // 친구 관계
      // ═══════════════════════════════════════
      case ProfileRelationType.friendClose:
        _buffer.writeln('### 분석 초점 — 절친/베프');
        _buffer.writeln('- 깊은 우정의 사주적 근거, 서로에게 미치는 영향');
        _buffer.writeln('- 평생 함께할 인연인지, 우정이 깨질 시기가 있는지');
        _buffer.writeln('- 함께 동업/투자 시 궁합');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 우정 유지법, 동업 가능성, 서로의 운세 영향, 평생 인연 여부');

      case ProfileRelationType.friendGeneral:
        _buffer.writeln('### 분석 초점 — 일반 친구/지인');
        _buffer.writeln('- 인연의 깊이, 더 가까워질 가능성');
        _buffer.writeln('- 서로에게 긍정/부정적 영향, 협업 가능성');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 관계 발전 가능성, 신뢰도, 공동 프로젝트, 우정 유지');

      // ═══════════════════════════════════════
      // 직장 관계 (파워 다이나믹 반영)
      // ═══════════════════════════════════════
      case ProfileRelationType.workBoss:
        _buffer.writeln('### 분석 초점 — 상사/윗사람');
        _buffer.writeln('- 상사의 리더십 스타일과 나의 업무 스타일 궁합');
        _buffer.writeln('- 상사의 인정을 받을 수 있는 시기, 승진 가능성');
        _buffer.writeln('- 갈등 시 대처법, 상사의 약점과 강점 파악');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 상사에게 인정받는 법, 승진 시기, 갈등 해소, 이직 판단');

      case ProfileRelationType.workSubordinate:
        _buffer.writeln('### 분석 초점 — 부하/후배');
        _buffer.writeln('- 부하 직원의 잠재력, 적합한 업무 배치');
        _buffer.writeln('- 동기부여 방법, 성장 가능성, 신뢰할 수 있는 사람인지');
        _buffer.writeln('- 리더십 궁합, 위임 가능 범위');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 효과적 관리법, 위임 범위, 후배 육성, 팀 궁합');

      case ProfileRelationType.workColleague:
        _buffer.writeln('### 분석 초점 — 동료');
        _buffer.writeln('- 업무 스타일 궁합, 협업 시너지');
        _buffer.writeln('- 경쟁 관계 vs 협력 관계, 프로젝트 궁합');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 협업 방법, 경쟁 대처, 공동 프로젝트 성공 가능성');

      case ProfileRelationType.workClient:
        _buffer.writeln('### 분석 초점 — 고객/클라이언트');
        _buffer.writeln('- 비즈니스 신뢰 궁합, 거래 성사 가능성');
        _buffer.writeln('- 장기 거래처가 될 인연인지, 주의할 시기');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 계약 성사 시기, 신뢰 구축법, 장기 거래 가능성');

      // ═══════════════════════════════════════
      // 기타 관계
      // ═══════════════════════════════════════
      case ProfileRelationType.businessPartner:
        _buffer.writeln('### 분석 초점 — 사업 파트너');
        _buffer.writeln('- 동업 궁합의 핵심: 재물운 시너지, 의사결정 스타일');
        _buffer.writeln('- 사업 성공 가능성, 분쟁 위험 시기, 역할 분담');
        _buffer.writeln('- 돈 관련 신뢰, 계약/법적 문제 발생 가능성');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 동업 적합성, 사업 시작 시기, 역할 분담, 재물운, 분쟁 방지');

      case ProfileRelationType.mentor:
        _buffer.writeln('### 분석 초점 — 멘토/스승');
        _buffer.writeln('- 멘토의 가르침 스타일과 나의 학습 스타일 궁합');
        _buffer.writeln('- 멘토에게서 배울 수 있는 핵심 역량, 인연의 깊이');
        _buffer.writeln('- 멘토 관계의 지속 기간, 독립 시기');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 멘토와의 관계 발전, 독립 시기, 은혜 갚는 방법');

      case ProfileRelationType.other:
        _buffer.writeln('### 분석 초점 — 일반 인연');
        _buffer.writeln('- 두 사람의 인연과 교류 방향, 서로에게 미치는 영향');
        _buffer.writeln('- 관계 발전 가능성, 주의해야 할 시기');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 관계 발전, 인연의 의미, 서로의 운세 영향');
    }
    _buffer.writeln();
  }

  /// 마무리 지시문 추가
  /// [totalParticipants]: 전체 참가자 수 (person1 + person2 + additional)
  void _addClosingInstructions({bool isCompatibilityMode = false, int totalParticipants = 2, String locale = 'ko'}) {
    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
    if (locale != 'ko') {
      // 비한국어: 영어로 마무리 지시 (AI가 한국어에 끌리지 않게)
      if (isCompatibilityMode) {
        if (totalParticipants > 2) {
          _buffer.writeln('Use ALL $totalParticipants participants\' data above for personalized compatibility analysis.');
          _buffer.writeln('If a mentioned person has no data provided, ask for their birth date/time and gender.');
        } else {
          _buffer.writeln('Use both people\'s data above for personalized compatibility analysis.');
          _buffer.writeln('You already have their birth dates and saju data — do NOT ask again.');
        }
        _buffer.writeln('Actively use hapchung (合沖刑破害) relationships. Hap is not always good, chung is not always bad.');
        _buffer.writeln('Deliver negative results honestly, but always suggest improvements.');
      } else {
        _buffer.writeln('Use the user\'s data above for personalized consultation.');
        _buffer.writeln('You already know their birth date — do NOT ask again.');
        _buffer.writeln('Actively use hapchung, sipsung, sinsal data. Always judge yongshin/gishin direction for hap/chung.');
        _buffer.writeln('Deliver negative results honestly, but always suggest improvements.');
      }
      _buffer.writeln();
      _buffer.writeln('**Current year: ${DateTime.now().year}. Always base your answers on this year.**');
    } else {
      // 한국어: 기존 지시
      if (isCompatibilityMode) {
        if (totalParticipants > 2) {
          _buffer.writeln('위 $totalParticipants명 모든 참가자의 정보를 참고하여 맞춤형 궁합 상담을 제공하세요.');
          _buffer.writeln('위에 프로필과 사주 데이터가 제공된 참가자는 즉시 해당 데이터를 활용하여 분석하세요.');
          _buffer.writeln('데이터가 제공되지 않은 인물이 언급되면, 해당 인물의 생년월일시와 성별을 요청하세요.');
        } else {
          _buffer.writeln('위 두 사람의 정보를 참고하여 맞춤형 궁합 상담을 제공하세요.');
          _buffer.writeln('두 사람의 생년월일과 사주 정보를 이미 알고 있으니, 다시 물어보지 마세요.');
        }
        _buffer.writeln('합충형파해 관계를 적극 활용하되, 합이 무조건 좋고 충이 무조건 나쁜 것이 아님을 기억하세요.');
        _buffer.writeln('나쁜 결과도 사실대로 전달하되 개선 방안을 함께 제시하세요.');
      } else {
        _buffer.writeln('위 사용자 정보를 참고하여 맞춤형 상담을 제공하세요.');
        _buffer.writeln('사용자가 생년월일을 다시 물어볼 필요 없이, 이미 알고 있는 정보를 활용하세요.');
        _buffer.writeln('합충형파해, 십성, 신살 정보를 적극 활용하되, 합/충의 용신·기신 방향을 반드시 판단하세요.');
        _buffer.writeln('나쁜 결과도 사실대로 전달하되 개선 방안을 함께 제시하세요.');
      }
      _buffer.writeln();
      _buffer.writeln('**현재 연도: ${DateTime.now().year}년. 반드시 이 연도를 기준으로 답변하세요.**');
    }

    // v13.0: 다국어 지시
    if (locale != 'ko') {
      final langMap = {
        'en': 'English', 'ja': '日本語', 'zh': '中文(简体)', 'vi': 'Tiếng Việt',
        'th': 'ภาษาไทย', 'id': 'Bahasa Indonesia', 'ms': 'Bahasa Melayu',
        'my': 'မြန်မာဘာသာ', 'fr': 'Français', 'de': 'Deutsch',
        'es': 'Español', 'pt': 'Português', 'it': 'Italiano',
        'ru': 'Русский', 'hi': 'हिन्दी', 'ar': 'العربية',
      };
      final langName = langMap[locale] ?? locale;
      _buffer.writeln();
      _buffer.writeln('**CRITICAL LANGUAGE INSTRUCTION:**');
      _buffer.writeln('**The user\'s language is: $langName (locale: $locale)**');
      _buffer.writeln('**You MUST respond ENTIRELY in $langName. Not Korean, not any other language.**');
      _buffer.writeln('**All saju data above is in Korean - translate all terminology into natural $langName expressions.**');
      _buffer.writeln('**[SUGGESTED_QUESTIONS] chips must also be written in $langName.**');
      _buffer.writeln('**If unsure about a saju term, use the original term in parentheses: e.g. "Day Master (日主)"**');
    }
  }

  /// 다국어 지시 (프롬프트 최상단) — 한국어 데이터 앞에 언어를 명시
  void _addTopLanguageInstruction(String locale) {
    final langMap = {
      'en': 'English', 'ja': '日本語', 'zh': '中文(简体)', 'vi': 'Tiếng Việt',
      'th': 'ภาษาไทย', 'id': 'Bahasa Indonesia', 'ms': 'Bahasa Melayu',
      'my': 'မြန်မာဘာသာ', 'fr': 'Français', 'de': 'Deutsch',
      'es': 'Español', 'pt': 'Português', 'it': 'Italiano',
      'ru': 'Русский', 'hi': 'हिन्दी', 'ar': 'العربية',
    };
    final langName = langMap[locale] ?? locale;

    _buffer.writeln('# ⚠️ LANGUAGE: $langName');
    _buffer.writeln('You MUST respond ENTIRELY in **$langName**.');
    _buffer.writeln('All data below is in Korean for reference only — your response must be in $langName.');
    _buffer.writeln('Suggested question chips must also be in $langName.');
    _buffer.writeln();
  }

  /// Gemini 궁합 분석 결과 추가
  /// v6.0 (Phase 57): isThirdPartyCompatibility 지원
  void _addCompatibilityAnalysisResult(
    CompatibilityAnalysis analysis,
    bool isThirdPartyCompatibility,
    SajuProfile? person1,
    SajuProfile? person2,
  ) {
    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
    if (isThirdPartyCompatibility && person1 != null && person2 != null) {
      _buffer.writeln('## 🎯 ${person1.displayName} ↔ ${person2.displayName} 궁합 분석 결과');
    } else {
      _buffer.writeln('## 🎯 AI 궁합 분석 결과 (Gemini)');
    }
    _buffer.writeln();

    // v7.1: 두 사람의 8글자 요약 (오행 비교 분석용)
    final p1Chars = analysis['_person1_chars'] as Map<String, dynamic>?;
    final p2Chars = analysis['_person2_chars'] as Map<String, dynamic>?;
    if (p1Chars != null && p2Chars != null) {
      _buffer.writeln('### 두 사람의 사주팔자 비교');
      _buffer.writeln('| 위치 | ${isThirdPartyCompatibility ? (person1?.displayName ?? '첫 번째') : '나'} | ${isThirdPartyCompatibility ? (person2?.displayName ?? '두 번째') : '상대방'} |');
      _buffer.writeln('|------|------|------|');
      _buffer.writeln('| 년간 | ${p1Chars['year_gan'] ?? '?'} | ${p2Chars['year_gan'] ?? '?'} |');
      _buffer.writeln('| 년지 | ${p1Chars['year_ji'] ?? '?'} | ${p2Chars['year_ji'] ?? '?'} |');
      _buffer.writeln('| 월간 | ${p1Chars['month_gan'] ?? '?'} | ${p2Chars['month_gan'] ?? '?'} |');
      _buffer.writeln('| 월지 | ${p1Chars['month_ji'] ?? '?'} | ${p2Chars['month_ji'] ?? '?'} |');
      _buffer.writeln('| 일간 | ${p1Chars['day_gan'] ?? '?'} | ${p2Chars['day_gan'] ?? '?'} |');
      _buffer.writeln('| 일지 | ${p1Chars['day_ji'] ?? '?'} | ${p2Chars['day_ji'] ?? '?'} |');
      _buffer.writeln('| 시간 | ${p1Chars['hour_gan'] ?? '?'} | ${p2Chars['hour_gan'] ?? '?'} |');
      _buffer.writeln('| 시지 | ${p1Chars['hour_ji'] ?? '?'} | ${p2Chars['hour_ji'] ?? '?'} |');
      _buffer.writeln();

      // 오행 비교 테이블
      final p1Oheng = _computeOhengFromChars(p1Chars);
      final p2Oheng = _computeOhengFromChars(p2Chars);
      _buffer.writeln('### 두 사람의 오행 분포 비교');
      _buffer.writeln('| 오행 | ${isThirdPartyCompatibility ? (person1?.displayName ?? '첫 번째') : '나'} | ${isThirdPartyCompatibility ? (person2?.displayName ?? '두 번째') : '상대방'} |');
      _buffer.writeln('|------|------|------|');
      for (final oh in ['목', '화', '토', '금', '수']) {
        _buffer.writeln('| $oh | ${p1Oheng[oh] ?? 0} | ${p2Oheng[oh] ?? 0} |');
      }
      _buffer.writeln();
    }

    // v3.7 레거시 target_calculated_saju 제거됨
    // - 상대방 사주는 saju_analyses 테이블에서 직접 로드 (_addSajuAnalysis)
    // - Gemini가 계산한 옛날 데이터가 정확한 DB 데이터와 충돌하는 문제 해결

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

    // Phase 51: 두 사람 간 합충형해파 (pair_hapchung) - 궁합의 핵심!
    // 두 가지 키 지원:
    // - 'pair_hapchung': DB 캐시에서 가져온 경우
    // - 'hapchung_details': 새로 계산한 경우 (CompatibilityResult.toJson())
    final pairHapchung = analysis['pair_hapchung'] as Map<String, dynamic>? ??
        analysis['hapchung_details'] as Map<String, dynamic>?;
    if (pairHapchung != null) {
      _addPairHapchungSection(pairHapchung);
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

  // v3.7 레거시 _addTargetCalculatedSaju / _addCalculatedHapchungSection 제거됨
  // 상대방 사주는 saju_analyses 테이블에서 직접 로드하여 _addSajuAnalysis()로 주입

  // v5.0: 다중 궁합 관련 메서드 제거됨
  // _addMultiCompatibilityAnalysisResult, _addMultiCategoryScore, _addPairCompatibilityDetail
  // 사주 궁합은 항상 2명만 가능 (합충형해파는 1:1 관계)

  /// 점수 등급 반환
  String _getScoreGrade(int score) {
    if (score >= 90) return '🏆 최고의 조합';
    if (score >= 80) return '🌟 매우 좋음';
    if (score >= 70) return '😊 좋음';
    if (score >= 60) return '🙂 보통';
    if (score >= 50) return '🤔 노력 필요';
    return '😅 주의 필요';
  }

  /// Phase 51: 두 사람 간 합충형해파 섹션 추가
  ///
  /// pair_hapchung 구조:
  /// ```json
  /// {
  ///   "hap": ["년지(年支)↔월지(月支): 자축합토(子丑合土)", ...],
  ///   "chung": [...],
  ///   "hyung": [...],
  ///   "hae": [...],
  ///   "pa": [...],
  ///   "wonjin": [...],
  ///   "overall_score": 75,
  ///   "positive_count": 3,
  ///   "negative_count": 2
  /// }
  /// ```
  void _addPairHapchungSection(Map<String, dynamic> pairHapchung) {
    _buffer.writeln('### 🔗 두 사람 간 합충형해파 (핵심 궁합 요소)');
    _buffer.writeln();

    // 종합 점수
    final overallScore = pairHapchung['overall_score'] as int?;
    final positiveCount = pairHapchung['positive_count'] as int? ?? 0;
    final negativeCount = pairHapchung['negative_count'] as int? ?? 0;

    if (overallScore != null) {
      _buffer.writeln('**종합**: $overallScore점 (긍정 ${positiveCount}개, 부정 ${negativeCount}개)');
      _buffer.writeln();
    }

    // 합 (긍정적 요소)
    final hap = pairHapchung['hap'] as List?;
    if (hap != null && hap.isNotEmpty) {
      _buffer.writeln('**🔗 합(合)** (합화 결과가 용신 방향인지 기신 방향인지 판단 필요):');
      for (final item in hap) {
        _buffer.writeln('- $item');
      }
      _buffer.writeln();
    }

    // 충 (종류·강도·위치에 따라 좋을 수도 나쁠 수도 있음)
    final chung = pairHapchung['chung'] as List?;
    if (chung != null && chung.isNotEmpty) {
      _buffer.writeln('**⚡ 충(沖)** (충의 종류·강도·위치에 따라 좋을 수도 나쁠 수도 있음):');
      for (final item in chung) {
        _buffer.writeln('- $item');
      }
      _buffer.writeln();
    }

    // 형
    final hyung = pairHapchung['hyung'] as List?;
    if (hyung != null && hyung.isNotEmpty) {
      _buffer.writeln('**⚠️ 형(刑)** - 마찰:');
      for (final item in hyung) {
        _buffer.writeln('- $item');
      }
      _buffer.writeln();
    }

    // 해
    final hae = pairHapchung['hae'] as List?;
    if (hae != null && hae.isNotEmpty) {
      _buffer.writeln('**⚠️ 해(害)** - 해로운 관계:');
      for (final item in hae) {
        _buffer.writeln('- $item');
      }
      _buffer.writeln();
    }

    // 파
    final pa = pairHapchung['pa'] as List?;
    if (pa != null && pa.isNotEmpty) {
      _buffer.writeln('**⚠️ 파(破)** - 파괴:');
      for (final item in pa) {
        _buffer.writeln('- $item');
      }
      _buffer.writeln();
    }

    // 원진
    final wonjin = pairHapchung['wonjin'] as List?;
    if (wonjin != null && wonjin.isNotEmpty) {
      _buffer.writeln('**⚠️ 원진(怨嗔)** - 원망:');
      for (final item in wonjin) {
        _buffer.writeln('- $item');
      }
      _buffer.writeln();
    }

    // 아무 것도 없는 경우
    final hasAnyHapchung = (hap?.isNotEmpty ?? false) ||
        (chung?.isNotEmpty ?? false) ||
        (hyung?.isNotEmpty ?? false) ||
        (hae?.isNotEmpty ?? false) ||
        (pa?.isNotEmpty ?? false) ||
        (wonjin?.isNotEmpty ?? false);

    if (!hasAnyHapchung) {
      _buffer.writeln('두 사람 간 특별한 합충형해파 관계가 발견되지 않았습니다.');
      _buffer.writeln('이는 중립적인 관계를 의미하며, 개인의 노력으로 관계를 발전시킬 수 있습니다.');
      _buffer.writeln();
    }
  }

  /// GPT-5.2 AI Summary 추가 (Intent Routing 적용)
  ///
  /// [aiSummary] - 전체 AI Summary
  /// [intentClassification] - Intent 분류 결과 (null이면 전체 포함)
  void _addAiSummary(
    AiSummary aiSummary,
    IntentClassificationResult? intentClassification,
  ) {
    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();

    // Intent Routing: 필요한 섹션만 필터링
    if (intentClassification != null &&
        !intentClassification.categories.contains(SummaryCategory.general)) {
      // 필터링된 데이터만 포함
      final filtered = FilteredAiSummary(
        original: aiSummary,
        classification: intentClassification,
      );

      final filteredJson = filtered.toFilteredJson();

      // 디버깅 로그: 필터링된 AI Summary 확인
      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 [6] AI_SUMMARIES 데이터 (필터링됨)');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔹 Intent 분류: ${intentClassification.categories.map((c) => c.korean).join(", ")}');
      print('🔹 포함된 Key: ${filteredJson.keys.join(", ")}');
      print('🔹 예상 토큰 절약: ~${filtered.estimatedTokenSavings}%');
      print('🔹 JSON 크기: ${const JsonEncoder().convert(filteredJson).length} bytes');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');

      _buffer.writeln('## 📊 GPT-5.2 사주 분석 (관련 섹션만)');
      _buffer.writeln(
          '다음은 GPT-5.2가 분석한 사주 정보입니다 (사용자 질문과 관련된 섹션만 포함):');
      _buffer.writeln();
      _buffer.writeln('```json');
      _buffer.writeln(
          const JsonEncoder.withIndent('  ').convert(filteredJson));
      _buffer.writeln('```');
      _buffer.writeln();
      _buffer.writeln(
          '💡 **포함된 섹션**: ${intentClassification.categories.map((c) => c.korean).join(", ")}');
      _buffer.writeln('💰 **예상 토큰 절약**: ~${filtered.estimatedTokenSavings}%');
      _buffer.writeln();
      _buffer.writeln('다른 주제에 대한 질문이 들어오면 관련 정보를 참조할 수 있습니다.');
    } else {
      // 전체 데이터 포함 (첫 메시지 or GENERAL)
      final fullJson = aiSummary.toJson();

      // 디버깅 로그: 전체 AI Summary 확인
      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 [6] AI_SUMMARIES 데이터 (전체)');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔹 Intent 분류: ${intentClassification == null ? 'null (첫 메시지)' : 'GENERAL'}');
      print('🔹 포함된 Key: ${fullJson.keys.join(", ")}');
      print('🔹 JSON 크기: ${const JsonEncoder().convert(fullJson).length} bytes');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');

      _buffer.writeln('## 📊 GPT-5.2 사주 분석 (전체)');
      _buffer.writeln('다음은 GPT-5.2가 분석한 평생 사주 정보입니다:');
      _buffer.writeln();
      _buffer.writeln('```json');
      _buffer.writeln(
          const JsonEncoder.withIndent('  ').convert(fullJson));
      _buffer.writeln('```');
    }
  }

  /// raw char map에서 오행 분포 계산 (궁합 비교용)
  Map<String, int> _computeOhengFromChars(Map<String, dynamic> chars) {
    final counts = <String, int>{'목': 0, '화': 0, '토': 0, '금': 0, '수': 0};

    void addOheng(String? char, bool isCheongan) {
      if (char == null) return;
      final oheng = isCheongan ? cheonganOheng[char] : jijiOheng[char];
      if (oheng != null && counts.containsKey(oheng)) {
        counts[oheng] = counts[oheng]! + 1;
      }
    }

    addOheng(chars['year_gan'] as String?, true);
    addOheng(chars['year_ji'] as String?, false);
    addOheng(chars['month_gan'] as String?, true);
    addOheng(chars['month_ji'] as String?, false);
    addOheng(chars['day_gan'] as String?, true);
    addOheng(chars['day_ji'] as String?, false);
    addOheng(chars['hour_gan'] as String?, true);
    addOheng(chars['hour_ji'] as String?, false);

    return counts;
  }

  /// v39: 사주 명리학 핵심 규칙 (AI 해석 정확도 향상)
  /// 2.5-flash-lite가 사주 용어를 가끔 잘못 해석하는 문제 방지
  /// ~500 토큰, implicit caching으로 2턴부터 비용 무시 가능
  void _addSajuCoreRules() {
    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
    _buffer.writeln('## 사주 명리학 핵심 규칙 (반드시 준수)');
    _buffer.writeln();
    _buffer.writeln('【오행 상생】 木→火→土→金→水→木 (목생화, 화생토, 토생금, 금생수, 수생목)');
    _buffer.writeln('【오행 상극】 木→土, 土→水, 水→火, 火→金, 金→木 (목극토, 토극수, 수극화, 화극금, 금극목)');
    _buffer.writeln();
    _buffer.writeln('【천간 오행/음양】');
    _buffer.writeln('양(+): 甲(갑)木, 丙(병)火, 戊(무)土, 庚(경)金, 壬(임)水');
    _buffer.writeln('음(-): 乙(을)木, 丁(정)火, 己(기)土, 辛(신)金, 癸(계)水');
    _buffer.writeln();
    _buffer.writeln('【십성 판별법 — 일간 기준, 절대 틀리지 말 것】');
    _buffer.writeln('같은오행+같은음양=비견, 같은오행+다른음양=겁재');
    _buffer.writeln('내가 생(生)하는 오행+같은음양=식신, +다른음양=상관');
    _buffer.writeln('내가 극(剋)하는 오행+같은음양=편재, +다른음양=정재');
    _buffer.writeln('나를 극(剋)하는 오행+같은음양=편관, +다른음양=정관');
    _buffer.writeln('나를 생(生)하는 오행+같은음양=편인, +다른음양=정인');
    _buffer.writeln();
    _buffer.writeln('【조후용신 — 궁통보감(窮通寶鑑) 핵심】');
    _buffer.writeln('봄(寅卯辰월): 수(水) 필요 — 목왕화상, 수로 윤택하게');
    _buffer.writeln('여름(巳午未월): 수(水) 필요 — 화왕토조, 수로 식혀야');
    _buffer.writeln('가을(申酉戌월): 화(火) 필요 — 금왕수냉, 화로 따뜻하게');
    _buffer.writeln('겨울(亥子丑월): 화(火) 필요 — 수왕목한, 화로 온기 공급');
    _buffer.writeln();
    _buffer.writeln('【용신 선정 — 억부법】');
    _buffer.writeln('신강(일간 강함): 설기(식상/재성) 또는 극(관성)으로 억제');
    _buffer.writeln('신약(일간 약함): 생조(인성) 또는 방조(비겁)으로 보강');
    _buffer.writeln();
    _buffer.writeln('【격국(格局) — 월지 기준 가장 강한 십성으로 판단】');
    _buffer.writeln('정관격: 조직력, 규율, 안정 / 칠살격(편관): 추진력, 권위, 강한 외부 압력');
    _buffer.writeln('정재격: 안정적 재물, 성실 / 편재격: 유동적 재물, 사업, 투기');
    _buffer.writeln('식신격: 표현력, 창의, 먹복 / 상관격: 재능, 반항, 자유분방');
    _buffer.writeln('정인격: 학문, 자격, 어머니 / 편인격: 편학, 종교, 예술, 고독');
    _buffer.writeln('비견격: 자존심, 독립, 경쟁 / 겁재격: 승부욕, 투쟁, 재물 손실 주의');
    _buffer.writeln('종왕격: 비겁 압도적 → 자기 길만 감 / 종살격: 관살 압도적 → 조직에 순응');
    _buffer.writeln('종재격: 재성 압도적 → 돈을 쫓는 삶 / 중화격: 균형 → 무난하지만 뚜렷한 특징 없음');
    _buffer.writeln();
    _buffer.writeln('【천간합(天干合) — 궁합의 핵심】');
    _buffer.writeln('甲己합토, 乙庚합금, 丙辛합수, 丁壬합목, 戊癸합화');
    _buffer.writeln();
    _buffer.writeln('【지지 삼합(三合) — 절대 틀리지 말 것】');
    _buffer.writeln('申子辰(신자진) = 水局 / 寅午戌(인오술) = 火局 / 巳酉丑(사유축) = 金局 / 亥卯未(해묘미) = 木局');
    _buffer.writeln('반합: 삼합 중 2글자만 있으면 반합 (예: 子+辰=수 반합, 寅+戌=화 반합)');
    _buffer.writeln();
    _buffer.writeln('【지지 방합(方合)】');
    _buffer.writeln('寅卯辰(인묘진)=동방 木 / 巳午未(사오미)=남방 火 / 申酉戌(신유술)=서방 金 / 亥子丑(해자축)=북방 水');
    _buffer.writeln();
    _buffer.writeln('【지지 육합(六合)】');
    _buffer.writeln('子丑합토, 寅亥합목, 卯戌합화, 辰酉합금, 巳申합수, 午未합토');
    _buffer.writeln();
    _buffer.writeln('【지지 충(冲)】');
    _buffer.writeln('子午충, 丑未충, 寅申충, 卯酉충, 辰戌충, 巳亥충');
    _buffer.writeln();
    _buffer.writeln('【해석 원칙 — 고급 규칙, 반드시 준수】');
    _buffer.writeln('1. 합화 결과가 용신이면 좋은합, 기신이면 나쁜합');
    _buffer.writeln('2. 충이 용신을 활성화하면 좋은충 (고지충=창고개방)');
    _buffer.writeln('3. 삼형≠충. 삼형은 만성적 마찰, 합으로 해소 불가');
    _buffer.writeln('4. 궁합은 쌍방(A→B + B→A) 양쪽 다 봐야 함');
    _buffer.writeln('5. 전무오행이 대운으로 오면 폭발적 반응');
    _buffer.writeln('6. 반합→삼합 완성 시점 = 인생 정점 예측 핵심');
    _buffer.writeln('7. 종격 먼저 판별. 종격이면 억부법 적용 안 됨');
    _buffer.writeln('8. 대운은 만세력 데이터 그대로. 임의 계산 금지');
    _buffer.writeln('9. 합과 충 동시 발생 시 삼합·방합이 충을 흡수');
    _buffer.writeln('10. 丙火(양화=태양)와 丁火(음화=촛불) 성격 구분 필수');
    _buffer.writeln('11. 모든 십성·구조는 양면성. 무조건 좋다/나쁘다 금지');
    _buffer.writeln();
    _buffer.writeln('⚠️ 위 규칙을 반드시 참조하세요. 모르면 추측하지 말고 "확인이 필요하다"고 하세요.');
    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
  }

}
