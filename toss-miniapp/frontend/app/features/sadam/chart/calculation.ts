import {
  cheongan,
  jiji,
  parseBirthDate,
  resolveIdentityFromGanji,
  type CalendarType,
} from "../personas";
import { buildSajuAnalysis } from "./analysis";
import { lunarToSolar } from "./lunar-calendar";
import type { DateParts, Pillar, SajuResolveResult } from "./types";

export type SajuResolveInput = {
  birthDate: string;
  birthTime?: string | null;
  birthTimeUnknown?: boolean;
  calendar?: CalendarType | string | null;
  isLeapMonth?: boolean | null;
  birthCity?: string | null;
  useYaJasi?: boolean;
  gender?: "male" | "female" | string | null;
};

const DAY_MS = 86_400_000;
const BASE_DAY_INDEX = 10;
const BASE_DATE_UTC = Date.UTC(1900, 0, 1);

const cityLongitude: Record<string, number> = {
  서울: 126.98,
  서울특별시: 126.98,
  부산: 129.03,
  부산광역시: 129.03,
  대구: 128.6,
  대구광역시: 128.6,
  인천: 126.7,
  인천광역시: 126.7,
  광주: 126.85,
  광주광역시: 126.85,
  대전: 127.38,
  대전광역시: 127.38,
  울산: 129.31,
  울산광역시: 129.31,
  세종: 127.29,
  세종특별자치시: 127.29,
  제주: 126.53,
  제주특별자치도: 126.53,
  default: 127,
};

const dstPeriods = [
  ["1948-06-01T00:00:00", "1948-09-12T23:59:59"],
  ["1949-04-03T00:00:00", "1949-09-10T23:59:59"],
  ["1950-04-01T00:00:00", "1950-09-09T23:59:59"],
  ["1951-05-06T00:00:00", "1951-09-08T23:59:59"],
  ["1955-05-05T00:00:00", "1955-09-08T23:59:59"],
  ["1956-05-20T00:00:00", "1956-09-29T23:59:59"],
  ["1957-05-05T00:00:00", "1957-09-21T23:59:59"],
  ["1958-05-04T00:00:00", "1958-09-20T23:59:59"],
  ["1959-05-03T00:00:00", "1959-09-19T23:59:59"],
  ["1960-05-01T00:00:00", "1960-09-17T23:59:59"],
  ["1987-05-10T00:00:00", "1987-10-10T23:59:59"],
  ["1988-05-08T00:00:00", "1988-10-08T23:59:59"],
].map(([start, end]) => ({
  start: new Date(start),
  end: new Date(end),
}));

const monthTermBoundaries = [
  { month: 2, day: 4, index: 0 },
  { month: 3, day: 6, index: 1 },
  { month: 4, day: 5, index: 2 },
  { month: 5, day: 6, index: 3 },
  { month: 6, day: 6, index: 4 },
  { month: 7, day: 7, index: 5 },
  { month: 8, day: 8, index: 6 },
  { month: 9, day: 8, index: 7 },
  { month: 10, day: 8, index: 8 },
  { month: 11, day: 7, index: 9 },
  { month: 12, day: 7, index: 10 },
  { month: 1, day: 6, index: 11 },
];

function parseBirthTime(value?: string | null) {
  if (!value || value === "unknown") return { hour: 12, minute: 0 };

  const match = value.match(/^(\d{1,2})(?::(\d{2}))?$/);
  if (!match) return { hour: 12, minute: 0 };

  const hour = Number(match[1]);
  const minute = Number(match[2] ?? "0");

  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return { hour: 12, minute: 0 };
  }

  return { hour, minute };
}

function toDate(parts: DateParts) {
  return new Date(parts.year, parts.month - 1, parts.day, parts.hour, parts.minute);
}

function addMinutes(date: Date, minutes: number) {
  return new Date(date.getTime() + minutes * 60_000);
}

function normalizeCycle(index: number, length: number) {
  return ((index % length) + length) % length;
}

function applyDst(date: Date) {
  const isDst = dstPeriods.some(
    ({ start, end }) => date.getTime() >= start.getTime() && date.getTime() <= end.getTime(),
  );

  return isDst ? addMinutes(date, -60) : date;
}

function applyTrueSolarTime(date: Date, city: string) {
  const longitude = cityLongitude[city] ?? cityLongitude.default;
  const correctionMinutes = Math.round((135 - longitude) * 4);
  return addMinutes(date, -correctionMinutes);
}

function applyJasi(date: Date, useYaJasi: boolean) {
  if (useYaJasi || date.getHours() !== 23) return date;
  return new Date(date.getFullYear(), date.getMonth(), date.getDate() + 1, date.getHours(), date.getMinutes());
}

