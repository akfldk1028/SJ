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
  }) {
    _buffer.clear();

    // v5.0: 다중 궁합 제거됨 - 궁합은 항상 2명만 (합충형해파는 1:1 관계)
    // 궁합 모드 여부 (상대방이 있는 경우)
    final isCompatibilityMode = targetProfile != null;

    // 1. 현재 날짜
    _addCurrentDate();

    // 2. 페르소나 지시문
    if (personaPrompt != null && personaPrompt.isNotEmpty) {
      _addPersona(personaPrompt);
    }

    // 3. 기본 프롬프트
    _buffer.writeln(basePrompt);

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
  void _addPersona(String personaPrompt) {
    _buffer.writeln('## 캐릭터 설정');
    _buffer.writeln();
    _buffer.writeln(personaPrompt);
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

    // 각 글자별 오행 매핑 (AI가 두 사람의 오행을 정확히 비교할 수 있도록)
    _buffer.writeln('### 글자별 오행');
    _buffer.writeln('| 위치 | 글자 | 오행 |');
    _buffer.writeln('|------|------|------|');
    _buffer.writeln('| 년간 | $yearGan | ${cheonganOheng[yearGan] ?? '?'} |');
    _buffer.writeln('| 년지 | $yearJi | ${jijiOheng[yearJi] ?? '?'} |');
    _buffer.writeln('| 월간 | $monthGan | ${cheonganOheng[monthGan] ?? '?'} |');
    _buffer.writeln('| 월지 | $monthJi | ${jijiOheng[monthJi] ?? '?'} |');
    _buffer.writeln('| 일간 | $dayGan | ${cheonganOheng[dayGan] ?? '?'} |');
    _buffer.writeln('| 일지 | $dayJi | ${jijiOheng[dayJi] ?? '?'} |');
    _buffer.writeln('| 시간 | $hourGan | ${cheonganOheng[hourGan] ?? '?'} |');
    _buffer.writeln('| 시지 | $hourJi | ${jijiOheng[hourJi] ?? '?'} |');
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
  }

  /// v8.1: 관계 유형별 분석 지시문 추가
  ///
  /// AI가 관계 유형에 맞는 분석과 후속 질문을 생성하도록 지시
  void _addRelationTypeContext(String relationType) {
    final type = ProfileRelationType.fromValue(relationType);
    final category = type.categoryLabel;  // 가족/연인/친구/직장/기타

    _buffer.writeln();
    _buffer.writeln('## 관계 유형별 분석 지침');
    _buffer.writeln('두 사람의 관계: **${type.displayName}** ($category)');
    _buffer.writeln();

    switch (category) {
      case '가족':
        _buffer.writeln('### 분석 초점');
        _buffer.writeln('- 세대 간 소통, 가치관 차이, 서로 보완하는 역할');
        _buffer.writeln('- 부모자녀 소통법, 가족 갈등 해소, 건강운 상호영향');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 가족 소통법, 세대차이 극복, 건강운, 가족 화합 등');
        _buffer.writeln('- **절대 금지**: 연애/성적/속궁합 관련 질문 유도 금지');
      case '연인':
        _buffer.writeln('### 분석 초점');
        _buffer.writeln('- 감정 교감, 결혼 적합성, 성격 충돌, 속궁합');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 결혼 시기, 속궁합, 성격 차이 극복, 장기 전망 등');
        _buffer.writeln('- 속궁합, 잠자리 궁합 등 친밀감 관련 질문 자연스럽게 가능');
      case '친구':
        _buffer.writeln('### 분석 초점');
        _buffer.writeln('- 우정의 깊이, 신뢰도, 동업/협업 가능성, 장기 인연');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 우정 유지법, 동업 가능성, 신뢰 문제, 오래갈 인연인지 등');
      case '직장':
        _buffer.writeln('### 분석 초점');
        _buffer.writeln('- 업무 시너지, 리더십 궁합, 의사결정 스타일, 승진/이직 영향');
        _buffer.writeln();
        _buffer.writeln('### 후속 질문 방향');
        _buffer.writeln('- 업무 협업법, 상사/부하 관계 개선, 비즈니스 궁합, 승진운 등');
      default:
        _buffer.writeln('### 분석 초점');
        _buffer.writeln('- 일반적 궁합 분석, 두 사람의 인연과 교류 방향');
    }
    _buffer.writeln();
  }

  /// 마무리 지시문 추가
  /// [totalParticipants]: 전체 참가자 수 (person1 + person2 + additional)
  void _addClosingInstructions({bool isCompatibilityMode = false, int totalParticipants = 2}) {
    _buffer.writeln();
    _buffer.writeln('---');
    _buffer.writeln();
    if (isCompatibilityMode) {
      if (totalParticipants > 2) {
        // v12.1: 3명 이상 참가자 → 모든 참가자 동등 참조
        _buffer.writeln('위 $totalParticipants명 모든 참가자의 정보를 참고하여 맞춤형 궁합 상담을 제공하세요.');
        _buffer.writeln('위에 프로필과 사주 데이터가 제공된 참가자는 즉시 해당 데이터를 활용하여 분석하세요.');
        _buffer.writeln('데이터가 제공되지 않은 인물이 언급되면, 해당 인물의 생년월일시와 성별을 요청하세요.');
      } else {
        _buffer.writeln('위 두 사람의 정보를 참고하여 맞춤형 궁합 상담을 제공하세요.');
        _buffer.writeln('두 사람의 생년월일과 사주 정보를 이미 알고 있으니, 다시 물어보지 마세요.');
      }
      _buffer.writeln('합충형파해 관계를 적극 활용하여 깊이 있는 궁합 분석을 제공하세요.');
    } else {
      _buffer.writeln('위 사용자 정보를 참고하여 맞춤형 상담을 제공하세요.');
      _buffer.writeln('사용자가 생년월일을 다시 물어볼 필요 없이, 이미 알고 있는 정보를 활용하세요.');
      _buffer.writeln('합충형파해, 십성, 신살 정보를 적극 활용하여 깊이 있는 상담을 제공하세요.');
    }
    _buffer.writeln();
    _buffer.writeln('**현재 연도: ${DateTime.now().year}년. 반드시 이 연도를 기준으로 답변하세요.**');
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
      _buffer.writeln('**💚 합(合)** - 긍정적 결합:');
      for (final item in hap) {
        _buffer.writeln('- $item');
      }
      _buffer.writeln();
    }

    // 충 (가장 강한 부정적 요소)
    final chung = pairHapchung['chung'] as List?;
    if (chung != null && chung.isNotEmpty) {
      _buffer.writeln('**❌ 충(沖)** - 강한 충돌:');
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

}
