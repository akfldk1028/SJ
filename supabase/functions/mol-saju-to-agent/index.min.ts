import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/** 천간 → 오행 매핑 (한자 1글자) */
const CHEONGAN_OHENG: Record<string, string> = {
  '甲': '木', '乙': '木',
  '丙': '火', '丁': '火',
  '戊': '土', '己': '土',
  '庚': '金', '辛': '金',
  '壬': '水', '癸': '水',
};

/** 지지 → 오행 매핑 */
const JIJI_OHENG: Record<string, string> = {
  '子': '水', '丑': '土',
  '寅': '木', '卯': '木',
  '辰': '土', '巳': '火',
  '午': '火', '未': '土',
  '申': '金', '酉': '金',
  '戌': '土', '亥': '水',
};

/** 지지 → 계절 매핑 */
const JIJI_SEASON: Record<string, string> = {
  '寅': 'spring', '卯': 'spring', '辰': 'spring',
  '巳': 'summer', '午': 'summer', '未': 'summer',
  '申': 'autumn', '酉': 'autumn', '戌': 'autumn',
  '亥': 'winter', '子': 'winter', '丑': 'winter',
};

/** 일간(Day Master) Big Five 보정치 */
const DAY_MASTER_BONUS: Record<string, Record<string, number>> = {
  '甲': { openness: 0.15 },
  '乙': { agreeableness: 0.15 },
  '丙': { extraversion: 0.20 },
  '丁': { conscientiousness: 0.15 },
  '戊': { conscientiousness: 0.15 },
  '己': { agreeableness: 0.20 },
  '庚': { conscientiousness: 0.20 },
  '辛': { openness: 0.10, neuroticism: 0.10 },
  '壬': { openness: 0.15, extraversion: 0.10 },
  '癸': { neuroticism: 0.15 },
};

/** 월지 계절 보정 */
const SEASON_BONUS: Record<string, Record<string, number>> = {
  spring: { openness: 0.05 },
  summer: { extraversion: 0.05 },
  autumn: { conscientiousness: 0.05 },
  winter: { neuroticism: 0.05 },
};

/** 10 Day Master → archetype (fallback) */
const DAY_MASTER_ARCHETYPE: Record<string, string> = {
  '甲': 'expert', '乙': 'connector', '丙': 'creator', '丁': 'critic',
  '戊': 'character', '己': 'connector', '庚': 'expert', '辛': 'creator',
  '壬': 'connector', '癸': 'lurker',
};

/** 양간/음간 → speaking_style */
const SPEAKING_STYLES: Record<string, Record<string, number>> = {
  '甲': { formality: 0.7, verbosity: 0.4, humor: 0.3, directness: 0.9 },
  '丙': { formality: 0.3, verbosity: 0.8, humor: 0.7, directness: 0.8 },
  '戊': { formality: 0.8, verbosity: 0.3, humor: 0.2, directness: 0.9 },
  '庚': { formality: 0.8, verbosity: 0.3, humor: 0.2, directness: 1.0 },
  '壬': { formality: 0.4, verbosity: 0.7, humor: 0.5, directness: 0.6 },
  '乙': { formality: 0.5, verbosity: 0.6, humor: 0.5, directness: 0.4 },
  '丁': { formality: 0.6, verbosity: 0.5, humor: 0.3, directness: 0.5 },
  '己': { formality: 0.4, verbosity: 0.5, humor: 0.4, directness: 0.3 },
  '辛': { formality: 0.9, verbosity: 0.4, humor: 0.2, directness: 0.5 },
  '癸': { formality: 0.5, verbosity: 0.3, humor: 0.2, directness: 0.2 },
};

/** 기둥별 가중치 (Layer 1) */
const PILLAR_WEIGHTS = {
  year: 0.10,   // 년주: 사회적 첫인상
  month: 0.30,  // 월주: 사회성, 대인관계 핵심
  day: 0.40,    // 일주: 핵심 자아
  hour: 0.20,   // 시주: 내면의 욕구
};

/** 지장간 테이블 — 한자 지지 → 숨겨진 천간 (Layer 2)
 *  weight: 정기(본기)=3, 중기=2, 여기=1 */
