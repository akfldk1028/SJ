import { Link, type MetaFunction, useLoaderData } from "react-router";
import {
  ArrowRightIcon,
  CalendarDaysIcon,
  HomeIcon,
  MessageCircleIcon,
} from "lucide-react";
import { Badge } from "~/common/components/ui/badge";
import { Button } from "~/common/components/ui/button";
import {
  ZodiacElementBackground,
  ZodiacRevealCard,
} from "../components/zodiac-widgets";
import { loadSadamProfile, type SadamProfileLoaderData } from "../data/route-loaders";

export const meta: MetaFunction = () => {
  return [{ title: "SaDam 수호동물 결과" }];
};

export const loader = loadSadamProfile;

function formatBirthDate(value: string) {
  return value.replaceAll("-", ".");
}

function readStringArray(value: unknown) {
  return Array.isArray(value)
    ? value.filter((item): item is string => typeof item === "string")
    : [];
}

export default function ResultPage() {
  const data = useLoaderData() as SadamProfileLoaderData;

  if (data.error || !data.profile || !data.calculation) {
    return (
      <ZodiacElementBackground elementName="화">
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

  const { profile, calculation } = data;
  const name = profile.display_name;
  const calendar = profile.is_lunar ? "음력" : "양력";
  const birthTime = profile.birth_time_unknown || profile.birth_time_minutes == null
    ? "시간 모름"
    : `${String(Math.floor(profile.birth_time_minutes / 60)).padStart(2, "0")}:${String(profile.birth_time_minutes % 60).padStart(2, "0")}`;
  const gender = profile.gender === "male" ? "남성" : "여성";
  const identity = calculation.identity;
  const query = data.query;
  const aiSummary = data.summary?.content;
  const personality = aiSummary?.personality &&
    typeof aiSummary.personality === "object"
    ? aiSummary.personality as Record<string, unknown>
    : null;
  const aiCore = typeof personality?.core === "string" ? personality.core : null;
  const aiStrengths = readStringArray(aiSummary?.strengths).slice(0, 3);

  return (
    <ZodiacElementBackground elementName={identity.elementName}>
      <div className="mx-auto flex min-h-screen w-full max-w-md flex-col px-5 py-6">
        <header className="flex items-start justify-between gap-3">
          <div>
            <p className="text-xs font-semibold uppercase text-white/65">
              Saju Analysis
            </p>
            <h1 className="mt-1 text-2xl font-bold text-white">
              {name}님의 사주 분석
            </h1>
          </div>
          <Button
            asChild
            className="size-10 shrink-0 rounded-md bg-white/10 p-0 text-white hover:bg-white/15"
            variant="ghost"
          >
            <Link aria-label="홈으로 가기" to="/">
              <HomeIcon className="size-5" />
            </Link>
          </Button>
        </header>

        <section className="mt-4 overflow-hidden rounded-lg border border-white/10 bg-white shadow-sm">
          <div className={identity.colorClass}>
            <ZodiacRevealCard
              elementName={identity.elementName}
              emoji={identity.animalEmoji}
              imageUrl={identity.largeImageUrl}
              fullName={identity.fullName}
              ganjiHanja={identity.ganjiHanja}
              subtitle={`${identity.title} · ${identity.tone}`}
            />
          </div>

          <div className="space-y-5 p-5">
            <div className="grid grid-cols-2 gap-2 text-sm">
              <div className="rounded-md bg-slate-100 p-3">
                <p className="text-xs font-semibold text-slate-500">생년월일</p>
                <p className="mt-1 font-bold">
                  {calendar} {formatBirthDate(profile.birth_date)}
                </p>
              </div>
              <div className="rounded-md bg-slate-100 p-3">
                <p className="text-xs font-semibold text-slate-500">시간/성별</p>
                <p className="mt-1 font-bold">
                  {birthTime} · {gender}
                </p>
              </div>
            </div>

            <p className="text-base leading-7">
              {identity.summary} {identity.modifier}
            </p>

            <div>
              <h3 className="text-sm font-semibold text-slate-600">
                핵심 키워드
              </h3>
              <div className="mt-2 flex flex-wrap gap-2">
                {identity.keywords.map((keyword) => (
                  <Badge
                    className="rounded-md bg-slate-100 text-slate-800"
                    key={keyword}
                  >
                    {keyword}
                  </Badge>
                ))}
              </div>
            </div>

            <div className="rounded-lg border border-sky-100 bg-sky-50 p-4">
              <div className="mb-2 flex items-center gap-2 text-sm font-semibold text-sky-800">
                <MessageCircleIcon className="size-4" />
                AI 분석 요약
              </div>
              {aiCore ? (
                <div className="space-y-3">
                  <p className="text-sm leading-6 text-sky-950">{aiCore}</p>
                  {aiStrengths.length > 0 ? (
                    <div className="flex flex-wrap gap-2">
                      {aiStrengths.map((strength) => (
                        <Badge
                          className="rounded-md bg-white text-sky-900"
                          key={strength}
                        >
                          {strength}
                        </Badge>
                      ))}
                    </div>
                  ) : null}
                </div>
              ) : (
                <p className="text-sm leading-6 text-sky-950">
                  AI 상세 요약을 준비하고 있습니다. 잠시 후 상세 분석에서 더 깊은 해석을 확인할 수 있습니다.
                </p>
              )}
            </div>

            <div className="rounded-lg border border-amber-200 bg-amber-50 p-4">
              <div className="mb-2 flex items-center gap-2 text-sm font-semibold text-amber-900">
                <CalendarDaysIcon className="size-4" />
                {calculation.calculationLabel}
              </div>
              <p className="text-sm leading-6 text-amber-950">
                일주는 {calculation.dayPillar.gan}{calculation.dayPillar.ji} 기준으로
                계산했습니다. {calculation.hourPillar
                  ? `시주는 ${calculation.hourPillar.gan}${calculation.hourPillar.ji}까지 반영했습니다.`
                  : "태어난 시간을 모르면 시주는 제외합니다."}
                {calculation.warnings.length > 0
                  ? ` ${calculation.warnings.join(" ")}`
                  : " 본앱 기준의 서머타임, 진태양시, 자시 보정을 적용했습니다."}
              </p>
            </div>
          </div>
        </section>

        <div className="mt-5 grid gap-3">
          <Button asChild className="h-12 rounded-md bg-white text-slate-950 hover:bg-white/90">
            <Link to={`/saju/chart?${query}`}>사주 차트 보기</Link>
          </Button>
          <Button asChild className="h-12 rounded-md bg-sky-600 text-white">
            <Link to={`/extra?${query}`}>
              광고 보고 추가 질문
              <ArrowRightIcon className="size-4" />
            </Link>
          </Button>
          <Button asChild className="h-12 rounded-md" variant="outline">
            <Link to={`/premium?${query}`}>상세 분석권 보기</Link>
          </Button>
        </div>
      </div>
    </ZodiacElementBackground>
  );
}
