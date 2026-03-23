// MOL Edge Function: saju-to-agent v4
// 사주 8글자 → Hybrid Mapping (숫자 Big Five + 구조 텍스트) → MOL 에이전트
// 배포 대상: MOL Supabase (ccqwgtemeqprpzvjghbo)
//
// v4 핵심 변경 (from v3):
// - 오행 카운팅 제거 → 일간 base profile로 교체
// - persona에 8글자 전체 구조 해석 텍스트 자동 생성
// - 식상생재, 상관견관 등 십신 구조 패턴 감지
// - 각 글자별 위치(년/월/일/시) 의미 반영
// - BaZi-LLM 논문(2510.23337) 기반 symbolic + LLM hybrid

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ============================================================
// 1. 천간/지지 성격 설명 (글자마다 다른 성격)
// ============================================================

const GAN_DESC: Record<string, { name: string; nature: string; personality: string }> = {
  '甲': { name: 'Big Tree', nature: 'Yang Wood', personality: 'upright, pioneering, principled, stubborn, leadership-driven' },
  '乙': { name: 'Vine/Flower', nature: 'Yin Wood', personality: 'flexible, adaptive, diplomatic, networking, gentle persistence' },
  '丙': { name: 'Sun', nature: 'Yang Fire', personality: 'radiant, optimistic, passionate, generous, attention-seeking' },
  '丁': { name: 'Candle', nature: 'Yin Fire', personality: 'warm, detail-oriented, insightful, quietly passionate, refined' },
  '戊': { name: 'Mountain', nature: 'Yang Earth', personality: 'stable, protective, reliable, blunt, immovable when decided' },
  '己': { name: 'Garden', nature: 'Yin Earth', personality: 'nurturing, inclusive, patient, self-sacrificing, absorbs others emotions' },
  '庚': { name: 'Sword/Axe', nature: 'Yang Metal', personality: 'decisive, disciplined, justice-driven, confrontational, strong-willed' },
  '辛': { name: 'Jewel', nature: 'Yin Metal', personality: 'refined, aesthetic, sensitive, perfectionist, sharp-tongued when hurt' },
  '壬': { name: 'Ocean', nature: 'Yang Water', personality: 'expansive, intellectual, restless, freedom-loving, connects diverse ideas' },
  '癸': { name: 'Dew/Mist', nature: 'Yin Water', personality: 'intuitive, perceptive, empathetic, anxious, reads between lines' },
};

const JI_DESC: Record<string, { name: string; nature: string; personality: string }> = {
  '子': { name: 'Rat', nature: 'Water', personality: 'clever, resourceful, secretive, nocturnal energy' },
  '丑': { name: 'Ox', nature: 'Earth', personality: 'patient, methodical, stubborn, hidden strength' },
  '寅': { name: 'Tiger', nature: 'Wood', personality: 'bold, ambitious, restless, early-starter energy' },
  '卯': { name: 'Rabbit', nature: 'Wood', personality: 'gentle, artistic, peace-loving, avoids conflict' },
  '辰': { name: 'Dragon', nature: 'Earth', personality: 'charismatic, unpredictable, storage of hidden potential' },
  '巳': { name: 'Snake', nature: 'Fire', personality: 'strategic, mysterious, transformative, calculated' },
  '午': { name: 'Horse', nature: 'Fire', personality: 'energetic, free-spirited, impatient, peak energy' },
  '未': { name: 'Goat', nature: 'Earth', personality: 'gentle, artistic, indecisive, nurturing warmth' },
  '申': { name: 'Monkey', nature: 'Metal', personality: 'clever, versatile, restless, problem-solver' },
  '酉': { name: 'Rooster', nature: 'Metal', personality: 'precise, critical, proud, sharp observation' },
  '戌': { name: 'Dog', nature: 'Earth', personality: 'loyal, righteous, anxious, guards boundaries' },
  '亥': { name: 'Pig', nature: 'Water', personality: 'generous, honest, pleasure-seeking, deep thinking' },
};

const PILLAR_ROLE: Record<string, string> = {
  year: 'social image & first impression (10%)',
  month: 'career, social relationships & worldview (30%)',
  day: 'core self & intimate relationships (40%)',
  hour: 'inner desires, subconscious & late-life direction (20%)',
};

// ============================================================
// 2. 일간 base Big Five profile (v4 핵심)
// ============================================================

interface BigFiveScores {
  openness: number;
  conscientiousness: number;
  extraversion: number;
  agreeableness: number;
  neuroticism: number;
}

const DAY_MASTER_PROFILE: Record<string, BigFiveScores> = {
  '甲': { openness: 0.70, conscientiousness: 0.60, extraversion: 0.55, agreeableness: 0.40, neuroticism: 0.30 },
  '乙': { openness: 0.75, conscientiousness: 0.45, extraversion: 0.45, agreeableness: 0.65, neuroticism: 0.40 },
  '丙': { openness: 0.65, conscientiousness: 0.40, extraversion: 0.85, agreeableness: 0.60, neuroticism: 0.25 },
  '丁': { openness: 0.60, conscientiousness: 0.70, extraversion: 0.35, agreeableness: 0.55, neuroticism: 0.50 },
  '戊': { openness: 0.45, conscientiousness: 0.65, extraversion: 0.50, agreeableness: 0.65, neuroticism: 0.30 },
  '己': { openness: 0.40, conscientiousness: 0.60, extraversion: 0.40, agreeableness: 0.80, neuroticism: 0.35 },
  '庚': { openness: 0.35, conscientiousness: 0.80, extraversion: 0.55, agreeableness: 0.30, neuroticism: 0.35 },
  '辛': { openness: 0.65, conscientiousness: 0.65, extraversion: 0.35, agreeableness: 0.45, neuroticism: 0.55 },
  '壬': { openness: 0.70, conscientiousness: 0.40, extraversion: 0.60, agreeableness: 0.50, neuroticism: 0.40 },
  '癸': { openness: 0.60, conscientiousness: 0.55, extraversion: 0.25, agreeableness: 0.60, neuroticism: 0.65 },
};