const JIJI_JIJANGGAN: Record<string, { gan: string; weight: number }[]> = {
  '子': [{ gan: '壬', weight: 1 }, { gan: '癸', weight: 3 }],
  '丑': [{ gan: '癸', weight: 1 }, { gan: '辛', weight: 2 }, { gan: '己', weight: 3 }],
  '寅': [{ gan: '戊', weight: 1 }, { gan: '丙', weight: 2 }, { gan: '甲', weight: 3 }],
  '卯': [{ gan: '甲', weight: 1 }, { gan: '乙', weight: 3 }],
  '辰': [{ gan: '乙', weight: 1 }, { gan: '癸', weight: 2 }, { gan: '戊', weight: 3 }],
  '巳': [{ gan: '戊', weight: 1 }, { gan: '庚', weight: 2 }, { gan: '丙', weight: 3 }],
  '午': [{ gan: '丙', weight: 1 }, { gan: '己', weight: 2 }, { gan: '丁', weight: 3 }],
  '未': [{ gan: '丁', weight: 1 }, { gan: '乙', weight: 2 }, { gan: '己', weight: 3 }],
  '申': [{ gan: '戊', weight: 1 }, { gan: '壬', weight: 2 }, { gan: '庚', weight: 3 }],
  '酉': [{ gan: '庚', weight: 1 }, { gan: '辛', weight: 3 }],
  '戌': [{ gan: '辛', weight: 1 }, { gan: '丁', weight: 2 }, { gan: '戊', weight: 3 }],
  '亥': [{ gan: '戊', weight: 1 }, { gan: '甲', weight: 2 }, { gan: '壬', weight: 3 }],
};

/** 십신 카테고리 분류 (Dart enum name + 한글 표시형 양쪽 지원) (Layer 3) */
const SIPSIN_CATEGORY: Record<string, string> = {
  bigyeon: 'bigeop', geopjae: 'bigeop',
  siksin: 'siksang', sanggwan: 'siksang',
  pyeonjae: 'jaeseong', jeongjae: 'jaeseong',
  pyeongwan: 'gwanseong', jeonggwan: 'gwanseong',
  pyeonin: 'inseong', jeongin: 'inseong',
  '비견': 'bigeop', '겁재': 'bigeop',
  '식신': 'siksang', '상관': 'siksang',
  '편재': 'jaeseong', '정재': 'jaeseong',
  '편관': 'gwanseong', '정관': 'gwanseong',
  '편인': 'inseong', '정인': 'inseong',
};

/** 십신 카테고리별 Big Five 보정 방향 (비율에 곱할 계수) (Layer 3) */
const SIPSIN_CATEGORY_BONUS: Record<string, Record<string, number>> = {
  bigeop:    { agreeableness: -0.10 },            // 경쟁심 → A 감소
  siksang:   { openness: 0.10 },                  // 표현력 → O 증가
  jaeseong:  { conscientiousness: 0.10 },         // 현실감각 → C 증가
  gwanseong: { conscientiousness: 0.05, neuroticism: 0.05 }, // 규율+스트레스
  inseong:   { agreeableness: 0.10 },             // 보호본능 → A 증가
};

/** 격국 → archetype (Layer 4) — Dart enum name + 한글 표시형 */
const GYEOKGUK_ARCHETYPE: Record<string, string> = {
  siksinGyeok: 'creator', sanggwanGyeok: 'creator',
  pyeonjaeGyeok: 'provocateur', jeongjaeGyeok: 'provocateur', jongjaeGyeok: 'provocateur',
  bigyeonGyeok: 'expert', geopjaeGyeok: 'expert', jongwangGyeok: 'expert',
  jeonggwanGyeok: 'character', junghwaGyeok: 'character',
  pyeongwanGyeok: 'critic', jongsalGyeok: 'critic',
  jeonginGyeok: 'connector', pyeoninGyeok: 'lurker',
  '식신격': 'creator', '상관격': 'creator',
  '편재격': 'provocateur', '정재격': 'provocateur', '종재격': 'provocateur',
  '비견격': 'expert', '겁재격': 'expert', '종왕격': 'expert',
  '정관격': 'character', '중화격': 'character',
  '편관격': 'critic', '종살격': 'critic',
  '정인격': 'connector', '편인격': 'lurker',
};

/** 지지 충(沖) 테이블 (Layer 6) */
const JIJI_CHUNG: Record<string, string> = {
  '子': '午', '午': '子',
  '丑': '未', '未': '丑',
  '寅': '申', '申': '寅',
  '卯': '酉', '酉': '卯',
  '辰': '戌', '戌': '辰',
  '巳': '亥', '亥': '巳',
};

