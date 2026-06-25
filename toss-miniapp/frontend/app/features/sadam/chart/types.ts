import type { ZodiacIdentityLite } from "../personas";

export type Pillar = {
  gan: string;
  ji: string;
};

export type DateParts = {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
};

export type SajuChart = {
  yearPillar: Pillar;
  monthPillar: Pillar;
  dayPillar: Pillar;
  hourPillar: Pillar | null;
};

export type SajuAnalysisPayload = {
  ohengDistribution: Record<string, number>;
  dayStrength: Record<string, unknown>;
  yongsin: Record<string, unknown>;
  gyeokguk: Record<string, unknown>;
  sipsinInfo: Record<string, unknown>;
  jijangganInfo: Record<string, unknown>;
  sinsalList: Array<Record<string, unknown>>;
  daeun: Record<string, unknown>;
  currentSeun: Record<string, unknown>;
  twelveUnsung: Array<Record<string, unknown>>;
  twelveSinsal: Array<Record<string, unknown>>;
  gilseong: Record<string, unknown>;
  hapchung: Record<string, unknown>;
  gongmang: Record<string, unknown>;
};

export type SajuResolveResult = SajuChart & {
  identity: ZodiacIdentityLite;
  originalDateTime: Date;
  correctedDateTime: Date;
  calculationLabel: string;
  warnings: string[];
  analysis: SajuAnalysisPayload;
};
