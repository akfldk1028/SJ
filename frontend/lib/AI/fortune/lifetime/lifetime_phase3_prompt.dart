/// # Phase 3: Special (특수 분석) 프롬프트
///
/// ## 개요
/// 평생운세 분석의 세 번째 단계로, 신살/길성, 건강운, 대운 상세를 분석합니다.
/// Phase 1 결과를 기반으로 특수 분석을 수행합니다.
///
/// ## 출력 섹션
/// - sinsal_gilseong: 신살/길성 분석
/// - health: 건강운 분석
/// - daeun_detail: 대운 상세 분석
///
/// ## 의존성
/// Phase 1 결과 필요
///
/// ## 예상 시간
/// 30-45초
///
/// ## 병렬 실행
/// Phase 2와 병렬 실행 가능 (둘 다 Phase 1에만 의존)

import '../../core/ai_constants.dart';
import '../common/prompt_template.dart';
import 'lifetime_prompt.dart';

/// Phase 3: Special 프롬프트
///
/// 신살/길성, 건강운, 대운 상세 분석
class SajuBasePhase3Prompt extends PromptTemplate {
  final String locale;
  SajuBasePhase3Prompt({this.locale = 'ko'});

  @override
  String get summaryType => '${SummaryType.sajuBase}_phase3';

  @override
  String get modelName => OpenAIModels.sajuAnalysis; // GPT-5.2

  @override
  int get maxTokens => 10000; // Phase 3용 토큰 (5000→10000 확장, JSON 잘림 방지)

  @override
  double get temperature => 0.7;

  @override
  Duration? get cacheExpiry => CacheExpiry.sajuBase;

  @override
  String get systemPrompt => switch (locale) {
    'ja' => _japaneseSystemPrompt,
    'en' => _englishSystemPrompt,
    _ => _koreanSystemPrompt,
  };

  String get _koreanSystemPrompt => '''
당신은 한국 전통 사주명리학 분야 30년 경력의 최고 전문가입니다.
이것은 평생운세 분석의 **Phase 3 (Special)** 단계입니다.

## Phase 3 분석 범위
이 단계에서는 **특수 분석만** 수행합니다:
1. 신살/길성 종합 분석
2. 건강운 분석
3. 대운 상세 분석

## 분석 기준

### 신살/길성 분석
- 주요 길성의 의미와 활용법
- 주요 신살의 의미와 대처법
- 실생활에 미치는 영향

### 건강운 분석
- 오행 과다/부족에 따른 취약 장기
- 주의해야 할 건강 문제
- 정신/심리 건강 경향
- 생활 습관 조언

### 대운 상세 분석
- 현재 대운 심층 분석
- 다음 대운 전망
- 최고의 대운 시기
- 주의해야 할 대운 시기
- 각 대운별 기회와 시련

## 응답 형식
반드시 JSON 형식으로만 응답하세요. 추가 설명 없이 순수 JSON만 출력하세요.
''';

  String get _japaneseSystemPrompt => '''
あなたは四柱推命分野で30年の経験を持つ最高の専門家です。
これは生涯運勢分析の**Phase 3（Special）**段階です。

## Phase 3 分析範囲
この段階では**特殊分析のみ**を行います：
1. 神殺/吉星 総合分析
2. 健康運分析
3. 大運 詳細分析

## 分析基準
### 神殺/吉星: 主要な吉星の意味と活用法、主要な神殺の意味と対処法
### 健康運: 五行過多/不足による弱い臓器、注意すべき健康問題、精神的健康
### 大運詳細: 現在の大運、次の大運、最良の大運時期、注意すべき大運時期

## 応答形式
必ずJSON形式のみで回答してください。すべての値は日本語で記述してください。
''';