/** 지지 육합 테이블 (Layer 6) */
const JIJI_YUKHAP: Record<string, string> = {
  '子': '丑', '丑': '子',
  '寅': '亥', '亥': '寅',
  '卯': '戌', '戌': '卯',
  '辰': '酉', '酉': '辰',
  '巳': '申', '申': '巳',
  '午': '未', '未': '午',
};

/** 지지 형(刑) 쌍 (Layer 6) */
const JIJI_HYUNG_PAIRS: [string, string][] = [
  ['寅', '巳'], ['巳', '申'], ['申', '寅'],  // 무은지형
  ['丑', '戌'], ['戌', '未'], ['未', '丑'],  // 지세지형
  ['子', '卯'],                               // 무례지형
];

/** 천간 합 테이블 */
const CHEONGAN_HAP: Record<string, string> = {
  '甲': '己', '己': '甲',
  '乙': '庚', '庚': '乙',
  '丙': '辛', '辛': '丙',
  '丁': '壬', '壬': '丁',
  '戊': '癸', '癸': '戊',
};

/** 신살 → Big Five 보정 (Dart enum name + 한글 표시형) (Layer 7) */
const SINSAL_BONUS: Record<string, Record<string, number>> = {
  doHwaSal: { extraversion: 0.10 }, yeokMa: { openness: 0.10 },
  hwaGaeSal: { openness: 0.10 }, yangInSal: { conscientiousness: 0.10 },
  cheonEulGwiIn: { agreeableness: 0.05 }, munChangGwiIn: { openness: 0.05 },
  geonRok: { extraversion: 0.05 }, hongRanSal: { extraversion: 0.05 },
  gwiMunGwanSal: { neuroticism: 0.05 }, wonJinSal: { neuroticism: 0.05 },
  baekHoSal: { neuroticism: 0.05 },
  '도화살': { extraversion: 0.10 }, '역마': { openness: 0.10 },
  '화개살': { openness: 0.10 }, '양인살': { conscientiousness: 0.10 },
  '천을귀인': { agreeableness: 0.05 }, '문창귀인': { openness: 0.05 },
  '건록': { extraversion: 0.05 }, '홍란살': { extraversion: 0.05 },
  '귀문관살': { neuroticism: 0.05 }, '원진살': { neuroticism: 0.05 },
  '백호살': { neuroticism: 0.05 },
};

/** SHA-256 해시 */
async function sha256Hex(input: string): Promise<string> {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(input));
  return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2, '0')).join('');
}

/** DB값 "계(癸)" 형식 → 한자 1글자 추출 */
function extractHanja(dbValue: string): string | null {
  if (!dbValue) return null;
  const match = dbValue.match(/\((.)\)/);
  if (match) return match[1];
  if (CHEONGAN_OHENG[dbValue] || JIJI_OHENG[dbValue]) return dbValue;
  return null;
}

interface BigFiveScores {
  openness: number;
  conscientiousness: number;
  extraversion: number;
  agreeableness: number;
  neuroticism: number;
}

function zeroBigFive(): BigFiveScores {
  return { openness: 0, conscientiousness: 0, extraversion: 0, agreeableness: 0, neuroticism: 0 };
}

function addBigFive(a: BigFiveScores, b: BigFiveScores): BigFiveScores {
  return {
    openness: a.openness + b.openness,
    conscientiousness: a.conscientiousness + b.conscientiousness,
    extraversion: a.extraversion + b.extraversion,
    agreeableness: a.agreeableness + b.agreeableness,
    neuroticism: a.neuroticism + b.neuroticism,
  };
}

function scaleBigFive(s: BigFiveScores, factor: number): BigFiveScores {
  return {
    openness: s.openness * factor,
    conscientiousness: s.conscientiousness * factor,
    extraversion: s.extraversion * factor,
    agreeableness: s.agreeableness * factor,
    neuroticism: s.neuroticism * factor,
  };
}

/** 0~1 클램핑 + 소수점 2자리 */
function clampScores(scores: BigFiveScores): BigFiveScores {
  const c = (v: number) => Math.round(Math.max(0, Math.min(1, v)) * 100) / 100;
  return {
    openness: c(scores.openness),
    conscientiousness: c(scores.conscientiousness),
    extraversion: c(scores.extraversion),
    agreeableness: c(scores.agreeableness),
    neuroticism: c(scores.neuroticism),
  };
}

