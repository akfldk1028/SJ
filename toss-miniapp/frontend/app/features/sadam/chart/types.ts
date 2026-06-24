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
  hapchung: Record<string, unknown>;
};

export type SajuResolveResult = SajuChart & {
  identity: ZodiacIdentityLite;
  originalDateTime: Date;
  correctedDateTime: Date;
  calculationLabel: string;
  warnings: string[];
  analysis: SajuAnalysisPayload;
};