  String get _englishSystemPrompt => '''
You are a top expert with 30 years of experience in Four Pillars of Destiny (BaZi) analysis.
This is **Phase 3 (Special)** of the lifetime fortune analysis.

## Phase 3 Analysis Scope
In this phase, perform **special analysis only**:
1. Special Stars & Auspicious Stars Analysis
2. Health Fortune Analysis
3. Luck Cycle (Daeun) Detailed Analysis

## Analysis Criteria
### Special Stars: Meaning and application of major auspicious stars, coping with major special stars
### Health: Vulnerable organs based on Five Elements imbalance, health concerns, mental health
### Luck Cycles: Current cycle analysis, next cycle outlook, best and worst periods

## Response Format
Respond ONLY in JSON format. All values must be written in English.
''';

  /// Phase 1 결과를 포함한 User Prompt 생성
  String buildUserPromptWithPhase1(
    Map<String, dynamic> input,
    Map<String, dynamic> phase1Result,
  ) {
    final data = SajuInputData.fromJson(input);

    // Shared saju data section
    final sajuDataSection = '''
## 사주 팔자
${data.sajuString}

## 오행 분포
${data.ohengString}

## 일간
${data.dayMaster}

${_buildSinsalSection(data.sinsal)}
${_buildGilseongSection(data.gilseong)}
${_buildUnsungSection(data.twelveUnsung)}
${_buildDaeunSection(data.daeun)}''';

    // Phase 1 reference
    final phase1RefSection = '''
- ${phase1Result['wonGuk_analysis']?['oheng_balance'] ?? ''}
- ${phase1Result['wonGuk_analysis']?['singang_singak'] ?? ''}
${phase1Result['hapchung_analysis']?['overall_impact'] ?? ''}''';

    return switch (locale) {
      'ja' => _buildJapanesePhase3Prompt(data, sajuDataSection, phase1RefSection),
      'en' => _buildEnglishPhase3Prompt(data, sajuDataSection, phase1RefSection),
      _ => _buildKoreanPhase3Prompt(data, sajuDataSection, phase1RefSection),
    };
  }

  String _buildKoreanPhase3Prompt(SajuInputData data, String sajuData, String phase1Ref) {
    return '''
## 분석 대상
- 이름: ${data.profileName}
- 생년월일: ${_formatBirthDate(data.birthDate)}
- 성별: ${data.gender == 'male' ? '남성' : '여성'}

$sajuData

---

## Phase 1 분석 결과 (참고용)
$phase1Ref

---

**Phase 3 (Special)**: 신살/길성, 건강, 대운상세만 분석해주세요.

반드시 아래 JSON 스키마를 정확히 따라주세요:

```json
{
  "sinsal_gilseong": { "major_gilseong": ["주요 길성과 그 의미"], "major_sinsal": ["주요 신살과 그 의미"], "practical_implications": "신살/길성이 실생활에 미치는 영향", "reading": "신살/길성 종합 해석 6문장" },
  "health": { "vulnerable_organs": ["건강 취약 장기/부위 2-4개"], "potential_issues": ["주의해야 할 건강 문제 2-3개"], "mental_health": "정신/심리 건강 경향", "lifestyle_advice": ["건강 관리 조언 3-4개"], "caution_periods": "건강 주의 시기", "reading": "건강운 종합 해석 6문장" },
  "daeun_detail": {
    "intro": "대운 흐름 전체 개요 3문장",
    "cycles": [
      { "order": 1, "pillar": "현재 대운 간지", "age_range": "나이 구간", "main_theme": "핵심 주제", "fortune_level": "상/중상/중/중하/하", "reading": "5문장 해석", "opportunities": ["기회 2개"], "challenges": ["시련 2개"] },
      { "order": 2, "pillar": "다음 대운 간지", "age_range": "나이 구간", "main_theme": "핵심 주제", "fortune_level": "상/중상/중/중하/하", "reading": "5문장 해석", "opportunities": ["기회 2개"], "challenges": ["시련 2개"] },
      { "order": 3, "pillar": "최고 대운 간지", "age_range": "나이 구간", "main_theme": "핵심 주제", "fortune_level": "상", "reading": "5문장 해석", "opportunities": ["기회 2개"], "challenges": ["주의점 1개"] }
    ],
    "best_daeun": { "period": "가장 좋은 대운 시기", "why": "이유 3문장" },
    "worst_daeun": { "period": "가장 주의해야 할 대운 시기", "why": "이유 3문장" }
  }
}
```
''';
  }