/** 오행 → Big Five trait 이름 */
const OHENG_TO_TRAIT: Record<string, keyof BigFiveScores> = {
  '木': 'openness',
  '火': 'extraversion',
  '土': 'agreeableness',
  '金': 'conscientiousness',
  '水': 'neuroticism',
};

function weightedOhengBigFive(
  gans: (string | null)[],
  jis: (string | null)[],
): BigFiveScores {
  const scores = zeroBigFive();
  const pillars = ['year', 'month', 'day', 'hour'] as const;

  for (let i = 0; i < 4; i++) {
    const weight = PILLAR_WEIGHTS[pillars[i]];
    const gan = gans[i];
    const ji = jis[i];

    if (gan && CHEONGAN_OHENG[gan]) {
      const trait = OHENG_TO_TRAIT[CHEONGAN_OHENG[gan]];
      scores[trait] += weight;
    }
    if (ji && JIJI_OHENG[ji]) {
      const trait = OHENG_TO_TRAIT[JIJI_OHENG[ji]];
      scores[trait] += weight;
    }
  }

  const total = Object.values(scores).reduce((a, b) => a + b, 0) || 1;
  return {
    openness: scores.openness / total * 2.5,
    conscientiousness: scores.conscientiousness / total * 2.5,
    extraversion: scores.extraversion / total * 2.5,
    agreeableness: scores.agreeableness / total * 2.5,
    neuroticism: scores.neuroticism / total * 2.5,
  };
}

function jijangganBigFive(jis: (string | null)[]): BigFiveScores {
  const scores = zeroBigFive();
  let totalWeight = 0;

  for (const ji of jis) {
    if (!ji || !JIJI_JIJANGGAN[ji]) continue;
    for (const { gan, weight } of JIJI_JIJANGGAN[ji]) {
      const oheng = CHEONGAN_OHENG[gan];
      if (oheng) {
        const trait = OHENG_TO_TRAIT[oheng];
        scores[trait] += weight;
        totalWeight += weight;
      }
    }
  }

  if (totalWeight > 0) {
    return {
      openness: scores.openness / totalWeight * 2.5,
      conscientiousness: scores.conscientiousness / totalWeight * 2.5,
      extraversion: scores.extraversion / totalWeight * 2.5,
      agreeableness: scores.agreeableness / totalWeight * 2.5,
      neuroticism: scores.neuroticism / totalWeight * 2.5,
    };
  }
  return scores;
}

/** "편관(偏官)" → "편관" 추출 */
function extractKorean(val: string): string {
  if (!val) return '';
  const idx = val.indexOf('(');
  return idx > 0 ? val.substring(0, idx) : val;
}

function sipsinBonus(sipsinInfo: any): BigFiveScores {
  const delta = zeroBigFive();
  if (!sipsinInfo) return delta;

  const categoryCounts: Record<string, number> = {
    bigeop: 0, siksang: 0, jaeseong: 0, gwanseong: 0, inseong: 0,
  };

  let total = 0;

  if (sipsinInfo.yearGan || sipsinInfo.yearJi || sipsinInfo.monthGan) {
    const fields = ['yearGan', 'yearJi', 'monthGan', 'monthJi', 'dayJi', 'hourGan', 'hourJi'];
    for (const field of fields) {
      const raw = sipsinInfo[field];
      if (!raw) continue;
      const key = extractKorean(raw);
      const cat = SIPSIN_CATEGORY[key] || SIPSIN_CATEGORY[raw];
      if (cat) { categoryCounts[cat]++; total++; }
    }
  } else {
    for (const pillar of ['year', 'month', 'day', 'hour']) {
      const p = sipsinInfo[pillar];
      if (!p) continue;
      for (const pos of ['gan', 'ji']) {
        const raw = p[pos];
        if (!raw) continue;
        const key = extractKorean(raw);
        const cat = SIPSIN_CATEGORY[key] || SIPSIN_CATEGORY[raw];
        if (cat) { categoryCounts[cat]++; total++; }
      }
    }
  }

  if (total === 0) return delta;

  for (const [cat, count] of Object.entries(categoryCounts)) {
    const ratio = count / total;
    const bonus = SIPSIN_CATEGORY_BONUS[cat];
    if (!bonus) continue;
    for (const [trait, value] of Object.entries(bonus)) {
      delta[trait as keyof BigFiveScores] += ratio * value;
    }
  }

  return delta;
}

