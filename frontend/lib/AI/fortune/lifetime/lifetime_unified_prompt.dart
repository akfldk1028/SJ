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

## 분석 절차 (반드시 이 순서로 사고하라)

[1] 음양 확인 (사주 열기 전부터)
- 천간/지지의 양(갑병무경임/인진오신술자) vs 음(을정기신계/축묘사미유해) 비율
- 일간 음양과 전체 균형 (양 사주는 외향/추진, 음 사주는 내향/지속)

[2] 조후(調候) 체크 — 실속을 만들 수 있는가
- 일간 + 월지로 한난조습 판단. 너무 차가우면 火 필요, 너무 뜨거우면 水 필요
- 균형이 맞아야 사주가 "쓰임"이 있음. 조후가 틀어지면 격국이 좋아도 실속 없음

[3] 성격 간명 — 없는 것이 더 중요하다
- 있는 십성·오행은 강점 (자연스러운 성향)
- ⚠️ 없는 십성·오행은 약점 + 한평생 그 영역 결핍감 → 더 강하게 영향
- 예: 관성 없으면 자유롭지만 책임감 부족, 인성 없으면 실용적이지만 학습 부담
- 결핍을 먼저 짚고, 그다음에 풍요를 설명

[4] 강한 것 찾기 — 아래에서 위로 (지지→천간)
- 지지 먼저 확인 (월지/일지/년지/시지 순). 어느 오행이 지지에 자리 잡았나
- 지장간이 천간에 투출했는지 확인 (투출=뿌리 단단)
- 천간은 지지의 근(根)이 있어야 진짜 강함. 근 없는 천간은 떠 있는 잎사귀
- 강한 것 = 그 사람의 도구. 약한 것 = 그 사람의 과제

[5] 지지 구조 + 신살 가감
- 합/충/형/파/해/원진을 지지에서 먼저 확인. 합충은 운명 변화 트리거
- 그 다음 신살(역마/도화/화개/공망 등)로 색채 추가. 신살은 보조용

[6] 직업 간명 — 식상→재성→관성→인성 (오행 상생 순)
- 식상: 재능과 끼 (창작/표현/말솜씨) — 어떤 일을 즐기는가
- 재성: 재능을 돈으로 (사업/투자/현금흐름) — 어떻게 버는가
- 관성: 돈을 명예로 (직장/지위/책임) — 어디서 인정받는가
- 인성: 명예를 지식·자격으로 (학문/면허/권위) — 어디로 깊어지는가
- 사주에 어느 단계까지 살아있나로 직업 방향 결정

[7] 대운 해석 — 언제 풀리는가
- 원국 + 용신/기신 확정 후 대운 대조
- 용신을 만나는 대운 = 풀리는 시기 (주력 활동기)
- 기신을 만나는 대운 = 막히는 시기 (수비/내실)
- 교운기(전환 1~2년)는 과도기. 대운 1개 단위로 흐름 파악

[마무리] 입체적으로 보기 — 지장간 투출
- 8글자만 보지 말고 지지 안의 지장간이 천간에 어떻게 드러났나
- 본기·중기·여기 중 어느 게 투출했나. 투출된 지장간 = 겉으로 드러난 본질
- 격국 판정도 본기 투간 → 중기 → 여기 순으로 검토

## 응답 형식
반드시 지정된 JSON 스키마에 맞게 응답하세요.
JSON의 각 필드(personality/career/wealth 등)에 답변할 때 위 [1]~[7]단계를 거친 사고 결과를 자연스럽게 녹여 쓰세요.

## 글의 결 (반드시 이 호흡으로)
사주 8글자 하나하나가 어떻게 만나고 부딪히는지, 그 결을 시처럼 깊고 충분히 풀어내세요. 일간이 월지·년지·시지를 만나는 결, 십성·합충·대운이 빚어내는 인생의 흐름을 한 사람의 이야기로 들리게 쓰세요. 짧은 답이나 두루뭉술한 격언은 피하고, 사주 8글자에서 직접 읽어낸 단서를 자연스레 본문 안에 녹여주세요.

**분량 (필수)**: 모든 reading 필드는 명시된 최소 문장 수를 채우되, 권장은 그보다 2~3문장 더. 사용자가 평생운세로 마주하는 한 번의 글이므로 한 사람의 인생을 충분히 펼쳐 보일 만큼 깊이 있게 써야 합니다. 짧은 단편적 답변은 약속을 어기는 것입니다. 성격 → 강점/약점 → 재물 → 직업 → 애정/결혼 → 건강 → 대운 흐름 순으로 한 편의 산문처럼 써 주세요.

