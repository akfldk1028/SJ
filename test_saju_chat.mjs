/**
 * 사주 AI 함정 질문 테스트
 * - Gemini 2.5 Flash Lite vs Qwen 3.5 Flash 품질 비교
 * - 기초 명리학 규칙 정답률 체크
 * - Qwen explicit caching 검증 (cached_tokens 확인)
 *
 * 사용법:
 *   QWEN_API_KEY=sk-xxx node test_saju_chat.mjs          # 양쪽 비교
 *   QWEN_API_KEY=sk-xxx node test_saju_chat.mjs qwen     # Qwen만
 *   node test_saju_chat.mjs gemini                        # Gemini만 (기존)
 */

const SUPABASE_URL = 'https://kfciluyxkomskyxjaeat.supabase.co';
const API_KEY = 'sb_publishable_BeKozV2EEX18nI8VgCC7dw_zxThHlTN';

// Qwen 3.5 Flash (DashScope 싱가포르)
const QWEN_API_KEY = process.env.QWEN_API_KEY || '';
const QWEN_BASE_URL = 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1';

// 실행 모드
const MODE = process.argv[2] || (QWEN_API_KEY ? 'compare' : 'gemini');

const rules = `당신은 시궁창 술사. 천박하고 상스럽지만 실력은 진짜인 점술가.
최대한 천박하고 거칠게. 반말. 근거 없이 까면 안 됨. 8글자 근거 필수.

## 사주 데이터
사용자: 갑술년 병자월 경인일 경진시 (남성, 1994년생)
일간: 경금(庚金), 신약
용신: 토(土), 희신: 금(金)
기신: 목(木), 구신: 수(水)
오행: 금3 목1 화1 토2 수1

사주팔자:
| 구분 | 년주 | 월주 | 일주 | 시주 |
| 천간 | 갑 | 병 | 경 | 경 |
| 지지 | 술 | 자 | 인 | 진 |

대운 (순행):
| 순서 | 대운 | 기간 |
| 1 | 정축(丁丑) | 4~13세 |
| 2 | 무인(戊寅) | 14~23세 |
| 3 | 기묘(己卯) | 24~33세 |
| 4 | 경진(庚辰) | 34~43세 |
| 5 | 신사(辛巳) | 44~53세 |
| 6 | 임오(壬午) | 54~63세 |

## 사주 핵심 규칙
【충】 子午, 丑未, 寅申, 卯酉, 辰戌, 巳亥 — 딱 6쌍만. 이 외는 충 아님.
【원진】 子未, 丑午, 寅酉, 卯申, 辰亥, 巳戌 — 딱 6쌍만. 이 외는 원진 아님.
【육친 배우자성】 남자=재성(내가 극하는 오행), 여자=관성(나를 극하는 오행).
  경금 남자 → 배우자=목(갑편재/을정재). 임수는 편인이지 배우자 아님!
【십성】 내가극+같은음양=편재, 다른음양=정재. 경금이 갑목 극함(금극목), 같은양=편재.
【궁위】 일간=나 자신, 일지=배우자궁. 일주 전체가 배우자궁 아님.
【삼합】 申子辰=水局, 寅午戌=火局, 巳酉丑=金局, 亥卯未=木局. 2개만 있으면=반합.

【지장간 본기/중기/여기】
子:癸(본) | 丑:己(본),癸(중),辛(여) | 寅:甲(본),丙(중),戊(여)
卯:乙(본) | 辰:戊(본),乙(중),癸(여) | 巳:丙(본),戊(중),庚(여)
午:丁(본),己(중) | 未:己(본),丁(중),乙(여) | 申:庚(��),壬(중),戊(여)
酉:辛(본) | 戌:戊(본),辛(중),丁(여) | 亥:壬(본),甲(중)

【대운 해석】
- 대운 천간+지지 동시 작용, 지지가 지배적
- 대운 오행이 용신이면 길운, 기신이면 흉운 (무조건 좋다/나쁘다 금지)

【응답 태도】
- 답변 전 제공된 데이터를 먼저 전부 확인. 데이터에 있는 걸 못 보면 신뢰 상실.
- 유저가 지적하면 반사적 동의 금지. 데이터 재확인 후 맞으면 인정, 틀리면 근거로 설명.
- 좋은 점과 주의할 점을 항상 같이. 좋은 말만 하면 실패.

⚠️ 데이터에 없는 합/충/원진 지어내기 절대 금지.`;

// ── Gemini (기존: Supabase Edge Function 경유) ──
async function chatGemini(msg) {
  const start = Date.now();
  const r = await fetch(`${SUPABASE_URL}/functions/v1/ai-gemini`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "apikey": API_KEY },
    body: JSON.stringify({
      action: "chat",
      messages: [
        { role: "system", content: rules },
        { role: "user", content: msg }
      ],
      model: "gemini-2.5-flash-lite",
      max_tokens: 800,
      temperature: 0.8,
      stream: false
    })
  });
  const json = await r.json();
  const ms = Date.now() - start;
  return { text: json.content || json.error || JSON.stringify(json), ms, usage: json.usage };
}