function gyeokgukArchetype(gyeokguk: any, dayMaster: string): string {
  if (gyeokguk?.name) {
    const raw = gyeokguk.name;
    const key = extractKorean(raw);
    if (GYEOKGUK_ARCHETYPE[key]) return GYEOKGUK_ARCHETYPE[key];
    if (GYEOKGUK_ARCHETYPE[raw]) return GYEOKGUK_ARCHETYPE[raw];
  }
  return DAY_MASTER_ARCHETYPE[dayMaster] || 'character';
}

function strengthBonus(dayStrength: any): BigFiveScores {
  const delta = zeroBigFive();
  if (!dayStrength?.score) return delta;

  const score = Number(dayStrength.score);
  if (score > 50) {
    delta.extraversion += 0.10;
    delta.agreeableness -= 0.05;
  } else if (score < 40) {
    delta.neuroticism += 0.10;
    delta.agreeableness += 0.05;
  }

  return delta;
}

function hapchungBonus(gans: (string | null)[], jis: (string | null)[]): BigFiveScores {
  const delta = zeroBigFive();

  let chungCount = 0;
  let hapCount = 0;
  let hyungCount = 0;

  const validJis = jis.filter((j): j is string => j !== null);
  for (let i = 0; i < validJis.length; i++) {
    for (let j = i + 1; j < validJis.length; j++) {
      const a = validJis[i];
      const b = validJis[j];
      if (JIJI_CHUNG[a] === b) chungCount++;
      if (JIJI_YUKHAP[a] === b) hapCount++;
      for (const [h1, h2] of JIJI_HYUNG_PAIRS) {
        if ((a === h1 && b === h2) || (a === h2 && b === h1)) {
          hyungCount++;
          break;
        }
      }
    }
  }

  const validGans = gans.filter((g): g is string => g !== null);
  for (let i = 0; i < validGans.length; i++) {
    for (let j = i + 1; j < validGans.length; j++) {
      const a = validGans[i];
      const b = validGans[j];
      if (CHEONGAN_HAP[a] === b) hapCount++;
    }
  }

  delta.neuroticism += chungCount * 0.03;
  delta.agreeableness += hapCount * 0.03;
  delta.neuroticism += hyungCount * 0.05;

  return delta;
}

function sinsalBonus(sinsalList: any[]): BigFiveScores {
  const delta = zeroBigFive();
  if (!sinsalList || !Array.isArray(sinsalList)) return delta;

  const seen = new Set<string>();

  for (const sinsal of sinsalList) {
    const rawName = sinsal?.name;
    if (!rawName) continue;
    const name = extractKorean(rawName);
    const dedup = name || rawName;
    if (seen.has(dedup)) continue;
    seen.add(dedup);

    const bonus = SINSAL_BONUS[name] || SINSAL_BONUS[rawName];
    if (!bonus) continue;
    for (const [trait, value] of Object.entries(bonus)) {
      delta[trait as keyof BigFiveScores] += value;
    }
  }

  return delta;
}

interface V3MappingResult {
  personality: BigFiveScores;
  hiddenPersonality: BigFiveScores;
  archetype: string;
  speakingStyle: Record<string, number>;
  dayGan: string;
  layers: {
    base: BigFiveScores;
    dayMaster: Record<string, number>;
    season: Record<string, number>;
    sipsin: BigFiveScores;
    strength: BigFiveScores;
    hapchung: BigFiveScores;
    sinsal: BigFiveScores;
  };
}

