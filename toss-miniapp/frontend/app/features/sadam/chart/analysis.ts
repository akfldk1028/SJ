import {
  cheongan,
  cheonganHanja,
  cheonganOheng,
  cheonganYinYang,
  exhausting,
  generating,
  hiddenStems,
  jiji,
  jijiHanja,
  jijiOheng,
  ohengDbKeys,
  ohengKorean,
  overcoming,
  type OhengKey,
} from "./constants";
import type { Pillar, SajuAnalysisPayload, SajuChart } from "./types";

type AnalysisContext = {
  birthDateTime: Date;
  birthYear: number;
  gender: "male" | "female";
};

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

const unsungOrder = [
  { key: "jangsaeng", name: "장생", hanja: "長生", strength: 7, fortuneType: "길" },
  { key: "mokyok", name: "목욕", hanja: "沐浴", strength: 4, fortuneType: "중" },
  { key: "gwandae", name: "관대", hanja: "冠帶", strength: 8, fortuneType: "길" },
  { key: "geonrok", name: "건록", hanja: "建祿", strength: 9, fortuneType: "길" },
  { key: "jewang", name: "제왕", hanja: "帝旺", strength: 10, fortuneType: "길" },
  { key: "soe", name: "쇠", hanja: "衰", strength: 3, fortuneType: "중" },
  { key: "byung", name: "병", hanja: "病", strength: 2, fortuneType: "흉" },
  { key: "sa", name: "사", hanja: "死", strength: 1, fortuneType: "흉" },
  { key: "myo", name: "묘", hanja: "墓", strength: 1, fortuneType: "흉" },
  { key: "jeol", name: "절", hanja: "絶", strength: 0, fortuneType: "흉" },
  { key: "tae", name: "태", hanja: "胎", strength: 5, fortuneType: "중" },
  { key: "yang", name: "양", hanja: "養", strength: 6, fortuneType: "중" },
] as const;

const yangGanJangsaeng: Record<string, string> = {
  갑: "해",
  병: "인",
  무: "인",
  경: "사",
  임: "신",
};

const yinGanJangsaeng: Record<string, string> = {
  을: "오",
  정: "유",
  기: "유",
  신: "자",
  계: "묘",
};

function normalizeCycle(index: number, length: number) {
  return ((index % length) + length) % length;
}

function calculateUnsung(dayGan: string, targetJi: string) {
  const isYangGan = cheonganYinYang[dayGan] === "양";
  const startJi = isYangGan ? yangGanJangsaeng[dayGan] : yinGanJangsaeng[dayGan];
  const startIndex = jiji.indexOf(startJi as (typeof jiji)[number]);
  const targetIndex = jiji.indexOf(targetJi as (typeof jiji)[number]);
  const unsungIndex = isYangGan
    ? normalizeCycle(targetIndex - startIndex, 12)
    : normalizeCycle(startIndex - targetIndex, 12);

  return unsungOrder[unsungIndex] ?? unsungOrder[0];
}

function analyzeTwelveUnsung(chart: SajuChart) {
  return pillars(chart)
    .filter((entry): entry is [(typeof pillarLabels)[number], Pillar] => Boolean(entry[1]))
    .map(([label, pillar]) => {
      const unsung = calculateUnsung(chart.dayPillar.gan, pillar.ji);
      return {
        pillar: label,
        pillar_name: pillarKorean[label],
        jiji: pillar.ji,
        day_gan: chart.dayPillar.gan,
        key: unsung.key,
        name: unsung.name,
        hanja: unsung.hanja,
        strength: unsung.strength,
        fortune_type: unsung.fortuneType,
      };
    });
}

const sinsalOrder = [
  { key: "geopsal", name: "겁살", fortuneType: "흉" },
  { key: "jaesal", name: "재살", fortuneType: "흉" },
  { key: "cheonsal", name: "천살", fortuneType: "흉" },
  { key: "jisal", name: "지살", fortuneType: "흉" },
  { key: "yeonsal", name: "연살", fortuneType: "중" },
  { key: "wolsal", name: "월살", fortuneType: "흉" },
  { key: "mangshin", name: "망신", fortuneType: "흉" },
  { key: "jangsung", name: "장성", fortuneType: "길" },
  { key: "banan", name: "반안", fortuneType: "길" },
  { key: "yeokma", name: "역마", fortuneType: "중" },
  { key: "yukhae", name: "육해", fortuneType: "흉" },
  { key: "hwagae", name: "화개", fortuneType: "중" },
] as const;

const sinsalGroupBase: Record<string, number> = {
  인: 2,
  오: 2,
  술: 2,
  사: 5,
  유: 5,
  축: 5,
  신: 8,
  자: 8,
  진: 8,
  해: 11,
  묘: 11,
  미: 11,
};