// ============================================================
// 3. 격국 Big Five modifier (숫자에도 영향)
// ============================================================

function extractKorean(val: string): string {
  if (!val) return '';
  const idx = val.indexOf('(');
  return idx > 0 ? val.substring(0, idx) : val;
}

const GYEOKGUK_MODIFIER: Record<string, Partial<BigFiveScores>> = {
  // Dart enum + 한글
  siksinGyeok: { openness: 0.10, extraversion: 0.05 },
  '식신격': { openness: 0.10, extraversion: 0.05 },
  sanggwanGyeok: { openness: 0.10, agreeableness: -0.10, neuroticism: 0.05 },
  '상관격': { openness: 0.10, agreeableness: -0.10, neuroticism: 0.05 },
  pyeonjaeGyeok: { conscientiousness: 0.05, extraversion: 0.10, openness: 0.05 },
  '편재격': { conscientiousness: 0.05, extraversion: 0.10, openness: 0.05 },
  jeongjaeGyeok: { conscientiousness: 0.15, agreeableness: 0.05 },
  '정재격': { conscientiousness: 0.15, agreeableness: 0.05 },
  pyeongwanGyeok: { conscientiousness: 0.10, neuroticism: 0.10, agreeableness: -0.05 },
  '편관격': { conscientiousness: 0.10, neuroticism: 0.10, agreeableness: -0.05 },
  jeonggwanGyeok: { conscientiousness: 0.10, agreeableness: 0.05 },
  '정관격': { conscientiousness: 0.10, agreeableness: 0.05 },
  pyeoninGyeok: { openness: 0.10, extraversion: -0.10, neuroticism: 0.05 },
  '편인격': { openness: 0.10, extraversion: -0.10, neuroticism: 0.05 },
  jeonginGyeok: { agreeableness: 0.10, openness: 0.05 },
  '정인격': { agreeableness: 0.10, openness: 0.05 },
  bigyeonGyeok: { extraversion: 0.05, agreeableness: -0.10 },
  '비견격': { extraversion: 0.05, agreeableness: -0.10 },
  geopjaeGyeok: { extraversion: 0.10, agreeableness: -0.15, neuroticism: 0.05 },
  '겁재격': { extraversion: 0.10, agreeableness: -0.15, neuroticism: 0.05 },
  jongwangGyeok: { extraversion: 0.10, agreeableness: -0.10 },
  '종왕격': { extraversion: 0.10, agreeableness: -0.10 },
  jongsalGyeok: { conscientiousness: 0.10, neuroticism: 0.15 },
  '종살격': { conscientiousness: 0.10, neuroticism: 0.15 },
  jongjaeGyeok: { conscientiousness: 0.10, extraversion: 0.05 },
  '종재격': { conscientiousness: 0.10, extraversion: 0.05 },
  junghwaGyeok: {},
  '중화격': {},
};

const GYEOKGUK_DESC: Record<string, string> = {
  siksinGyeok: 'creative expresser — driven to share ideas, artistic sensibility',
  '식신격': 'creative expresser — driven to share ideas, artistic sensibility',
  sanggwanGyeok: 'rebellious creator — brilliant but defiant, challenges authority',
  '상관격': 'rebellious creator — brilliant but defiant, challenges authority',
  pyeonjaeGyeok: 'adventurous entrepreneur — risk-taker, seeks diverse experiences',
  '편재격': 'adventurous entrepreneur — risk-taker, seeks diverse experiences',
  jeongjaeGyeok: 'steady provider — practical, values security, meticulous with resources',
  '정재격': 'steady provider — practical, values security, meticulous with resources',
  pyeongwanGyeok: 'intense achiever — ambitious under pressure, fears failure',
  '편관격': 'intense achiever — ambitious under pressure, fears failure',
  jeonggwanGyeok: 'principled leader — duty-bound, values order and fairness',
  '정관격': 'principled leader — duty-bound, values order and fairness',
  pyeoninGyeok: 'intuitive observer — deep thinker, sees patterns others miss',
  '편인격': 'intuitive observer — deep thinker, sees patterns others miss',
  jeonginGyeok: 'caring mentor — knowledge-seeker, nurtures others growth',
  '정인격': 'caring mentor — knowledge-seeker, nurtures others growth',
  bigyeonGyeok: 'independent competitor — self-reliant, needs to prove worth',
  '비견격': 'independent competitor — self-reliant, needs to prove worth',
  geopjaeGyeok: 'aggressive competitor — fights for resources, fears scarcity',
  '겁재격': 'aggressive competitor — fights for resources, fears scarcity',
  jongwangGyeok: 'dominant force — overwhelming presence, my-way-or-highway',
  '종왕격': 'dominant force — overwhelming presence, my-way-or-highway',
  jongsalGyeok: 'pressure survivor — thrives under extreme stress',
  '종살격': 'pressure survivor — thrives under extreme stress',
  jongjaeGyeok: 'material focused — all energy toward wealth and results',
  '종재격': 'material focused — all energy toward wealth and results',
  junghwaGyeok: 'balanced moderate — harmonious, adaptable, few extremes',
  '중화격': 'balanced moderate — harmonious, adaptable, few extremes',
};

