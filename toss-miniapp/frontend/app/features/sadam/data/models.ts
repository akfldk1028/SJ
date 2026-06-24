import { cheongan, jiji, parseBirthDate } from "../personas";
import { resolveSadamIdentity, type SajuResolveResult } from "../saju-calculation";
import {
  cheonganHanja,
  cheonganOheng,
  jijiHanja,
  jijiOheng,
  zodiacAnimalByJi,
} from "../chart/constants";

export type GenderDb = "male" | "female";
export type CalendarDb = "solar" | "lunar";

export type ProfileFormValues = {
  displayName: string;
  gender: GenderDb;
  birthDate: string;
  calendar: CalendarDb;
  isLeapMonth: boolean;
  birthTime: string;
  birthCity: string;
  useYaJasi: boolean;
};

export type SajuProfileRow = {
  id: string;
  user_id: string;
  display_name: string;
  relation_type: string | null;
  memo: string | null;
  birth_date: string;
  birth_time_minutes: number | null;
  birth_time_unknown: boolean | null;
  is_lunar: boolean | null;
  is_leap_month: boolean | null;
  gender: GenderDb;
  birth_city: string;
  time_correction: number | null;
  use_ya_jasi: boolean | null;
  profile_type: "primary" | "other" | null;
  country_code: string | null;
  locale: string;
  zodiac_animal: string | null;
  zodiac_element: string | null;
  zodiac_ganji: string | null;
  created_at: string | null;
  updated_at: string | null;
};

export type SajuAnalysisRow = {
  id: string;
  profile_id: string;
  year_gan: string;
  year_ji: string;
  month_gan: string;
  month_ji: string;
  day_gan: string;
  day_ji: string;
  hour_gan: string | null;
  hour_ji: string | null;
  corrected_datetime: string | null;
  oheng_distribution: Record<string, number>;
  day_strength?: Record<string, unknown> | null;
  yongsin?: Record<string, unknown> | null;
  gyeokguk?: Record<string, unknown> | null;
  sipsin_info?: Record<string, unknown> | null;
  jijanggan_info?: Record<string, unknown> | null;
  sinsal_list?: Array<Record<string, unknown>> | null;
  daeun?: Record<string, unknown> | null;
  current_seun?: Record<string, unknown> | null;
  twelve_unsung?: Array<Record<string, unknown>> | null;
  twelve_sinsal?: Array<Record<string, unknown>> | null;
  gilseong?: Record<string, unknown> | null;
  hapchung?: Record<string, unknown> | null;
  calculated_at?: string | null;
  updated_at?: string | null;
};

export type AiSummaryRow = {
  id: string;
  user_id: string;
  profile_id: string;
  summary_type: string;
  content: Record<string, unknown>;
  input_data: Record<string, unknown> | null;
  model_provider: string | null;
  model_name: string | null;
  prompt_tokens: number | null;
  completion_tokens: number | null;
  total_tokens: number | null;
  cached_tokens: number | null;
  total_cost_usd: number | null;
  processing_time_ms: number | null;
  status: string | null;
  is_cached: boolean | null;
  prompt_version: string | null;
  locale: string;
  created_at: string | null;
  updated_at: string | null;
};

type SummaryPillar = {
  gan: string;
  ji: string;
  ganHanja?: string;
  jiHanja?: string;
};

export type GenerateSummaryInput = {
  saju: {
    year: SummaryPillar;
    month: SummaryPillar;
    day: SummaryPillar;
    hour: SummaryPillar;
  };
  oheng: {
    wood: number;
    fire: number;
    earth: number;
    metal: number;
    water: number;
  };
  yongsin?: {
    yongsin: string;
    huisin: string;
    gisin: string;
    gusin: string;
  };
  sipsin?: Record<string, string>;
  singang_singak?: {
    is_singang: boolean;
    score: number;
    factors: {
      deukryeong: boolean;
      deukji: boolean;
      deuksi: boolean;
      deukse: boolean;
    };
  };
};

function formatGan(value: string) {
  return `${value}(${cheonganHanja[value] ?? ""})`;
}

function formatJi(value: string) {
  return `${value}(${jijiHanja[value] ?? ""})`;
}

export function extractHangul(value: string | null | undefined) {
  if (!value) return "";
  const index = value.indexOf("(");
  return index >= 0 ? value.slice(0, index) : value;
}

function extractHanja(value: string | null | undefined) {
  if (!value) return undefined;
  const match = /\(([^)]+)\)/.exec(value);
  return match?.[1];
}

