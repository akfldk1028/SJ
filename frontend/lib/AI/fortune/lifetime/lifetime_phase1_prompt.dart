/// # Phase 1: Foundation (기초 분석) 프롬프트
///
/// ## 개요
/// 평생운세 분석의 첫 번째 단계로, 원국/십성/합충/성격/행운요소를 분석합니다.
/// 이 결과는 후속 Phase(2,3,4)의 기반 데이터가 됩니다.
///
/// ## 출력 섹션
/// - wonGuk_analysis: 원국 분석
/// - sipsung_analysis: 십성 분석
/// - hapchung_analysis: 합충 분석
/// - personality: 성격 분석
/// - lucky_elements: 행운 요소
///
/// ## 의존성
/// 없음 (최초 분석)
///
/// ## 예상 시간
/// 60-90초

import '../../core/ai_constants.dart';
import '../common/prompt_template.dart';
import 'lifetime_prompt.dart';

/// Phase 1: Foundation 프롬프트
///
/// 원국, 십성, 합충, 성격, 행운요소 분석
class SajuBasePhase1Prompt extends PromptTemplate {
  @override
  String get summaryType => '${SummaryType.sajuBase}_phase1';

  @override
  String get modelName => OpenAIModels.sajuAnalysis; // GPT-5.2

  @override
  int get maxTokens => 10000; // Phase 1용 토큰 (6000→10000 확장, JSON 잘림 방지)

  @override
  double get temperature => 0.7;

  @override
  Duration? get cacheExpiry => CacheExpiry.sajuBase;

  @override
  String get systemPrompt => '''
당신은 한국 전통 사주명리학 분야 30년 경력의 최고 전문가입니다.
이것은 평생운세 분석의 **Phase 1 (Foundation)** 단계입니다.

## Phase 1 분석 범위
이 단계에서는 **기초 분석만** 수행합니다:
1. 원국 구조 분석
2. 십성 분석
3. 합충형파해 분석
4. 성격 분석
5. 행운 요소 분석

## 분석 방법론

### 1단계: 원국 구조 분석
- 일간(日干) 특성 분석
- 오행 분포 및 균형 분석
- 신강/신약 판정 (제공된 점수 사용)
- 격국 분석 (해당시)

### 2단계: 십성(十星) 분석
- 비겁/식상/재성/관성/인성 분포
- 강한 십성과 약한 십성 파악
- 십성 간 상호작용

### 3단계: 합충형파해 분석
**합(合) 결속력 순서**
- 방합(5 최강) > 삼합(4 유연) > 반합(3 불완전) > 육합(★ 부드러움)

**충(沖) 파괴력 순서**
- 왕지충(묘유/자오 5) > 생지충(인신/사해 4) > 고지충(진술/축미 3)

**형(刑) 흉의 강도 순서**
- 삼형(인사신/축술미 5) > 상형(3) > 자묘형(2) > 자형(1)

### 4단계: 성격 분석
- 일간과 십성 기반 핵심 성격 특성
- 장점과 약점
- 대인관계 스타일

### 5단계: 행운 요소
- 용신 기반 행운의 색, 방향, 숫자, 계절

## 분석 원칙
- **원국 우선**: 원국의 구조를 정확히 파악
- **육친 중심**: 십성을 통해 인간관계와 운세 해석
- **상호작용**: 글자 간 합충형파해를 놓치지 않음
- **균형 해석**: 좋은 점과 주의할 점을 함께 제시

## 응답 형식
반드시 JSON 형식으로만 응답하세요. 추가 설명 없이 순수 JSON만 출력하세요.
''';