function calculateDayPillar(date: Date): Pillar {
  const targetUTC = Date.UTC(date.getFullYear(), date.getMonth(), date.getDate());
  const daysDiff = Math.floor((targetUTC - BASE_DATE_UTC) / DAY_MS);
  const dayIndex = normalizeCycle(BASE_DAY_INDEX + daysDiff, 60);

  return {
    gan: cheongan[dayIndex % 10],
    ji: jiji[dayIndex % 12],
  };
}

function getIpchunDate(year: number) {
  return new Date(year, 1, 4, 0, 0);
}

function calculateYearPillar(date: Date): Pillar {
  const year = date.getTime() < getIpchunDate(date.getFullYear()).getTime()
    ? date.getFullYear() - 1
    : date.getFullYear();
  const ganIndex = normalizeCycle(year - 4, 10);
  const jiIndex = normalizeCycle(year - 4, 12);

  return {
    gan: cheongan[ganIndex],
    ji: jiji[jiIndex],
  };
}

function getMonthPillarIndex(date: Date) {
  let selected = 11;
  for (const boundary of monthTermBoundaries) {
    const boundaryYear = boundary.month === 1 && date.getMonth() + 1 !== 1
      ? date.getFullYear() + 1
      : date.getFullYear();
    const boundaryDate = new Date(boundaryYear, boundary.month - 1, boundary.day, 0, 0);

    if (date.getTime() >= boundaryDate.getTime()) {
      selected = boundary.index;
    }
  }

  if (date.getMonth() === 0 && date.getDate() < 6) return 10;
  return selected;
}

function calculateMonthPillar(date: Date, yearPillar: Pillar): Pillar {
  const monthIndex = getMonthPillarIndex(date);
  const yearGanIndex = cheongan.indexOf(yearPillar.gan as (typeof cheongan)[number]);
  const monthGanStart = ((yearGanIndex % 5) * 2 + 2) % 10;
  const ganIndex = (monthGanStart + monthIndex) % 10;
  const jiIndex = (monthIndex + 2) % 12;

  return {
    gan: cheongan[ganIndex],
    ji: jiji[jiIndex],
  };
}

function calculateHourPillar(hour: number, dayPillar: Pillar): Pillar {
  const jiIndex = Math.floor((hour + 1) / 2) % 12;
  const dayGanIndex = cheongan.indexOf(dayPillar.gan as (typeof cheongan)[number]);
  const hourGanStart = (dayGanIndex % 5) * 2;
  const ganIndex = (hourGanStart + jiIndex) % 10;

  return {
    gan: cheongan[ganIndex],
    ji: jiji[jiIndex],
  };
}

export function resolveSadamIdentity(input: SajuResolveInput): SajuResolveResult {
  const parsed = parseBirthDate(input.birthDate) ?? parseBirthDate("19950101")!;
  const birthTimeUnknown = input.birthTimeUnknown || input.birthTime === "unknown";
  const time = parseBirthTime(input.birthTime);
  const warnings: string[] = [];
  const isLunarCalendar = input.calendar === "lunar";

  let calculationDateParts = parsed;
  if (isLunarCalendar) {
    const solarParts = lunarToSolar({
      year: parsed.year,
      month: parsed.month,
      day: parsed.day,
      isLeapMonth: input.isLeapMonth ?? false,
    });

    if (solarParts) {
      calculationDateParts = { ...solarParts, compact: input.birthDate.replace(/\D/g, "") };
    } else {
      warnings.push("지원 범위를 벗어나거나 유효하지 않은 음력 날짜라 입력일을 양력 기준으로 계산했습니다.");
    }
  }

  const originalDateTime = toDate({ ...calculationDateParts, ...time });
  const city = input.birthCity?.trim() || "서울";
  const dstAdjusted = applyDst(originalDateTime);
  const trueSolarTime = applyTrueSolarTime(dstAdjusted, city);
  const correctedDateTime = birthTimeUnknown
    ? toDate({ ...calculationDateParts, hour: 12, minute: 0 })
    : applyJasi(trueSolarTime, input.useYaJasi ?? true);
  const yearPillar = calculateYearPillar(correctedDateTime);
  const monthPillar = calculateMonthPillar(correctedDateTime, yearPillar);
  const dayPillar = calculateDayPillar(correctedDateTime);
  const hourPillar = birthTimeUnknown
    ? null
    : calculateHourPillar(correctedDateTime.getHours(), dayPillar);
  const identity = resolveIdentityFromGanji(dayPillar.gan, dayPillar.ji, "saju-corrected");
  const chart = { yearPillar, monthPillar, dayPillar, hourPillar };

  return {
    identity,
    ...chart,
    originalDateTime,
    correctedDateTime,
    calculationLabel: warnings.length > 0 ? "부분 보정 계산" : "정밀 계산 모드",
    warnings,
    analysis: buildSajuAnalysis(chart, {
      birthDateTime: correctedDateTime,
      birthYear: parsed.year,
      gender: input.gender === "male" ? "male" : "female",
    }),
  };
}
