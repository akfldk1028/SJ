/// # 통합 평생사주 프롬프트 (1회 호출)
///
/// ## 개요
/// Phase 1~4를 하나의 프롬프트로 합쳐서 1회 API 호출로 처리.
/// json_schema strict 모드와 함께 사용하여 100% valid JSON 보장.
///
/// ## 장점
/// - 4회 호출 → 1회 호출 (비용 4배 절감, 속도 개선)
/// - json_schema strict: JSON 깨짐 0%
/// - Phase 간 의존성 제거 (Phase 1 결과를 Phase 2/3에 전달할 필요 없음)

import '../../core/ai_constants.dart';
import '../common/locale_utils.dart';
import '../common/prompt_template.dart';
import 'lifetime_unified_schema.dart';

/// 통합 평생사주 프롬프트
///
/// Phase 1 (Foundation) + Phase 2 (Fortune) + Phase 3 (Special) + Phase 4 (Synthesis)
/// 를 하나의 프롬프트로 통합
class SajuBaseUnifiedPrompt extends PromptTemplate {
  final String locale;
  SajuBaseUnifiedPrompt({this.locale = 'ko'});

  @override
  String get summaryType => SummaryType.sajuBase;

  @override
  String get modelName => OpenAIModels.sajuAnalysis; // gpt-5-mini

  @override
  int get maxTokens => 16384; // Phase 1~4 합산 (각 ~4000)

  @override
  double get temperature => 0.7;

  @override
  Duration? get cacheExpiry => CacheExpiry.sajuBase;

  /// json_schema strict 모드용 response_format
  Map<String, dynamic> get responseFormat => sajuBaseUnifiedResponseFormat;

