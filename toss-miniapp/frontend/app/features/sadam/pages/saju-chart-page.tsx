import { Link, type MetaFunction, useLoaderData } from "react-router";
import { ArrowRightIcon, SparklesIcon } from "lucide-react";
import { Button } from "~/common/components/ui/button";
import { loadSadamProfile, type SadamProfileLoaderData } from "../data/route-loaders";
import {
  ElementDistribution,
  ErrorState,
  PageShell,
  PillarCard,
  ProfileSummary,
  SajuNavButtons,
} from "./saju-page-utils";

export const meta: MetaFunction = () => [{ title: "SaDam 사주 차트" }];
export const loader = loadSadamProfile;

export default function SajuChartPage() {
  const data = useLoaderData() as SadamProfileLoaderData;
  if (data.error || !data.profile || !data.calculation) return <ErrorState data={data} />;

  const { calculation } = data;

  return (
    <PageShell calculation={calculation} eyebrow="Saju Chart" title="만세력 사주 차트">
      <ProfileSummary data={data} />

      <section className="mt-5 overflow-hidden rounded-lg border border-white/15 bg-white/[0.96] text-slate-950 shadow-2xl shadow-black/20">
        <div className="border-b border-slate-200 bg-slate-950 px-4 py-4 text-center text-white">
          <div className="flex items-center justify-center gap-2">
            <SparklesIcon className="size-4 text-amber-300" />
            <p className="text-sm font-bold">사주팔자</p>
            <SparklesIcon className="size-4 text-amber-300" />
          </div>
          <p className="mt-2 text-base font-bold tracking-[0.22em] text-white/80">
            {calculation.hourPillar ? `${calculation.hourPillar.gan}${calculation.hourPillar.ji} ` : ""}
            {calculation.dayPillar.gan}{calculation.dayPillar.ji} {calculation.monthPillar.gan}{calculation.monthPillar.ji} {calculation.yearPillar.gan}{calculation.yearPillar.ji}
          </p>
        </div>
        <div className="grid grid-cols-4 gap-0 px-3 py-4">
          {calculation.hourPillar ? (
            <PillarCard label="시주" gan={calculation.hourPillar.gan} ji={calculation.hourPillar.ji} />
          ) : (
            <div className="mx-1 min-w-0 rounded-lg border border-dashed border-slate-300 bg-slate-50 px-2 py-3 text-center">
              <p className="text-[11px] font-bold text-slate-500">시주</p>
              <div className="mt-2 flex h-[7.6rem] items-center justify-center rounded-md bg-white text-xs font-bold leading-5 text-slate-500 ring-1 ring-slate-200">
                시간<br />모름
              </div>
            </div>
          )}
          <div className="mx-1"><PillarCard isDayMaster label="일주 · 나" gan={calculation.dayPillar.gan} ji={calculation.dayPillar.ji} /></div>
          <div className="mx-1"><PillarCard label="월주" gan={calculation.monthPillar.gan} ji={calculation.monthPillar.ji} /></div>
          <div className="mx-1"><PillarCard label="연주" gan={calculation.yearPillar.gan} ji={calculation.yearPillar.ji} /></div>
        </div>
      </section>

      <div className="mt-5">
        <ElementDistribution distribution={data.analysis?.oheng_distribution ?? calculation.analysis.ohengDistribution} />
      </div>

      <section className="mt-5 rounded-lg border border-white/15 bg-white/[0.96] p-4 text-slate-950 shadow-xl shadow-black/10">
        <h3 className="text-sm font-bold">나의 일간 · {calculation.dayPillar.gan}</h3>
        <p className="mt-2 text-sm leading-6 text-slate-700">
          {calculation.dayPillar.gan} 일간은 이 차트의 기준점입니다. 상세 분석에서는 이 일간을 기준으로
          십신, 지장간, 신강약, 용신을 해석합니다.
        </p>
      </section>

      <SajuNavButtons query={data.query} />

      <Button asChild className="mt-3 h-12 rounded-md bg-sky-500 text-white hover:bg-sky-400">
        <Link to={`/saju/chat?${data.query}`}>
          AI 상담 시작
          <ArrowRightIcon className="size-4" />
        </Link>
      </Button>
    </PageShell>
  );
}