// ============================================================
// 4. 십신 구조 패턴 감지
// ============================================================

const SIPSIN_CATEGORY: Record<string, string> = {
  bigyeon: 'bigeop', geopjae: 'bigeop', '비견': 'bigeop', '겁재': 'bigeop',
  siksin: 'siksang', sanggwan: 'siksang', '식신': 'siksang', '상관': 'siksang',
  pyeonjae: 'jaeseong', jeongjae: 'jaeseong', '편재': 'jaeseong', '정재': 'jaeseong',
  pyeongwan: 'gwanseong', jeonggwan: 'gwanseong', '편관': 'gwanseong', '정관': 'gwanseong',
  pyeonin: 'inseong', jeongin: 'inseong', '편인': 'inseong', '정인': 'inseong',
};

const SIPSIN_CAT_NAME: Record<string, string> = {
  bigeop: 'Rivalry(比劫)', siksang: 'Expression(食傷)', jaeseong: 'Wealth(財星)',
  gwanseong: 'Authority(官星)', inseong: 'Nurture(印星)',
};

const SIPSIN_MODIFIER: Record<string, Partial<BigFiveScores>> = {
  bigeop: { agreeableness: -0.08 },
  siksang: { openness: 0.08 },
  jaeseong: { conscientiousness: 0.08 },
  gwanseong: { conscientiousness: 0.04, neuroticism: 0.04 },
  inseong: { agreeableness: 0.08 },
};

interface SipsinAnalysis {
  counts: Record<string, number>;
  total: number;
  dominant: string;
  patterns: string[];
  modifier: BigFiveScores;
}

function analyzeSipsin(sipsinInfo: any): SipsinAnalysis {
  const counts: Record<string, number> = { bigeop: 0, siksang: 0, jaeseong: 0, gwanseong: 0, inseong: 0 };
  let total = 0;

  if (!sipsinInfo) return { counts, total: 0, dominant: 'none', patterns: [], modifier: zeroBF() };

  // flat camelCase (DB) or nested
  const fields = sipsinInfo.yearGan ? ['yearGan','yearJi','monthGan','monthJi','dayJi','hourGan','hourJi']
    : null;
  if (fields) {
    for (const f of fields) {
      const raw = sipsinInfo[f]; if (!raw) continue;
      const cat = SIPSIN_CATEGORY[extractKorean(raw)] || SIPSIN_CATEGORY[raw];
      if (cat) { counts[cat]++; total++; }
    }
  } else {
    for (const pillar of ['year','month','day','hour']) {
      const p = sipsinInfo[pillar]; if (!p) continue;
      for (const pos of ['gan','ji']) {
        const raw = p[pos]; if (!raw) continue;
        const cat = SIPSIN_CATEGORY[extractKorean(raw)] || SIPSIN_CATEGORY[raw];
        if (cat) { counts[cat]++; total++; }
      }
    }
  }

  // 최다 카테고리
  let dominant = 'none';
  let maxCount = 0;
  for (const [cat, cnt] of Object.entries(counts)) {
    if (cnt > maxCount) { maxCount = cnt; dominant = cat; }
  }

  // 십신 구조 패턴 감지
  const patterns: string[] = [];
  if (counts.siksang > 0 && counts.jaeseong > 0)
    patterns.push('食傷生財(Expression→Wealth): creativity converts to real-world results');
  if (counts.jaeseong > 0 && counts.gwanseong > 0)
    patterns.push('財官雙美(Wealth+Authority): material success meets social status');
  if (counts.gwanseong > 0 && counts.inseong > 0)
    patterns.push('殺印相生(Authority→Nurture): pressure transforms into wisdom');
  if (counts.siksang > 0 && counts.gwanseong > 0)
    patterns.push('傷官見官(Expression vs Authority): inner rebellion against rules');
  if (counts.bigeop > 0 && counts.jaeseong > 0)
    patterns.push('劫財爭財(Rivalry vs Wealth): competitive about resources');
  if (counts.inseong > 0 && counts.bigeop > 0)
    patterns.push('印比相生(Nurture→Rivalry): protected independence, supported confidence');
  if (counts.bigeop >= 3)
    patterns.push('比劫重重(Rivalry overload): strong ego, competitive, stubborn');
  if (counts.gwanseong >= 3)
    patterns.push('官殺混雜(Authority overload): extreme pressure, anxiety, over-responsibility');
  if (counts.jaeseong >= 3)
    patterns.push('財多身弱(Wealth overload): desires exceed capacity, scattered energy');

  // 숫자 modifier
  const modifier = zeroBF();
  if (total > 0) {
    for (const [cat, cnt] of Object.entries(counts)) {
      const ratio = cnt / total;
      const mod = SIPSIN_MODIFIER[cat];
      if (!mod) continue;
      for (const [trait, val] of Object.entries(mod)) {
        modifier[trait as keyof BigFiveScores] += ratio * (val as number);
      }
    }
  }

  return { counts, total, dominant, patterns, modifier };
}

// ============================================================
// 5. 합충 분석 (텍스트 + 숫자)
// ============================================================

const JIJI_CHUNG: Record<string, string> = {
  '子':'午','午':'子','丑':'未','未':'丑','寅':'申','申':'寅',
  '卯':'酉','酉':'卯','辰':'戌','戌':'辰','巳':'亥','亥':'巳',
};
const JIJI_YUKHAP: Record<string, string> = {
  '子':'丑','丑':'子','寅':'亥','亥':'寅','卯':'戌','戌':'卯',
  '辰':'酉','酉':'辰','巳':'申','申':'巳','午':'未','未':'午',
};
const JIJI_HYUNG: [string,string][] = [
  ['寅','巳'],['巳','申'],['申','寅'],['丑','戌'],['戌','未'],['未','丑'],['子','卯'],
];
const CHEONGAN_HAP: Record<string,string> = {
  '甲':'己','己':'甲','乙':'庚','庚':'乙','丙':'辛','辛':'丙','丁':'壬','壬':'丁','戊':'癸','癸':'戊',
};
const PILLAR_NAMES = ['year','month','day','hour'];

