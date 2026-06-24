import { Link, type MetaFunction, useSearchParams } from "react-router";
import {
  ArrowRightIcon,
  CalendarDaysIcon,
  MessageCircleIcon,
} from "lucide-react";
import { Badge } from "~/common/components/ui/badge";
import { Button } from "~/common/components/ui/button";
import {
  ZodiacElementBackground,
  ZodiacRevealCard,
} from "../components/zodiac-widgets";
import { resolveSadamIdentity } from "../saju-calculation";
import { parseBirthDate } from "../personas";

export const meta: MetaFunction = () => {
  return [{ title: "SaDam 수호동물 결과" }];
};

function formatBirthDate(value: string) {
  const parsed = parseBirthDate(value);
  if (!parsed) return "1995.01.01";
  return `${parsed.year}.${String(parsed.month).padStart(2, "0")}.${String(
    parsed.day,
  ).padStart(2, "0")}`;
}

export default function ResultPage() {
  const [searchParams] = useSearchParams();
  const name = searchParams.get("name") || "나";
  const birthDate = searchParams.get("birthDate") || "19950101";
  const calendar = searchParams.get("calendar") === "lunar" ? "음력" : "양력";
  const birthTime = searchParams.get("birthTime") || "unknown";
  const gender = searchParams.get("gender") === "male" ? "남성" : "여성";
  const calculation = resolveSadamIdentity({
    birthDate,
    birthTime,
    birthTimeUnknown: birthTime === "unknown",
    calendar: searchParams.get("calendar"),
    birthCity: searchParams.get("birthCity"),
  });
  const identity = calculation.identity;
  const query = searchParams.toString();

  return (
    <ZodiacElementBackground elementName={identity.elementName}>
      <div className="mx-auto flex min-h-screen w-full max-w-md flex-col px-5 py-6">
        <header>
          <p className="text-xs font-semibold uppercase text-white/65">
            Guardian Animal Card
          </p>
          <h1 className="mt-1 text-2xl font-bold text-white">
            {name}님의 수호동물
          </h1>
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
                  {calendar} {formatBirthDate(birthDate)}
                </p>
              </div>
              <div className="rounded-md bg-slate-100 p-3">
                <p className="text-xs font-semibold text-slate-500">시간/성별</p>
                <p className="mt-1 font-bold">
                  {birthTime === "unknown" ? "시간 모름" : birthTime} · {gender}
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
                기본 사주 정보
              </div>
              <p className="text-sm leading-6 text-sky-950">{identity.advice}</p>
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
