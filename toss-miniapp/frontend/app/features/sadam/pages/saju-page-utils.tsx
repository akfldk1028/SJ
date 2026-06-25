import { Link, useLocation } from "react-router";
import {
  ArrowLeftIcon,
  CalendarDaysIcon,
  GitBranchIcon,
  HomeIcon,
  MessageCircleIcon,
  SparklesIcon,
} from "lucide-react";
import { Badge } from "~/common/components/ui/badge";
import { Button } from "~/common/components/ui/button";
import {
  cheonganHanja,
  cheonganOheng,
  jijiHanja,
  jijiOheng,
  ohengKorean,
  type OhengKey,
} from "../chart/constants";
import {
  ZodiacElementBackground,
} from "../components/zodiac-widgets";
import type { SadamProfileLoaderData } from "../data/route-loaders";
import type { SajuResolveResult } from "../saju-calculation";

export const ohengStyle: Record<OhengKey, { label: string; bg: string; text: string; border: string }> = {
  wood: { label: "목", bg: "bg-emerald-500", text: "text-emerald-950", border: "border-emerald-200" },
  fire: { label: "화", bg: "bg-red-500", text: "text-red-950", border: "border-red-200" },
  earth: { label: "토", bg: "bg-amber-500", text: "text-amber-950", border: "border-amber-200" },
  metal: { label: "금", bg: "bg-zinc-400", text: "text-zinc-950", border: "border-zinc-200" },
  water: { label: "수", bg: "bg-sky-500", text: "text-sky-950", border: "border-sky-200" },
};

export function ErrorState({ data }: { data: SadamProfileLoaderData }) {
  return (
    <ZodiacElementBackground elementName="earth">
      <div className="mx-auto flex min-h-screen w-full max-w-md flex-col justify-center px-5 py-6">
        <section className="rounded-lg bg-white p-5 text-slate-950">
          <h1 className="text-xl font-bold">프로필을 불러오지 못했습니다</h1>
          <p className="mt-2 text-sm leading-6 text-slate-600">
            {data.error ?? "프로필 정보가 없습니다. 다시 입력해 주세요."}
          </p>
          <Button asChild className="mt-5 h-12 w-full rounded-md bg-sky-600 text-white">
            <Link to="/">다시 입력하기</Link>
          </Button>
        </section>
      </div>
    </ZodiacElementBackground>
  );
}

export function PageShell({
  calculation,
  title,
  eyebrow,
  children,
}: {
  calculation: SajuResolveResult;
  title: string;
  eyebrow: string;
  children: React.ReactNode;
}) {
  const location = useLocation();
  const query = new URLSearchParams(location.search).toString();

  return (
    <ZodiacElementBackground elementName={calculation.identity.elementName}>
      <div className="mx-auto flex min-h-screen w-full max-w-md flex-col px-5 py-6 text-white">
        <header className="flex items-start justify-between gap-3">
          <div>
            <p className="text-xs font-semibold uppercase text-white/65">{eyebrow}</p>
            <h1 className="mt-1 text-2xl font-bold">{title}</h1>
          </div>
          <div className="flex shrink-0 gap-2">
            <Button asChild className="size-10 rounded-md bg-white/10 p-0 text-white hover:bg-white/15" variant="ghost">
              <Link aria-label="결과로 돌아가기" to={`/result?${query}`}>
                <ArrowLeftIcon className="size-5" />
              </Link>
            </Button>
            <Button asChild className="size-10 rounded-md bg-white/10 p-0 text-white hover:bg-white/15" variant="ghost">
              <Link aria-label="홈으로 가기" to="/">
                <HomeIcon className="size-5" />
              </Link>
            </Button>
          </div>
        </header>
        {children}
      </div>
    </ZodiacElementBackground>
  );
}