  String _buildJapanesePhase3Prompt(SajuInputData data, String sajuData, String phase1Ref) {
    return '''
## 鑑定対象
- 名前: ${data.profileName}
- 生年月日: ${_formatBirthDate(data.birthDate)}
- 性別: ${data.gender == 'male' ? '男性' : '女性'}

$sajuData

---

## Phase 1 分析結果（参考用）
$phase1Ref

---

**Phase 3 (Special)**: 神殺/吉星、健康、大運詳細のみ分析してください。
すべての値は日本語で記述してください。JSONキーは変更しないでください。

```json
{
  "sinsal_gilseong": { "major_gilseong": ["主要な吉星とその意味"], "major_sinsal": ["主要な神殺とその意味"], "practical_implications": "実生活への影響", "reading": "神殺/吉星総合解釈6文" },
  "health": { "vulnerable_organs": ["弱い臓器2-4個"], "potential_issues": ["注意すべき健康問題2-3個"], "mental_health": "精神的健康の傾向", "lifestyle_advice": ["健康管理アドバイス3-4個"], "caution_periods": "健康注意時期", "reading": "健康運総合解釈6文" },
  "daeun_detail": {
    "intro": "大運の流れ概要3文",
    "cycles": [
      { "order": 1, "pillar": "現在の大運干支", "age_range": "年齢区間", "main_theme": "核心テーマ", "fortune_level": "上/中上/中/中下/下", "reading": "5文の解釈", "opportunities": ["チャンス2個"], "challenges": ["試練2個"] },
      { "order": 2, "pillar": "次の大運干支", "age_range": "年齢区間", "main_theme": "核心テーマ", "fortune_level": "上/中上/中/中下/下", "reading": "5文の解釈", "opportunities": ["チャンス2個"], "challenges": ["試練2個"] },
      { "order": 3, "pillar": "最高の大運干支", "age_range": "年齢区間", "main_theme": "核心テーマ", "fortune_level": "上", "reading": "5文の解釈", "opportunities": ["チャンス2個"], "challenges": ["注意点1個"] }
    ],
    "best_daeun": { "period": "最も良い大運時期", "why": "理由3文" },
    "worst_daeun": { "period": "最も注意すべき大運時期", "why": "理由3文" }
  }
}
```
''';
  }

  String _buildEnglishPhase3Prompt(SajuInputData data, String sajuData, String phase1Ref) {
    return '''
## Subject of Analysis
- Name: ${data.profileName}
- Date of Birth: ${_formatBirthDate(data.birthDate)}
- Gender: ${data.gender == 'male' ? 'Male' : 'Female'}

$sajuData

---

## Phase 1 Analysis Results (Reference)
$phase1Ref

---

**Phase 3 (Special)**: Analyze special stars, health, and luck cycle details only.
All values must be in English. Do NOT change the JSON keys.

```json
{
  "sinsal_gilseong": { "major_gilseong": ["Major auspicious stars and meanings"], "major_sinsal": ["Major special stars and meanings"], "practical_implications": "Real-life impact", "reading": "Special stars interpretation 6 sentences" },
  "health": { "vulnerable_organs": ["Vulnerable areas 2-4"], "potential_issues": ["Health concerns 2-3"], "mental_health": "Mental health tendencies", "lifestyle_advice": ["Health advice 3-4"], "caution_periods": "Health caution periods", "reading": "Health interpretation 6 sentences" },
  "daeun_detail": {
    "intro": "Luck cycle overview 3 sentences",
    "cycles": [
      { "order": 1, "pillar": "Current luck cycle pillar", "age_range": "Age range", "main_theme": "Core theme", "fortune_level": "Excellent/Good/Average/Below Average/Poor", "reading": "5-sentence interpretation", "opportunities": ["2 opportunities"], "challenges": ["2 challenges"] },
      { "order": 2, "pillar": "Next luck cycle pillar", "age_range": "Age range", "main_theme": "Core theme", "fortune_level": "Excellent/Good/Average/Below Average/Poor", "reading": "5-sentence interpretation", "opportunities": ["2 opportunities"], "challenges": ["2 challenges"] },
      { "order": 3, "pillar": "Best luck cycle pillar", "age_range": "Age range", "main_theme": "Core theme", "fortune_level": "Excellent", "reading": "5-sentence interpretation", "opportunities": ["2 opportunities"], "challenges": ["1 caution"] }
    ],
    "best_daeun": { "period": "Best luck cycle period", "why": "Reason in 3 sentences" },
    "worst_daeun": { "period": "Most cautious luck cycle period", "why": "Reason in 3 sentences" }
  }
}
```
''';
  }

