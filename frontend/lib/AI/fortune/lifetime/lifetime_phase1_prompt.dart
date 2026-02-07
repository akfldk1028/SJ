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
  final String locale;
  SajuBasePhase1Prompt({this.locale = 'ko'});

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
  String get systemPrompt => switch (locale) {
    'ja' => _japaneseSystemPrompt,
    'en' => _englishSystemPrompt,
    _ => _koreanSystemPrompt,
  };

  String get _koreanSystemPrompt => '''
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

  String get _japaneseSystemPrompt => '''
あなたは四柱推命分野で30年の経験を持つ最高の専門家です。
これは生涯運勢分析の**Phase 1（Foundation）**段階です。

## Phase 1 分析範囲
この段階では**基礎分析のみ**を行います：
1. 原局構造分析
2. 十星分析
3. 合冲刑破害分析
4. 性格分析
5. 幸運要素分析

## 分析方法論

### 第1段階：原局構造分析
- 日干の特性分析
- 五行分布およびバランス分析
- 身強/身弱判定（提供されたスコアを使用）
- 格局分析（該当する場合）

### 第2段階：十星分析
- 比劫/食傷/財星/官星/印星の分布
- 強い十星と弱い十星の把握
- 十星間の相互作用

### 第3段階：合冲刑破害分析
**合の結束力順序**: 方合 > 三合 > 半合 > 六合
**冲の破壊力順序**: 旺支冲 > 生支冲 > 庫支冲
**刑の凶の強度順序**: 三刑 > 相刑 > 子卯刑 > 自刑

### 第4段階：性格分析
### 第5段階：幸運要素

## 分析原則
- **原局優先**: 原局の構造を正確に把握
- **六親中心**: 十星を通じた人間関係と運勢の解釈
- **相互作用**: 文字間の合冲刑破害を見逃さない
- **バランス解釈**: 良い点と注意点を共に提示

## 応答形式
必ずJSON形式のみで回答してください。すべての値は日本語で記述してください。
''';

  String get _englishSystemPrompt => '''
You are a top expert with 30 years of experience in Four Pillars of Destiny (BaZi) analysis.
This is **Phase 1 (Foundation)** of the lifetime fortune analysis.

## Phase 1 Analysis Scope
In this phase, perform **foundation analysis only**:
1. Natal Chart Structure Analysis
2. Ten Gods Analysis
3. Combinations, Clashes, Punishments Analysis
4. Personality Analysis
5. Lucky Elements Analysis

## Methodology

### Step 1: Natal Chart Structure
- Day Master characteristics
- Five Elements distribution and balance
- Strong/Weak Day Master determination (use provided score)
- Chart structure analysis (if applicable)

### Step 2: Ten Gods Analysis
- Distribution of Companions/Output/Wealth/Power/Resource stars
- Identify strong and weak Ten Gods
- Interactions between Ten Gods

### Step 3: Combinations & Clashes Analysis
**Combination strength**: Directional > Three Harmony > Half > Six Harmony
**Clash destructive power**: Cardinal > Growth > Storage
**Punishment severity**: Triple > Mutual > Zi-Mao > Self

### Step 4: Personality Analysis
### Step 5: Lucky Elements

## Analysis Principles
- **Natal chart first**: Accurately understand the natal chart structure
- **Six Relations focus**: Interpret through Ten Gods
- **Interactions**: Never miss combinations, clashes, punishments
- **Balanced reading**: Present both strengths and cautions