  @override
  String buildUserPrompt([Map<String, dynamic>? input]) {
    final data = SajuInputData.fromJson(input!);

    return '''
## 분석 대상
- 이름: ${data.profileName}
- 생년월일: ${_formatBirthDate(data.birthDate)}
- 성별: ${data.gender == 'male' ? '남성' : '여성'}
- 태어난 시간: ${data.birthTime ?? '미상'}

## 사주 팔자
${data.sajuString}

## 오행 분포
${data.ohengString}

## 일간 (나를 대표하는 오행)
${data.dayMaster}

${_buildYongsinSection(data.yongsin)}
${_buildDayStrengthSection(data.dayStrength)}
${_buildGyeokgukSection(data.gyeokguk)}
${_buildSipsinSection(data.sipsinInfo)}
${_buildJijangganSection(data.jijangganInfo)}
${_buildHapchungSection(data.hapchung)}

---

**Phase 1 (Foundation)**: 원국, 십성, 합충, 성격, 행운요소만 분석해주세요.

반드시 아래 JSON 스키마를 정확히 따라주세요:

```json
{
  "mySajuIntro": {
    "title": "나의 사주, 나는 누구인가요?",
    "ilju": "일주(日柱) 설명: 일간+일지 조합의 의미 (예: '갑자일주는 큰 나무가 깊은 물을 만난 형상으로...')",
    "reading": "일주를 기반으로 '나'라는 사람에 대한 핵심 설명 6-8문장. 타고난 기질, 성향, 인생의 방향성을 일주 중심으로 설명. 사주 초보자도 쉽게 이해할 수 있게 작성."
  },

  "my_saju_characters": {
    "description": "사주팔자 8글자 각각의 의미를 초보자도 이해할 수 있게 설명",
    "year_gan": {
      "character": "연간 한자 (예: 甲)",
      "reading": "연간 읽는 법 (예: 갑)",
      "oheng": "오행 (목/화/토/금/수)",
      "yin_yang": "음양 (양/음)",
      "meaning": "이 글자가 뜻하는 의미를 쉽게 설명"
    },
    "year_ji": {
      "character": "연지 한자 (예: 子)",
      "reading": "연지 읽는 법 (예: 자)",
      "animal": "띠 동물 (예: 쥐)",
      "oheng": "오행",
      "yin_yang": "음양",
      "meaning": "이 글자가 뜻하는 의미를 쉽게 설명"
    },
    "month_gan": {
      "character": "월간 한자",
      "reading": "월간 읽는 법",
      "oheng": "오행",
      "yin_yang": "음양",
      "meaning": "월간의 의미 쉽게 설명"
    },
    "month_ji": {
      "character": "월지 한자",
      "reading": "월지 읽는 법",
      "season": "계절 (봄/여름/환절기/가을/겨울)",
      "oheng": "오행",
      "yin_yang": "음양",
      "meaning": "월지의 의미 쉽게 설명"
    },
    "day_gan": {
      "character": "일간 한자 (나를 대표하는 글자!)",
      "reading": "일간 읽는 법",
      "oheng": "오행",
      "yin_yang": "음양",
      "meaning": "일간은 '나 자신'을 뜻합니다. 이 글자의 특성이 곧 내 성격과 기질입니다. 쉽게 설명"
    },
    "day_ji": {
      "character": "일지 한자 (배우자궁)",
      "reading": "일지 읽는 법",
      "animal": "띠 동물",
      "oheng": "오행",
      "yin_yang": "음양",
      "meaning": "일지는 배우자궁으로 결혼운과 관련됩니다. 쉽게 설명"
    },
    "hour_gan": {
      "character": "시간 한자 (미상이면 null)",
      "reading": "시간 읽는 법",
      "oheng": "오행",
      "yin_yang": "음양",
      "meaning": "시간의 의미 쉽게 설명"
    },
    "hour_ji": {
      "character": "시지 한자 (자녀궁, 미상이면 null)",
      "reading": "시지 읽는 법",
      "animal": "띠 동물",
      "oheng": "오행",
      "yin_yang": "음양",
      "meaning": "시지는 자녀궁으로 자녀운과 말년운에 관련됩니다. 쉽게 설명"
    },
    "overall_reading": "8글자 조합이 만들어내는 전체적인 기운과 특성을 초보자도 이해할 수 있게 3-4문장으로 설명"
  },

  "wonGuk_analysis": {
    "day_master": "일간 분석 (예: 甲木일간으로 성장과 진취성을 상징)",
    "oheng_balance": "오행 균형 분석 (과다/부족 오행과 그 영향)",
    "singang_singak": "신강/신약 판정 근거와 의미",
    "gyeokguk": "격국 분석 (해당되는 경우)",
    "reading": "원국 종합 해석 8문장. 일간 본성, 오행 균형, 신강/신약이 삶에 미치는 핵심 영향"
  },

  "sipsung_analysis": {
    "dominant_sipsung": ["사주에서 강한 십성 1-3개"],
    "weak_sipsung": ["사주에서 약한 십성 1-2개"],
    "key_interactions": "십성 간 주요 상호작용 분석",
    "life_implications": "십성 구조가 인생에 미치는 영향",
    "reading": "십성 종합 해석 8문장. 비겁/식상/재성/관성/인성 분포가 성격, 재물, 직업에 미치는 핵심 영향"
  },

  "hapchung_analysis": {
    "major_haps": ["주요 합의 의미와 영향"],
    "major_chungs": ["주요 충의 의미와 영향"],
    "other_interactions": "형/파/해/원진 영향 (있는 경우)",
    "overall_impact": "합충 구조가 인생에 미치는 종합 영향",
    "reading": "합충 종합 해석 8문장. 천간합, 지지합, 충, 형, 파, 해가 변화와 기회에 미치는 핵심 영향"
  },

  "personality": {
    "core_traits": ["핵심 성격 특성 4-6개"],
    "strengths": ["장점 4-6개"],
    "weaknesses": ["약점/주의점 3-4개"],
    "social_style": "대인관계 스타일",
    "reading": "성격 종합 해석 10문장. 일간과 십성 구조 기반으로 성격, 행동 패턴, 대인관계 핵심"
  },

  "lucky_elements": {
    "colors": ["행운의 색 2-3개"],
    "directions": ["좋은 방향 1-2개"],
    "numbers": [1, 6],
    "seasons": "유리한 계절",
    "partner_elements": ["궁합이 좋은 띠 2-3개"]
  }
}
```
''';
  }