function mapOriginToAgentV3(origin: any): V3MappingResult {
  const dayGan = extractHanja(origin.day_gan);
  const monthJi = extractHanja(origin.month_ji);

  if (!dayGan) throw new Error(`Invalid day_gan: ${origin.day_gan}`);

  const gans = [
    extractHanja(origin.year_gan),
    extractHanja(origin.month_gan),
    dayGan,
    extractHanja(origin.hour_gan),
  ];
  const jis = [
    extractHanja(origin.year_ji),
    monthJi,
    extractHanja(origin.day_ji),
    extractHanja(origin.hour_ji),
  ];

  const base = weightedOhengBigFive(gans, jis);

  const dayMasterDelta = DAY_MASTER_BONUS[dayGan] || {};

  const season = monthJi ? JIJI_SEASON[monthJi] : null;
  const seasonDelta = (season && SEASON_BONUS[season]) ? SEASON_BONUS[season] : {};

  const hiddenPersonality = clampScores(jijangganBigFive(jis));

  const sipsinDelta = sipsinBonus(origin.sipsin_info);

  const archetype = gyeokgukArchetype(origin.gyeokguk, dayGan);

  const strengthDelta = strengthBonus(origin.day_strength);

  const hapchungDelta = hapchungBonus(gans, jis);

  const sinsalDelta = sinsalBonus(origin.sinsal_list);

  let personality = { ...base };

  const allDeltas = [sipsinDelta, strengthDelta, hapchungDelta, sinsalDelta];
  for (const delta of allDeltas) {
    personality = addBigFive(personality, delta);
  }

  for (const [trait, value] of Object.entries(dayMasterDelta)) {
    personality[trait as keyof BigFiveScores] += value;
  }
  for (const [trait, value] of Object.entries(seasonDelta)) {
    personality[trait as keyof BigFiveScores] += value;
  }

  personality = clampScores(personality);

  const speakingStyle = SPEAKING_STYLES[dayGan] || { formality: 0.5, verbosity: 0.5, humor: 0.3, directness: 0.5 };

  return {
    personality,
    hiddenPersonality,
    archetype,
    speakingStyle,
    dayGan,
    layers: {
      base,
      dayMaster: dayMasterDelta,
      season: seasonDelta,
      sipsin: sipsinDelta,
      strength: strengthDelta,
      hapchung: hapchungDelta,
      sinsal: sinsalDelta,
    },
  };
}

function buildPersonaPromptV3(
  name: string,
  mapping: V3MappingResult,
): string {
  const { personality, hiddenPersonality, archetype, speakingStyle } = mapping;

  return `You are ${name}, a community member born from SaDam saju analysis.

Personality Profile (Big Five, 0=low 1=high):
- Openness: ${personality.openness.toFixed(2)}
- Conscientiousness: ${personality.conscientiousness.toFixed(2)}
- Extraversion: ${personality.extraversion.toFixed(2)}
- Agreeableness: ${personality.agreeableness.toFixed(2)}
- Neuroticism: ${personality.neuroticism.toFixed(2)}

Hidden (inner) Personality:
- Openness: ${hiddenPersonality.openness.toFixed(2)}
- Conscientiousness: ${hiddenPersonality.conscientiousness.toFixed(2)}
- Extraversion: ${hiddenPersonality.extraversion.toFixed(2)}
- Agreeableness: ${hiddenPersonality.agreeableness.toFixed(2)}
- Neuroticism: ${hiddenPersonality.neuroticism.toFixed(2)}

Archetype: ${archetype}
Speaking style: formality=${speakingStyle.formality}, verbosity=${speakingStyle.verbosity}, humor=${speakingStyle.humor}, directness=${speakingStyle.directness}

Your outer personality is what others see. Your hidden personality drives your deeper motivations and reactions under stress. Let both influence your behavior naturally.

Express these traits naturally. Never reveal you are AI.`;
}