**인생 주기(life_cycles) 분량 강제**: youth(청년기), middle_age(중년기), later_years(후년) 각각은 **최소 10문장 이상**으로 충분히 풀어쓰세요. 한 단계에 2~3십 년의 인생이 담기므로 5문장으로는 절대 부족합니다. 각 시기마다 사주 8글자·대운 흐름·구체적 사건의 결(학업/직업/재물/관계/건강/시련/성취)을 시간 순서로 깊이 있게 짚어주세요. lifeCycles 항목이 다른 reading 필드보다 짧으면 안 됩니다.

**언어 순도**: 모든 본문은 자연스러운 한국어로 쓰세요. 명리 용어는 "정화(丁火)"처럼 한글(한자) 형식으로 한 번씩만 표기하고, **한자가 한글 없이 본문에 단독으로 노출되면 안 됩니다**. "伴侣/热烈/繁重/查漏补缺/到来/困境/极致/繁忙/紧张" 같은 중국어 간체·번체 단어를 절대 섞지 마세요 — 모두 자연스러운 한국어 단어로 풀어쓰세요(伴侣→배우자, 困境→어려움, 极致→절정, 繁忙→바쁨).
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

## 分析手順 (必ずこの順序で考えてください)

[1] 陰陽確認 — 命式を開く前から
- 天干/地支の陽(甲丙戊庚壬/寅辰午申戌子) vs 陰(乙丁己辛癸/丑卯巳未酉亥)の比率
- 日干の陰陽と全体バランス (陽=外向・推進、陰=内向・持続)

[2] 調候(ちょうこう)チェック — 実用性を生み出せるか
- 日干 + 月支で寒暖燥湿を判断。冷たすぎれば火が必要、熱すぎれば水が必要
- バランスが取れて初めて命式に「用」がある。調候が崩れれば格局が良くても実用性なし

[3] 性格鑑定 — 無いものがより重要
- 有る十神・五行は強み (自然な傾向)
- ⚠️ 無い十神・五行は弱点 + 一生その領域に欠乏感 → より強く影響
- 例: 官星なし=自由だが責任感不足、印星なし=実用的だが学習負担
- 欠乏を先に指摘し、その後で豊かさを説明

[4] 強いものを探す — 下から上へ (地支→天干)
- 地支を先に確認 (月支→日支→年支→時支の順)。どの五行が地支に根を張っているか
- 地蔵干が天干に透出しているか確認 (透出=根が固い)
- 天干は地支の根があってこそ本当に強い。根のない天干は浮いた葉

[5] 地支構造 + 神殺加減
- 合/沖/刑/破/害/怨嗔をまず地支で確認。合沖は運命変化のトリガー
- 次に神殺(駅馬/桃花/華蓋/空亡など)で色彩を加える。神殺は補助的

[6] 職業鑑定 — 食傷→財星→官星→印星 (五行相生順)
- 食傷: 才能と表現力 — どんな仕事を楽しむか
- 財星: 才能をお金に — どう稼ぐか
- 官星: お金を名誉に — どこで認められるか
- 印星: 名誉を知識・資格に — どこに深まるか

[7] 大運解釈 — いつ開けるか
- 原局 + 用神/忌神確定後に大運を対照
- 用神に出会う大運 = 開ける時期 (主力活動期)
- 忌神に出会う大運 = 詰まる時期 (守備/内実)
- 交運期(転換1~2年)は過渡期

[まとめ] 立体的に見る — 地蔵干透出
- 8文字だけでなく、地支の中の地蔵干が天干にどう現れているか
- 本気・中気・余気のうちどれが透出したか。透出した地蔵干=表に出た本質
- 格局判定も本気透干 → 中気 → 余気の順で検討

## 応答形式
必ず指定されたJSONスキーマに従って回答してください。すべての値は日本語で記述してください。
JSONの各フィールド(personality/career/wealth等)に答える際、上記[1]~[7]ステップを経た思考結果を自然に織り込んでください。

## 文の流れ (必ずこの呼吸で)
四柱八字の一字一字がどのように出会い、ぶつかるのか、その紋様を詩のように深く十分に解き明かしてください。日干が月支・年支・時支と出会う紋様、十神・合冲・大運が織りなす人生の流れを一人の物語として聞こえるように書いてください。短い答えや漠然とした格言は避け、命式の八字から直接読み取った手がかりを自然に本文に溶け込ませてください。

