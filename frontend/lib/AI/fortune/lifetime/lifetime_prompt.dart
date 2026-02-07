/// # 기본 사주 분석 프롬프트 (GPT-5.2용)
///
/// ## 개요
/// 프로필 저장 시 1회 실행되는 평생 사주 분석 프롬프트입니다.
/// GPT-5.2 모델을 사용하여 가장 정확한 분석을 제공합니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/lifetime/lifetime_prompt.dart`
///
/// ## 분석 내용
/// - 타고난 성격과 기질
/// - 적성과 재능
/// - 대인관계 특성
/// - 건강 취약점
/// - 재물운 경향
/// - 직업/진로 적합성
/// - 연애/결혼운 특성
///
/// ## 입력 데이터 (SajuInputData)
/// ```dart
/// {
///   'profile_id': 'uuid',
///   'profile_name': '이름',
///   'birth_date': '1990-01-15',
///   'gender': 'male',
///   'saju': {'year_gan': '경', ...},
///   'oheng': {'wood': 2, 'fire': 1, ...},
///   'yongsin': {'yongsin': '금(金)', ...},
///   'day_strength': {'is_singang': true, 'score': 65},
///   'sinsal': [...],
///   'gilseong': [...],
/// }
/// ```
///
/// ## 출력 형식 (JSON)
/// ```json
/// {
///   "summary": "한 문장 요약",
///   "personality": {...},
///   "career": {...},
///   "relationships": {...},
///   "wealth": {...},
///   "health": {...},
///   "overall_advice": "...",
///   "lucky_elements": {...}
/// }
/// ```
///
/// ## 호출 흐름
/// ```
/// profile_provider.dart
///   → _triggerAiAnalysis()
///     → SajuAnalysisService.analyzeOnProfileSave()
///       → _runSajuBaseAnalysis()
///         → SajuBasePrompt.buildMessages()
///           → AiApiService.callOpenAI()
///             → Edge Function (ai-openai)
///               → OpenAI API (GPT-5.2)
/// ```
///
/// ## 캐시 정책
/// - 만료 기간: 무기한 (null)
/// - 프로필이 변경되지 않는 한 재생성 불필요
/// - upsert로 동일 profile_id에 대해 덮어쓰기
///
/// ## 비용 참고 (2025-12 기준)
/// - GPT-5.2: 입력 $1.75/1M, 출력 $14.00/1M, 캐시 90% 할인
/// - 평균 분석 1회: 약 $0.02~0.05

import '../../core/ai_constants.dart';
import '../common/prompt_template.dart';

/// 기본 사주 분석 프롬프트
///
/// ## 사용 예시
/// ```dart
/// final prompt = SajuBasePrompt();
/// final messages = prompt.buildMessages(sajuInputData.toJson());
///
/// final response = await aiApiService.callOpenAI(
///   messages: messages,
///   model: prompt.modelName,          // gpt-5.2
///   maxTokens: prompt.maxTokens,      // 4096
///   temperature: prompt.temperature,  // 0.7
/// );
/// ```
///
/// ## 프롬프트 구조
/// 1. **System Prompt**: 사주명리학 전문가 역할 정의
/// 2. **User Prompt**: 사주 데이터 + JSON 출력 스키마
///
/// ## JSON 출력 필드
/// | 필드 | 설명 |
/// |------|------|
/// | summary | 사주 특성 한 문장 요약 |
/// | personality | 성격 분석 (traits, strengths, weaknesses) |
/// | career | 진로 적합성 (suitable_fields, work_style) |
/// | relationships | 대인관계 (social_style, compatibility_tips) |
/// | wealth | 재물운 (tendency, advice) |
/// | health | 건강 (vulnerable_areas, advice) |
/// | overall_advice | 종합 인생 조언 |
/// | lucky_elements | 행운 요소 (colors, directions, numbers) |
class SajuBasePrompt extends PromptTemplate {
  final String locale;
  SajuBasePrompt({this.locale = 'ko'});

  @override
  String get summaryType => SummaryType.sajuBase;

  @override
  String get modelName => OpenAIModels.sajuAnalysis; // GPT-5.2