function toSummaryPillar(gan: string | null, ji: string | null): SummaryPillar {
  return {
    gan: extractHangul(gan) || "?",
    ji: extractHangul(ji) || "?",
    ganHanja: extractHanja(gan) ?? undefined,
    jiHanja: extractHanja(ji) ?? undefined,
  };
}

function readOhengCount(distribution: Record<string, number>, keys: string[]) {
  for (const key of keys) {
    const value = distribution[key];
    if (typeof value === "number") return value;
  }
  return 0;
}

function pickText(value: unknown) {
  return typeof value === "string" ? value : "";
}

function flattenSipsinInfo(value: Record<string, unknown> | null | undefined) {
  if (!value) return undefined;
  const result: Record<string, string> = {};

  for (const [key, raw] of Object.entries(value)) {
    if (typeof raw === "string") {
      result[key] = raw;
      continue;
    }
    if (!raw || typeof raw !== "object") continue;
    for (const [nestedKey, nestedRaw] of Object.entries(raw as Record<string, unknown>)) {
      if (typeof nestedRaw === "string") {
        result[`${key}_${nestedKey}`] = nestedRaw;
      }
    }
  }

  return Object.keys(result).length > 0 ? result : undefined;
}

export function toGenerateSummaryInput(analysis: SajuAnalysisRow): GenerateSummaryInput {
  const yongsin = analysis.yongsin ?? undefined;
  const dayStrength = analysis.day_strength ?? undefined;

  return {
    saju: {
      year: toSummaryPillar(analysis.year_gan, analysis.year_ji),
      month: toSummaryPillar(analysis.month_gan, analysis.month_ji),
      day: toSummaryPillar(analysis.day_gan, analysis.day_ji),
      hour: toSummaryPillar(analysis.hour_gan, analysis.hour_ji),
    },
    oheng: {
      wood: readOhengCount(analysis.oheng_distribution, ["wood", "mok", "목", "목(木)"]),
      fire: readOhengCount(analysis.oheng_distribution, ["fire", "hwa", "화", "화(火)"]),
      earth: readOhengCount(analysis.oheng_distribution, ["earth", "to", "토", "토(土)"]),
      metal: readOhengCount(analysis.oheng_distribution, ["metal", "geum", "금", "금(金)"]),
      water: readOhengCount(analysis.oheng_distribution, ["water", "su", "수", "수(水)"]),
    },
    yongsin: yongsin
      ? {
          yongsin: pickText(yongsin.yongsin),
          huisin: pickText(yongsin.huisin ?? yongsin.heesin),
          gisin: pickText(yongsin.gisin),
          gusin: pickText(yongsin.gusin),
        }
      : undefined,
    sipsin: flattenSipsinInfo(analysis.sipsin_info),
    singang_singak: dayStrength
      ? {
          is_singang: Boolean(dayStrength.isStrong ?? dayStrength.is_singang),
          score: Number(dayStrength.score ?? 50),
          factors: {
            deukryeong: Boolean(dayStrength.deukryeong),
            deukji: Boolean(dayStrength.deukji),
            deuksi: Boolean(dayStrength.deuksi),
            deukse: Boolean(dayStrength.deukse),
          },
        }
      : undefined,
  };
}

export function parseBirthTimeMinutes(value: string) {
  if (!value || value === "unknown") return null;
  const [hourText, minuteText = "0"] = value.split(":");
  const hour = Number(hourText);
  const minute = Number(minuteText);
  if (!Number.isInteger(hour) || !Number.isInteger(minute)) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return hour * 60 + minute;
}

export function birthDateToIsoDate(value: string) {
  const parsed = parseBirthDate(value);
  if (!parsed) throw new Error("생년월일은 YYYYMMDD 형식이어야 합니다.");
  return `${parsed.year}-${String(parsed.month).padStart(2, "0")}-${String(parsed.day).padStart(2, "0")}`;
}