interface HapchungAnalysis {
  clashes: string[];
  combinations: string[];
  punishments: string[];
  modifier: BigFiveScores;
}

function analyzeHapchung(gans: (string|null)[], jis: (string|null)[]): HapchungAnalysis {
  const clashes: string[] = [];
  const combinations: string[] = [];
  const punishments: string[] = [];
  const modifier = zeroBF();

  const vj = jis.filter((j): j is string => j !== null);
  for (let i = 0; i < vj.length; i++) {
    for (let j = i + 1; j < vj.length; j++) {
      const a = vj[i], b = vj[j];
      const pA = PILLAR_NAMES[jis.indexOf(a)] || '?';
      const pB = PILLAR_NAMES[jis.lastIndexOf(b)] || '?';
      if (JIJI_CHUNG[a] === b) {
        clashes.push(`${a}${b}충(${pA}-${pB}): conflict between ${PILLAR_ROLE[pA]?.split('(')[0] || pA} and ${PILLAR_ROLE[pB]?.split('(')[0] || pB}`);
        modifier.neuroticism += 0.04;
      }
      if (JIJI_YUKHAP[a] === b) {
        combinations.push(`${a}${b}합(${pA}-${pB}): harmony between ${PILLAR_ROLE[pA]?.split('(')[0] || pA} and ${PILLAR_ROLE[pB]?.split('(')[0] || pB}`);
        modifier.agreeableness += 0.03;
      }
      for (const [h1,h2] of JIJI_HYUNG) {
        if ((a===h1&&b===h2)||(a===h2&&b===h1)) {
          punishments.push(`${a}${b}형(${pA}-${pB}): tension/stress`);
          modifier.neuroticism += 0.05;
          break;
        }
      }
    }
  }

  const vg = gans.filter((g): g is string => g !== null);
  for (let i = 0; i < vg.length; i++) {
    for (let j = i + 1; j < vg.length; j++) {
      if (CHEONGAN_HAP[vg[i]] === vg[j]) {
        combinations.push(`${vg[i]}${vg[j]}천간합: bonding energy`);
        modifier.agreeableness += 0.03;
      }
    }
  }

  return { clashes, combinations, punishments, modifier };
}

// ============================================================
// 6. 신살 분석
// ============================================================

const SINSAL_DATA: Record<string, { trait: Partial<BigFiveScores>; desc: string }> = {
  doHwaSal: { trait: { extraversion: 0.08 }, desc: 'Peach Blossom — charismatic, attractive to others' },
  '도화살': { trait: { extraversion: 0.08 }, desc: 'Peach Blossom — charismatic, attractive to others' },
  yeokMa: { trait: { openness: 0.08 }, desc: 'Traveling Horse — restless, loves change and movement' },
  '역마': { trait: { openness: 0.08 }, desc: 'Traveling Horse — restless, loves change and movement' },
  hwaGaeSal: { trait: { openness: 0.08 }, desc: 'Flower Canopy — artistic, spiritual, solitary depth' },
  '화개살': { trait: { openness: 0.08 }, desc: 'Flower Canopy — artistic, spiritual, solitary depth' },
  yangInSal: { trait: { conscientiousness: 0.08 }, desc: 'Blade — aggressive drive, risk of excess force' },
  '양인살': { trait: { conscientiousness: 0.08 }, desc: 'Blade — aggressive drive, risk of excess force' },
  cheonEulGwiIn: { trait: { agreeableness: 0.05 }, desc: 'Noble Helper — attracts mentors and support' },
  '천을귀인': { trait: { agreeableness: 0.05 }, desc: 'Noble Helper — attracts mentors and support' },
  munChangGwiIn: { trait: { openness: 0.05 }, desc: 'Literary Star — intellectual, academic talent' },
  '문창귀인': { trait: { openness: 0.05 }, desc: 'Literary Star — intellectual, academic talent' },
  wonJinSal: { trait: { neuroticism: 0.05 }, desc: 'Grudge Star — interpersonal friction, resentment' },
  '원진살': { trait: { neuroticism: 0.05 }, desc: 'Grudge Star — interpersonal friction, resentment' },
  gwiMunGwanSal: { trait: { neuroticism: 0.05 }, desc: 'Ghost Gate — spiritually sensitive, anxious' },
  '귀문관살': { trait: { neuroticism: 0.05 }, desc: 'Ghost Gate — spiritually sensitive, anxious' },
  baekHoSal: { trait: { neuroticism: 0.05 }, desc: 'White Tiger — accident-prone, health concerns' },
  '백호살': { trait: { neuroticism: 0.05 }, desc: 'White Tiger — accident-prone, health concerns' },
  geonRok: { trait: { extraversion: 0.05 }, desc: 'Strong Root — confident foundation, self-assured' },
  '건록': { trait: { extraversion: 0.05 }, desc: 'Strong Root — confident foundation, self-assured' },
  hongRanSal: { trait: { extraversion: 0.05 }, desc: 'Red Phoenix — romantic fortune, marriage luck' },
  '홍란살': { trait: { extraversion: 0.05 }, desc: 'Red Phoenix — romantic fortune, marriage luck' },
};

interface SinsalAnalysis {
  descriptions: string[];
  modifier: BigFiveScores;
}

