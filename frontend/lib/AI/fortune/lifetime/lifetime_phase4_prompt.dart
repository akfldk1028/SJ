/// # Phase 4: Synthesis (종합 분석) 프롬프트
///
/// ## 개요
/// 평생운세 분석의 마지막 단계로, 전체 결과를 종합하여
/// 요약, 인생주기, 전성기, 현대해석을 제공합니다.
///
/// ## 출력 섹션
/// - summary: 전체 요약
/// - life_cycles: 인생 주기별 전망
/// - peak_years: 인생 전성기
/// - modern_interpretation: AI시대 현대적 해석
///
/// ## 의존성
/// Phase 1, 2, 3 결과 모두 필요
///
/// ## 예상 시간
/// 45-60초

import '../../core/ai_constants.dart';
import '../common/prompt_template.dart';
import 'lifetime_prompt.dart';

/// Phase 4: Synthesis 프롬프트
///
/// 전체 종합: 요약, 인생주기, 전성기, 현대해석
class SajuBasePhase4Prompt extends PromptTemplate {
  final String locale;
  SajuBasePhase4Prompt({this.locale = 'ko'});

  @override
  String get summaryType => '${SummaryType.sajuBase}_phase4';

  @override
  String get modelName => OpenAIModels.sajuAnalysis; // GPT-5.2

