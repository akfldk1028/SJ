/// # Phase 2: Fortune (운세 분석) 프롬프트
///
/// ## 개요
/// 평생운세 분석의 두 번째 단계로, 재물/직업/사업/애정/결혼운을 분석합니다.
/// Phase 1 결과(십성, 합충)를 기반으로 운세를 도출합니다.
///
/// ## 출력 섹션
/// - wealth: 재물운
/// - career: 직업운
/// - business: 사업운
/// - love: 애정운
/// - marriage: 결혼운
///
/// ## 의존성
/// Phase 1 결과 필요 (십성, 합충 기반)
///
/// ## 예상 시간
/// 30-45초

import '../../core/ai_constants.dart';
import '../common/prompt_template.dart';
import 'lifetime_prompt.dart';

/// Phase 2: Fortune 프롬프트
///
/// 재물, 직업, 사업, 애정, 결혼운 분석
class SajuBasePhase2Prompt extends PromptTemplate {
  final String locale;
  SajuBasePhase2Prompt({this.locale = 'ko'});

  @override
  String get summaryType => '${SummaryType.sajuBase}_phase2';

  @override
  String get modelName => OpenAIModels.sajuAnalysis; // GPT-5.2

  @override
  int get maxTokens => 8000; // Phase 2용 토큰 (4000→8000 확장, 결혼운 JSON 잘림 방지)

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
이것은 평생운세 분석의 **Phase 2 (Fortune)** 단계입니다.

## Phase 2 분석 범위
이 단계에서는 **운세 분석만** 수행합니다:
1. 재물운 분석
2. 직업운 분석
3. 사업운 분석
4. 애정운 분석
5. 결혼운 분석

## 분석 기준

### 재물운
- 정재/편재 위치와 강약
- 식상생재 구조 유무
- 재성 충합 관계
- 돈 버는 스타일과 시기

### 직업운
- 관성 상태 (정관/편관)
- 인성의 지원 여부
- 적합한 직업 분야
- 승진/이직 타이밍

### 사업운
- 식상생재 구조
- 편재 활용도
- 사업 적합성
- 파트너 특성

### 애정운
- 도화살, 홍염살 유무
- 재성(남)/관성(여) 상태
- 연애 스타일과 주의점
- 좋은 시기

### 결혼운
- 배우자궁(일지) 상태
- 충합 여부
- 결혼 시기
- 배우자 특성

## 응답 형식
반드시 JSON 형식으로만 응답하세요. 추가 설명 없이 순수 JSON만 출력하세요.
''';

  String get _japaneseSystemPrompt => '''
あなたは四柱推命分野で30年の経験を持つ最高の専門家です。
これは生涯運勢分析の**Phase 2（Fortune）**段階です。

## Phase 2 分析範囲
この段階では**運勢分析のみ**を行います：
1. 財運分析
2. 職業運分析
3. 事業運分析
4. 恋愛運分析
5. 結婚運分析

## 分析基準
### 財運: 正財/偏財の位置と強弱、食傷生財構造、財星の冲合
### 職業運: 官星の状態、印星のサポート、適した分野
### 事業運: 食傷生財構造、偏財の活用、パートナー特性
### 恋愛運: 桃花殺、紅艶殺、財星/官星の状態
### 結婚運: 配偶者宮（日支）の状態、冲合の有無

## 応答形式
必ずJSON形式のみで回答してください。すべての値は日本語で記述してください。
''';

  String get _englishSystemPrompt => '''
You are a top expert with 30 years of experience in Four Pillars of Destiny (BaZi) analysis.
This is **Phase 2 (Fortune)** of the lifetime fortune analysis.

## Phase 2 Analysis Scope
In this phase, perform **fortune analysis only**:
1. Wealth Fortune Analysis
2. Career Fortune Analysis
3. Business Fortune Analysis
4. Love/Romance Fortune Analysis
5. Marriage Fortune Analysis

## Analysis Criteria
### Wealth: Direct/Indirect Wealth positions and strength, Output-generating-Wealth structure
### Career: Officer star status, Resource star support, suitable fields
### Business: Output-generating-Wealth structure, Indirect Wealth utilization
### Romance: Peach Blossom, Red Romance stars, Wealth/Officer star status
### Marriage: Spouse Palace (Day Branch) status, clashes and combinations

## Response Format
Respond ONLY in JSON format. All values must be written in English.
''';

  /// Phase 1 결과를 포함한 User Prompt 생성
  String buildUserPromptWithPhase1(
    Map<String, dynamic> input,
    Map<String, dynamic> phase1Result,
  ) {
    final data = SajuInputData.fromJson(input);

    // Structured saju data section (shared across locales)
    final sajuDataSection = '''
## 사주 팔자
${data.sajuString}

## 오행 분포
${data.ohengString}

## 일간
${data.dayMaster}

${_buildYongsinSection(data.yongsin)}
${_buildSinsalSummary(data.sinsal)}
${_buildGilseongSummary(data.gilseong)}''';

    // Phase 1 reference section (shared across locales)
    final phase1RefSection = '''
${phase1Result['wonGuk_analysis']?['reading'] ?? ''}

- ${(phase1Result['sipsung_analysis']?['dominant_sipsung'] as List?)?.join(', ') ?? ''}
- ${(phase1Result['sipsung_analysis']?['weak_sipsung'] as List?)?.join(', ') ?? ''}
${phase1Result['sipsung_analysis']?['key_interactions'] ?? ''}

${phase1Result['hapchung_analysis']?['overall_impact'] ?? ''}''';

    return switch (locale) {
      'ja' => _buildJapanesePhase2Prompt(data, sajuDataSection, phase1RefSection),
      'en' => _buildEnglishPhase2Prompt(data, sajuDataSection, phase1RefSection),
      _ => _buildKoreanPhase2Prompt(data, sajuDataSection, phase1RefSection),
    };
  }

  String _buildKoreanPhase2Prompt(SajuInputData data, String sajuData, String phase1Ref) {
    return '''
## 분석 대상
- 이름: ${data.profileName}
- 성별: ${data.gender == 'male' ? '남성' : '여성'}

$sajuData

---

## Phase 1 분석 결과 (참고용)
$phase1Ref

---

**Phase 2 (Fortune)**: 재물, 직업, 사업, 애정, 결혼운만 분석해주세요.

반드시 아래 JSON 스키마를 정확히 따라주세요:

```json
{
  "wealth": { "overall_tendency": "전체적인 재물운 경향", "earning_style": "돈을 버는 방식", "spending_tendency": "소비 성향", "investment_aptitude": "투자 적성", "wealth_timing": "재물운이 좋은 시기", "cautions": ["주의사항 2-3개"], "advice": "재물운 향상 조언", "reading": "재물운 종합 해석 8문장" },
  "career": { "suitable_fields": ["적합한 직업 5-7개"], "unsuitable_fields": ["피해야 할 분야 2-3개"], "work_style": "업무 스타일", "leadership_potential": "리더십 적성", "career_timing": "직장운이 좋은 시기", "advice": "진로 조언", "reading": "직업운 종합 해석 8문장" },
  "business": { "entrepreneurship_aptitude": "사업 적성", "suitable_business_types": ["적합한 사업 유형 3-5개"], "business_partner_traits": "좋은 사업 파트너 특성", "cautions": ["주의사항 2-3개"], "success_factors": ["성공 요인 2-3개"], "advice": "사업 조언", "reading": "사업운 종합 해석 8문장" },
  "love": { "attraction_style": "끌리는 이성 유형", "dating_pattern": "연애 패턴", "romantic_strengths": ["강점 2-3개"], "romantic_weaknesses": ["약점 2-3개"], "ideal_partner_traits": ["이상적 파트너 특성 3-4개"], "love_timing": "연애운 좋은 시기", "advice": "연애 조언", "reading": "연애운 종합 해석 8문장" },
  "marriage": { "spouse_palace_analysis": "배우자궁 분석", "marriage_timing": "결혼 적령기", "spouse_characteristics": "배우자 특성", "married_life_tendency": "결혼 생활 경향", "cautions": ["주의사항 2-3개"], "advice": "결혼운 조언", "reading": "결혼운 종합 해석 8문장" }
}
```
''';
  }

  String _buildJapanesePhase2Prompt(SajuInputData data, String sajuData, String phase1Ref) {
    return '''
## 鑑定対象
- 名前: ${data.profileName}
- 性別: ${data.gender == 'male' ? '男性' : '女性'}

$sajuData

---

## Phase 1 分析結果（参考用）
$phase1Ref

---

**Phase 2 (Fortune)**: 財運、職業運、事業運、恋愛運、結婚運のみ分析してください。
すべての値は日本語で記述してください。JSONキーは変更しないでください。

```json
{
  "wealth": { "overall_tendency": "全体的な財運の傾向", "earning_style": "お金を稼ぐスタイル", "spending_tendency": "消費傾向", "investment_aptitude": "投資適性", "wealth_timing": "財運が良い時期", "cautions": ["注意事項2-3個"], "advice": "財運向上アドバイス", "reading": "財運総合解釈8文" },
  "career": { "suitable_fields": ["適した職業5-7個"], "unsuitable_fields": ["避けるべき分野2-3個"], "work_style": "仕事のスタイル", "leadership_potential": "リーダーシップ適性", "career_timing": "職業運が良い時期", "advice": "キャリアアドバイス", "reading": "職業運総合解釈8文" },
  "business": { "entrepreneurship_aptitude": "起業適性", "suitable_business_types": ["適した事業タイプ3-5個"], "business_partner_traits": "良いパートナーの特性", "cautions": ["注意事項2-3個"], "success_factors": ["成功要因2-3個"], "advice": "事業アドバイス", "reading": "事業運総合解釈8文" },
  "love": { "attraction_style": "惹かれる異性のタイプ", "dating_pattern": "恋愛パターン", "romantic_strengths": ["恋愛の強み2-3個"], "romantic_weaknesses": ["恋愛の弱点2-3個"], "ideal_partner_traits": ["理想のパートナー特性3-4個"], "love_timing": "恋愛運が良い時期", "advice": "恋愛アドバイス", "reading": "恋愛運総合解釈8文" },
  "marriage": { "spouse_palace_analysis": "配偶者宮分析", "marriage_timing": "結婚適齢期", "spouse_characteristics": "配偶者の特性", "married_life_tendency": "結婚生活の傾向", "cautions": ["注意事項2-3個"], "advice": "結婚運アドバイス", "reading": "結婚運総合解釈8文" }
}
```
''';
  }

  String _buildEnglishPhase2Prompt(SajuInputData data, String sajuData, String phase1Ref) {
    return '''
## Subject of Analysis
- Name: ${data.profileName}
- Gender: ${data.gender == 'male' ? 'Male' : 'Female'}

$sajuData

---

## Phase 1 Analysis Results (Reference)
$phase1Ref

---

**Phase 2 (Fortune)**: Analyze wealth, career, business, romance, and marriage fortune only.
All values must be in English. Do NOT change the JSON keys.

```json
{
  "wealth": { "overall_tendency": "Overall wealth tendency", "earning_style": "Money-making style", "spending_tendency": "Spending habits", "investment_aptitude": "Investment aptitude", "wealth_timing": "Best wealth periods", "cautions": ["Wealth cautions 2-3"], "advice": "Wealth advice", "reading": "Wealth interpretation 8 sentences" },
  "career": { "suitable_fields": ["Suitable careers 5-7"], "unsuitable_fields": ["Fields to avoid 2-3"], "work_style": "Work style", "leadership_potential": "Leadership aptitude", "career_timing": "Best career periods", "advice": "Career advice", "reading": "Career interpretation 8 sentences" },
  "business": { "entrepreneurship_aptitude": "Business aptitude", "suitable_business_types": ["Suitable business types 3-5"], "business_partner_traits": "Good partner traits", "cautions": ["Business cautions 2-3"], "success_factors": ["Success factors 2-3"], "advice": "Business advice", "reading": "Business interpretation 8 sentences" },
  "love": { "attraction_style": "Attraction type", "dating_pattern": "Dating pattern", "romantic_strengths": ["Romantic strengths 2-3"], "romantic_weaknesses": ["Romantic weaknesses 2-3"], "ideal_partner_traits": ["Ideal partner traits 3-4"], "love_timing": "Best romance period", "advice": "Romance advice", "reading": "Love interpretation 8 sentences" },
  "marriage": { "spouse_palace_analysis": "Spouse Palace analysis", "marriage_timing": "Best marriage timing", "spouse_characteristics": "Spouse characteristics", "married_life_tendency": "Marriage life tendencies", "cautions": ["Marriage cautions 2-3"], "advice": "Marriage advice", "reading": "Marriage interpretation 8 sentences" }
}
```
''';
  }

  @override
  String buildUserPrompt([Map<String, dynamic>? input]) {
    // Phase 2는 Phase 1 결과가 필요하므로 buildUserPromptWithPhase1 사용 권장
    throw UnimplementedError(
        'Phase 2는 buildUserPromptWithPhase1()을 사용하세요');
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

    return buffer.toString();
  }

  String _buildSinsalSummary(List<Map<String, dynamic>>? sinsal) {
    if (sinsal == null || sinsal.isEmpty) return '';

    final buffer = StringBuffer('\n## 주요 신살\n');
    final importantSinsal = ['도화살', '홍염살', '역마살', '귀문관살', '천살'];

    for (final s in sinsal) {
      final name = s['name'] ?? '';
      if (importantSinsal.any((i) => name.toString().contains(i))) {
        buffer.writeln('- $name (${s['pillar'] ?? ''})');
      }
    }

    return buffer.toString();
  }

  String _buildGilseongSummary(List<Map<String, dynamic>>? gilseong) {
    if (gilseong == null || gilseong.isEmpty) return '';

    final buffer = StringBuffer('\n## 주요 길성\n');
    final importantGilseong = ['천을귀인', '문창귀인', '금여록', '천관귀인'];

    for (final g in gilseong) {
      final name = g['name'] ?? '';
      if (importantGilseong.any((i) => name.toString().contains(i))) {
        buffer.writeln('- $name (${g['pillar'] ?? ''})');
      }
    }

    return buffer.toString();
  }
}