  @override
  int get maxTokens => TokenLimits.sajuBaseMaxTokens;

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
전통사주를  분석하되 현대시대에 어울리는 해석을 명쾌하게 해주세요.
원국(原局)을 철저히 분석하여 정확하고 깊이 있는 사주 해석을 제공합니다.

## 쉬운말 원칙 (최우선! 이 규칙을 가장 먼저 지키세요!)

사주를 전혀 모르는 20-30대가 읽는다고 가정하세요.
전문용어 없이도 "아, 내 성격이 이런 거구나" 하고 고개를 끄덕일 수 있게 써야 합니다.

### reading 필드 작성법
1. 첫 문장: 자연현상 비유로 핵심 특성 (전문용어 0개)
2. 2-5문장: 구체적 상황/성격/경향 설명 (전문용어 0개)
3. 마지막 문장: 조언 (전문용어 0개)
4. ※ 전문 분석 근거는 별도 필드가 아닌, 본문 뒤 괄호에 한 줄로

### 절대 금지 용어 (reading 필드에 직접 쓰지 마세요)
- 십성 용어: 비견, 겁재, 식신, 상관, 정재, 편재, 정관, 편관, 정인, 편인
- 위치 용어: 일간, 월간, 연간, 시간 → "당신의 타고난 기운" 등으로
- 신살 용어: 용신, 희신, 기신, 구신 → "당신에게 힘이 되는 기운" 등으로
- 관계 용어: 상생, 상극 → 자연현상 비유로 대체
- 오행 한자 표기: 목(木), 화(火) 등 → "나무", "불", "흙", "금속", "물"로만

### reading 예시

나쁜 예: "정재 성향이 강해 가벼운 연애보다 안정적 관계를 선호합니다"
좋은 예: "한번 마음을 주면 쉽게 바뀌지 않는 성격이에요.
가벼운 만남보다는 오래 함께할 사람을 찾는 편이고,
연애도 미래를 생각하며 신중하게 시작하는 타입이에요."

나쁜 예: "식상(火)이 약해 감정표현이 부족"
좋은 예: "마음은 따뜻한데 표현이 서툰 편이에요.
속으로는 많이 생각하지만 말로 잘 안 나와서
상대가 '무심하다'고 오해할 수 있어요."

나쁜 예: "관성(金)이 강해 스스로를 단정히 관리"
좋은 예: "자기 관리가 철저한 편이에요.
약속 시간, 외모, 생활 습관까지 꼼꼼하게 신경 쓰는 타입이죠."

나쁜 예: "인성이 도와 학업운이 좋다"
좋은 예: "배우는 걸 좋아하고 한번 파면 깊이 파는 스타일이에요.
새로운 기술이나 지식을 익히면 금방 자기 것으로 만드는 재주가 있어요."

### 만약 전문용어를 꼭 써야 한다면
"표현과 재능의 에너지(사주에서는 '식상'이라고 해요)" 처럼
**쉬운말 먼저, 전문용어는 괄호 안에 작게**

---

## 분석 방법론 (반드시 순서대로)

### 1단계: 원국 구조 분석

### 2단계: 십성(十星) 분석


### 3단계: 신살(神殺) & 길성(吉星) 해석

### 4단계: 합충형파해(合沖刑破害) 분석


**합(合) 결속력 순서**
- 방합(최강/고정적) > 삼합(유연) > 반합(불완전) > 육합(부드러움)
- 방합 있으면 해당 오행 매우 강력! 삼합보다 방합 먼저 확인

**⚠️ 3글자 완성 조건 (매우 중요!)**
- 삼합: 3글자 모두 있어야 완성 (木局:亥卯未 / 火局:寅午戌 / 金局:巳酉丑 / 水局:申子辰)
- 방합: 3글자 모두 있어야 완성 (水局:亥子丑 / 木局:寅卯辰 / 火局:巳午未 / 金局:申酉戌)
- 반합: 왕지(子午卯酉) 포함 2글자만 있을 때 → 삼합보다 약함
- 왕지 없이 2글자만 있으면 반합 성립 안 됨!

**충(沖) 파괴력 순서**
- 왕지충(묘유/자오, 원수충) > 생지충(인신/사해, 역마) > 고지충(진술/축미)
- 충 영향력: 일지 > 월지 > 연지 > 시지

**형(刑) 흉의 강도 순서**
- 삼형(인사신/축술미 5 관재/배신) > 상형(2자3) > 자묘형(2 무례) > 자형(1)
- 3자 모두 있으면 흉 최강! 2자만 있으면 감소

### 5단계: 12운성 분석


### 6단계: 종합 해 석 (아래 영역별로 상세 분석)
1. **재물운**: 정재/편재 위치, 강약, 충합 관계
2. **연애운**: 도화살, 홍염살, 재성/관성 상태
3. **결혼운**: 배우자궁(일지) 상태, 충합 여부
4. **사업운**: 식상생재 구조, 편재 활용도
5. **직장운**: 관성 상태, 인성의 지원 여부
6. **건강운**: 오행 편중, 충형 위치

### 7단계: 전통 vs AI시대 해석 비교 (내부 참고용 - reading 필드에 한자/전문용어 쓰지 말 것!)

분석 시 이 표를 참고하되, 사용자에게는 쉬운 말로만 전달하세요.
"옛날에는 ~라고 봤지만, 요즘은 ~로 나타나요" 형식을 자연스럽게 포함하세요.

| 내부 참고 | reading에 쓸 표현 | AI시대 적용 |
|-----------|-----------------|-------------|
| 식상 | "표현력/창작 에너지" | 콘텐츠창작/SNS/유튜브/블로그 |
| 역마살 | "이동/변화의 기운" | 디지털노마드/해외근무/원격근무 |
| 도화살 | "매력이 빛나는 기운" | 인플루언서/대중인기/연예/마케팅 |
| 인성 | "배움/보호의 기운" | AI활용능력/온라인학습/코딩/자기계발 |
| 재성 | "재물/기회의 기운" | 디지털자산/투자/N잡/부업/스타트업 |
| 관성 | "직장/책임의 기운" | 대기업/공무원/프리랜서플랫폼 |
| 비겁 | "경쟁/협력의 기운" | 네트워킹/커뮤니티/협업/팀워크 |
| 화개살 | "집중/몰입의 기운" | IT개발/연구직/1인창업/재택근무 |
| 문창귀인 | "글과 학문에 빛나는 기운" | 블로그/작가/교육콘텐츠/자격증 |

## 분석 원칙
- **원국 우선**: 대운/세운보다 원국의 구조를 먼저 파악
- **육친 중심**: 십성을 통해 인간관계와 운세 해석
- **상호작용**: 글자 간 합충형파해를 놓치지 않음
- **균형 해석**: 좋은 점과 주의할 점을 함께 제시

## 응답 형식
반드시 JSON 형식으로만 응답하세요. 추가 설명 없이 순수 JSON만 출력하세요.
''';

  String get _japaneseSystemPrompt => '''
あなたは四柱推命（しちゅうすいめい）分野で30年の経験を持つ最高の専門家です。
伝統的な四柱推命を分析しつつ、現代に合った解釈を明快に提供してください。
原局（げんきょく）を徹底的に分析し、正確で深みのある四柱推命の鑑定を提供します。

## わかりやすさの原則（最優先！）

四柱推命を全く知らない20〜30代が読むことを想定してください。
専門用語なしでも「なるほど、自分の性格はこういうことか」と納得できるように書いてください。

### readingフィールドの書き方
1. 最初の文：自然現象の比喩で核心特性（専門用語ゼロ）
2. 2〜5文：具体的な状況・性格・傾向の説明（専門用語ゼロ）
3. 最後の文：アドバイス（専門用語ゼロ）
4. ※専門的な分析根拠は本文の後に括弧で一行で記載

### 使用禁止用語（readingフィールドに直接書かないでください）
- 十星用語：比肩、劫財、食神、傷官、正財、偏財、正官、偏官、正印、偏印
- 位置用語：日干、月干、年干、時干 → 「あなたの生まれ持ったエネルギー」などに
- 神殺用語：用神、喜神、忌神、仇神 → 「あなたを支える力」などに
- 関係用語：相生、相剋 → 自然現象の比喩で代替
- 五行の漢字表記：木（もく）、火（か）等 → 「木」「火」「土」「金」「水」のみ

## 分析方法論（必ず順番通りに）

### 第1段階：原局構造分析
### 第2段階：十星（じゅっせい）分析
### 第3段階：神殺（しんさつ）・吉星（きっせい）解釈
### 第4段階：合冲刑破害（がっちゅうけいはがい）分析

**合の結束力順序**
- 方合（最強）> 三合（柔軟）> 半合（不完全）> 六合（穏やか）

**冲の破壊力順序**
- 旺支冲（卯酉/子午）> 生支冲（寅申/巳亥）> 庫支冲（辰戌/丑未）

**刑の凶の強度順序**
- 三刑（寅巳申/丑戌未）> 相刑 > 子卯刑 > 自刑

### 第5段階：十二運星分析
### 第6段階：総合解析
1. **財運**: 正財/偏財の位置、強弱、冲合関係
2. **恋愛運**: 桃花殺、紅艶殺、財星/官星の状態
3. **結婚運**: 配偶者宮（日支）の状態、冲合の有無
4. **事業運**: 食傷生財の構造、偏財の活用度
5. **職業運**: 官星の状態、印星のサポート
6. **健康運**: 五行の偏り、冲刑の位置

### 第7段階：伝統 vs 現代の解釈比較（内部参考用）

## 分析原則
- **原局優先**: 大運/歳運よりも原局の構造を先に把握
- **六親中心**: 十星を通じた人間関係と運勢の解釈
- **相互作用**: 文字間の合冲刑破害を見逃さない
- **バランス解釈**: 良い点と注意点を共に提示

## 応答形式
必ずJSON形式のみで回答してください。追加説明なしで純粋なJSONのみ出力してください。
すべてのJSON値は日本語で記述してください。JSONキーは変更しないでください。
''';

  String get _englishSystemPrompt => '''
You are a top expert with 30 years of experience in Four Pillars of Destiny (BaZi / Saju) analysis.
Analyze the traditional Four Pillars while providing interpretations relevant to modern life.
Thoroughly analyze the natal chart (original configuration) and provide accurate, in-depth readings.

## Plain Language Principle (Top Priority!)

Assume the reader is a 20-30 year old who knows nothing about Four Pillars of Destiny.
Write so they can think "Oh, so THAT'S what my personality is like" without any jargon.

### How to write the "reading" fields
1. First sentence: A nature metaphor capturing the core trait (zero jargon)
2. Sentences 2-5: Concrete situations, personality, and tendencies (zero jargon)
3. Last sentence: Practical advice (zero jargon)
4. Professional analysis basis can be added in parentheses at the end

### Forbidden terms in reading fields
- Ten Gods terms: Rob Wealth, Eating God, Hurting Officer, Direct/Indirect Wealth, Direct/Indirect Officer, Direct/Indirect Resource
- Position terms: Day Master, Month Stem, Year Stem → use "your innate energy" etc.
- Deity terms: Useful God, Favorable God, Unfavorable God → use "the energy that supports you" etc.
- Relationship terms: generating, controlling → use nature metaphors instead
- Use simple element names: Wood, Fire, Earth, Metal, Water

## Analysis Methodology (Follow in order)

### Step 1: Natal Chart Structure Analysis
### Step 2: Ten Gods Analysis
### Step 3: Special Stars & Auspicious Stars Interpretation
### Step 4: Combinations, Clashes, Punishments, Harms Analysis

**Combination (He) strength order**
- Directional Combo (strongest) > Three Harmony > Half Combo > Six Harmony (gentlest)

**Clash (Chong) destructive order**
- Cardinal Clash (Mao-You/Zi-Wu) > Growth Clash (Yin-Shen/Si-Hai) > Storage Clash (Chen-Xu/Chou-Wei)

**Punishment (Xing) severity order**
- Triple Punishment (Yin-Si-Shen/Chou-Xu-Wei) > Mutual Punishment > Zi-Mao Punishment > Self-Punishment

### Step 5: Twelve Life Stages Analysis
### Step 6: Comprehensive Analysis
1. **Wealth**: Position and strength of Direct/Indirect Wealth, clash/combo relationships
2. **Romance**: Peach Blossom, Red Romance stars, Wealth/Officer star status
3. **Marriage**: Spouse Palace (Day Branch) status, clashes and combos
4. **Business**: Food God generating Wealth structure, Indirect Wealth utilization
5. **Career**: Officer star status, Resource star support
6. **Health**: Five Elements imbalance, clash/punishment positions

### Step 7: Traditional vs Modern Interpretation (internal reference)

## Analysis Principles
- **Natal chart first**: Understand the natal chart structure before luck cycles
- **Six Relations focus**: Interpret relationships and fortune through Ten Gods
- **Interactions**: Never miss combinations, clashes, punishments between characters
- **Balanced reading**: Present both strengths and cautions

## Response Format
Respond ONLY in JSON format. Output pure JSON without any additional explanation.
All JSON values must be written in English. Do NOT change the JSON keys.
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
${_buildSinsalSection(data.sinsal)}
${_buildGilseongSection(data.gilseong)}
${_buildUnsungSection(data.twelveUnsung)}
${_buildTwelveSinsalSection(data.twelveSinsal)}
${_buildDaeunSection(data.daeun)}
${_buildHapchungSection(data.hapchung)}

---

위 사주 정보를 바탕으로 종합적인 사주 분석을 JSON 형식으로 제공해주세요.

반드시 아래 JSON 스키마를 정확히 따라주세요. 모든 필드를 빠짐없이 채워주세요:

```json
{

  "mySajuIntro": {
    "title": "나의 사주, 나는 누구인가요?",
    "ilju": "일주(日柱) 설명: 일간+일지 조합의 의미 (예: '갑자일주는 큰 나무가 깊은 물을 만난 형상으로...')",
    "reading": "일주를 기반으로 '나'라는 사람에 대한 핵심 설명 6-8문장. 타고난 기질, 성향, 인생의 방향성을 일주 중심으로 설명. 사주 초보자도 쉽게 이해할 수 있게 작성."
  },

  "summary": "이 사주의 핵심 특성을 10~20문장으로 사주에대해 모르는사람들이 이해할수있게 객관적으로 요약",

  "my_saju_characters": {
    "description": "사주팔자 8글자 각각의 의미를 초보자도 이해할 수 있게 설명",
    "year_gan": {
      "character": "연간 한자 (예: 甲)",
      "reading": "연간 읽는 법 (예: 갑)",
      "oheng": "오행 (목/화/토/금/수)",
      "yin_yang": "음양 (양/음)",
      "meaning": "이 글자가 뜻하는 의미를 쉽게 설명 (예: 갑목은 큰 나무처럼 꿋꿋하고 곧은 성질)"
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
      "character": "시간 한자",
      "reading": "시간 읽는 법",
      "oheng": "오행",
      "yin_yang": "음양",
      "meaning": "시간의 의미 쉽게 설명"
    },
    "hour_ji": {
      "character": "시지 한자 (자녀궁)",
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

  "wealth": {
    "overall_tendency": "전체적인 재물운 경향",
    "earning_style": "돈을 버는 방식/스타일",
    "spending_tendency": "소비 성향",
    "investment_aptitude": "투자 적성",
    "wealth_timing": "재물운이 좋은 시기/나이대",
    "cautions": ["재물 관련 주의사항 2-3개"],
    "advice": "재물운 향상을 위한 조언",
    "reading": "재물운 종합 해석 8문장. 재성 상태와 식상생재 구조 기반 돈 버는 스타일과 시기"
  },

  "love": {
    "attraction_style": "끌리는 이성 유형",
    "dating_pattern": "연애 패턴/스타일",
    "romantic_strengths": ["연애에서의 강점 2-3개"],
    "romantic_weaknesses": ["연애에서의 약점 2-3개"],
    "ideal_partner_traits": ["이상적인 파트너 특성 3-4개"],
    "love_timing": "연애운이 좋은 시기",
    "advice": "연애 관련 조언",
    "reading": "연애운 종합 해석 8문장. 일지와 재관 상태 기반 연애 스타일과 주의점"
  },

  "marriage": {
    "spouse_palace_analysis": "배우자궁(일지) 분석",
    "marriage_timing": "결혼 적령기/좋은 시기",
    "spouse_characteristics": "배우자 특성 예상",
    "married_life_tendency": "결혼 생활 경향",
    "cautions": ["결혼 관련 주의사항 2-3개"],
    "advice": "결혼운 향상을 위한 조언",
    "reading": "결혼운 종합 해석 8문장. 배우자궁 상태와 충합 기반 결혼 시기와 생활"
  },

  "career": {
    "suitable_fields": ["적합한 직업/분야 5-7개"],
    "unsuitable_fields": ["피해야 할 분야 2-3개"],
    "work_style": "업무 스타일",
    "leadership_potential": "리더십/관리자 적성",
    "career_timing": "직장운이 좋은 시기",
    "advice": "진로 관련 조언",
    "reading": "직업운 종합 해석 8문장. 관성과 인성 기반 적합한 일, 승진/이직 타이밍"
  },

  "business": {
    "entrepreneurship_aptitude": "사업 적성 분석",
    "suitable_business_types": ["적합한 사업 유형 3-5개"],
    "business_partner_traits": "좋은 사업 파트너 특성",
    "cautions": ["사업 시 주의사항 2-3개"],
    "success_factors": ["사업 성공 요인 2-3개"],
    "advice": "사업 관련 조언",
    "reading": "사업운 종합 해석 8문장. 식상생재 구조와 편재 기반 사업 적합성과 타이밍"
  },

  "health": {
    "vulnerable_organs": ["건강 취약 장기/부위 2-4개"],
    "potential_issues": ["주의해야 할 건강 문제 2-3개"],
    "mental_health": "정신/심리 건강 경향",
    "lifestyle_advice": ["건강 관리 생활 습관 조언 3-4개"],
    "caution_periods": "건강 주의 시기 (있는 경우)",
    "reading": "건강운 종합 해석 6문장. 오행 과다/부족 기반 취약 장기와 관리법"
  },

  "sinsal_gilseong": {
    "major_gilseong": ["주요 길성과 그 의미"],
    "major_sinsal": ["주요 신살과 그 의미"],
    "practical_implications": "신살/길성이 실생활에 미치는 영향",
    "reading": "신살/길성 종합 해석 6문장. 주요 신살이 인생에 가져오는 복과 시련"
  },

  "life_cycles": {
    "youth": "청년기(20-35세) 총평 8-10문장. 이 시기 전반적 에너지와 핵심 기회, 성장 방향",
    "youth_detail": {
      "career": "청년기 직업/학업 전망 6-8문장",
      "wealth": "청년기 재물 전망 6-8문장",
      "love": "청년기 연애/결혼 전망 6-8문장",
      "health": "청년기 건강 전망 4-5문장",
      "tip": "청년기 핵심 조언 3문장",
      "best_period": "가장 좋은 시기 (예: 28-32세)",
      "caution_period": "주의 시기 (예: 25-27세)"
    },
    "middle_age": "중년기(35-55세) 총평 8-10문장",
    "middle_age_detail": {
      "career": "중년기 직업/사업 전망 6-8문장",
      "wealth": "중년기 재물/자산 전망 6-8문장",
      "love": "중년기 가정/부부관계 전망 6-8문장",
      "health": "중년기 건강 전망 6-8문장",
      "tip": "중년기 핵심 조언 3문장",
      "best_period": "가장 좋은 시기 (예: 42-48세)",
      "caution_period": "주의 시기 (예: 38-41세)"
    },
    "later_years": "후년기(55세 이후) 총평 8-10문장",
    "later_years_detail": {
      "career": "후년기 직업/활동 전망 6-8문장",
      "wealth": "후년기 재물/노후 전망 6-8문장",
      "love": "후년기 가정/인간관계 전망 6-8문장",
      "health": "후년기 건강 전망 6-8문장",
      "tip": "후년기 핵심 조언 3문장",
      "best_period": "가장 좋은 시기 (예: 60-65세)",
      "caution_period": "주의 시기 (예: 55-58세)"
    },
    "key_years": ["인생 중요 전환점 3-4개 (예: 28세, 42세, 51세)"]
  },

  "lucky_elements": {
    "colors": ["행운의 색 2-3개"],
    "directions": ["좋은 방향 1-2개"],
    "numbers": [1, 6],
    "seasons": "유리한 계절",
    "partner_elements": ["궁합이 좋은 띠 2-3개"]
  },


  "peak_years": {
    "period": "최전성기 구간 (예: 38-48세)",
    "age_range": [38, 48],
    "why": "왜 이 시기가 최전성기인지 8문장",
    "what_to_prepare": "최전성기 준비사항 3문장",
    "what_to_do": "최전성기에 해야 할 것 3문장",
    "cautions": "최전성기 주의점 2문장"
  },

  "daeun_detail": {
    "intro": "대운 흐름 전체 개요 3문장",
    "cycles": [
      {
        "order": 1,
        "pillar": "현재 대운 간지",
        "age_range": "현재 대운 나이 구간",
        "main_theme": "현재 대운 핵심 주제",
        "fortune_level": "상/중상/중/중하/하",
        "reading": "현재 대운 5문장",
        "opportunities": ["기회 2개"],
        "challenges": ["시련 2개"]
      }
    ],
    "best_daeun": {
      "period": "가장 좋은 대운 시기",
      "why": "왜 이 대운이 가장 좋은지 3문장"
    },
    "worst_daeun": {
      "period": "가장 주의해야 할 대운 시기",
      "why": "왜 이 대운을 조심해야 하는지 3문장"
    }
  },
  "modern_interpretation": {
    "dominant_elements": [
      {
        "element": "사주에서 강한 요소",
        "traditional": "전통적 의미",
        "modern": "AI시대 적용",
        "advice": "현대 사회에서 활용법"
      }
    ],
    "career_in_ai_era": {
      "traditional_path": "전통적 진로 해석",
      "modern_opportunities": ["AI시대 적합 직업/분야 3-5개"],
      "digital_strengths": "디지털/IT 분야 강점"
    },
    "wealth_in_ai_era": {
      "traditional_view": "전통적 재물운 해석",
      "modern_opportunities": ["현대 재물 기회"],
      "risk_factors": "현대 재테크 주의점"
    },
    "relationships_in_ai_era": {
      "traditional_view": "전통적 대인관계 해석",
      "modern_networking": "온라인/SNS 네트워킹 스타일",
      "collaboration_style": "현대 협업 방식"
    }
  }
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

## 日干（自分を表す五行）
${data.dayMaster}

${_buildYongsinSection(data.yongsin)}
${_buildDayStrengthSection(data.dayStrength)}
${_buildGyeokgukSection(data.gyeokguk)}
${_buildSipsinSection(data.sipsinInfo)}
${_buildJijangganSection(data.jijangganInfo)}
${_buildSinsalSection(data.sinsal)}
${_buildGilseongSection(data.gilseong)}
${_buildUnsungSection(data.twelveUnsung)}
${_buildTwelveSinsalSection(data.twelveSinsal)}
${_buildDaeunSection(data.daeun)}
${_buildHapchungSection(data.hapchung)}

---

上記の四柱推命データに基づき、総合的な四柱推命鑑定をJSON形式で提供してください。

以下のJSONスキーマに正確に従ってください。すべてのフィールドを漏れなく記入してください。
すべての値は日本語で記述してください。JSONキーは変更しないでください。

```json
{
  "mySajuIntro": {
    "title": "私の四柱推命、私はどんな人？",
    "ilju": "日柱の説明：日干と日支の組み合わせの意味",
    "reading": "日柱を基に「私」という人の核心説明6〜8文。生まれ持った気質、性向、人生の方向性を説明。"
  },

  "summary": "この命式の核心特性を10〜20文で初心者にもわかるように客観的にまとめる",

  "my_saju_characters": {
    "description": "四柱八字の8文字それぞれの意味を初心者にもわかりやすく説明",
    "year_gan": { "character": "年干の漢字", "reading": "読み方", "oheng": "五行", "yin_yang": "陰陽", "meaning": "意味の説明" },
    "year_ji": { "character": "年支の漢字", "reading": "読み方", "animal": "干支の動物", "oheng": "五行", "yin_yang": "陰陽", "meaning": "意味の説明" },
    "month_gan": { "character": "月干の漢字", "reading": "読み方", "oheng": "五行", "yin_yang": "陰陽", "meaning": "意味の説明" },
    "month_ji": { "character": "月支の漢字", "reading": "読み方", "season": "季節", "oheng": "五行", "yin_yang": "陰陽", "meaning": "意味の説明" },
    "day_gan": { "character": "日干の漢字（自分を表す文字）", "reading": "読み方", "oheng": "五行", "yin_yang": "陰陽", "meaning": "日干は『自分自身』を意味します。わかりやすく説明" },
    "day_ji": { "character": "日支の漢字（配偶者宮）", "reading": "読み方", "animal": "干支の動物", "oheng": "五行", "yin_yang": "陰陽", "meaning": "日支は配偶者宮で結婚運に関連します。わかりやすく説明" },
    "hour_gan": { "character": "時干の漢字", "reading": "読み方", "oheng": "五行", "yin_yang": "陰陽", "meaning": "意味の説明" },
    "hour_ji": { "character": "時支の漢字（子女宮）", "reading": "読み方", "animal": "干支の動物", "oheng": "五行", "yin_yang": "陰陽", "meaning": "時支は子女宮で子供運と晩年運に関連します。わかりやすく説明" },
    "overall_reading": "8文字の組み合わせが作り出す全体的なエネルギーと特性を3〜4文で説明"
  },

  "wonGuk_analysis": { "day_master": "日干分析", "oheng_balance": "五行バランス分析", "singang_singak": "身強/身弱の判定根拠と意味", "gyeokguk": "格局分析", "reading": "原局総合解釈8文" },
  "sipsung_analysis": { "dominant_sipsung": ["強い十星1-3個"], "weak_sipsung": ["弱い十星1-2個"], "key_interactions": "十星間の主要相互作用", "life_implications": "十星構造が人生に与える影響", "reading": "十星総合解釈8文" },
  "hapchung_analysis": { "major_haps": ["主要な合の意味と影響"], "major_chungs": ["主要な冲の意味と影響"], "other_interactions": "刑/破/害/怨嗔の影響", "overall_impact": "合冲構造が人生に与える総合影響", "reading": "合冲総合解釈8文" },
  "personality": { "core_traits": ["核心的な性格特性4-6個"], "strengths": ["長所4-6個"], "weaknesses": ["短所/注意点3-4個"], "social_style": "対人関係スタイル", "reading": "性格総合解釈10文" },
  "wealth": { "overall_tendency": "全体的な財運の傾向", "earning_style": "お金を稼ぐスタイル", "spending_tendency": "消費傾向", "investment_aptitude": "投資適性", "wealth_timing": "財運が良い時期/年齢帯", "cautions": ["財運の注意事項2-3個"], "advice": "財運向上のアドバイス", "reading": "財運総合解釈8文" },
  "love": { "attraction_style": "惹かれる異性のタイプ", "dating_pattern": "恋愛パターン/スタイル", "romantic_strengths": ["恋愛の強み2-3個"], "romantic_weaknesses": ["恋愛の弱点2-3個"], "ideal_partner_traits": ["理想のパートナー特性3-4個"], "love_timing": "恋愛運が良い時期", "advice": "恋愛アドバイス", "reading": "恋愛運総合解釈8文" },
  "marriage": { "spouse_palace_analysis": "配偶者宮（日支）分析", "marriage_timing": "結婚適齢期/良い時期", "spouse_characteristics": "配偶者の特性予想", "married_life_tendency": "結婚生活の傾向", "cautions": ["結婚の注意事項2-3個"], "advice": "結婚運向上のアドバイス", "reading": "結婚運総合解釈8文" },
  "career": { "suitable_fields": ["適した職業/分野5-7個"], "unsuitable_fields": ["避けるべき分野2-3個"], "work_style": "仕事のスタイル", "leadership_potential": "リーダーシップ適性", "career_timing": "職業運が良い時期", "advice": "キャリアアドバイス", "reading": "職業運総合解釈8文" },
  "business": { "entrepreneurship_aptitude": "起業適性分析", "suitable_business_types": ["適した事業タイプ3-5個"], "business_partner_traits": "良いビジネスパートナーの特性", "cautions": ["事業の注意事項2-3個"], "success_factors": ["事業成功要因2-3個"], "advice": "事業アドバイス", "reading": "事業運総合解釈8文" },
  "health": { "vulnerable_organs": ["健康上の弱点2-4個"], "potential_issues": ["注意すべき健康問題2-3個"], "mental_health": "精神/心理的健康の傾向", "lifestyle_advice": ["健康管理の生活習慣アドバイス3-4個"], "caution_periods": "健康注意時期", "reading": "健康運総合解釈6文" },
  "sinsal_gilseong": { "major_gilseong": ["主要な吉星とその意味"], "major_sinsal": ["主要な神殺とその意味"], "practical_implications": "神殺/吉星が実生活に与える影響", "reading": "神殺/吉星総合解釈6文" },
  "life_cycles": {
    "youth": "青年期(20-35歳)総評8-10文",
    "youth_detail": { "career": "青年期の職業展望6-8文", "wealth": "青年期の財運展望6-8文", "love": "青年期の恋愛/結婚展望6-8文", "health": "青年期の健康展望4-5文", "tip": "青年期の核心アドバイス3文", "best_period": "最も良い時期", "caution_period": "注意時期" },
    "middle_age": "中年期(35-55歳)総評8-10文",
    "middle_age_detail": { "career": "中年期の職業展望6-8文", "wealth": "中年期の資産展望6-8文", "love": "中年期の家庭/夫婦関係展望6-8文", "health": "中年期の健康展望6-8文", "tip": "中年期の核心アドバイス3文", "best_period": "最も良い時期", "caution_period": "注意時期" },
    "later_years": "晩年期(55歳以降)総評8-10文",
    "later_years_detail": { "career": "晩年期の活動展望6-8文", "wealth": "晩年期の老後展望6-8文", "love": "晩年期の人間関係展望6-8文", "health": "晩年期の健康展望6-8文", "tip": "晩年期の核心アドバイス3文", "best_period": "最も良い時期", "caution_period": "注意時期" },
    "key_years": ["人生の重要な転換点3-4個"]
  },
  "lucky_elements": { "colors": ["ラッキーカラー2-3個"], "directions": ["良い方角1-2個"], "numbers": [1, 6], "seasons": "有利な季節", "partner_elements": ["相性の良い干支2-3個"] },
  "peak_years": { "period": "最盛期の区間", "age_range": [38, 48], "why": "なぜこの時期が最盛期なのか8文", "what_to_prepare": "最盛期の準備事項3文", "what_to_do": "最盛期にすべきこと3文", "cautions": "最盛期の注意点2文" },
  "daeun_detail": {
    "intro": "大運の流れ全体概要3文",
    "cycles": [{ "order": 1, "pillar": "現在の大運干支", "age_range": "年齢区間", "main_theme": "核心テーマ", "fortune_level": "上/中上/中/中下/下", "reading": "5文の解釈", "opportunities": ["チャンス2個"], "challenges": ["試練2個"] }],
    "best_daeun": { "period": "最も良い大運時期", "why": "理由3文" },
    "worst_daeun": { "period": "最も注意すべき大運時期", "why": "理由3文" }
  },
  "modern_interpretation": {
    "dominant_elements": [{ "element": "強い要素", "traditional": "伝統的意味", "modern": "AI時代の適用", "advice": "現代社会での活用法" }],
    "career_in_ai_era": { "traditional_path": "伝統的なキャリア解釈", "modern_opportunities": ["AI時代に適した職業3-5個"], "digital_strengths": "デジタル/IT分野の強み" },
    "wealth_in_ai_era": { "traditional_view": "伝統的な財運解釈", "modern_opportunities": ["現代の財運チャンス"], "risk_factors": "現代の投資注意点" },
    "relationships_in_ai_era": { "traditional_view": "伝統的な対人関係解釈", "modern_networking": "オンライン/SNSネットワーキングスタイル", "collaboration_style": "現代のコラボレーション方式" }
  }
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

## Day Master (Element representing you)
${data.dayMaster}

${_buildYongsinSection(data.yongsin)}
${_buildDayStrengthSection(data.dayStrength)}
${_buildGyeokgukSection(data.gyeokguk)}
${_buildSipsinSection(data.sipsinInfo)}
${_buildJijangganSection(data.jijangganInfo)}
${_buildSinsalSection(data.sinsal)}
${_buildGilseongSection(data.gilseong)}
${_buildUnsungSection(data.twelveUnsung)}
${_buildTwelveSinsalSection(data.twelveSinsal)}
${_buildDaeunSection(data.daeun)}
${_buildHapchungSection(data.hapchung)}

---

Based on the Four Pillars data above, provide a comprehensive BaZi analysis in JSON format.

Follow the JSON schema below exactly. Fill in ALL fields without omission.
All values must be written in English. Do NOT change the JSON keys.

```json
{
  "mySajuIntro": {
    "title": "My Four Pillars - Who Am I?",
    "ilju": "Day Pillar explanation: meaning of the Day Stem + Day Branch combination",
    "reading": "Core description of 'you' based on the Day Pillar in 6-8 sentences. Explain innate temperament, tendencies, and life direction in beginner-friendly language."
  },

  "summary": "Summarize the core characteristics of this chart in 10-20 sentences, written so someone unfamiliar with BaZi can understand",

  "my_saju_characters": {
    "description": "Explain the meaning of each of the 8 characters in beginner-friendly terms",
    "year_gan": { "character": "Year Stem Chinese character", "reading": "Pronunciation", "oheng": "Five Element", "yin_yang": "Yin/Yang", "meaning": "Easy explanation of this character's meaning" },
    "year_ji": { "character": "Year Branch Chinese character", "reading": "Pronunciation", "animal": "Zodiac animal", "oheng": "Five Element", "yin_yang": "Yin/Yang", "meaning": "Easy explanation" },
    "month_gan": { "character": "Month Stem", "reading": "Pronunciation", "oheng": "Five Element", "yin_yang": "Yin/Yang", "meaning": "Easy explanation" },
    "month_ji": { "character": "Month Branch", "reading": "Pronunciation", "season": "Season", "oheng": "Five Element", "yin_yang": "Yin/Yang", "meaning": "Easy explanation" },
    "day_gan": { "character": "Day Stem (represents YOU!)", "reading": "Pronunciation", "oheng": "Five Element", "yin_yang": "Yin/Yang", "meaning": "The Day Stem represents 'yourself'. This character's traits are your personality and temperament." },
    "day_ji": { "character": "Day Branch (Spouse Palace)", "reading": "Pronunciation", "animal": "Zodiac animal", "oheng": "Five Element", "yin_yang": "Yin/Yang", "meaning": "The Day Branch is the Spouse Palace, connected to marriage fortune." },
    "hour_gan": { "character": "Hour Stem", "reading": "Pronunciation", "oheng": "Five Element", "yin_yang": "Yin/Yang", "meaning": "Easy explanation" },
    "hour_ji": { "character": "Hour Branch (Children Palace)", "reading": "Pronunciation", "animal": "Zodiac animal", "oheng": "Five Element", "yin_yang": "Yin/Yang", "meaning": "The Hour Branch is the Children Palace, related to children and later years." },
    "overall_reading": "Explain the overall energy and characteristics created by the 8-character combination in 3-4 sentences"
  },

  "wonGuk_analysis": { "day_master": "Day Master analysis", "oheng_balance": "Five Elements balance analysis", "singang_singak": "Strong/Weak Day Master determination and meaning", "gyeokguk": "Chart structure analysis", "reading": "Natal chart comprehensive interpretation in 8 sentences" },
  "sipsung_analysis": { "dominant_sipsung": ["Strong Ten Gods 1-3"], "weak_sipsung": ["Weak Ten Gods 1-2"], "key_interactions": "Key interactions between Ten Gods", "life_implications": "How the Ten Gods structure affects life", "reading": "Ten Gods comprehensive interpretation in 8 sentences" },
  "hapchung_analysis": { "major_haps": ["Major combinations and their effects"], "major_chungs": ["Major clashes and their effects"], "other_interactions": "Punishments/Harms effects (if any)", "overall_impact": "Overall impact of combinations and clashes on life", "reading": "Combinations & Clashes comprehensive interpretation in 8 sentences" },
  "personality": { "core_traits": ["Core personality traits 4-6"], "strengths": ["Strengths 4-6"], "weaknesses": ["Weaknesses/cautions 3-4"], "social_style": "Social and relationship style", "reading": "Personality comprehensive interpretation in 10 sentences" },
  "wealth": { "overall_tendency": "Overall wealth fortune tendency", "earning_style": "Money-making style", "spending_tendency": "Spending habits", "investment_aptitude": "Investment aptitude", "wealth_timing": "Best periods for wealth", "cautions": ["Wealth cautions 2-3"], "advice": "Wealth improvement advice", "reading": "Wealth fortune comprehensive interpretation in 8 sentences" },
  "love": { "attraction_style": "Type of partner you are attracted to", "dating_pattern": "Dating pattern/style", "romantic_strengths": ["Romantic strengths 2-3"], "romantic_weaknesses": ["Romantic weaknesses 2-3"], "ideal_partner_traits": ["Ideal partner traits 3-4"], "love_timing": "Best period for romance", "advice": "Romance advice", "reading": "Love fortune comprehensive interpretation in 8 sentences" },
  "marriage": { "spouse_palace_analysis": "Spouse Palace (Day Branch) analysis", "marriage_timing": "Best marriage timing", "spouse_characteristics": "Expected spouse characteristics", "married_life_tendency": "Marriage life tendencies", "cautions": ["Marriage cautions 2-3"], "advice": "Marriage fortune advice", "reading": "Marriage fortune comprehensive interpretation in 8 sentences" },
  "career": { "suitable_fields": ["Suitable careers/fields 5-7"], "unsuitable_fields": ["Fields to avoid 2-3"], "work_style": "Work style", "leadership_potential": "Leadership aptitude", "career_timing": "Best career periods", "advice": "Career advice", "reading": "Career fortune comprehensive interpretation in 8 sentences" },
  "business": { "entrepreneurship_aptitude": "Business aptitude analysis", "suitable_business_types": ["Suitable business types 3-5"], "business_partner_traits": "Good business partner traits", "cautions": ["Business cautions 2-3"], "success_factors": ["Business success factors 2-3"], "advice": "Business advice", "reading": "Business fortune comprehensive interpretation in 8 sentences" },
  "health": { "vulnerable_organs": ["Health vulnerable areas 2-4"], "potential_issues": ["Health concerns 2-3"], "mental_health": "Mental/psychological health tendencies", "lifestyle_advice": ["Health lifestyle advice 3-4"], "caution_periods": "Health caution periods", "reading": "Health fortune comprehensive interpretation in 6 sentences" },
  "sinsal_gilseong": { "major_gilseong": ["Major auspicious stars and meanings"], "major_sinsal": ["Major special stars and meanings"], "practical_implications": "Real-life impact of special stars", "reading": "Special stars comprehensive interpretation in 6 sentences" },
  "life_cycles": {
    "youth": "Young adult years (20-35) overview in 8-10 sentences",
    "youth_detail": { "career": "Youth career outlook 6-8 sentences", "wealth": "Youth wealth outlook 6-8 sentences", "love": "Youth romance outlook 6-8 sentences", "health": "Youth health outlook 4-5 sentences", "tip": "Youth key advice 3 sentences", "best_period": "Best period (e.g., ages 28-32)", "caution_period": "Caution period (e.g., ages 25-27)" },
    "middle_age": "Middle age (35-55) overview in 8-10 sentences",
    "middle_age_detail": { "career": "Middle age career outlook 6-8 sentences", "wealth": "Middle age wealth outlook 6-8 sentences", "love": "Middle age family outlook 6-8 sentences", "health": "Middle age health outlook 6-8 sentences", "tip": "Middle age key advice 3 sentences", "best_period": "Best period", "caution_period": "Caution period" },
    "later_years": "Later years (55+) overview in 8-10 sentences",
    "later_years_detail": { "career": "Later years activity outlook 6-8 sentences", "wealth": "Later years retirement outlook 6-8 sentences", "love": "Later years relationships outlook 6-8 sentences", "health": "Later years health outlook 6-8 sentences", "tip": "Later years key advice 3 sentences", "best_period": "Best period", "caution_period": "Caution period" },
    "key_years": ["Key life turning points 3-4 (e.g., age 28, 42, 51)"]
  },
  "lucky_elements": { "colors": ["Lucky colors 2-3"], "directions": ["Good directions 1-2"], "numbers": [1, 6], "seasons": "Favorable season", "partner_elements": ["Compatible zodiac signs 2-3"] },
  "peak_years": { "period": "Peak period (e.g., ages 38-48)", "age_range": [38, 48], "why": "Why this is the peak period in 8 sentences", "what_to_prepare": "Peak preparation in 3 sentences", "what_to_do": "What to do during peak in 3 sentences", "cautions": "Peak cautions in 2 sentences" },
  "daeun_detail": {
    "intro": "Luck cycle overview in 3 sentences",
    "cycles": [{ "order": 1, "pillar": "Current luck cycle pillar", "age_range": "Age range", "main_theme": "Core theme", "fortune_level": "Excellent/Good/Average/Below Average/Poor", "reading": "5-sentence interpretation", "opportunities": ["2 opportunities"], "challenges": ["2 challenges"] }],
    "best_daeun": { "period": "Best luck cycle period", "why": "Reason in 3 sentences" },
    "worst_daeun": { "period": "Most cautious luck cycle period", "why": "Reason in 3 sentences" }
  },
  "modern_interpretation": {
    "dominant_elements": [{ "element": "Strong element in chart", "traditional": "Traditional meaning", "modern": "AI era application", "advice": "How to leverage in modern society" }],
    "career_in_ai_era": { "traditional_path": "Traditional career interpretation", "modern_opportunities": ["AI era suitable careers 3-5"], "digital_strengths": "Digital/IT strengths" },
    "wealth_in_ai_era": { "traditional_view": "Traditional wealth interpretation", "modern_opportunities": ["Modern wealth opportunities"], "risk_factors": "Modern investment cautions" },
    "relationships_in_ai_era": { "traditional_view": "Traditional relationship interpretation", "modern_networking": "Online/SNS networking style", "collaboration_style": "Modern collaboration style" }
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

    final buffer = StringBuffer('\n## 신강/신약 (8단계 판정) - ⚠️ 중요 ⚠️\n');

    final score = dayStrength['score'] as int? ?? 50;
    final level = dayStrength['level'] as String? ?? _determineLevelFromScore(score);
    final isSingang = score >= 50;

    buffer.writeln('');
    buffer.writeln('┌─────────────────────────────────────────────────┐');
    buffer.writeln('│ [중요] 이 값을 그대로 사용하세요 (재계산 금지)     │');
    buffer.writeln('├─────────────────────────────────────────────────┤');
    buffer.writeln('│ 점수: $score점                                   │');
    buffer.writeln('│ 등급: $level                                     │');
    buffer.writeln('│ is_singang: $isSingang                           │');
    buffer.writeln('└─────────────────────────────────────────────────┘');
    buffer.writeln('');
    buffer.writeln('**8단계 기준표** (점수 → 등급 매핑):');
    buffer.writeln('| 점수 범위 | 등급 | is_singang |');
    buffer.writeln('|-----------|------|------------|');
    buffer.writeln('| 88-100 | 극왕 | true |');
    buffer.writeln('| 75-87 | 태강 | true |');
    buffer.writeln('| 63-74 | 신강 | true |');
    buffer.writeln('| 50-62 | 중화신강 | true |');
    buffer.writeln('| 38-49 | 중화신약 | false |');
    buffer.writeln('| 26-37 | 신약 | false |');
    buffer.writeln('| 13-25 | 태약 | false |');
    buffer.writeln('| 0-12 | 극약 | false |');
    buffer.writeln('');
    buffer.writeln('> **경고**: 점수 $score은 "$level"입니다. 응답에서 이 등급을 그대로 사용하세요.');

    return buffer.toString();
  }

  /// 점수로부터 8단계 등급 결정 (Flutter day_strength_service.dart와 동일)
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

  /// 격국 섹션 빌드
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

  /// 십신 섹션 빌드
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

  /// 지장간 섹션 빌드
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

  /// 12신살 섹션 빌드
  String _buildTwelveSinsalSection(List<dynamic>? twelveSinsal) {
    if (twelveSinsal == null || twelveSinsal.isEmpty) return '';

    final buffer = StringBuffer('\n## 12신살 (十二神殺)\n');

    for (final item in twelveSinsal) {
      if (item is Map) {
        final pillar = item['pillar'] ?? '';
        final sinsal = item['sinsal'] ?? '';
        final fortuneType = item['fortuneType'] ?? '';
        if (sinsal.toString().isNotEmpty) {
          buffer.writeln('- $pillar: $sinsal ($fortuneType)');
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

    final buffer = StringBuffer('\n## 대운 (大運)\n');

    // 대운 시작 나이 (snake_case 또는 camelCase)
    final startAge = daeun['start_age'] ?? daeun['startAge'];
    if (startAge != null) {
      buffer.writeln('- 대운 시작: $startAge세');
    }

    // 순행/역행
    final isForward = daeun['isForward'] ?? daeun['is_forward'];
    if (isForward != null) {
      buffer.writeln('- 운행: ${isForward == true ? '순행' : '역행'}');
    }

    // 대운 목록
    final list = daeun['list'];
    if (list != null && list is List && list.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('### 대운 목록 (10년 단위)');
      buffer.writeln('| 순서 | 대운 | 시작나이 | 종료나이 |');
      buffer.writeln('|------|------|----------|----------|');

      for (final d in list) {
        if (d is Map) {
          final order = d['order'] ?? '';
          // pillar: "임(壬)신(申)" 형식 또는 gan/ji 분리 형식
          String pillarStr = '';
          if (d['pillar'] != null) {
            pillarStr = _extractDaeunPillar(d['pillar'].toString());
          } else if (d['gan'] != null && d['ji'] != null) {
            pillarStr = '${d['gan']}${d['ji']}';
          }
          final sAge = d['startAge'] ?? d['start_age'] ?? '';
          final eAge = d['endAge'] ?? d['end_age'] ?? '';
          buffer.writeln('| $order | $pillarStr | ${sAge}세 | ${eAge}세 |');
        }
      }
      buffer.writeln('');

      // 대운 흐름 요약
      final flowList = list.take(10).map((d) {
        if (d is Map) {
          if (d['pillar'] != null) {
            return _extractDaeunPillar(d['pillar'].toString());
          } else if (d['gan'] != null && d['ji'] != null) {
            return '${d['gan']}${d['ji']}';
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
    return hangulOnly;
  }

  /// 합충형파해 섹션 빌드
  ///
  /// 천간/지지 간의 합충형파해 관계를 프롬프트에 포함합니다.
  /// - 합: 천간합, 지지육합, 삼합, 방합 (길한 관계)
  /// - 충: 천간충, 지지충 (충돌 관계)
  /// - 형: 지지형 (갈등 관계)
  /// - 파: 지지파 (손상 관계)
  /// - 해: 지지해 (방해 관계)
  /// - 원진: 미움 관계
  String _buildHapchungSection(Map<String, dynamic>? hapchung) {
    if (hapchung == null) return '';

    final hasRelations = hapchung['has_relations'] as bool? ?? false;
    if (!hasRelations) return '';

    final buffer = StringBuffer('\n## 합충형파해 (合沖刑破害)\n');

    // 집계 정보
    final totalHaps = hapchung['total_haps'] as int? ?? 0;
    final totalChungs = hapchung['total_chungs'] as int? ?? 0;
    final totalNegatives = hapchung['total_negatives'] as int? ?? 0;

    buffer.writeln('> 합 ${totalHaps}개, 충 ${totalChungs}개, 형/파/해/원진 ${totalNegatives}개');
    buffer.writeln('');

    // 천간합 (합화 시 더 강력)
    final cheonganHaps = hapchung['cheongan_haps'] as List? ?? [];
    if (cheonganHaps.isNotEmpty) {
      buffer.writeln('### 천간합 (天干合) [중간 강도]');
      for (final h in cheonganHaps) {
        final desc = h['description'] ?? '${h['gan1']}${h['gan2']}합';
        buffer.writeln('- ${h['pillar1']}주-${h['pillar2']}주: $desc');
      }
      buffer.writeln('');
    }

    // 천간충
    final cheonganChungs = hapchung['cheongan_chungs'] as List? ?? [];
    if (cheonganChungs.isNotEmpty) {
      buffer.writeln('### 천간충 (天干沖)');
      for (final c in cheonganChungs) {
        buffer.writeln('- ${c['pillar1']}주-${c['pillar2']}주: ${c['gan1']}${c['gan2']}충');
      }
      buffer.writeln('');
    }

    // 지지육합 (가장 부드러운 결합)
    final jijiYukhaps = hapchung['jiji_yukhaps'] as List? ?? [];
    if (jijiYukhaps.isNotEmpty) {
      buffer.writeln('### 지지육합 (地支六合) [부드러운 결합]');
      for (final y in jijiYukhaps) {
        final desc = y['description'] ?? '${y['ji1']}${y['ji2']}합';
        buffer.writeln('- ${y['pillar1']}주-${y['pillar2']}주: $desc');
      }
      buffer.writeln('');
    }

    // 삼합 (완성 / 반합)
    final jijiSamhaps = hapchung['jiji_samhaps'] as List? ?? [];
    if (jijiSamhaps.isNotEmpty) {
      buffer.writeln('### 삼합 (三合) [강하고 유연함]');
      for (final s in jijiSamhaps) {
        final jijis = (s['jijis'] as List?)?.join('') ?? '';
        final pillars = (s['pillars'] as List?)?.join(',') ?? '';
        final isFull = s['is_full'] as bool? ?? true;
        final label = isFull ? '삼합(완성)' : '반합(불완전)';
        buffer.writeln('- ${pillars}주: $jijis $label (${s['result_oheng']}국)');
      }
      buffer.writeln('');
    }

    // 방합 (가장 강력!)
    final jijiBanghaps = hapchung['jiji_banghaps'] as List? ?? [];
    if (jijiBanghaps.isNotEmpty) {
      buffer.writeln('### 방합 (方合) [가장 강력! 고정적]');
      for (final b in jijiBanghaps) {
        final jijis = (b['jijis'] as List?)?.join('') ?? '';
        final pillars = (b['pillars'] as List?)?.join(',') ?? '';
        buffer.writeln('- ${pillars}주: $jijis 방합(최강) (${b['season']}, ${b['direction']}방)');
      }
      buffer.writeln('');
    }

    // 지지충 (강도별: 왕지충 > 생지충 > 고지충)
    final jijiChungs = hapchung['jiji_chungs'] as List? ?? [];
    if (jijiChungs.isNotEmpty) {
      buffer.writeln('### 지지충 (地支沖) [왕지충>생지충>고지충]');
      for (final c in jijiChungs) {
        final ji1 = c['ji1'] as String? ?? '';
        final ji2 = c['ji2'] as String? ?? '';
        final chungStrength = _getChungStrength(ji1, ji2);
        buffer.writeln('- ${c['pillar1']}주-${c['pillar2']}주: $ji1$ji2충 $chungStrength');
      }
      buffer.writeln('');
    }

    // 지지형 (삼형 > 상형 > 자묘형 > 자형)
    final jijiHyungs = hapchung['jiji_hyungs'] as List? ?? [];
    if (jijiHyungs.isNotEmpty) {
      buffer.writeln('### 지지형 (地支刑) [삼형>상형>자묘형>자형]');
      for (final h in jijiHyungs) {
        final desc = h['description'] ?? '${h['ji1']}${h['ji2']}형';
        final hyungType = h['hyung_type'] as String? ?? '';
        final hyungStrength = _getHyungStrength(hyungType);
        buffer.writeln('- ${h['pillar1']}주-${h['pillar2']}주: $desc $hyungStrength');
      }
      buffer.writeln('');
    }

    // 지지파
    final jijiPas = hapchung['jiji_pas'] as List? ?? [];
    if (jijiPas.isNotEmpty) {
      buffer.writeln('### 지지파 (地支破)');
      for (final p in jijiPas) {
        buffer.writeln('- ${p['pillar1']}주-${p['pillar2']}주: ${p['ji1']}${p['ji2']}파');
      }
      buffer.writeln('');
    }

    // 지지해
    final jijiHaes = hapchung['jiji_haes'] as List? ?? [];
    if (jijiHaes.isNotEmpty) {
      buffer.writeln('### 지지해 (地支害)');
      for (final h in jijiHaes) {
        buffer.writeln('- ${h['pillar1']}주-${h['pillar2']}주: ${h['ji1']}${h['ji2']}해');
      }
      buffer.writeln('');
    }

    // 원진
    final wonjins = hapchung['wonjins'] as List? ?? [];
    if (wonjins.isNotEmpty) {
      buffer.writeln('### 원진 (怨嗔)');
      for (final w in wonjins) {
        buffer.writeln('- ${w['pillar1']}주-${w['pillar2']}주: ${w['ji1']}${w['ji2']}원진');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// 충(沖) 강도 판별
  /// 왕지충(묘유,자오) > 생지충(인신,사해) > 고지충(진술,축미)
  String _getChungStrength(String ji1, String ji2) {
    final pair = {ji1, ji2};

    // 왕지충 (가장 강함)
    if (pair.containsAll({'묘', '유'}) || pair.containsAll({'卯', '酉'})) {
      return '(왕지충 원수충!)';
    }
    if (pair.containsAll({'자', '오'}) || pair.containsAll({'子', '午'})) {
      return '(왕지충)';
    }

    // 생지충 (강함)
    if (pair.containsAll({'인', '신'}) || pair.containsAll({'寅', '申'})) {
      return '(생지충 역마충돌!)';
    }
    if (pair.containsAll({'사', '해'}) || pair.containsAll({'巳', '亥'})) {
      return '(생지충)';
    }

    // 고지충 (중간)
    if (pair.containsAll({'진', '술'}) || pair.containsAll({'辰', '戌'})) {
      return '(고지충 오래지속)';
    }
    if (pair.containsAll({'축', '미'}) || pair.containsAll({'丑', '未'})) {
      return '(고지충 오래지속)';
    }

    return '';
  }

  /// 형(刑) 강도 판별
  /// 삼형 > 상형 > 자묘형 > 자형
  String _getHyungStrength(String hyungType) {
    switch (hyungType) {
      case '인사신삼형':
      case '寅巳申삼형':
        return '(삼형 관재/배신!)';
      case '축술미삼형':
      case '丑戌未삼형':
        return '(삼형신의깨짐!)';
      case '인사형':
      case '사신형':
      case '인신형':
      case '축술형':
      case '술미형':
      case '축미형':
        return '(상형)';
      case '자묘형':
      case '子卯형':
        return '(무례지형)';
      case '자형':
      case '진진형':
      case '오오형':
      case '유유형':
      case '해해형':
        return '(자형)';
      default:
        return '';
    }
  }
}