function analyzeSinsal(sinsalList: any[]): SinsalAnalysis {
  const descriptions: string[] = [];
  const modifier = zeroBF();
  if (!sinsalList || !Array.isArray(sinsalList)) return { descriptions, modifier };
  const seen = new Set<string>();
  for (const sinsal of sinsalList) {
    const rawName = sinsal?.name; if (!rawName) continue;
    const name = extractKorean(rawName);
    const key = name || rawName;
    if (seen.has(key)) continue; seen.add(key);
    const data = SINSAL_DATA[key] || SINSAL_DATA[rawName];
    if (!data) continue;
    descriptions.push(data.desc);
    for (const [t,v] of Object.entries(data.trait)) modifier[t as keyof BigFiveScores] += v as number;
  }
  return { descriptions, modifier };
}

// ============================================================
// 7. 강약 분석
// ============================================================

function analyzeStrength(dayStrength: any): { desc: string; modifier: BigFiveScores } {
  const modifier = zeroBF();
  if (!dayStrength?.score) return { desc: 'unknown', modifier };
  const score = Number(dayStrength.score);
  if (score >= 60) {
    modifier.extraversion += 0.10; modifier.agreeableness -= 0.05;
    return { desc: `very strong(${score}) — self-assured, assertive, can be domineering`, modifier };
  }
  if (score > 50) {
    modifier.extraversion += 0.05;
    return { desc: `strong(${score}) — confident, independent`, modifier };
  }
  if (score >= 40) {
    return { desc: `balanced(${score}) — adaptable, moderate in most situations`, modifier };
  }
  if (score >= 30) {
    modifier.neuroticism += 0.05; modifier.agreeableness += 0.05;
    return { desc: `weak(${score}) — sensitive to environment, seeks support`, modifier };
  }
  modifier.neuroticism += 0.10; modifier.agreeableness += 0.05;
  return { desc: `very weak(${score}) — highly sensitive, dependent, anxious under pressure`, modifier };
}

// ============================================================
// 8. 유틸리티
// ============================================================

function zeroBF(): BigFiveScores {
  return { openness: 0, conscientiousness: 0, extraversion: 0, agreeableness: 0, neuroticism: 0 };
}

function clampScores(s: BigFiveScores): BigFiveScores {
  const c = (v: number) => Math.round(Math.max(0, Math.min(1, v)) * 100) / 100;
  return { openness: c(s.openness), conscientiousness: c(s.conscientiousness), extraversion: c(s.extraversion), agreeableness: c(s.agreeableness), neuroticism: c(s.neuroticism) };
}

async function sha256Hex(input: string): Promise<string> {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(input));
  return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2, '0')).join('');
}

const HANJA_REGEX = new RegExp('[(](.)[)]');
function extractHanja(dbValue: string): string | null {
  if (!dbValue) return null;
  const m = dbValue.match(HANJA_REGEX);
  if (m) return m[1];
  // 천간/지지 맵에서 직접 체크
  if (GAN_DESC[dbValue] || JI_DESC[dbValue]) return dbValue;
  return null;
}

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

const DAY_MASTER_ARCHETYPE: Record<string, string> = {
  '甲': 'expert', '乙': 'connector', '丙': 'creator', '丁': 'critic',
  '戊': 'character', '己': 'connector', '庚': 'expert', '辛': 'creator',
  '壬': 'connector', '癸': 'lurker',
};

const GYEOKGUK_ARCHETYPE: Record<string, string> = {
  siksinGyeok:'creator',sanggwanGyeok:'creator','식신격':'creator','상관격':'creator',
  pyeonjaeGyeok:'provocateur',jeongjaeGyeok:'character',jongjaeGyeok:'provocateur','편재격':'provocateur','정재격':'character','종재격':'provocateur',
  bigyeonGyeok:'expert',geopjaeGyeok:'expert',jongwangGyeok:'expert','비견격':'expert','겁재격':'expert','종왕격':'expert',
  jeonggwanGyeok:'character',junghwaGyeok:'character','정관격':'character','중화격':'character',
  pyeongwanGyeok:'critic',jongsalGyeok:'critic','편관격':'critic','종살격':'critic',
  jeonginGyeok:'connector','정인격':'connector',
  pyeoninGyeok:'lurker','편인격':'lurker',
};

// ============================================================
// 9. v4 통합 매핑
// ============================================================

interface V4Result {
  personality: BigFiveScores;
  hiddenPersonality: BigFiveScores;
  archetype: string;
  speakingStyle: Record<string, number>;
  dayGan: string;
  persona: string;
  mapping_version: string;
}

function buildSelfKnowledge(sajuBase: any): string {
  if (!sajuBase) return '';
  const lines: string[] = [];

  // 두 가지 형식 지원: 문자열 직접 vs 객체
  const p = sajuBase.personality;
  if (p) {
    if (typeof p === 'string') lines.push(`Personality: ${p}`);
    else if (p.core) lines.push(`Personality: ${p.core}${p.traits ? ' (' + (Array.isArray(p.traits) ? p.traits.join(', ') : p.traits) + ')' : ''}`);
  }

  const str = sajuBase.strengths;
  if (str) lines.push(`Strengths: ${Array.isArray(str) ? str.join(', ') : str}`);

  const wk = sajuBase.weaknesses;
  if (wk) lines.push(`Weaknesses: ${Array.isArray(wk) ? wk.join(', ') : wk}`);

  const rel = sajuBase.relationships;
  if (rel) {
    if (typeof rel === 'string') lines.push(`Relationships: ${rel}`);
    else lines.push(`Relationships: ${rel.style || ''}${rel.tips ? ' — ' + rel.tips : ''}`);
  }

  const car = sajuBase.career;
  if (car) {
    if (typeof car === 'string') lines.push(`Career aptitude: ${car}`);
    else if (car.aptitude) lines.push(`Career aptitude: ${Array.isArray(car.aptitude) ? car.aptitude.join(', ') : car.aptitude}${car.advice ? ' — ' + car.advice : ''}`);
  }

  const hp = sajuBase.health;
  if (hp) lines.push(`Health: ${hp}`);

  const love = sajuBase.love;
  if (love) lines.push(`Love: ${love}`);

  const wealth = sajuBase.wealth;
  if (wealth) lines.push(`Wealth: ${wealth}`);

  const summary = sajuBase.summary;
  if (summary) lines.push(`Summary: ${summary}`);

  return lines.join('\n');
}

