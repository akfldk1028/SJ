import { Link, type MetaFunction, useLoaderData } from "react-router";
import { ArrowRightIcon } from "lucide-react";
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

      <section className="mt-5 rounded-lg border border-white/10 bg-white p-4 text-slate-950">
        <div className="mb-4 text-center">
          <p className="text-sm font-semibold text-slate-500">사주팔자</p>
          <p className="mt-1 text-lg font-bold tracking-[0.25em]">
            {calculation.hourPillar ? `${calculation.hourPillar.gan}${calculation.hourPillar.ji} ` : ""}
            {calculation.dayPillar.gan}{calculation.dayPillar.ji} {calculation.monthPillar.gan}{calculation.monthPillar.ji} {calculation.yearPillar.gan}{calculation.yearPillar.ji}
          </p>
        </div>
        <div className="grid grid-cols-4 gap-2">
          {calculation.hourPillar ? (
            <PillarCard label="시주" gan={calculation.hourPillar.gan} ji={calculation.hourPillar.ji} />
          ) : (
            <div className="rounded-lg border border-dashed border-slate-300 bg-slate-50 p-3 text-center">
              <p className="text-xs font-semibold text-slate-500">시주</p>
              <p className="mt-8 text-sm font-bold text-slate-500">시간 모름</p>
            </div>
          )}
          <PillarCard isDayMaster label="일주" gan={calculation.dayPillar.gan} ji={calculation.dayPillar.ji} />
          <PillarCard label="월주" gan={calculation.monthPillar.gan} ji={calculation.monthPillar.ji} />
          <PillarCard label="연주" gan={calculation.yearPillar.gan} ji={calculation.yearPillar.ji} />
        </div>
      </section>

      <div className="mt-5">
        <ElementDistribution distribution={data.analysis?.oheng_distribution ?? calculation.analysis.ohengDistribution} />
      </div>

      <section className="mt-5 rounded-lg border border-white/10 bg-white p-4 text-slate-950">
        <h3 className="text-sm font-bold">나의 일간</h3>
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