## Response Format
Respond ONLY in JSON format. All values must be written in English.
''';

  @override
  String buildUserPrompt([Map<String, dynamic>? input]) {
    final data = SajuInputData.fromJson(input!);

    return switch (locale) {
      'ja' => _buildJapaneseUserPrompt(data),
      'en' => _buildEnglishUserPrompt(data),
      _ => _buildKoreanUserPrompt(data),
    };
  }

  String _buildKoreanUserPrompt(SajuInputData data) {
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
    "ilju": "일주(日柱) 설명",
    "reading": "일주 기반 핵심 설명 6-8문장"
  },
  "my_saju_characters": {
    "description": "사주팔자 8글자 각각의 의미를 초보자도 이해할 수 있게 설명",
    "year_gan": { "character": "연간 한자", "reading": "읽는 법", "oheng": "오행", "yin_yang": "음양", "meaning": "의미 설명" },
    "year_ji": { "character": "연지 한자", "reading": "읽는 법", "animal": "띠 동물", "oheng": "오행", "yin_yang": "음양", "meaning": "의미 설명" },
    "month_gan": { "character": "월간 한자", "reading": "읽는 법", "oheng": "오행", "yin_yang": "음양", "meaning": "의미 설명" },
    "month_ji": { "character": "월지 한자", "reading": "읽는 법", "season": "계절", "oheng": "오행", "yin_yang": "음양", "meaning": "의미 설명" },
    "day_gan": { "character": "일간 한자 (나를 대표하는 글자!)", "reading": "읽는 법", "oheng": "오행", "yin_yang": "음양", "meaning": "일간은 나 자신. 쉽게 설명" },
    "day_ji": { "character": "일지 한자 (배우자궁)", "reading": "읽는 법", "animal": "띠 동물", "oheng": "오행", "yin_yang": "음양", "meaning": "배우자궁. 쉽게 설명" },
    "hour_gan": { "character": "시간 한자 (미상이면 null)", "reading": "읽는 법", "oheng": "오행", "yin_yang": "음양", "meaning": "의미 설명" },
    "hour_ji": { "character": "시지 한자 (자녀궁, 미상이면 null)", "reading": "읽는 법", "animal": "띠 동물", "oheng": "오행", "yin_yang": "음양", "meaning": "자녀궁. 쉽게 설명" },
    "overall_reading": "8글자 조합의 전체적인 기운과 특성 3-4문장"
  },
  "wonGuk_analysis": { "day_master": "일간 분석", "oheng_balance": "오행 균형 분석", "singang_singak": "신강/신약 판정 근거와 의미", "gyeokguk": "격국 분석", "reading": "원국 종합 해석 8문장" },
  "sipsung_analysis": { "dominant_sipsung": ["강한 십성 1-3개"], "weak_sipsung": ["약한 십성 1-2개"], "key_interactions": "십성 간 주요 상호작용", "life_implications": "십성 구조가 인생에 미치는 영향", "reading": "십성 종합 해석 8문장" },
  "hapchung_analysis": { "major_haps": ["주요 합의 의미와 영향"], "major_chungs": ["주요 충의 의미와 영향"], "other_interactions": "형/파/해/원진 영향", "overall_impact": "합충 종합 영향", "reading": "합충 종합 해석 8문장" },
  "personality": { "core_traits": ["핵심 성격 특성 4-6개"], "strengths": ["장점 4-6개"], "weaknesses": ["약점 3-4개"], "social_style": "대인관계 스타일", "reading": "성격 종합 해석 10문장" },
  "lucky_elements": { "colors": ["행운의 색 2-3개"], "directions": ["좋은 방향 1-2개"], "numbers": [1, 6], "seasons": "유리한 계절", "partner_elements": ["궁합이 좋은 띠 2-3개"] }
}
```
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

---

**Phase 1 (Foundation)**: 原局、十星、合冲、性格、幸運要素のみ分析してください。
すべての値は日本語で記述してください。JSONキーは変更しないでください。

```json
{
  "mySajuIntro": { "title": "私の四柱推命、私はどんな人？", "ilju": "日柱の説明", "reading": "日柱基盤の核心説明6-8文" },
  "my_saju_characters": {
    "description": "四柱八字の8文字それぞれの意味を初心者にもわかりやすく説明",
    "year_gan": { "character": "年干の漢字", "reading": "読み方", "oheng": "五行", "yin_yang": "陰陽", "meaning": "意味の説明" },
    "year_ji": { "character": "年支の漢字", "reading": "読み方", "animal": "干支の動物", "oheng": "五行", "yin_yang": "陰陽", "meaning": "意味の説明" },
    "month_gan": { "character": "月干の漢字", "reading": "読み方", "oheng": "五行", "yin_yang": "陰陽", "meaning": "意味の説明" },
    "month_ji": { "character": "月支の漢字", "reading": "読み方", "season": "季節", "oheng": "五行", "yin_yang": "陰陽", "meaning": "意味の説明" },
    "day_gan": { "character": "日干の漢字", "reading": "読み方", "oheng": "五行", "yin_yang": "陰陽", "meaning": "日干は自分自身を意味します" },
    "day_ji": { "character": "日支の漢字（配偶者宮）", "reading": "読み方", "animal": "干支の動物", "oheng": "五行", "yin_yang": "陰陽", "meaning": "配偶者宮の説明" },
    "hour_gan": { "character": "時干の漢字", "reading": "読み方", "oheng": "五行", "yin_yang": "陰陽", "meaning": "意味の説明" },
    "hour_ji": { "character": "時支の漢字（子女宮）", "reading": "読み方", "animal": "干支の動物", "oheng": "五行", "yin_yang": "陰陽", "meaning": "子女宮の説明" },
    "overall_reading": "8文字の全体的なエネルギーと特性3-4文"
  },
  "wonGuk_analysis": { "day_master": "日干分析", "oheng_balance": "五行バランス分析", "singang_singak": "身強/身弱判定", "gyeokguk": "格局分析", "reading": "原局総合解釈8文" },
  "sipsung_analysis": { "dominant_sipsung": ["強い十星1-3個"], "weak_sipsung": ["弱い十星1-2個"], "key_interactions": "十星間の相互作用", "life_implications": "十星構造の人生への影響", "reading": "十星総合解釈8文" },
  "hapchung_analysis": { "major_haps": ["主要な合"], "major_chungs": ["主要な冲"], "other_interactions": "刑/破/害の影響", "overall_impact": "合冲の総合影響", "reading": "合冲総合解釈8文" },
  "personality": { "core_traits": ["性格特性4-6個"], "strengths": ["長所4-6個"], "weaknesses": ["短所3-4個"], "social_style": "対人関係スタイル", "reading": "性格総合解釈10文" },
  "lucky_elements": { "colors": ["ラッキーカラー2-3個"], "directions": ["良い方角1-2個"], "numbers": [1, 6], "seasons": "有利な季節", "partner_elements": ["相性の良い干支2-3個"] }
}
```
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

---

**Phase 1 (Foundation)**: Analyze natal chart, Ten Gods, combinations/clashes, personality, and lucky elements only.
All values must be in English. Do NOT change the JSON keys.

```json
{
  "mySajuIntro": { "title": "My Four Pillars - Who Am I?", "ilju": "Day Pillar explanation", "reading": "Core description based on Day Pillar 6-8 sentences" },
  "my_saju_characters": {
    "description": "Explain each of the 8 characters in beginner-friendly terms",
    "year_gan": { "character": "Year Stem character", "reading": "Pronunciation", "oheng": "Five Element", "yin_yang": "Yin/Yang", "meaning": "Easy explanation" },
    "year_ji": { "character": "Year Branch character", "reading": "Pronunciation", "animal": "Zodiac animal", "oheng": "Five Element", "yin_yang": "Yin/Yang", "meaning": "Easy explanation" },
    "month_gan": { "character": "Month Stem", "reading": "Pronunciation", "oheng": "Five Element", "yin_yang": "Yin/Yang", "meaning": "Easy explanation" },
    "month_ji": { "character": "Month Branch", "reading": "Pronunciation", "season": "Season", "oheng": "Five Element", "yin_yang": "Yin/Yang", "meaning": "Easy explanation" },
    "day_gan": { "character": "Day Stem (represents YOU)", "reading": "Pronunciation", "oheng": "Five Element", "yin_yang": "Yin/Yang", "meaning": "The Day Stem represents yourself" },
    "day_ji": { "character": "Day Branch (Spouse Palace)", "reading": "Pronunciation", "animal": "Zodiac animal", "oheng": "Five Element", "yin_yang": "Yin/Yang", "meaning": "Spouse Palace explanation" },
    "hour_gan": { "character": "Hour Stem", "reading": "Pronunciation", "oheng": "Five Element", "yin_yang": "Yin/Yang", "meaning": "Easy explanation" },
    "hour_ji": { "character": "Hour Branch (Children Palace)", "reading": "Pronunciation", "animal": "Zodiac animal", "oheng": "Five Element", "yin_yang": "Yin/Yang", "meaning": "Children Palace explanation" },
    "overall_reading": "Overall energy and characteristics of the 8-character combination in 3-4 sentences"
  },
  "wonGuk_analysis": { "day_master": "Day Master analysis", "oheng_balance": "Five Elements balance", "singang_singak": "Strong/Weak determination", "gyeokguk": "Chart structure", "reading": "Natal chart interpretation 8 sentences" },
  "sipsung_analysis": { "dominant_sipsung": ["Strong Ten Gods 1-3"], "weak_sipsung": ["Weak Ten Gods 1-2"], "key_interactions": "Key interactions", "life_implications": "Life impact", "reading": "Ten Gods interpretation 8 sentences" },
  "hapchung_analysis": { "major_haps": ["Major combinations"], "major_chungs": ["Major clashes"], "other_interactions": "Punishments/Harms effects", "overall_impact": "Overall impact", "reading": "Combinations & Clashes interpretation 8 sentences" },
  "personality": { "core_traits": ["Core traits 4-6"], "strengths": ["Strengths 4-6"], "weaknesses": ["Weaknesses 3-4"], "social_style": "Social style", "reading": "Personality interpretation 10 sentences" },
  "lucky_elements": { "colors": ["Lucky colors 2-3"], "directions": ["Good directions 1-2"], "numbers": [1, 6], "seasons": "Favorable season", "partner_elements": ["Compatible zodiac 2-3"] }
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