  String _formatBirthDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String _buildYongsinSection(Map<String, dynamic>? yongsin) {
    if (yongsin == null || yongsin.isEmpty) return '';

    final buffer = StringBuffer('\n## 용신 정보\n');

    if (yongsin['yongsin'] != null) {
      buffer.writeln('- 용신(用神): ${yongsin['yongsin']}');
    }
    if (yongsin['huisin'] != null) {
      buffer.writeln('- 희신(喜神): ${yongsin['huisin']}');
    }
    if (yongsin['gisin'] != null) {
      buffer.writeln('- 기신(忌神): ${yongsin['gisin']}');
    }
    if (yongsin['gusin'] != null) {
      buffer.writeln('- 구신(仇神): ${yongsin['gusin']}');
    }

    return buffer.toString();
  }

  String _buildDayStrengthSection(Map<String, dynamic>? dayStrength) {
    if (dayStrength == null || dayStrength.isEmpty) return '';

    final buffer = StringBuffer('\n## 신강/신약 (8단계 판정)\n');

    final score = dayStrength['score'] as int? ?? 50;
    final level =
        dayStrength['level'] as String? ?? _determineLevelFromScore(score);
    final isSingang = score >= 50;

    buffer.writeln('');
    buffer.writeln('┌─────────────────────────────────────────────────┐');
    buffer.writeln('│ ★★★ 이 값을 그대로 사용하세요 (재계산 금지) ★★★  │');
    buffer.writeln('├─────────────────────────────────────────────────┤');
    buffer.writeln('│ 점수: $score점                                   │');
    buffer.writeln('│ 등급: $level                                     │');
    buffer.writeln('│ is_singang: $isSingang                           │');
    buffer.writeln('└─────────────────────────────────────────────────┘');

    return buffer.toString();
  }

  String _determineLevelFromScore(int score) {
    if (score >= 88) return '극왕';
    if (score >= 75) return '태강';
    if (score >= 63) return '신강';
    if (score >= 50) return '중화신강';
    if (score >= 38) return '중화신약';
    if (score >= 26) return '신약';
    if (score >= 13) return '태약';
    return '극약';
  }

  String _buildGyeokgukSection(Map<String, dynamic>? gyeokguk) {
    if (gyeokguk == null || gyeokguk.isEmpty) return '';

    final buffer = StringBuffer('\n## 격국\n');

    final name = gyeokguk['name'] ?? gyeokguk['type'] ?? '';
    final description = gyeokguk['description'] ?? '';

    if (name.toString().isNotEmpty) {
      buffer.writeln('- 격국: $name');
    }
    if (description.toString().isNotEmpty) {
      buffer.writeln('- 설명: $description');
    }

    return buffer.toString();
  }

  String _buildSipsinSection(Map<String, dynamic>? sipsin) {
    if (sipsin == null || sipsin.isEmpty) return '';

    final buffer = StringBuffer('\n## 십신 (十神)\n');

    final pillars = ['year', 'month', 'day', 'hour'];
    final pillarNames = {
      'year': '년주',
      'month': '월주',
      'day': '일주',
      'hour': '시주'
    };

    for (final pillar in pillars) {
      final data = sipsin[pillar];
      if (data != null && data is Map) {
        final gan = data['gan'] ?? '';
        final ji = data['ji'] ?? '';
        if (gan.toString().isNotEmpty || ji.toString().isNotEmpty) {
          buffer.writeln('- ${pillarNames[pillar]}: 천간=$gan, 지지=$ji');
        }
      }
    }

    return buffer.toString();
  }