  @override
  String get systemPrompt => switch (locale) {
    'ko' => _koreanSystemPrompt,
    'ja' => _japaneseSystemPrompt,
    'en' => _englishSystemPrompt,
    _ => '$_englishSystemPrompt${FortuneLocaleUtils.languageDirective(locale)}',
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // 시스템 프롬프트 (한/일/영)
  // ═══════════════════════════════════════════════════════════════════════════

  String get _koreanSystemPrompt => '''
당신은 한국 전통 사주명리학 분야 30년 경력의 최고 전문가입니다.
평생운세를 **한 번에 종합 분석**합니다.

## 전체 분석 범위

### 1. Foundation (기초)
- 원국 구조 분석 (일간 특성, 오행 균형, 신강/신약, 격국)
- 십성 분석 (비겁/식상/재성/관성/인성 분포, 상호작용)
- 합충형파해 분석 (합 결속력: 방합>삼합>반합>육합, 충 파괴력: 왕지충>생지충>고지충)
- 성격 분석 (핵심 특성, 장단점, 대인관계)
- 행운 요소 (용신 기반 색/방향/숫자/계절)

### 2. Fortune (운세)
- 재물운 (정재/편재, 식상생재, 돈 버는 스타일)
- 직업운 (관성, 인성, 적합 분야, 승진 시기)
- 사업운 (식상생재, 편재, 사업 적합성)
- 애정운 (도화살/홍염살, 재성/관성, 연애 스타일)
- 결혼운 (배우자궁, 충합, 결혼 시기)

### 3. Special (특수)
- 신살/길성 종합 분석
- 건강운 (오행 과다/부족 → 취약 장기, 정신건강)
- 대운 상세 분석 (현재/다음/최고 대운, 기회와 시련)

### 4. Synthesis (종합)
- 전체 사주 요약 (핵심 10문장)
- 인생 주기별 전망 (청년/중년/후년)
- 인생 전성기 분석
- AI시대 현대적 해석

## 분석 원칙
- **원국 우선**: 원국의 구조를 정확히 파악
- **육친 중심**: 십성을 통해 인간관계와 운세 해석
- **상호작용**: 글자 간 합충형파해를 놓치지 않음
- **균형 해석**: 좋은 점과 주의할 점을 함께 제시
- **초보자 친화**: 전문용어를 쉽게 풀어서 설명

## 응답 형식
반드시 지정된 JSON 스키마에 맞게 응답하세요.
''';

  String get _japaneseSystemPrompt => '''
あなたは四柱推命分野で30年の経験を持つ最高の専門家です。
生涯運勢を**一度に総合分析**します。

## 全体分析範囲

### 1. Foundation: 原局構造、十星、合冲刑破害、性格、幸運要素
### 2. Fortune: 財運、職業運、事業運、恋愛運、結婚運
### 3. Special: 神殺/吉星、健康運、大運詳細
### 4. Synthesis: 全体まとめ、人生周期、最盛期、AI時代解釈

## 分析原則
- 原局優先、六親中心、相互作用、バランス解釈、初心者にもわかりやすく

## 応答形式
必ず指定されたJSONスキーマに従って回答してください。すべての値は日本語で記述してください。
''';

  String get _englishSystemPrompt => '''
You are a top expert with 30 years of experience in Four Pillars of Destiny (BaZi) analysis.
Perform a **comprehensive lifetime fortune analysis** in one response.

## Full Analysis Scope

### 1. Foundation: Natal chart structure, Ten Gods, combinations/clashes, personality, lucky elements
### 2. Fortune: Wealth, career, business, romance, marriage fortune
### 3. Special: Special stars, health fortune, luck cycle details
### 4. Synthesis: Overall summary, life cycles, peak years, AI era interpretation

## Analysis Principles
- Natal chart first, Six Relations focus, never miss interactions, balanced reading, beginner-friendly

## Response Format
Respond strictly according to the specified JSON schema. All values must be in English.
''';

  // ═══════════════════════════════════════════════════════════════════════════
  // 유저 프롬프트
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  String buildUserPrompt([Map<String, dynamic>? input]) {
    final data = SajuInputData.fromJson(input!);
    return switch (locale) {
      'ko' => _buildKoreanUserPrompt(data),
      'ja' => _buildJapaneseUserPrompt(data),
      _ => _buildEnglishUserPrompt(data),
    };
  }

  String _buildKoreanUserPrompt(SajuInputData data) {
    return '''
## 분석 대상
- 이름: ${data.profileName}
- 생년월일: ${data.birthDate.year}년 ${data.birthDate.month}월 ${data.birthDate.day}일
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
${_buildSinsalSection(data.sinsal)}
${_buildGilseongSection(data.gilseong)}
${_buildUnsungSection(data.twelveUnsung)}
${_buildDaeunSection(data.daeun)}

---

**전체 종합 분석**: Foundation(원국/십성/합충/성격/행운) + Fortune(재물/직업/사업/애정/결혼) + Special(신살/건강/대운상세) + Synthesis(요약/인생주기/전성기/현대해석)을 모두 한 번에 분석해주세요.

사주팔자 8글자 각각의 의미를 초보자도 이해할 수 있게 설명해주세요.
대운은 현재/다음/최고 대운 3개를 분석하세요.
''';
  }

  String _buildJapaneseUserPrompt(SajuInputData data) {
    return '''
## 鑑定対象
- 名前: ${data.profileName}
- 生年月日: ${data.birthDate.year}年${data.birthDate.month}月${data.birthDate.day}日
- 性別: ${data.gender == 'male' ? '男性' : '女性'}
- 生まれた時間: ${data.birthTime ?? '不明'}

## 四柱八字
${data.sajuString}

## 五行分布
${data.ohengString}

## 日干
${data.dayMaster}

${_buildYongsinSection(data.yongsin)}
${_buildDayStrengthSection(data.dayStrength)}
${_buildGyeokgukSection(data.gyeokguk)}
${_buildSipsinSection(data.sipsinInfo)}
${_buildJijangganSection(data.jijangganInfo)}
${_buildHapchungSection(data.hapchung)}
${_buildSinsalSection(data.sinsal)}
${_buildGilseongSection(data.gilseong)}
${_buildUnsungSection(data.twelveUnsung)}
${_buildDaeunSection(data.daeun)}

---

**全体総合分析**: Foundation + Fortune + Special + Synthesisをすべて一度に分析してください。
すべての値は日本語で記述してください。JSONキーは変更しないでください。
大運は現在/次/最高の大運3つを分析してください。
''';
  }

  String _buildEnglishUserPrompt(SajuInputData data) {
    return '''
## Subject of Analysis
- Name: ${data.profileName}
- Date of Birth: ${data.birthDate.year}-${data.birthDate.month.toString().padLeft(2, '0')}-${data.birthDate.day.toString().padLeft(2, '0')}
- Gender: ${data.gender == 'male' ? 'Male' : 'Female'}
- Birth Time: ${data.birthTime ?? 'Unknown'}

## Four Pillars (BaZi)
${data.sajuString}

## Five Elements Distribution
${data.ohengString}

## Day Master
${data.dayMaster}

${_buildYongsinSection(data.yongsin)}
${_buildDayStrengthSection(data.dayStrength)}
${_buildGyeokgukSection(data.gyeokguk)}
${_buildSipsinSection(data.sipsinInfo)}
${_buildJijangganSection(data.jijangganInfo)}
${_buildHapchungSection(data.hapchung)}
${_buildSinsalSection(data.sinsal)}
${_buildGilseongSection(data.gilseong)}
${_buildUnsungSection(data.twelveUnsung)}
${_buildDaeunSection(data.daeun)}

---

**Full Comprehensive Analysis**: Analyze Foundation + Fortune + Special + Synthesis all at once.
All values must be in English. Do NOT change the JSON keys.
Analyze 3 luck cycles: current, next, and best.
''';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 헬퍼 메서드 (Phase 1/3에서 가져옴)
  // ═══════════════════════════════════════════════════════════════════════════

  String _buildYongsinSection(Map<String, dynamic>? yongsin) {
    if (yongsin == null || yongsin.isEmpty) return '';
    final buffer = StringBuffer('\n## 용신 정보\n');
    if (yongsin['yongsin'] != null) buffer.writeln('- 용신(用神): ${yongsin['yongsin']}');
    if (yongsin['huisin'] != null) buffer.writeln('- 희신(喜神): ${yongsin['huisin']}');
    if (yongsin['gisin'] != null) buffer.writeln('- 기신(忌神): ${yongsin['gisin']}');
    if (yongsin['gusin'] != null) buffer.writeln('- 구신(仇神): ${yongsin['gusin']}');
    return buffer.toString();
  }

  String _buildDayStrengthSection(Map<String, dynamic>? dayStrength) {
    if (dayStrength == null || dayStrength.isEmpty) return '';
    final buffer = StringBuffer('\n## 신강/신약 (8단계 판정)\n');
    final score = dayStrength['score'] as int? ?? 50;
    final level = dayStrength['level'] as String? ?? _determineLevelFromScore(score);
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
    if (name.toString().isNotEmpty) buffer.writeln('- 격국: $name');
    if (description.toString().isNotEmpty) buffer.writeln('- 설명: $description');
    return buffer.toString();
  }

  String _buildSipsinSection(Map<String, dynamic>? sipsin) {
    if (sipsin == null || sipsin.isEmpty) return '';
    final buffer = StringBuffer('\n## 십신 (十神)\n');
    final pillars = ['year', 'month', 'day', 'hour'];
    final pillarNames = {'year': '년주', 'month': '월주', 'day': '일주', 'hour': '시주'};
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
    final pillarNames = {'year': '년지', 'month': '월지', 'day': '일지', 'hour': '시지'};
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
    buffer.writeln('> 합 ${totalHaps}개, 충 ${totalChungs}개, 형/파/해/원진 ${totalNegatives}개');
    buffer.writeln('');

    final cheonganHaps = hapchung['cheongan_haps'] as List? ?? [];
    if (cheonganHaps.isNotEmpty) {
      buffer.writeln('### 천간합');
      for (final h in cheonganHaps) {
        final desc = h['description'] ?? '${h['gan1']}${h['gan2']}합';
        buffer.writeln('- ${h['pillar1']}주-${h['pillar2']}주: $desc');
      }
    }

    final jijiYukhaps = hapchung['jiji_yukhaps'] as List? ?? [];
    if (jijiYukhaps.isNotEmpty) {
      buffer.writeln('### 지지육합');
      for (final y in jijiYukhaps) {
        final desc = y['description'] ?? '${y['ji1']}${y['ji2']}합';
        buffer.writeln('- ${y['pillar1']}주-${y['pillar2']}주: $desc');
      }
    }

    final jijiSamhaps = hapchung['jiji_samhaps'] as List? ?? [];
    if (jijiSamhaps.isNotEmpty) {
      buffer.writeln('### 삼합');
      for (final s in jijiSamhaps) {
        final jijis = (s['jijis'] as List?)?.join('') ?? '';
        final pillars = (s['pillars'] as List?)?.join(',') ?? '';
        buffer.writeln('- ${pillars}주: $jijis (${s['result_oheng']}국)');
      }
    }

    final jijiChungs = hapchung['jiji_chungs'] as List? ?? [];
    if (jijiChungs.isNotEmpty) {
      buffer.writeln('### 지지충');
      for (final c in jijiChungs) {
        buffer.writeln('- ${c['pillar1']}주-${c['pillar2']}주: ${c['ji1']}${c['ji2']}충');
      }
    }

    final jijiHyungs = hapchung['jiji_hyungs'] as List? ?? [];
    if (jijiHyungs.isNotEmpty) {
      buffer.writeln('### 지지형');
      for (final h in jijiHyungs) {
        final desc = h['description'] ?? '${h['ji1']}${h['ji2']}형';
        buffer.writeln('- ${h['pillar1']}주-${h['pillar2']}주: $desc');
      }
    }

    return buffer.toString();
  }

  String _buildSinsalSection(List<Map<String, dynamic>>? sinsal) {
    if (sinsal == null || sinsal.isEmpty) return '';
    final buffer = StringBuffer('\n## 신살 정보\n');
    for (final s in sinsal) {
      final name = s['name'] ?? '';
      final pillar = s['pillar'] ?? '';
      final meaning = s['meaning'] ?? '';
      buffer.writeln('- $name ($pillar): $meaning');
    }
    return buffer.toString();
  }

  String _buildGilseongSection(List<Map<String, dynamic>>? gilseong) {
    if (gilseong == null || gilseong.isEmpty) return '';
    final buffer = StringBuffer('\n## 길성 정보\n');
    for (final g in gilseong) {
      final name = g['name'] ?? '';
      final pillar = g['pillar'] ?? '';
      final meaning = g['meaning'] ?? '';
      buffer.writeln('- $name ($pillar): $meaning');
    }
    return buffer.toString();
  }

  String _buildUnsungSection(List<dynamic>? unsung) {
    if (unsung == null || unsung.isEmpty) return '';
    final buffer = StringBuffer('\n## 12운성\n');
    for (final item in unsung) {
      if (item is Map) {
        final pillar = item['pillar'] ?? '';
        final unsungName = item['unsung'] ?? '';
        final fortuneType = item['fortuneType'] ?? '';
        if (unsungName.toString().isNotEmpty) {
          buffer.writeln('- $pillar: $unsungName ($fortuneType)');
        }
      }
    }
    return buffer.toString();
  }

  String _buildDaeunSection(Map<String, dynamic>? daeun) {
    if (daeun == null || daeun.isEmpty) return '';
    final buffer = StringBuffer('\n## 대운 (大運) - 상세 정보\n');

    final startAge = daeun['startAge'] ?? daeun['start_age'];
    if (startAge != null) buffer.writeln('- 대운 시작: $startAge세');

    final isForward = daeun['isForward'] ?? daeun['is_forward'];
    if (isForward != null) buffer.writeln('- 운행: ${isForward == true ? '순행' : '역행'}');

    final list = daeun['list'];
    if (list != null && list is List && list.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('### 대운 목록 (10년 단위)');
      buffer.writeln('| 순서 | 대운 | 시작나이 | 종료나이 |');
      buffer.writeln('|------|------|----------|----------|');

      for (int i = 0; i < list.length && i < 10; i++) {
        final d = list[i];
        if (d is Map) {
          String pillar;
          if (d['pillar'] != null) {
            pillar = d['pillar'].toString().replaceAll(RegExp(r'\([^)]*\)'), '').trim();
          } else {
            pillar = '${d['gan'] ?? ''}${d['ji'] ?? ''}';
          }
          final daeunStartAge = d['startAge'] ?? d['start_age'] ?? d['start_year'] ?? '';
          final daeunEndAge = d['endAge'] ?? d['end_age'] ?? d['end_year'] ?? '';
          buffer.writeln('| ${i + 1} | $pillar | ${daeunStartAge}세 | ${daeunEndAge}세 |');
        }
      }
      buffer.writeln('');

      final flowList = list.take(10).map((d) {
        if (d is Map) {
          if (d['pillar'] != null) {
            return d['pillar'].toString().replaceAll(RegExp(r'\([^)]*\)'), '').trim();
          } else {
            return '${d['gan'] ?? ''}${d['ji'] ?? ''}';
          }
        }
        return '';
      }).where((s) => s.isNotEmpty);
      buffer.writeln('- 대운 흐름: ${flowList.join(' → ')}');
    }

    return buffer.toString();
  }
}