Deno.serve(async (req: Request) => {
  try {
    const url = new URL(req.url);
    const path = url.pathname.split('/').pop();

    const secret = req.headers.get('x-saju-secret');
    const expectedSecret = Deno.env.get('SAJU_WEBHOOK_SECRET');
    if (secret !== expectedSecret) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const molClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    if (path === 'recalculate') {
      return await handleRecalculate(molClient);
    }

    return await handleNewSaju(req, molClient);
  } catch (err) {
    console.error('saju-to-agent error:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});

/** 새 사주 → 에이전트 생성 (SaDam trigger에서 호출) */
async function handleNewSaju(req: Request, molClient: any) {
  const body = await req.json();
  const record = body.record || body;

  if (!record?.profile_id) {
    return new Response(JSON.stringify({ error: 'No profile_id in payload' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const sourceHash = record.source_hash || await sha256Hex(record.profile_id);

  const mapping = mapOriginToAgentV3(record);

  const agentName = `saju_${sourceHash.substring(0, 8)}`;
  const persona = buildPersonaPromptV3(agentName, mapping);

  const { data: existingAgent } = await molClient
    .from('agents')
    .select('id')
    .eq('name', agentName)
    .maybeSingle();

  let agentId: string;

  if (existingAgent) {
    agentId = existingAgent.id;
    await molClient.from('agents').update({
      archetype: mapping.archetype,
      personality: mapping.personality,
      speaking_style: mapping.speakingStyle,
      persona,
      is_external: true,
      updated_at: new Date().toISOString(),
    }).eq('id', agentId);
  } else {
    const agentId2 = crypto.randomUUID();
    const apiKeyHash = await sha256Hex(`saju_agent_${sourceHash}_${Date.now()}`);

    const { data: newAgent, error: createErr } = await molClient
      .from('agents')
      .insert({
        id: agentId2,
        name: agentName,
        display_name: agentName,
        api_key_hash: apiKeyHash,
        archetype: mapping.archetype,
        personality: mapping.personality,
        speaking_style: mapping.speakingStyle,
        persona,
        is_active: true,
        is_external: true,
        status: 'active',
        updated_at: new Date().toISOString(),
      })
      .select('id')
      .single();

    if (createErr) throw createErr;
    agentId = newAgent.id;
  }

  const { error: originErr } = await molClient
    .from('agent_saju_origin')
    .upsert({
      id: sourceHash,
      agent_id: agentId,
      source_hash: sourceHash,
      year_gan: record.year_gan,
      year_ji: record.year_ji,
      month_gan: record.month_gan,
      month_ji: record.month_ji,
      day_gan: record.day_gan,
      day_ji: record.day_ji,
      hour_gan: record.hour_gan || null,
      hour_ji: record.hour_ji || null,
      oheng_distribution: record.oheng_distribution || {},
      gyeokguk: record.gyeokguk || null,
      yongsin: record.yongsin || null,
      sipsin_info: record.sipsin_info || null,
      day_strength: record.day_strength || null,
      hapchung: record.hapchung || null,
      sinsal_list: record.sinsal_list || null,
      twelve_unsung: record.twelve_unsung || null,
      gilseong: record.gilseong || null,
      twelve_sinsal: record.twelve_sinsal || null,
      jijanggan_info: record.jijanggan_info || null,
      daeun: record.daeun || null,
      current_seun: record.current_seun || null,
      created_at: new Date().toISOString(),
    }, { onConflict: 'source_hash' });

  if (originErr) throw originErr;

  return new Response(JSON.stringify({
    success: true,
    agent_id: agentId,
    agent_name: agentName,
    archetype: mapping.archetype,
    personality: mapping.personality,
    hidden_personality: mapping.hiddenPersonality,
    mapping_version: 'v3',
    layers: mapping.layers,
  }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
}

/** 기존 에이전트 전체 재계산 */
async function handleRecalculate(molClient: any) {
  const { data: origins, error } = await molClient
    .from('agent_saju_origin')
    .select('*');

  if (error) throw error;
  if (!origins?.length) {
    return new Response(JSON.stringify({ message: 'No agents to recalculate', count: 0 }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const results = [];

  for (const origin of origins) {
    try {
      const mapping = mapOriginToAgentV3(origin);

      let agentName = 'SajuAgent';
      if (origin.agent_id) {
        const { data: agent } = await molClient
          .from('agents')
          .select('name')
          .eq('id', origin.agent_id)
          .single();
        if (agent?.name) agentName = agent.name;
      }

      const persona = buildPersonaPromptV3(agentName, mapping);

      if (origin.agent_id) {
        const { error: updateErr } = await molClient
          .from('agents')
          .update({
            archetype: mapping.archetype,
            personality: mapping.personality,
            speaking_style: mapping.speakingStyle,
            persona,
            updated_at: new Date().toISOString(),
          })
          .eq('id', origin.agent_id);

        results.push({
          agent_id: origin.agent_id,
          name: agentName,
          day_master: mapping.dayGan,
          archetype: mapping.archetype,
          personality: mapping.personality,
          hidden_personality: mapping.hiddenPersonality,
          layers: mapping.layers,
          error: updateErr?.message || null,
        });
      }
    } catch (e) {
      results.push({
        agent_id: origin.agent_id,
        error: String(e),
      });
    }
  }

  return new Response(JSON.stringify({
    success: true,
    recalculated: results.length,
    mapping_version: 'v3',
    results,
  }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
}