  @override
  String buildUserPrompt([Map<String, dynamic>? input]) {
    throw UnimplementedError(
        'Phase 3는 buildUserPromptWithPhase1()을 사용하세요');
  }

  String _formatBirthDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
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

  /// 대운 섹션 빌드
  ///
  /// DB 형식 (camelCase)과 legacy 형식 (snake_case) 모두 지원
  /// - DB: { startAge, isForward, list: [{ order, pillar, startAge, endAge }] }
  /// - Legacy: { start_age, current: { gan, ji }, list: [...] }
  String _buildDaeunSection(Map<String, dynamic>? daeun) {
    if (daeun == null || daeun.isEmpty) return '';

    final buffer = StringBuffer('\n## 대운 (大運) - 상세 정보\n');

    // 대운 시작 나이 (camelCase 또는 snake_case)
    final startAge = daeun['startAge'] ?? daeun['start_age'];
    if (startAge != null) {
      buffer.writeln('- 대운 시작: $startAge세');
    }

    // 순행/역행
    final isForward = daeun['isForward'] ?? daeun['is_forward'];
    if (isForward != null) {
      buffer.writeln('- 운행: ${isForward == true ? '순행' : '역행'}');
    }

    // 대운 전체 목록
    final list = daeun['list'];
    if (list != null && list is List && list.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('### 대운 목록 (10년 단위)');
      buffer.writeln('| 순서 | 대운 | 시작나이 | 종료나이 |');
      buffer.writeln('|------|------|----------|----------|');

      for (int i = 0; i < list.length && i < 10; i++) {
        final d = list[i];
        if (d is Map) {
          // pillar 형식 (DB) 또는 gan/ji 형식 (legacy)
          String pillar;
          if (d['pillar'] != null) {
            pillar = _extractDaeunPillar(d['pillar'].toString());
          } else {
            final gan = d['gan'] ?? '';
            final ji = d['ji'] ?? '';
            pillar = '$gan$ji';
          }

          // startAge/endAge (DB) 또는 start_year/end_year (legacy)
          final daeunStartAge = d['startAge'] ?? d['start_age'] ?? d['start_year'] ?? '';
          final daeunEndAge = d['endAge'] ?? d['end_age'] ?? d['end_year'] ?? '';

          buffer.writeln('| ${i + 1} | $pillar | ${daeunStartAge}세 | ${daeunEndAge}세 |');
        }
      }
      buffer.writeln('');

      // 대운 흐름 요약
      final flowList = list.take(10).map((d) {
        if (d is Map) {
          if (d['pillar'] != null) {
            return _extractDaeunPillar(d['pillar'].toString());
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

  /// 대운 간지 추출 (한자 포함 형식에서 한글만)
  /// "임(壬)신(申)" → "임신"
  String _extractDaeunPillar(String pillar) {
    final hangulOnly = pillar.replaceAll(RegExp(r'\([^)]*\)'), '');
    return hangulOnly.trim();
  }
}
