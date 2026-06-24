import {
  cheonganHanja,
  cheonganOheng,
  cheonganYinYang,
  exhausting,
  generating,
  hiddenStems,
  jijiHanja,
  jijiOheng,
  ohengDbKeys,
  ohengKorean,
  overcoming,
  type OhengKey,
} from "./constants";
import type { Pillar, SajuAnalysisPayload, SajuChart } from "./types";

type SipSin =
  | "비견"
  | "겁재"
  | "식신"
  | "상관"
  | "편재"
  | "정재"
  | "편관"
  | "정관"
  | "편인"
  | "정인";

type SipSinCategory = "비겁" | "식상" | "재성" | "관성" | "인성";

const sipsinCategory: Record<SipSin, SipSinCategory> = {
  비견: "비겁",
  겁재: "비겁",
  식신: "식상",
  상관: "식상",
  편재: "재성",
  정재: "재성",
  편관: "관성",
  정관: "관성",
  편인: "인성",
  정인: "인성",
};

const relationByElement = {
  same: ["비견", "겁재"],
  output: ["식신", "상관"],
  wealth: ["편재", "정재"],
  officer: ["편관", "정관"],
  resource: ["편인", "정인"],
} satisfies Record<string, [SipSin, SipSin]>;

const pillarLabels = ["year", "month", "day", "hour"] as const;
const pillarKorean: Record<(typeof pillarLabels)[number], string> = {
  year: "연주",
  month: "월주",
  day: "일주",
  hour: "시주",
};

function isSamePolarity(dayGan: string, targetGan: string) {
  return cheonganYinYang[dayGan] === cheonganYinYang[targetGan];
}

function calculateSipSin(dayGan: string, targetGan: string): SipSin {
  const dayElement = cheonganOheng[dayGan];
  const targetElement = cheonganOheng[targetGan];
  const samePolarity = isSamePolarity(dayGan, targetGan);

  if (dayElement === targetElement) {
    return samePolarity ? relationByElement.same[0] : relationByElement.same[1];
  }
  if (exhausting[dayElement] === targetElement) {
    return samePolarity ? relationByElement.output[0] : relationByElement.output[1];
  }
  if (overcoming[dayElement] === targetElement) {
    return samePolarity ? relationByElement.wealth[0] : relationByElement.wealth[1];
  }
  if (overcoming[targetElement] === dayElement) {
    return samePolarity ? relationByElement.officer[0] : relationByElement.officer[1];
  }
  return samePolarity ? relationByElement.resource[0] : relationByElement.resource[1];
}

function pillars(chart: SajuChart) {
  return [
    ["year", chart.yearPillar],
    ["month", chart.monthPillar],
    ["day", chart.dayPillar],
    ["hour", chart.hourPillar],
  ] as const;
}

function getJeongGi(ji: string) {
  return hiddenStems[ji]?.find((stem) => stem.type === "정기")?.gan;
}

function isSupport(dayElement: OhengKey, ji: string) {
  const mainGan = getJeongGi(ji);
  if (!mainGan) return false;
  const mainElement = cheonganOheng[mainGan];
  return dayElement === mainElement || generating[mainElement] === dayElement;
}

function countGanSupport(chart: SajuChart, dayGan: string) {
  const supportCategories = new Set<SipSinCategory>(["비겁", "인성"]);
  return [chart.yearPillar.gan, chart.monthPillar.gan, chart.hourPillar?.gan]
    .filter((gan): gan is string => Boolean(gan))
    .filter((gan) => supportCategories.has(sipsinCategory[calculateSipSin(dayGan, gan)]))
    .length;
}

function calculateSipsinDistribution(chart: SajuChart) {
  const dayGan = chart.dayPillar.gan;
  const result: Record<SipSinCategory, number> = {
    비겁: 0,
    식상: 0,
    재성: 0,
    관성: 0,
    인성: 0,
  };

  const gans = [
    dayGan,
    chart.yearPillar.gan,
    chart.monthPillar.gan,
    chart.hourPillar?.gan,
  ].filter((gan): gan is string => Boolean(gan));

  for (const gan of gans) {
    result[sipsinCategory[calculateSipSin(dayGan, gan)]] += 1;
  }

  for (const [, pillar] of pillars(chart)) {
    if (!pillar) continue;
    const mainGan = getJeongGi(pillar.ji);
    if (!mainGan) continue;
    result[sipsinCategory[calculateSipSin(dayGan, mainGan)]] += 1;
  }

  return result;
}