export function ProfileSummary({
  data,
}: {
  data: Extract<SadamProfileLoaderData, { error: null }>;
}) {
  const birthTime = data.profile.birth_time_unknown || data.profile.birth_time_minutes == null
    ? "시간 모름"
    : `${String(Math.floor(data.profile.birth_time_minutes / 60)).padStart(2, "0")}:${String(data.profile.birth_time_minutes % 60).padStart(2, "0")}`;

  return (
    <section className="mt-5 rounded-lg border border-white/10 bg-white p-4 text-slate-950">
      <div className="flex items-center gap-3">
        <div className={`flex size-12 items-center justify-center rounded-md ${data.calculation.identity.colorClass} text-xl`}>
          {data.calculation.identity.animalEmoji}
        </div>
        <div className="min-w-0">
          <h2 className="truncate text-lg font-bold">{data.profile.display_name}</h2>
          <p className="text-sm text-slate-600">
            {data.profile.is_lunar ? "음력" : "양력"} {data.profile.birth_date.replaceAll("-", ".")} · {birthTime}
          </p>
        </div>
      </div>
    </section>
  );
}

export function PillarCard({
  label,
  gan,
  ji,
  isDayMaster,
}: {
  label: string;
  gan: string;
  ji: string;
  isDayMaster?: boolean;
}) {
  const ganElement = cheonganOheng[gan] ?? "earth";
  const jiElement = jijiOheng[ji] ?? "earth";

  return (
    <div className={`min-w-0 rounded-lg border ${isDayMaster ? "border-sky-300 bg-sky-50" : "border-slate-200 bg-white"} p-3 text-center`}>
      <p className="text-xs font-semibold text-slate-500">{label}</p>
      <div className="mt-3 grid grid-cols-1 gap-2">
        <StemBranchBox value={gan} hanja={cheonganHanja[gan]} element={ganElement} />
        <StemBranchBox value={ji} hanja={jijiHanja[ji]} element={jiElement} />
      </div>
    </div>
  );
}

function StemBranchBox({
  value,
  hanja,
  element,
}: {
  value: string;
  hanja?: string;
  element: OhengKey;
}) {
  return (
    <div className={`rounded-md border ${ohengStyle[element].border} bg-slate-50 px-2 py-2`}>
      <p className="text-xl font-bold text-slate-950">{hanja ?? value}</p>
      <p className="text-xs text-slate-600">{value} · {ohengKorean[element]}</p>
    </div>
  );
}

export function SajuNavButtons({ query }: { query: string }) {
  return (
    <div className="mt-5 grid grid-cols-3 gap-2">
      <Button asChild className="h-11 rounded-md bg-white text-slate-950 hover:bg-white/90">
        <Link to={`/saju/detail?${query}`}>
          <SparklesIcon className="size-4" />
          상세
        </Link>
      </Button>
      <Button asChild className="h-11 rounded-md bg-white/10 text-white hover:bg-white/15">
        <Link to={`/saju/graph?${query}`}>
          <GitBranchIcon className="size-4" />
          그래프
        </Link>
      </Button>
      <Button asChild className="h-11 rounded-md bg-white/10 text-white hover:bg-white/15">
        <Link to={`/saju/chat?${query}`}>
          <MessageCircleIcon className="size-4" />
          상담
        </Link>
      </Button>
    </div>
  );
}

export function ReadonlyJsonCard({
  title,
  value,
}: {
  title: string;
  value: unknown;
}) {
  if (value == null) {
    return (
      <section className="rounded-lg border border-slate-200 bg-white p-4 text-slate-950">
        <h3 className="text-sm font-bold">{title}</h3>
        <p className="mt-2 text-sm text-slate-500">아직 저장된 분석 데이터가 없습니다.</p>
      </section>
    );
  }

  return (
    <section className="rounded-lg border border-slate-200 bg-white p-4 text-slate-950">
      <h3 className="text-sm font-bold">{title}</h3>
      <pre className="mt-3 max-h-72 overflow-auto rounded-md bg-slate-950 p-3 text-xs leading-5 text-slate-100">
        {JSON.stringify(value, null, 2)}
      </pre>
    </section>
  );
}

export function InfoCard({
  id,
  title,
  children,
}: {
  id?: string;
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section id={id} className="scroll-mt-28 rounded-lg border border-slate-200 bg-white p-4 text-slate-950">
      <h3 className="text-sm font-bold">{title}</h3>
      <div className="mt-3">{children}</div>
    </section>
  );
}