const sinsalStartOffset: Record<number, number> = {
  2: 11,
  5: 2,
  8: 5,
  11: 8,
};

function calculateTwelveSinsal(baseJi: string, targetJi: string) {
  const groupBase = sinsalGroupBase[baseJi];
  const startOffset = groupBase == null ? undefined : sinsalStartOffset[groupBase];
  const targetIndex = jiji.indexOf(targetJi as (typeof jiji)[number]);
  if (startOffset == null || targetIndex < 0) return null;
  return sinsalOrder[normalizeCycle(targetIndex - startOffset, 12)];
}

function sinsalBasis(yearJi: string, dayJi: string, targetJi: string, key: string) {
  const yearMatch = calculateTwelveSinsal(yearJi, targetJi)?.key === key;
  const dayMatch = calculateTwelveSinsal(dayJi, targetJi)?.key === key;
  if (yearMatch && dayMatch) return "both";
  if (yearMatch) return "year";
  if (dayMatch) return "day";
  return null;
}

function analyzeTwelveSinsal(chart: SajuChart) {
  return pillars(chart)
    .filter((entry): entry is [(typeof pillarLabels)[number], Pillar] => Boolean(entry[1]))
    .map(([label, pillar]) => {
      const yearBased = calculateTwelveSinsal(chart.yearPillar.ji, pillar.ji);
      const dayBased = calculateTwelveSinsal(chart.dayPillar.ji, pillar.ji);
      return {
        pillar: label,
        pillar_name: pillarKorean[label],
        jiji: pillar.ji,
        year_based: yearBased,
        day_based: dayBased,
      };
    });
}

function buildSinsalList(chart: SajuChart) {
  const results: Array<Record<string, unknown>> = [];
  const dayGan = chart.dayPillar.gan;
  const yearJi = chart.yearPillar.ji;
  const dayJi = chart.dayPillar.ji;
  const allPillars = pillars(chart).filter((entry): entry is [(typeof pillarLabels)[number], Pillar] => Boolean(entry[1]));
  const cheoneul: Record<string, string[]> = {
    갑: ["축", "미"],
    을: ["자", "신"],
    병: ["해", "유"],
    정: ["해", "유"],
    무: ["축", "미"],
    기: ["자", "신"],
    경: ["축", "미"],
    신: ["인", "오"],
    임: ["묘", "사"],
    계: ["묘", "사"],
  };
  const yangin: Record<string, string> = {
    갑: "묘",
    을: "진",
    병: "오",
    정: "미",
    무: "오",
    기: "미",
    경: "유",
    신: "술",
    임: "자",
    계: "축",
  };

  for (const [label, pillar] of allPillars) {
    if (cheoneul[dayGan]?.includes(pillar.ji)) {
      results.push({
        key: "cheoneul_gwiin",
        name: "천을귀인",
        fortune_type: "길",
        pillar: label,
        pillar_name: pillarKorean[label],
        related_ji: pillar.ji,
      });
    }

    for (const special of [
      ["dohwasal", "도화살", "yeonsal"],
      ["yeokmasal", "역마살", "yeokma"],
      ["hwagaesal", "화개살", "hwagae"],
    ] as const) {
      const basis = sinsalBasis(yearJi, dayJi, pillar.ji, special[2]);
      if (basis) {
        results.push({
          key: special[0],
          name: special[1],
          fortune_type: "중",
          pillar: label,
          pillar_name: pillarKorean[label],
          related_ji: pillar.ji,
          basis,
        });
      }
    }

    if (yangin[dayGan] === pillar.ji) {
      results.push({
        key: "yangin",
        name: "양인살",
        fortune_type: "흉",
        pillar: label,
        pillar_name: pillarKorean[label],
        related_ji: pillar.ji,
      });
    }
  }

  return results;
}

function analyzeGilseong(chart: SajuChart, sinsalList: Array<Record<string, unknown>>) {
  const allJis = pillars(chart)
    .map(([, pillar]) => pillar?.ji)
    .filter((ji): ji is string => Boolean(ji));
  const good = sinsalList.filter((item) => item.fortune_type === "길");
  const bad = sinsalList.filter((item) => item.fortune_type === "흉");
  const wonjinPairs = new Set(["자미", "축오", "인유", "묘신", "진해", "사술"]);
  let wonjinCount = 0;

  for (let i = 0; i < allJis.length; i += 1) {
    for (let k = i + 1; k < allJis.length; k += 1) {
      const pair = `${allJis[i]}${allJis[k]}`;
      const reversePair = `${allJis[k]}${allJis[i]}`;
      if (wonjinPairs.has(pair) || wonjinPairs.has(reversePair)) wonjinCount += 1;
    }
  }

  return {
    summary: good.length > 0 ? good.map((item) => item.name).join(", ") : "특수 길성 없음",
    total_good_count: good.length,
    total_bad_count: bad.length,
    all_unique_sinsals: Array.from(new Set(sinsalList.map((item) => String(item.name)))),
    has_gwimungwansal: allJis.includes("진") && allJis.includes("해"),
    wonjinsal_count: wonjinCount,
  };
}