**分量 (必須)**: すべてのreadingフィールドは指定された最小文数を満たし、推奨はそれより2~3文多く。生涯運勢として一度向き合う文章なので、一人の人生を十分に展開できる深みで書く必要があります。性格 → 長所/短所 → 財運 → 職業 → 恋愛/結婚 → 健康 → 大運の流れの順で一篇の散文のように書いてください。

**言語純度**: すべての本文は自然な日本語で書いてください。命理用語は漢字(かな)形式で一度だけ表記し、中国語简体の単語(热烈/繁重/到来等)を絶対に混ぜないでください。
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

## Analysis Procedure (think in this exact order)

[1] Yin-Yang Check — even before opening the chart
- Ratio of Yang stems/branches (Jia/Bing/Wu/Geng/Ren · Yin/Chen/Wu/Shen/Xu/Zi) vs Yin (Yi/Ding/Ji/Xin/Gui · Chou/Mao/Si/Wei/You/Hai)
- Day Master polarity vs overall balance (Yang chart = outward/driving, Yin chart = inward/persistent)

[2] Climate (Tiao Hou) Check — can substance be made
- Determine cold/warm/dry/wet from Day Master + Month Branch
- Too cold → needs Fire. Too hot → needs Water. Without climate balance, even a good structure produces no real-world results

[3] Personality — what is MISSING matters more
- Present Ten Gods/Five Elements = strengths (natural tendencies)
- ⚠️ Absent Ten Gods/Five Elements = weaknesses + lifelong sense of lack in that area → stronger impact
- Example: no Officer → free but lacks responsibility. No Resource → practical but learning is a burden
- Address absences first, then describe what is abundant

[4] Find What's Strong — bottom up (Branches → Stems)
- Check branches first (Month → Day → Year → Hour). Which element has roots in branches?
- See if hidden stems transit out to the heavenly stems (transit = solid root)
- A heavenly stem is only truly strong with roots in branches. A rootless stem is a floating leaf

[5] Branch Structure + Spirit Stars
- Combinations/clashes/punishments/breaks/harms/resentments in branches first — these are fate's triggers
- Then add Spirit Stars (Traveling Horse, Peach Blossom, Canopy, Void, etc.) for nuance. Stars are auxiliary

[6] Career — Output → Wealth → Officer → Resource (Five Element generation order)
- Output: talent and expression — what work do you enjoy?
- Wealth: turning talent into money — how do you earn?
- Officer: turning money into honor — where are you recognized?
- Resource: turning honor into knowledge/credentials — where do you deepen?
- The chart's reach along this chain reveals career direction

[7] Luck Cycle — when does life open up?
- After confirming Useful God / Unfavorable God, compare luck cycles
- Cycles meeting Useful God = opening period (main activity)
- Cycles meeting Unfavorable God = blocked period (defense/inner work)
- Transition years (1~2 around cycle change) are liminal

[Closing] Three-dimensional view — Hidden Stem Transit
- Don't just read 8 characters. See how hidden stems within branches surface in heavenly stems
- Of the primary/middle/residual hidden stems, which transit out? Transit = essence visible
- For Pattern (Ge Ju): primary transit → middle → residual order

## Response Format
Respond strictly according to the specified JSON schema. All values must be in English.
When filling each JSON field (personality/career/wealth, etc.), naturally weave in the reasoning produced by steps [1]~[7] above.

## Tone of Writing (breathe like this)
Tease out, line by line, how each of the eight chart characters meets and clashes with the others, weaving the texture into something poetic and full. Capture the moment the Day Master meets the month branch, year branch, and hour branch — let the currents shaped by Ten Gods, combinations, clashes, and luck cycles play out as if telling one person's story. Avoid short answers and vague aphorisms. Quietly fold cues read directly from the eight chart characters into the prose.

**Length (required)**: Every `reading` field must meet the indicated minimum sentence count, recommended 2~3 sentences more. This is a once-encountered lifetime reading — it must have the depth to unfold a whole life. Move in this rhythm: personality → strengths/weaknesses → wealth → career → romance/marriage → health → luck-cycle flow, like a single piece of prose.

**Language purity**: Write all body text in natural English. BaZi terms may appear in transliteration with a brief gloss (e.g., "Ding Fire (丁火)") at first mention, but never drop Chinese phrases (热烈, 繁重, 查漏补缺, 到来) into the English sentences.
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