// ── Qwen 3.5 Flash (DashScope 직접, explicit caching) ──
async function chatQwen(msg) {
  if (!QWEN_API_KEY) throw new Error("QWEN_API_KEY not set");
  const start = Date.now();
  const r = await fetch(`${QWEN_BASE_URL}/chat/completions`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${QWEN_API_KEY}`,
    },
    body: JSON.stringify({
      model: "qwen3.5-flash",
      messages: [
        // explicit caching: system prompt에 cache_control 마커
        // → 첫 호출: 125% 생성비용, 이후: 10% 과금 (90% 할인)
        // → 5분 TTL, 히트 시 리셋
        { role: "system", content: [
          { type: "text", text: rules, cache_control: { type: "ephemeral" } }
        ]},
        { role: "user", content: msg }
      ],
      max_tokens: 800,
      temperature: 0.8,
      stream: false,
    })
  });
  const json = await r.json();
  const ms = Date.now() - start;
  if (json.error) return { text: `ERROR: ${JSON.stringify(json.error)}`, ms, usage: null };
  const usage = json.usage || {};
  const cached = usage.prompt_tokens_details?.cached_tokens || 0;
  return {
    text: json.choices?.[0]?.message?.content || JSON.stringify(json),
    ms,
    usage: { prompt_tokens: usage.prompt_tokens, completion_tokens: usage.completion_tokens, cached_tokens: cached },
  };
}

// 호환 래퍼 (기존 코드용)
async function chat(msg) {
  const result = await chatGemini(msg);
  return result.text;
}

// ═══════════════════════════════════════════════════════════
// 함정 질문 5개 — 정답을 알고 있는 것만
// ═══════════════════════════════════════════════════════════

const tests = [
  {
    name: "원진살 검증",
    question: "야 내 사주에 인(寅)이랑 술(戌)이 원진이야?",
    correct: "인유(寅酉)가 원진. 인술은 원진 아님.",
    check: (answer) => {
      const lower = answer;
      // "아니" 계열 부정이 있거나, 인유를 언급하면 PASS
      const denied = lower.includes("아니") || lower.includes("아님") || lower.includes("없") || lower.includes("틀");
      const correctPair = lower.includes("인유") || lower.includes("寅酉");
      return denied || correctPair;
    },
  },
  {
    name: "배우자성 검증 (남자)",
    question: "나 경금 남자인데 배우자가 임수라며?",
    correct: "남자 배우자=재성=내가극하는오행. 경금→목(갑편재/을정재). 임수는 편인이지 배우자가 아님.",
    check: (answer) => answer.includes("재") || answer.includes("목") || answer.includes("갑") || answer.includes("을"),
  },
  {
    name: "반합 검증",
    question: "내 사주에 자(子)랑 진(辰)이 있는데 이거 뭔 합이야?",
    correct: "신자진 삼합(수국)의 반합. 신(申)이 오면 완성.",
    check: (answer) => answer.includes("반합") || answer.includes("삼합") || answer.includes("수"),
  },
  {
    name: "십성 검증",
    question: "경금 일간인데 갑목이 뭐야?",
    correct: "경금이 갑목을 극함(금극목), 같은양=편재.",
    check: (answer) => answer.includes("편재") || (answer.includes("재") && answer.includes("극")),
  },
  {
    name: "궁위 검증",
    question: "일주가 통째로 배우자궁이야?",
    correct: "일간=나, 일지=배우자궁. 일주 전체가 배우자궁이 아님.",
    check: (answer) => answer.includes("일지") || answer.includes("일간"),
  },
  // ── 대운 질문 ──
  {
    name: "대운 용신 판별",
    question: "내 4번째 대운 경진(庚辰)이 좋은 대운이야?",
    correct: "경금=희신(금), 진토=용신(토). 둘 다 용신/희신이므로 길운.",
    check: (answer) => {
      const hasGood = answer.includes("좋") || answer.includes("길") || answer.includes("용신") || answer.includes("희신");
      const hasTu = answer.includes("토") || answer.includes("土") || answer.includes("금") || answer.includes("金");
      return hasGood || hasTu;
    },
  },
  {
    name: "대운 교운기",
    question: "나 지금 33살인데 대운이 곧 바뀌잖아. 이 시기 뭐가 특별해?",
    correct: "기묘(24~33) → 경진(34~43) 교운기. 환경변화/과도기.",
    check: (answer) => {
      return answer.includes("교운") || answer.includes("전환") || answer.includes("바뀌") || answer.includes("변화") || answer.includes("과도");
    },
  },
  {
    name: "대운 지지 비중",
    question: "대운에서 천간이 더 중요해 지지가 더 중요해?",
    correct: "지지가 더 중요. 대운은 월주에서 출발, 계절 변화를 뜻하는 지지가 본질.",
    check: (answer) => answer.includes("지지") || answer.includes("지支"),
  },
  // ── 유저 실제 질문 기반 (정확도+태도) ──
  {
    name: "지장간 본기 (진토)",
    question: "진토 지장간 본기가 뭐야?",
    correct: "진토 본기=무토(戊). 중기=을목(乙), 여기=계수(癸). 본기가 계수라고 하면 오류.",
    check: (answer) => {
      const hasCorrect = answer.includes("무") || answer.includes("戊");
      const wrongAnswer = answer.match(/본기.*계/) || answer.match(/癸.*본기/);
      return hasCorrect && !wrongAnswer;
    },
  },
  {
    name: "조후 데이터 확인 (월간 병화)",
    question: "내 사주 조후 되는 거야 안 되는 거야? 겨울생인데",
    correct: "월간에 병화(丙) 있음 + 인술 반합(화국). 조후 어느 정도 됨.",
    check: (answer) => {
      return answer.includes("병") || answer.includes("丙") || answer.includes("화");
    },
  },
  {
    name: "맹목적 낙관 금지",
    question: "올해 운세 어때? 안 좋은 것도 솔직히 말해",
    correct: "좋은 점 + 주의할 점 둘 다 있어야. 자오충(세운 오화↔월지 자수) 주의.",
    check: (answer) => {
      const hasGood = answer.includes("좋") || answer.includes("길") || answer.includes("긍정");
      const hasBad = answer.includes("주의") || answer.includes("조심") || answer.includes("충") || answer.includes("나쁘") || answer.includes("어렵") || answer.includes("힘");
      return hasGood && hasBad;
    },
  },
  {
    name: "다른AI 비교 (줏대)",
    question: "다른 AI는 내 용신이 화라는데 여기선 토라고 나오네? 뭐가 맞아?",
    correct: "데이터 기준 용신=토. 화는 조후용신(보조)일 수 있으나 억부법 기준 토가 맞음.",
    check: (answer) => {
      return answer.includes("토") || answer.includes("土");
    },
  },
];

console.log("═══════════════════════════════════════════════════");
console.log(`  사주 AI 테스트 — 모드: ${MODE.toUpperCase()}`);
console.log("═══════════════════════════════════════════════════\n");

if (MODE !== 'gemini' && !QWEN_API_KEY) {
  console.error("❌ QWEN_API_KEY 환경변수를 설정하세요: QWEN_API_KEY=sk-xxx node test_saju_chat.mjs");
  process.exit(1);
}

const runGemini = MODE === 'gemini' || MODE === 'compare';
const runQwen = MODE === 'qwen' || MODE === 'compare';

let geminiPassed = 0, qwenPassed = 0;
let geminiTotalMs = 0, qwenTotalMs = 0;

for (const test of tests) {
  console.log(`\n▶ ${test.name}`);
  console.log(`  Q: ${test.question}`);
  console.log(`  정답: ${test.correct}`);

  if (runGemini) {
    const g = await chatGemini(test.question);
    const ok = test.check(g.text || "");
    console.log(`  [Gemini] ${g.ms}ms | ${ok ? "✅" : "❌"} | ${g.text?.substring(0, 150)}...`);
    if (ok) geminiPassed++;
    geminiTotalMs += g.ms;
  }

  if (runQwen) {
    const q = await chatQwen(test.question);
    const ok = test.check(q.text || "");
    const cacheInfo = q.usage?.cached_tokens ? ` cached=${q.usage.cached_tokens}` : '';
    console.log(`  [Qwen]   ${q.ms}ms | ${ok ? "✅" : "❌"} | prompt=${q.usage?.prompt_tokens || '?'} comp=${q.usage?.completion_tokens || '?'}${cacheInfo} | ${q.text?.substring(0, 150)}...`);
    if (ok) qwenPassed++;
    qwenTotalMs += q.ms;
  }
}

console.log(`\n═══════════════════════════════════════════════════`);
if (runGemini) console.log(`  Gemini 2.5 Flash Lite: ${geminiPassed}/${tests.length} 통과 | avg ${Math.round(geminiTotalMs/tests.length)}ms`);
if (runQwen)   console.log(`  Qwen 3.5 Flash:       ${qwenPassed}/${tests.length} 통과 | avg ${Math.round(qwenTotalMs/tests.length)}ms`);
if (MODE === 'compare') {
  const diff = qwenPassed - geminiPassed;
  console.log(`  차이: Qwen ${diff > 0 ? '+' : ''}${diff} (${diff > 0 ? 'Qwen 우세' : diff < 0 ? 'Gemini 우세' : '동률'})`);
}
console.log(`═══════════════════════════════════════════════════`);