export function parseProfileForm(formData: FormData): ProfileFormValues {
  const displayName = String(formData.get("name") ?? "").trim();
  const birthDate = String(formData.get("birthDate") ?? "").trim();
  const calendar = formData.get("calendar") === "lunar" ? "lunar" : "solar";
  const birthTime = String(formData.get("birthTime") ?? "unknown");
  const gender = formData.get("gender") === "male" ? "male" : "female";
  const birthCity = String(formData.get("birthCity") ?? "서울").trim() || "서울";
  const useYaJasiValues = formData.getAll("useYaJasi").map(String);

  if (!displayName || displayName.length > 12) {
    throw new Error("이름은 1자 이상 12자 이하로 입력해 주세요.");
  }

  const parsed = parseBirthDate(birthDate);
  if (!parsed) throw new Error("생년월일은 YYYYMMDD 형식으로 입력해 주세요.");

  const date = new Date(parsed.year, parsed.month - 1, parsed.day);
  const now = new Date();
  if (parsed.year < 1900 || date.getTime() > now.getTime()) {
    throw new Error("생년월일은 1900년 이후, 오늘 이전 날짜여야 합니다.");
  }

  return {
    displayName,
    gender,
    birthDate,
    calendar,
    isLeapMonth: formData.get("isLeapMonth") === "on",
    birthTime,
    birthCity,
    useYaJasi: useYaJasiValues.includes("on"),
  };
}

export function calculateOhengDistribution(calculation: SajuResolveResult) {
  return calculation.analysis.ohengDistribution;
}

export function toProfileInsert(
  id: string,
  userId: string,
  values: ProfileFormValues,
  calculation: SajuResolveResult,
) {
  const now = new Date().toISOString();
  const birthTimeMinutes = parseBirthTimeMinutes(values.birthTime);

  return {
    id,
    user_id: userId,
    display_name: values.displayName,
    relation_type: "me",
    memo: null,
    birth_date: birthDateToIsoDate(values.birthDate),
    birth_time_minutes: birthTimeMinutes,
    birth_time_unknown: birthTimeMinutes == null,
    is_lunar: values.calendar === "lunar",
    is_leap_month: values.isLeapMonth,
    gender: values.gender,
    birth_city: values.birthCity,
    time_correction: 0,
    use_ya_jasi: values.useYaJasi,
    profile_type: "primary",
    country_code: "KR",
    locale: "ko",
    zodiac_animal: zodiacAnimalByJi[calculation.dayPillar.ji] ?? "tiger",
    zodiac_element: cheonganOheng[calculation.dayPillar.gan] ?? "earth",
    zodiac_ganji: `${calculation.dayPillar.gan}${calculation.dayPillar.ji}`,
    created_at: now,
    updated_at: now,
  };
}

export function toAnalysisUpsert(
  id: string,
  profileId: string,
  calculation: SajuResolveResult,
) {
  const now = new Date().toISOString();

  return {
    id,
    profile_id: profileId,
    year_gan: formatGan(calculation.yearPillar.gan),
    year_ji: formatJi(calculation.yearPillar.ji),
    month_gan: formatGan(calculation.monthPillar.gan),
    month_ji: formatJi(calculation.monthPillar.ji),
    day_gan: formatGan(calculation.dayPillar.gan),
    day_ji: formatJi(calculation.dayPillar.ji),
    hour_gan: calculation.hourPillar ? formatGan(calculation.hourPillar.gan) : null,
    hour_ji: calculation.hourPillar ? formatJi(calculation.hourPillar.ji) : null,
    corrected_datetime: calculation.correctedDateTime.toISOString(),
    oheng_distribution: calculateOhengDistribution(calculation),
    day_strength: calculation.analysis.dayStrength,
    yongsin: calculation.analysis.yongsin,
    gyeokguk: calculation.analysis.gyeokguk,
    sipsin_info: calculation.analysis.sipsinInfo,
    jijanggan_info: calculation.analysis.jijangganInfo,
    sinsal_list: null,
    daeun: null,
    current_seun: null,
    twelve_unsung: null,
    twelve_sinsal: null,
    gilseong: null,
    hapchung: calculation.analysis.hapchung,
    calculated_at: now,
    updated_at: now,
  };
}

export function resolveCalculationFromProfile(profile: SajuProfileRow) {
  const compactBirthDate = profile.birth_date.replaceAll("-", "");
  const birthTime = profile.birth_time_unknown || profile.birth_time_minutes == null
    ? "unknown"
    : `${String(Math.floor(profile.birth_time_minutes / 60)).padStart(2, "0")}:${String(profile.birth_time_minutes % 60).padStart(2, "0")}`;

  return resolveSadamIdentity({
    birthDate: compactBirthDate,
    birthTime,
    birthTimeUnknown: profile.birth_time_unknown ?? false,
    calendar: profile.is_lunar ? "lunar" : "solar",
    birthCity: profile.birth_city,
    useYaJasi: profile.use_ya_jasi ?? true,
  });
}

export { cheongan, jiji, jijiOheng as zodiacElementByJi };