function analyzeDayStrength(chart: SajuChart) {
  const dayGan = chart.dayPillar.gan;
  const dayElement = cheonganOheng[dayGan];
  const distribution = calculateSipsinDistribution(chart);
  const deukryeong = isSupport(dayElement, chart.monthPillar.ji);
  const deukji = isSupport(dayElement, chart.dayPillar.ji);
  const deuksi = chart.hourPillar ? isSupport(dayElement, chart.hourPillar.ji) : false;
  const deuknyeonji = isSupport(dayElement, chart.yearPillar.ji);
  const deukse = countGanSupport(chart, dayGan) >= 2;
  let rawScore = 0;

  if (sipsinCategory[calculateSipSin(dayGan, chart.yearPillar.gan)] === "비겁" || sipsinCategory[calculateSipSin(dayGan, chart.yearPillar.gan)] === "인성") rawScore += 10;
  if (sipsinCategory[calculateSipSin(dayGan, chart.monthPillar.gan)] === "비겁" || sipsinCategory[calculateSipSin(dayGan, chart.monthPillar.gan)] === "인성") rawScore += 10;
  if (chart.hourPillar && (sipsinCategory[calculateSipSin(dayGan, chart.hourPillar.gan)] === "비겁" || sipsinCategory[calculateSipSin(dayGan, chart.hourPillar.gan)] === "인성")) rawScore += 10;
  if (deukryeong) rawScore += 30;
  if (deukji) rawScore += 15;
  if (deuksi) rawScore += 15;
  if (deuknyeonji) rawScore += 10;

  const maxScore = chart.hourPillar ? 100 : 75;
  const score = Math.max(0, Math.min(100, Math.round((rawScore / maxScore) * 100)));
  const level = score >= 88
    ? "극신강"
    : score >= 75
      ? "신강"
      : score >= 63
        ? "약신강"
        : score >= 50
          ? "중화신강"
          : score >= 38
            ? "중화신약"
            : score >= 26
              ? "신약"
              : score >= 13
                ? "약신약"
                : "극신약";

  return {
    score,
    raw_score: rawScore,
    max_score: maxScore,
    level,
    isStrong: score >= 50,
    isWeak: score < 50,
    deukryeong,
    deukji,
    deuksi,
    deuknyeonji,
    deukse,
    monthStatus: deukryeong ? "득월" : "중립",
    details: {
      bigeopCount: distribution.비겁,
      inseongCount: distribution.인성,
      jaeseongCount: distribution.재성,
      gwanseongCount: distribution.관성,
      siksangCount: distribution.식상,
    },
  };
}

function analyzeYongsin(chart: SajuChart, dayStrength: ReturnType<typeof analyzeDayStrength>) {
  const dayElement = cheonganOheng[chart.dayPillar.gan];
  let yongsin: OhengKey;
  let reason: string;

  if (dayStrength.isStrong) {
    if (dayStrength.details.bigeopCount > dayStrength.details.inseongCount) {
      yongsin = exhausting[exhausting[dayElement]];
      reason = `신강 사주 - 비겁 과다로 ${ohengKorean[yongsin]} 기운으로 제어`;
    } else {
      yongsin = exhausting[dayElement];
      reason = `신강 사주 - ${ohengKorean[yongsin]} 기운으로 설기`;
    }
  } else if (dayStrength.details.inseongCount > 0) {
    yongsin = generating[dayElement];
    reason = `신약 사주 - ${ohengKorean[yongsin]} 기운으로 생조`;
  } else {
    yongsin = dayElement;
    reason = `신약 사주 - 같은 ${ohengKorean[yongsin]} 기운으로 조력`;
  }

  const heesin = generating[yongsin];
  const gisin = overcoming[yongsin];
  const gusin = exhausting[yongsin];
  const hansin = generating[overcoming[yongsin]];

  return {
    yongsin: ohengKorean[yongsin],
    heesin: ohengKorean[heesin],
    huisin: ohengKorean[heesin],
    gisin: ohengKorean[gisin],
    gusin: ohengKorean[gusin],
    hansin: ohengKorean[hansin],
    yongsin_key: yongsin,
    heesin_key: heesin,
    gisin_key: gisin,
    gusin_key: gusin,
    hansin_key: hansin,
    method: "억부",
    reason,
  };
}