  @override
  int get maxTokens => 8000; // Phase 4용 토큰 (4000→8000 확장, JSON 잘림 방지)

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
이것은 평생운세 분석의 **Phase 4 (Synthesis)** 단계입니다.

## Phase 4 분석 범위
이 단계에서는 **종합 분석만** 수행합니다:
1. 전체 사주 요약
2. 인생 주기별 전망 (청년/중년/후년)
3. 인생 전성기 분석
4. AI시대 현대적 해석

## 분석 기준

### 전체 요약
- Phase 1~3 분석 결과를 압축
- 이 사람 사주의 핵심 특성
- 가장 중요한 운세 포인트

### 인생 주기
- 청년기(20-35세): 핵심 기회와 집중 포인트 학업/직장/재물/사업/연애 흐름 (6~8문장)
- 중년기(35-55세):핵심 기회와 집중 포인트  가정/직장/재물/건강/결혼 흐름 (6~8문장)
- 후년기(55세+): 핵심 기회와 집중 포인트 건강/가족/여유/재물/사업 흐름 (6~8문장)
- 인생 중요 전환점 나이

### 인생 전성기
- 최전성기 구간 (예: 38-48세)
- 왜 이 시기가 최전성기인지
- 준비사항과 해야 할 것
- 주의점

### AI시대 현대 해석
| 전통 요소 | 전통 의미 | AI시대 적용 |
|----------|----------|-------------|
| 식상 | 자녀운/표현력 | 콘텐츠창작/SNS/유튜브 |
| 역마살 | 먼여행/이사 | 디지털노마드/원격근무 |
| 도화살 | 이성매력/예술 | 인플루언서/마케팅 |
| 인성 | 학문/자격증 | AI활용능력/코딩 |
| 재성 | 재물/토지 | 디지털자산/N잡/스타트업 |
| 비겁 | 형제/경쟁 | 네트워킹/커뮤니티/협업 |

## 응답 형식
반드시 JSON 형식으로만 응답하세요. 추가 설명 없이 순수 JSON만 출력하세요.
''';

  String get _japaneseSystemPrompt => '''
あなたは四柱推命分野で30年の経験を持つ最高の専門家です。
これは生涯運勢分析の**Phase 4（Synthesis）**段階です。

## Phase 4 分析範囲
この段階では**総合分析のみ**を行います：
1. 全体の四柱推命まとめ
2. 人生周期別展望（青年/中年/晩年）
3. 人生の最盛期分析
4. AI時代の現代的解釈

## 分析基準
### 全体まとめ: Phase 1〜3の結果を凝縮、核心特性、最重要ポイント
### 人生周期: 青年期(20-35歳)、中年期(35-55歳)、晩年期(55歳+)
### 最盛期: 最盛期の期間、理由、準備事項、注意点
### AI時代解釈: 伝統的要素の現代的適用

## 応答形式
必ずJSON形式のみで回答してください。すべての値は日本語で記述してください。
''';

  String get _englishSystemPrompt => '''
You are a top expert with 30 years of experience in Four Pillars of Destiny (BaZi) analysis.
This is **Phase 4 (Synthesis)** of the lifetime fortune analysis.

## Phase 4 Analysis Scope
In this phase, perform **synthesis analysis only**:
1. Overall BaZi Summary
2. Life Cycle Outlook (Youth/Middle Age/Later Years)
3. Peak Years Analysis
4. AI Era Modern Interpretation

## Analysis Criteria
### Summary: Compress Phase 1-3 results, core characteristics, key fortune points
### Life Cycles: Youth (20-35), Middle Age (35-55), Later Years (55+)
### Peak Years: Peak period, reasons, preparation, cautions
### Modern Interpretation: Traditional elements applied to the AI era

## Response Format
Respond ONLY in JSON format. All values must be written in English.
''';

  /// Phase 1~3 결과를 포함한 User Prompt 생성
  String buildUserPromptWithAllPhases(
    Map<String, dynamic> input,
    Map<String, dynamic> phase1Result,
    Map<String, dynamic> phase2Result,
    Map<String, dynamic> phase3Result,
  ) {
    final data = SajuInputData.fromJson(input);

    // Build shared previous phases reference (structured data, locale-independent)
    final phasesRef = '''
${phase1Result['wonGuk_analysis']?['reading'] ?? ''}
- ${(phase1Result['sipsung_analysis']?['dominant_sipsung'] as List?)?.join(', ') ?? ''}
${phase1Result['sipsung_analysis']?['life_implications'] ?? ''}
- ${(phase1Result['personality']?['core_traits'] as List?)?.join(', ') ?? ''}
${phase1Result['personality']?['social_style'] ?? ''}
- ${(phase1Result['lucky_elements']?['colors'] as List?)?.join(', ') ?? ''}
- ${(phase1Result['lucky_elements']?['seasons'] ?? '')}
${phase2Result['wealth']?['overall_tendency'] ?? ''}
- ${phase2Result['wealth']?['wealth_timing'] ?? ''}
- ${(phase2Result['career']?['suitable_fields'] as List?)?.take(5).join(', ') ?? ''}
${phase2Result['business']?['entrepreneurship_aptitude'] ?? ''}
${phase2Result['love']?['dating_pattern'] ?? ''}
- ${phase2Result['marriage']?['marriage_timing'] ?? ''}
${phase3Result['sinsal_gilseong']?['practical_implications'] ?? ''}
- ${(phase3Result['health']?['vulnerable_organs'] as List?)?.join(', ') ?? ''}
- best: ${phase3Result['daeun_detail']?['best_daeun']?['period'] ?? ''}
- worst: ${phase3Result['daeun_detail']?['worst_daeun']?['period'] ?? ''}''';

    return switch (locale) {
      'ja' => _buildJapanesePhase4Prompt(data, phasesRef),
      'en' => _buildEnglishPhase4Prompt(data, phasesRef),
      _ => _buildKoreanPhase4Prompt(data, phasesRef),
    };
  }

  String _buildKoreanPhase4Prompt(SajuInputData data, String phasesRef) {
    return '''
## 분석 대상
- 이름: ${data.profileName}
- 생년월일: ${_formatBirthDate(data.birthDate)}
- 성별: ${data.gender == 'male' ? '남성' : '여성'}

## 사주 팔자
${data.sajuString}

## 일간
${data.dayMaster}

---

## Phase 1-3 결과 요약 (참고용)
$phasesRef

---

**Phase 4 (Synthesis)**: 전체 종합하여 요약, 인생주기, 전성기, 현대해석을 분석해주세요.

```json
{
  "summary": "핵심 특성 10문장 요약",
  "life_cycles": {
    "youth": "청년기(20-35세) 전망 5문장",
    "middle_age": "중년기(35-55세) 전망 5문장",
    "later_years": "후년기(55세+) 전망 5문장",
    "key_years": ["전환점 3-4개"]
  },
  "peak_years": { "period": "최전성기 구간", "age_range": [38, 48], "why": "이유 8문장", "what_to_prepare": "준비 3문장", "what_to_do": "해야 할 것 3문장", "cautions": "주의점 2문장" },
  "modern_interpretation": {
    "dominant_elements": [{ "element": "강한 요소", "traditional": "전통적 의미", "modern": "AI시대 적용", "advice": "활용법" }],
    "career_in_ai_era": { "traditional_path": "전통 진로", "modern_opportunities": ["AI시대 직업 3-5개"], "digital_strengths": "디지털 강점" },
    "wealth_in_ai_era": { "traditional_view": "전통 재물운", "modern_opportunities": ["현대 재물 기회"], "risk_factors": "재테크 주의점" },
    "relationships_in_ai_era": { "traditional_view": "전통 대인관계", "modern_networking": "SNS 네트워킹", "collaboration_style": "현대 협업" }
  }
}
```
''';
  }

  String _buildJapanesePhase4Prompt(SajuInputData data, String phasesRef) {
    return '''
## 鑑定対象
- 名前: ${data.profileName}
- 生年月日: ${_formatBirthDate(data.birthDate)}
- 性別: ${data.gender == 'male' ? '男性' : '女性'}

## 四柱八字
${data.sajuString}

## 日干
${data.dayMaster}

---

## Phase 1-3 結果要約（参考用）
$phasesRef

---

**Phase 4 (Synthesis)**: 全体を総合して、まとめ、人生周期、最盛期、現代解釈を分析してください。
すべての値は日本語で記述してください。JSONキーは変更しないでください。

```json
{
  "summary": "核心特性を10文でまとめる",
  "life_cycles": {
    "youth": "青年期(20-35歳)展望5文",
    "middle_age": "中年期(35-55歳)展望5文",
    "later_years": "晩年期(55歳+)展望5文",
    "key_years": ["転換点3-4個"]
  },
  "peak_years": { "period": "最盛期の期間", "age_range": [38, 48], "why": "理由8文", "what_to_prepare": "準備事項3文", "what_to_do": "すべきこと3文", "cautions": "注意点2文" },
  "modern_interpretation": {
    "dominant_elements": [{ "element": "強い要素", "traditional": "伝統的意味", "modern": "AI時代の適用", "advice": "活用法" }],
    "career_in_ai_era": { "traditional_path": "伝統的キャリア", "modern_opportunities": ["AI時代の職業3-5個"], "digital_strengths": "デジタル強み" },
    "wealth_in_ai_era": { "traditional_view": "伝統的財運", "modern_opportunities": ["現代の財運チャンス"], "risk_factors": "投資注意点" },
    "relationships_in_ai_era": { "traditional_view": "伝統的対人関係", "modern_networking": "SNSネットワーキング", "collaboration_style": "現代コラボレーション" }
  }
}
```
''';
  }

  String _buildEnglishPhase4Prompt(SajuInputData data, String phasesRef) {
    return '''
## Subject of Analysis
- Name: ${data.profileName}
- Date of Birth: ${_formatBirthDate(data.birthDate)}
- Gender: ${data.gender == 'male' ? 'Male' : 'Female'}

## Four Pillars (BaZi)
${data.sajuString}

## Day Master
${data.dayMaster}

---

## Phase 1-3 Results Summary (Reference)
$phasesRef

---

**Phase 4 (Synthesis)**: Synthesize everything into summary, life cycles, peak years, and modern interpretation.
All values must be in English. Do NOT change the JSON keys.

```json
{
  "summary": "Core characteristics summary in 10 sentences",
  "life_cycles": {
    "youth": "Youth (20-35) outlook 5 sentences",
    "middle_age": "Middle age (35-55) outlook 5 sentences",
    "later_years": "Later years (55+) outlook 5 sentences",
    "key_years": ["Key turning points 3-4"]
  },
  "peak_years": { "period": "Peak period", "age_range": [38, 48], "why": "Reason 8 sentences", "what_to_prepare": "Preparation 3 sentences", "what_to_do": "Actions 3 sentences", "cautions": "Cautions 2 sentences" },
  "modern_interpretation": {
    "dominant_elements": [{ "element": "Strong element", "traditional": "Traditional meaning", "modern": "AI era application", "advice": "How to leverage" }],
    "career_in_ai_era": { "traditional_path": "Traditional career", "modern_opportunities": ["AI era careers 3-5"], "digital_strengths": "Digital strengths" },
    "wealth_in_ai_era": { "traditional_view": "Traditional wealth", "modern_opportunities": ["Modern wealth opportunities"], "risk_factors": "Investment cautions" },
    "relationships_in_ai_era": { "traditional_view": "Traditional relationships", "modern_networking": "SNS networking style", "collaboration_style": "Modern collaboration" }
  }
}
```
''';
  }

  @override
  String buildUserPrompt([Map<String, dynamic>? input]) {
    throw UnimplementedError(
        'Phase 4는 buildUserPromptWithAllPhases()를 사용하세요');
  }

  String _formatBirthDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}