  String _buildJijangganSection(Map<String, dynamic>? jijanggan) {
    if (jijanggan == null || jijanggan.isEmpty) return '';

    final buffer = StringBuffer('\n## 지장간 (地藏干)\n');

    final pillars = ['year', 'month', 'day', 'hour'];
    final pillarNames = {
      'year': '년지',
      'month': '월지',
      'day': '일지',
      'hour': '시지'
    };

    for (final pillar in pillars) {
      final data = jijanggan[pillar];
      if (data != null) {
        if (data is List) {
          buffer.writeln('- ${pillarNames[pillar]}: ${data.join(', ')}');
        } else {
          buffer.writeln('- ${pillarNames[pillar]}: $data');
        }
      }
    }

    return buffer.toString();
  }

  String _buildHapchungSection(Map<String, dynamic>? hapchung) {
    if (hapchung == null) return '';

    final hasRelations = hapchung['has_relations'] as bool? ?? false;
    if (!hasRelations) return '';

    final buffer = StringBuffer('\n## 합충형파해 (合沖刑破害)\n');

    final totalHaps = hapchung['total_haps'] as int? ?? 0;
    final totalChungs = hapchung['total_chungs'] as int? ?? 0;
    final totalNegatives = hapchung['total_negatives'] as int? ?? 0;

    buffer.writeln(
        '> 합 ${totalHaps}개, 충 ${totalChungs}개, 형/파/해/원진 ${totalNegatives}개');
    buffer.writeln('');

    // 천간합
    final cheonganHaps = hapchung['cheongan_haps'] as List? ?? [];
    if (cheonganHaps.isNotEmpty) {
      buffer.writeln('### 천간합 (天干合)');
      for (final h in cheonganHaps) {
        final desc = h['description'] ?? '${h['gan1']}${h['gan2']}합';
        buffer.writeln('- ${h['pillar1']}주-${h['pillar2']}주: $desc');
      }
      buffer.writeln('');
    }

    // 지지육합
    final jijiYukhaps = hapchung['jiji_yukhaps'] as List? ?? [];
    if (jijiYukhaps.isNotEmpty) {
      buffer.writeln('### 지지육합 (地支六合)');
      for (final y in jijiYukhaps) {
        final desc = y['description'] ?? '${y['ji1']}${y['ji2']}합';
        buffer.writeln('- ${y['pillar1']}주-${y['pillar2']}주: $desc');
      }
      buffer.writeln('');
    }

    // 삼합
    final jijiSamhaps = hapchung['jiji_samhaps'] as List? ?? [];
    if (jijiSamhaps.isNotEmpty) {
      buffer.writeln('### 삼합 (三合)');
      for (final s in jijiSamhaps) {
        final jijis = (s['jijis'] as List?)?.join('') ?? '';
        final pillars = (s['pillars'] as List?)?.join(',') ?? '';
        buffer.writeln('- ${pillars}주: $jijis (${s['result_oheng']}국)');
      }
      buffer.writeln('');
    }

    // 방합
    final jijiBanghaps = hapchung['jiji_banghaps'] as List? ?? [];
    if (jijiBanghaps.isNotEmpty) {
      buffer.writeln('### 방합 (方合)');
      for (final b in jijiBanghaps) {
        final jijis = (b['jijis'] as List?)?.join('') ?? '';
        final pillars = (b['pillars'] as List?)?.join(',') ?? '';
        buffer.writeln('- ${pillars}주: $jijis (${b['season']})');
      }
      buffer.writeln('');
    }

    // 지지충
    final jijiChungs = hapchung['jiji_chungs'] as List? ?? [];
    if (jijiChungs.isNotEmpty) {
      buffer.writeln('### 지지충 (地支沖)');
      for (final c in jijiChungs) {
        buffer.writeln(
            '- ${c['pillar1']}주-${c['pillar2']}주: ${c['ji1']}${c['ji2']}충');
      }
      buffer.writeln('');
    }

    // 지지형
    final jijiHyungs = hapchung['jiji_hyungs'] as List? ?? [];
    if (jijiHyungs.isNotEmpty) {
      buffer.writeln('### 지지형 (地支刑)');
      for (final h in jijiHyungs) {
        final desc = h['description'] ?? '${h['ji1']}${h['ji2']}형';
        buffer.writeln('- ${h['pillar1']}주-${h['pillar2']}주: $desc');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }
}