function calculateOhengDistribution(chart: SajuChart) {
  const result: Record<string, number> = {
    [ohengDbKeys.wood]: 0,
    [ohengDbKeys.fire]: 0,
    [ohengDbKeys.earth]: 0,
    [ohengDbKeys.metal]: 0,
    [ohengDbKeys.water]: 0,
    wood: 0,
    fire: 0,
    earth: 0,
    metal: 0,
    water: 0,
  };

  for (const [, pillar] of pillars(chart)) {
    if (!pillar) continue;
    for (const element of [cheonganOheng[pillar.gan], jijiOheng[pillar.ji]]) {
      result[element] += 1;
      result[ohengDbKeys[element]] += 1;
    }
  }

  return result;
}

function analyzeSipsin(chart: SajuChart) {
  const dayGan = chart.dayPillar.gan;
  const result: Record<string, unknown> = {};

  for (const [label, pillar] of pillars(chart)) {
    if (!pillar) continue;
    result[label] = {
      pillar: pillarKorean[label],
      gan: {
        value: pillar.gan,
        hanja: cheonganHanja[pillar.gan],
        sipsin: label === "day" ? "일간" : calculateSipSin(dayGan, pillar.gan),
      },
      ji_main: {
        value: getJeongGi(pillar.ji),
        sipsin: getJeongGi(pillar.ji) ? calculateSipSin(dayGan, getJeongGi(pillar.ji)!) : null,
      },
    };
  }

  result.distribution = calculateSipsinDistribution(chart);
  return result;
}

function analyzeJijanggan(chart: SajuChart) {
  const dayGan = chart.dayPillar.gan;
  const result: Record<string, unknown> = {};

  for (const [label, pillar] of pillars(chart)) {
    if (!pillar) continue;
    result[label] = {
      pillar: pillarKorean[label],
      jiji: pillar.ji,
      jiji_hanja: jijiHanja[pillar.ji],
      stems: (hiddenStems[pillar.ji] ?? []).map((stem) => ({
        gan: stem.gan,
        gan_hanja: cheonganHanja[stem.gan],
        oheng: ohengKorean[cheonganOheng[stem.gan]],
        type: stem.type,
        strength: stem.strength,
        sipsin: calculateSipSin(dayGan, stem.gan),
      })),
    };
  }

  return result;
}

function analyzeGyeokguk(chart: SajuChart) {
  const monthMainGan = getJeongGi(chart.monthPillar.ji);
  const sipsin = monthMainGan ? calculateSipSin(chart.dayPillar.gan, monthMainGan) : null;

  return {
    name: sipsin ? `${sipsin}격` : "보류",
    basis: "월지 정기 기준",
    month_main_gan: monthMainGan,
    month_main_gan_hanja: monthMainGan ? cheonganHanja[monthMainGan] : null,
    sipsin,
  };
}

function pairRelations<T extends Pillar>(items: Array<[string, T]>, predicate: (a: string, b: string) => boolean, label: string) {
  const result: Array<Record<string, string>> = [];
  for (let i = 0; i < items.length; i += 1) {
    for (let j = i + 1; j < items.length; j += 1) {
      const first = items[i];
      const second = items[j];
      if (predicate(first[1].ji, second[1].ji)) {
        result.push({
          type: label,
          from: first[0],
          to: second[0],
          pair: `${first[1].ji}${second[1].ji}`,
        });
      }
    }
  }
  return result;
}

function analyzeHapchung(chart: SajuChart) {
  const items = pillars(chart).filter((entry): entry is [(typeof pillarLabels)[number], Pillar] => Boolean(entry[1]));
  const sixHaps = new Set(["자축", "인해", "묘술", "진유", "사신", "오미"]);
  const chungs = new Set(["자오", "축미", "인신", "묘유", "진술", "사해"]);
  const hasPair = (set: Set<string>, a: string, b: string) => set.has(`${a}${b}`) || set.has(`${b}${a}`);

  return {
    jijiYukhaps: pairRelations(items, (a, b) => hasPair(sixHaps, a, b), "육합"),
    jijiChungs: pairRelations(items, (a, b) => hasPair(chungs, a, b), "충"),
  };
}

export function buildSajuAnalysis(chart: SajuChart): SajuAnalysisPayload {
  const dayStrength = analyzeDayStrength(chart);

  return {
    ohengDistribution: calculateOhengDistribution(chart),
    dayStrength,
    yongsin: analyzeYongsin(chart, dayStrength),
    gyeokguk: analyzeGyeokguk(chart),
    sipsinInfo: analyzeSipsin(chart),
    jijangganInfo: analyzeJijanggan(chart),
    hapchung: analyzeHapchung(chart),
  };
}
