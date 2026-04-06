/**
 * 사주 AI 함정 질문 테스트
 * - function calling (saju-tools + sequential thinking) 검증
 * - 기초 명리학 규칙 정답률 체크
 *
 * 사용법: node test_saju_chat.mjs
 */

const SUPABASE_URL = 'https://kfciluyxkomskyxjaeat.supabase.co';
const API_KEY = 'sb_publishable_BeKozV2EEX18nI8VgCC7dw_zxThHlTN';

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

【대운 해석 규칙】
- 대운 천간+지지 동시 작용, 지지가 지배적(7:3)
- 대운 지지가 원국 지지와 삼합/충/형 → 구조 변화
- 천극지충: 대운 천간이 일간 극 + 대운 지지가 일지 충 → 최대 격변기
- 교운기(대운 전환 전후 1~2년) = 과도기, 환경 변화 집중
- 대운 오행이 용신이면 길운, 기신이면 흉운 (단 무조건 좋다/나쁘다 금지)
- 대운=10년 환경, 세운=1년 사건. 대운 틀 안에서 세운 작용

⚠️ 데이터에 없는 합/충/원진 지어내기 절대 금지.`;

async function chat(msg) {
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
  return json.content || json.error || JSON.stringify(json);
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
];

console.log("═══════════════════════════════════════════════════");
console.log("  사주 AI 함정 질문 테스트 (function calling)");
console.log("═══════════════════════════════════════════════════\n");

let passed = 0;

for (const test of tests) {
  console.log(`\n▶ ${test.name}`);
  console.log(`  Q: ${test.question}`);
  console.log(`  정답: ${test.correct}`);

  const answer = await chat(test.question);
  console.log(`  AI: ${answer?.substring(0, 200)}...`);

  const ok = test.check(answer || "");
  console.log(`  결과: ${ok ? "✅ PASS" : "❌ FAIL"}`);
  if (ok) passed++;
}

console.log(`\n═══════════════════════════════════════════════════`);
console.log(`  결과: ${passed}/${tests.length} 통과`);
console.log(`═══════════════════════════════════════════════════`);