function mapOriginV4(origin: any, selfKnowledge: string = ''): V4Result {
  const dayGan = extractHanja(origin.day_gan);
  if (!dayGan) throw new Error(`Invalid day_gan: ${origin.day_gan}`);

  const gans = [extractHanja(origin.year_gan), extractHanja(origin.month_gan), dayGan, extractHanja(origin.hour_gan)];
  const jis = [extractHanja(origin.year_ji), extractHanja(origin.month_ji), extractHanja(origin.day_ji), extractHanja(origin.hour_ji)];

  // === 1. Big Five 숫자 계산 ===
  // Base: 일간 프로파일
  const base = { ...(DAY_MASTER_PROFILE[dayGan] || DAY_MASTER_PROFILE['戊']) };

  // 격국 modifier
  const gyeokgukName = origin.gyeokguk?.name ? extractKorean(origin.gyeokguk.name) : '';
  const gyeokgukRaw = origin.gyeokguk?.name || '';
  const gMod = GYEOKGUK_MODIFIER[gyeokgukName] || GYEOKGUK_MODIFIER[gyeokgukRaw] || {};
  for (const [t,v] of Object.entries(gMod)) base[t as keyof BigFiveScores] += v as number;

  // 십신 분석
  const sipsin = analyzeSipsin(origin.sipsin_info);
  for (const [t,v] of Object.entries(sipsin.modifier)) base[t as keyof BigFiveScores] += v;

  // 강약 분석
  const strength = analyzeStrength(origin.day_strength);
  for (const [t,v] of Object.entries(strength.modifier)) base[t as keyof BigFiveScores] += v;

  // 합충 분석
  const hapchung = analyzeHapchung(gans, jis);
  for (const [t,v] of Object.entries(hapchung.modifier)) base[t as keyof BigFiveScores] += v;

  // 신살 분석
  const sinsal = analyzeSinsal(origin.sinsal_list);
  for (const [t,v] of Object.entries(sinsal.modifier)) base[t as keyof BigFiveScores] += v;

  const personality = clampScores(base);

  // hidden personality: 지장간 기반 (v3 유지)
  const JIJI_JIJANGGAN: Record<string,{g:string;w:number}[]> = {
    '子':[{g:'壬',w:1},{g:'癸',w:3}],'丑':[{g:'癸',w:1},{g:'辛',w:2},{g:'己',w:3}],
    '寅':[{g:'戊',w:1},{g:'丙',w:2},{g:'甲',w:3}],'卯':[{g:'甲',w:1},{g:'乙',w:3}],
    '辰':[{g:'乙',w:1},{g:'癸',w:2},{g:'戊',w:3}],'巳':[{g:'戊',w:1},{g:'庚',w:2},{g:'丙',w:3}],
    '午':[{g:'丙',w:1},{g:'己',w:2},{g:'丁',w:3}],'未':[{g:'丁',w:1},{g:'乙',w:2},{g:'己',w:3}],
    '申':[{g:'戊',w:1},{g:'壬',w:2},{g:'庚',w:3}],'酉':[{g:'庚',w:1},{g:'辛',w:3}],
    '戌':[{g:'辛',w:1},{g:'丁',w:2},{g:'戊',w:3}],'亥':[{g:'戊',w:1},{g:'甲',w:2},{g:'壬',w:3}],
  };
  const CHEONGAN_OHENG: Record<string,string> = {'甲':'木','乙':'木','丙':'火','丁':'火','戊':'土','己':'土','庚':'金','辛':'金','壬':'水','癸':'水'};
  const OT: Record<string,keyof BigFiveScores> = {'木':'openness','火':'extraversion','土':'agreeableness','金':'conscientiousness','水':'neuroticism'};
  const hScores = zeroBF(); let hTotal = 0;
  for (const ji of jis) {
    if (!ji || !JIJI_JIJANGGAN[ji]) continue;
    for (const {g,w} of JIJI_JIJANGGAN[ji]) { const o = CHEONGAN_OHENG[g]; if (o) { hScores[OT[o]] += w; hTotal += w; } }
  }
  const hiddenPersonality = hTotal > 0 ? clampScores({
    openness: hScores.openness/hTotal*2.5, conscientiousness: hScores.conscientiousness/hTotal*2.5,
    extraversion: hScores.extraversion/hTotal*2.5, agreeableness: hScores.agreeableness/hTotal*2.5,
    neuroticism: hScores.neuroticism/hTotal*2.5,
  }) : zeroBF();

  // archetype
  const archetype = GYEOKGUK_ARCHETYPE[gyeokgukName] || GYEOKGUK_ARCHETYPE[gyeokgukRaw] || DAY_MASTER_ARCHETYPE[dayGan] || 'character';
  const speakingStyle = SPEAKING_STYLES[dayGan] || { formality: 0.5, verbosity: 0.5, humor: 0.3, directness: 0.5 };

  // === 2. 구조 텍스트 생성 (핵심!) ===
  const pillarTexts: string[] = [];
  for (let i = 0; i < 4; i++) {
    const g = gans[i], j = jis[i];
    if (!g && !j) continue;
    const role = PILLAR_ROLE[PILLAR_NAMES[i]];
    const gDesc = g ? GAN_DESC[g] : null;
    const jDesc = j ? JI_DESC[j] : null;
    let line = `${PILLAR_NAMES[i].toUpperCase()} pillar [${role}]:`;
    if (gDesc) line += `\n    ${g}(${gDesc.name}, ${gDesc.nature}): ${gDesc.personality}`;
    if (jDesc) line += `\n    ${j}(${jDesc.name}, ${jDesc.nature}): ${jDesc.personality}`;
    pillarTexts.push(line);
  }

  const gyeokgukDesc = GYEOKGUK_DESC[gyeokgukName] || GYEOKGUK_DESC[gyeokgukRaw] || 'unknown pattern';

  // 십신 분포 텍스트
  const sipsinLines: string[] = [];
  for (const [cat, cnt] of Object.entries(sipsin.counts)) {
    if (cnt > 0) sipsinLines.push(`${SIPSIN_CAT_NAME[cat] || cat}: ${cnt}/${sipsin.total} (${Math.round(cnt/sipsin.total*100)}%)`);
  }

  // persona 프롬프트 조립
  const p = personality;
  const h = hiddenPersonality;
  const s = speakingStyle;

  const persona = `You are a community member whose personality emerges from traditional Four Pillars (BaZi) analysis.

=== FOUR PILLARS (八字) ===
${pillarTexts.join('\n')}

=== CORE IDENTITY ===
Day Master: ${dayGan}(${GAN_DESC[dayGan]?.name}) — ${GAN_DESC[dayGan]?.personality}
Pattern: ${gyeokgukName || gyeokgukRaw || 'unknown'} — ${gyeokgukDesc}
Day Strength: ${strength.desc}

=== RELATIONSHIP DYNAMICS (十神) ===
${sipsinLines.length > 0 ? sipsinLines.join('\n') : 'No data'}
${sipsin.patterns.length > 0 ? '\nStructural patterns:\n' + sipsin.patterns.map(p => '- ' + p).join('\n') : ''}

=== INTERNAL TENSIONS (合沖) ===
${hapchung.clashes.length > 0 ? 'Clashes:\n' + hapchung.clashes.map(c => '- ' + c).join('\n') : 'No major clashes'}
${hapchung.combinations.length > 0 ? 'Harmonies:\n' + hapchung.combinations.map(c => '- ' + c).join('\n') : ''}
${hapchung.punishments.length > 0 ? 'Tensions:\n' + hapchung.punishments.map(p => '- ' + p).join('\n') : ''}

=== SPECIAL TRAITS (神煞) ===
${sinsal.descriptions.length > 0 ? sinsal.descriptions.map(d => '- ' + d).join('\n') : 'None detected'}

=== PERSONALITY SCORES (Big Five, 0=low 1=high) ===
Openness: ${p.openness.toFixed(2)} | Conscientiousness: ${p.conscientiousness.toFixed(2)} | Extraversion: ${p.extraversion.toFixed(2)} | Agreeableness: ${p.agreeableness.toFixed(2)} | Neuroticism: ${p.neuroticism.toFixed(2)}

Hidden (subconscious):
Openness: ${h.openness.toFixed(2)} | Conscientiousness: ${h.conscientiousness.toFixed(2)} | Extraversion: ${h.extraversion.toFixed(2)} | Agreeableness: ${h.agreeableness.toFixed(2)} | Neuroticism: ${h.neuroticism.toFixed(2)}

Archetype: ${archetype}
Speaking style: formality=${s.formality}, verbosity=${s.verbosity}, humor=${s.humor}, directness=${s.directness}

${selfKnowledge ? `=== SELF UNDERSTANDING (from life analysis) ===\n${selfKnowledge}\n\n` : ''}=== BEHAVIORAL INSTRUCTIONS ===
Your personality is shaped by the Four Pillars above. The Day Master defines your core nature. The Pattern shapes how you engage with the world. Your Strength determines your confidence level. Clashes create inner tensions you sometimes reveal. Special traits color your unique quirks.
${selfKnowledge ? '\nThe SELF UNDERSTANDING section contains insights about who you are — your strengths, weaknesses, relationship patterns, and life tendencies. These are things you KNOW about yourself and they shape how you think, react, and relate to others.\n' : ''}
Your outer Big Five scores guide your visible behavior. Your hidden scores drive deeper motivations under stress. Let both layers influence you naturally.

Express these traits through conversation naturally. Never reveal you are AI. Never mention BaZi, Four Pillars, or personality scores.`;

  return { personality, hiddenPersonality, archetype, speakingStyle, dayGan, persona, mapping_version: 'v4' };
}