const jeolipBoundaries = [
  { month: 2, day: 4 },
  { month: 3, day: 6 },
  { month: 4, day: 5 },
  { month: 5, day: 6 },
  { month: 6, day: 6 },
  { month: 7, day: 7 },
  { month: 8, day: 8 },
  { month: 9, day: 8 },
  { month: 10, day: 8 },
  { month: 11, day: 7 },
  { month: 12, day: 7 },
  { month: 1, day: 6 },
];

function nearestJeolipDays(date: Date, isForward: boolean) {
  const candidates: Date[] = [];
  for (const year of [date.getFullYear() - 1, date.getFullYear(), date.getFullYear() + 1]) {
    for (const boundary of jeolipBoundaries) {
      candidates.push(new Date(year, boundary.month - 1, boundary.day, 0, 0));
    }
  }
  candidates.sort((a, b) => a.getTime() - b.getTime());
  const target = isForward
    ? candidates.find((candidate) => candidate.getTime() > date.getTime())
    : candidates.reverse().find((candidate) => candidate.getTime() < date.getTime());
  if (!target) return 15;
  return Math.abs(Math.round((target.getTime() - date.getTime()) / 86_400_000));
}

function analyzeDaeun(chart: SajuChart, context: AnalysisContext) {
  const isYearGanYang = cheonganYinYang[chart.yearPillar.gan] === "양";
  const isForward = (context.gender === "male" && isYearGanYang) || (context.gender === "female" && !isYearGanYang);
  const startAge = Math.max(1, Math.min(10, Math.round(nearestJeolipDays(context.birthDateTime, isForward) / 3)));
  let ganIndex = cheongan.indexOf(chart.monthPillar.gan as (typeof cheongan)[number]);
  let jiIndex = jiji.indexOf(chart.monthPillar.ji as (typeof jiji)[number]);
  const list = [];

  for (let i = 0; i < 10; i += 1) {
    ganIndex = normalizeCycle(ganIndex + (isForward ? 1 : -1), 10);
    jiIndex = normalizeCycle(jiIndex + (isForward ? 1 : -1), 12);
    const age = startAge + i * 10;
    list.push({
      order: i + 1,
      start_age: age,
      end_age: age + 9,
      gan: cheongan[ganIndex],
      ji: jiji[jiIndex],
      gan_hanja: cheonganHanja[cheongan[ganIndex]],
      ji_hanja: jijiHanja[jiji[jiIndex]],
    });
  }

  return {
    start_age: startAge,
    is_forward: isForward,
    gender: context.gender,
    is_year_gan_yang: isYearGanYang,
    daeun_list: list,
  };
}

function analyzeCurrentSeun(context: AnalysisContext) {
  const year = new Date().getFullYear();
  const ganIndex = normalizeCycle(year - 4, 10);
  const jiIndex = normalizeCycle(year - 4, 12);

  return {
    year,
    age: year - context.birthYear + 1,
    gan: cheongan[ganIndex],
    ji: jiji[jiIndex],
    gan_hanja: cheonganHanja[cheongan[ganIndex]],
    ji_hanja: jijiHanja[jiji[jiIndex]],
  };
}

export function buildSajuAnalysis(chart: SajuChart, context: AnalysisContext): SajuAnalysisPayload {
  const dayStrength = analyzeDayStrength(chart);
  const sinsalList = buildSinsalList(chart);

  return {
    ohengDistribution: calculateOhengDistribution(chart),
    dayStrength,
    yongsin: analyzeYongsin(chart, dayStrength),
    gyeokguk: analyzeGyeokguk(chart),
    sipsinInfo: analyzeSipsin(chart),
    jijangganInfo: analyzeJijanggan(chart),
    sinsalList,
    daeun: analyzeDaeun(chart, context),
    currentSeun: analyzeCurrentSeun(context),
    twelveUnsung: analyzeTwelveUnsung(chart),
    twelveSinsal: analyzeTwelveSinsal(chart),
    gilseong: analyzeGilseong(chart, sinsalList),
    hapchung: analyzeHapchung(chart),
  };
}
