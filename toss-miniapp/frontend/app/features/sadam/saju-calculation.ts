import {
  cheongan,
  jiji,
  parseBirthDate,
  resolveIdentityFromBirthDate,
  resolveIdentityFromGanji,
  type CalendarType,
  type ZodiacIdentityLite,
} from "./personas";

type DateParts = {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
};

type Pillar = {
  gan: string;
  ji: string;
};

export type SajuResolveInput = {
  birthDate: string;
  birthTime?: string | null;
  birthTimeUnknown?: boolean;
  calendar?: CalendarType | string | null;
  birthCity?: string | null;
  useYaJasi?: boolean;
};

export type SajuResolveResult = {
  identity: ZodiacIdentityLite;
  dayPillar: Pillar;
  hourPillar: Pillar | null;
  originalDateTime: Date;
  correctedDateTime: Date;
  calculationLabel: string;
  warnings: string[];
};

const DAY_MS = 86_400_000;
const BASE_DAY_INDEX = 10;
const BASE_DATE_UTC = Date.UTC(1900, 0, 1);

const cityLongitude: Record<string, number> = {
  "서울": 126.98,
  "서울특별시": 126.98,
  "부산": 129.03,
  "부산광역시": 129.03,
  "대구": 128.6,
  "대구광역시": 128.6,
  "인천": 126.7,
  "인천광역시": 126.7,
  "광주": 126.85,
  "광주광역시": 126.85,
  "대전": 127.38,
  "대전광역시": 127.38,
  "울산": 129.31,
  "울산광역시": 129.31,
  "세종": 127.29,
  "세종특별자치시": 127.29,
  "제주": 126.53,
  "제주특별자치도": 126.53,
  "default": 127,
};

const cityStandardMeridian: Record<string, number> = {
  "서울": 135,
  "서울특별시": 135,
  "부산": 135,
  "부산광역시": 135,
  "대구": 135,
  "대구광역시": 135,
  "인천": 135,
  "인천광역시": 135,
  "광주": 135,
  "광주광역시": 135,
  "대전": 135,
  "대전광역시": 135,
  "울산": 135,
  "울산광역시": 135,
  "세종": 135,
  "세종특별자치시": 135,
  "제주": 135,
  "제주특별자치도": 135,
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
  const meridian = cityStandardMeridian[city] ?? 135;
  const correctionMinutes = Math.round((meridian - longitude) * 4);
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

  if (input.calendar === "lunar") {
    warnings.push("음력 변환 테이블은 아직 본앱 Dart 모듈에만 있어 양력 날짜로 계산했습니다.");
  }

  const originalDateTime = toDate({ ...parsed, ...time });
  const city = input.birthCity?.trim() || "서울";
  const dstAdjusted = applyDst(originalDateTime);
  const trueSolarTime = applyTrueSolarTime(dstAdjusted, city);
  const correctedDateTime = birthTimeUnknown
    ? toDate({ ...parsed, hour: 12, minute: 0 })
    : applyJasi(trueSolarTime, input.useYaJasi ?? true);
  const dayPillar = calculateDayPillar(correctedDateTime);
  const hourPillar = birthTimeUnknown
    ? null
    : calculateHourPillar(correctedDateTime.getHours(), dayPillar);
  const identity = input.calendar === "lunar"
    ? resolveIdentityFromBirthDate(input.birthDate)
    : resolveIdentityFromGanji(dayPillar.gan, dayPillar.ji, "saju-corrected");

  return {
    identity,
    dayPillar,
    hourPillar,
    originalDateTime,
    correctedDateTime,
    calculationLabel: warnings.length > 0
      ? "부분 정밀 계산"
      : "정밀 계산 모드",
    warnings,
  };
}