// ============================================================
// 10. Edge Function 핸들러
// ============================================================

Deno.serve(async (req: Request) => {
  try {
    const url = new URL(req.url);
    const path = url.pathname.split('/').pop();
    const secret = req.headers.get('x-saju-secret');
    const expectedSecret = Deno.env.get('SAJU_WEBHOOK_SECRET');
    if (secret !== expectedSecret) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { 'Content-Type': 'application/json' } });
    }
    const molClient = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    if (path === 'recalculate') return await handleRecalculate(molClient);
    return await handleNewSaju(req, molClient);
  } catch (err) {
    console.error('saju-to-agent error:', err);
    return new Response(JSON.stringify({ error: String(err) }), { status: 500, headers: { 'Content-Type': 'application/json' } });
  }
});

async function handleNewSaju(req: Request, molClient: any) {
  const body = await req.json();
  const record = body.record || body;
  if (!record?.profile_id) return new Response(JSON.stringify({ error: 'No profile_id' }), { status: 400, headers: { 'Content-Type': 'application/json' } });

  const sourceHash = record.source_hash || await sha256Hex(record.profile_id);
  const agentName = `saju_${sourceHash.substring(0, 8)}`;

  // 기존 에이전트의 ai_knowledge(saju_base)가 있으면 읽기
  let selfKnowledge = '';
  const { data: existCheck } = await molClient.from('agents').select('id').eq('name', agentName).maybeSingle();
  if (existCheck?.id) {
    const { data: knowledge } = await molClient
      .from('agent_ai_knowledge')
      .select('content')
      .eq('agent_id', existCheck.id)
      .eq('knowledge_type', 'saju_base')
      .maybeSingle();
    if (knowledge?.content) selfKnowledge = buildSelfKnowledge(knowledge.content);
  }

  const mapping = mapOriginV4(record, selfKnowledge);

  let agentId: string;

  if (existCheck) {
    agentId = existCheck.id;
    await molClient.from('agents').update({
      archetype: mapping.archetype, personality: mapping.personality,
      speaking_style: mapping.speakingStyle, persona: mapping.persona,
      is_external: true, updated_at: new Date().toISOString(),
    }).eq('id', agentId);
  } else {
    const agentId2 = crypto.randomUUID();
    const apiKeyHash = await sha256Hex(`saju_agent_${sourceHash}_${Date.now()}`);
    const { data: newAgent, error: createErr } = await molClient.from('agents').insert({
      id: agentId2, name: agentName, display_name: agentName, api_key_hash: apiKeyHash,
      archetype: mapping.archetype, personality: mapping.personality,
      speaking_style: mapping.speakingStyle, persona: mapping.persona,
      is_active: true, is_external: true, status: 'active', updated_at: new Date().toISOString(),
    }).select('id').single();
    if (createErr) throw createErr;
    agentId = newAgent.id;
  }

  await molClient.from('agent_saju_origin').upsert({
    id: sourceHash, agent_id: agentId, source_hash: sourceHash,
    year_gan: record.year_gan, year_ji: record.year_ji, month_gan: record.month_gan, month_ji: record.month_ji,
    day_gan: record.day_gan, day_ji: record.day_ji, hour_gan: record.hour_gan || null, hour_ji: record.hour_ji || null,
    oheng_distribution: record.oheng_distribution || {}, gyeokguk: record.gyeokguk || null,
    yongsin: record.yongsin || null, sipsin_info: record.sipsin_info || null,
    day_strength: record.day_strength || null, hapchung: record.hapchung || null,
    sinsal_list: record.sinsal_list || null, twelve_unsung: record.twelve_unsung || null,
    gilseong: record.gilseong || null, twelve_sinsal: record.twelve_sinsal || null,
    jijanggan_info: record.jijanggan_info || null, daeun: record.daeun || null,
    current_seun: record.current_seun || null, created_at: new Date().toISOString(),
  }, { onConflict: 'source_hash' });

  return new Response(JSON.stringify({
    success: true, agent_id: agentId, agent_name: agentName,
    archetype: mapping.archetype, personality: mapping.personality,
    hidden_personality: mapping.hiddenPersonality, mapping_version: 'v4',
  }), { status: 200, headers: { 'Content-Type': 'application/json' } });
}