export function MetricRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between gap-3 border-b border-slate-100 py-2 last:border-b-0">
      <span className="text-sm text-slate-500">{label}</span>
      <span className="text-right text-sm font-semibold text-slate-900">{value}</span>
    </div>
  );
}

export function getRecord(value: unknown): Record<string, unknown> | null {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

export function getArray(value: unknown): Array<Record<string, unknown>> {
  return Array.isArray(value)
    ? value.filter((item): item is Record<string, unknown> => Boolean(item) && typeof item === "object")
    : [];
}

export function getText(value: unknown, fallback = "-") {
  if (typeof value === "string" && value.length > 0) return value;
  if (typeof value === "number" || typeof value === "boolean") return String(value);
  return fallback;
}

export function ElementDistribution({ distribution }: { distribution: Record<string, number> | undefined }) {
  const keys: OhengKey[] = ["wood", "fire", "earth", "metal", "water"];
  const values = keys.map((key) => ({
    key,
    value: distribution?.[key] ?? distribution?.[`${ohengKorean[key]}(${key})`] ?? 0,
  }));
  const total = values.reduce((sum, item) => sum + item.value, 0);
  const strongest = values.reduce((current, item) => item.value > current.value ? item : current, values[0]);
  const weakest = values.reduce((current, item) => item.value < current.value ? item : current, values[0]);
  const missing = values.filter((item) => item.value === 0);
  const getStatus = (value: number) => {
    const percentage = total > 0 ? (value / total) * 100 : 0;
    if (percentage >= 30) return "과다";
    if (percentage >= 20) return "발달";
    if (percentage >= 10) return "적정";
    return "부족";
  };

  return (
    <section className="rounded-lg border border-slate-200 bg-white p-4 text-slate-950">
      <div className="mb-3 flex items-center gap-2">
        <CalendarDaysIcon className="size-4 text-sky-600" />
        <h3 className="text-sm font-bold">오행 분포</h3>
      </div>
      <div className="mb-3 grid grid-cols-3 gap-2">
        <div className="rounded-md bg-slate-100 p-2">
          <p className="text-[11px] font-semibold text-slate-500">총량</p>
          <p className="mt-1 text-sm font-bold text-slate-950">{total}개</p>
        </div>
        <div className="rounded-md bg-slate-100 p-2">
          <p className="text-[11px] font-semibold text-slate-500">강한 오행</p>
          <p className="mt-1 text-sm font-bold text-slate-950">{ohengKorean[strongest.key]}</p>
        </div>
        <div className="rounded-md bg-slate-100 p-2">
          <p className="text-[11px] font-semibold text-slate-500">부족 오행</p>
          <p className="mt-1 truncate text-sm font-bold text-slate-950">
            {missing.length > 0 ? missing.map((item) => ohengKorean[item.key]).join(", ") : ohengKorean[weakest.key]}
          </p>
        </div>
      </div>
      <div className="grid grid-cols-5 gap-2">
        {values.map(({ key, value }) => {
          const percentage = total > 0 ? Math.round((value / total) * 100) : 0;
          return (
            <div className="rounded-md bg-slate-100 p-2 text-center" key={key}>
              <div className={`mx-auto mb-2 size-3 rounded-full ${ohengStyle[key].bg}`} />
              <p className="text-xs font-semibold text-slate-600">{ohengKorean[key]}</p>
              <p className="text-lg font-bold">{value}</p>
              <p className="text-[10px] text-slate-500">{percentage}%</p>
              <p className="mt-1 text-[10px] font-semibold text-slate-600">{getStatus(value)}</p>
            </div>
          );
        })}
      </div>
    </section>
  );
}

export function SimpleBadgeList({ values }: { values: string[] }) {
  return (
    <div className="flex flex-wrap gap-2">
      {values.map((value) => (
        <Badge className="rounded-md bg-slate-100 text-slate-800" key={value}>
          {value}
        </Badge>
      ))}
    </div>
  );
}