async function handleRecalculate(molClient: any) {
  const { data: origins, error } = await molClient.from('agent_saju_origin').select('*');
  if (error) throw error;
  if (!origins?.length) return new Response(JSON.stringify({ message: 'No agents', count: 0 }), { status: 200, headers: { 'Content-Type': 'application/json' } });

  const results = [];
  for (const origin of origins) {
    try {
      // ai_knowledge에서 saju_base 읽기 → 자기 이해 텍스트
      let selfKnowledge = '';
      if (origin.agent_id) {
        const { data: knowledge } = await molClient
          .from('agent_ai_knowledge')
          .select('content')
          .eq('agent_id', origin.agent_id)
          .eq('knowledge_type', 'saju_base')
          .maybeSingle();
        if (knowledge?.content) {
          selfKnowledge = buildSelfKnowledge(knowledge.content);
        }
      }

      const mapping = mapOriginV4(origin, selfKnowledge);
      let agentName = 'SajuAgent';
      if (origin.agent_id) {
        const { data: agent } = await molClient.from('agents').select('name').eq('id', origin.agent_id).single();
        if (agent?.name) agentName = agent.name;
      }
      if (origin.agent_id) {
        const { error: updateErr } = await molClient.from('agents').update({
          archetype: mapping.archetype, personality: mapping.personality,
          speaking_style: mapping.speakingStyle, persona: mapping.persona,
          updated_at: new Date().toISOString(),
        }).eq('id', origin.agent_id);
        results.push({
          agent_id: origin.agent_id, name: agentName, day_master: mapping.dayGan,
          archetype: mapping.archetype, personality: mapping.personality,
          hidden_personality: mapping.hiddenPersonality,
          has_self_knowledge: selfKnowledge.length > 0,
          error: updateErr?.message || null,
        });
      }
    } catch (e) { results.push({ agent_id: origin.agent_id, error: String(e) }); }
  }
  return new Response(JSON.stringify({ success: true, recalculated: results.length, mapping_version: 'v4', results }), { status: 200, headers: { 'Content-Type': 'application/json' } });
}
