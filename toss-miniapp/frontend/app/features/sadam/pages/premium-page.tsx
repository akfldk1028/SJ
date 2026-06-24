import { useState } from "react";
import { Link, type MetaFunction, useLoaderData } from "react-router";
import { CheckIcon, CreditCardIcon, LockKeyholeIcon } from "lucide-react";
import { Badge } from "~/common/components/ui/badge";
import { Button } from "~/common/components/ui/button";
import {
  ZodiacElementBackground,
  ZodiacRevealCard,
} from "../components/zodiac-widgets";
import { loadSadamProfile, type SadamProfileLoaderData } from "../data/route-loaders";
import { requestPremiumPurchase } from "../toss-adapters";

export const meta: MetaFunction = () => {
  return [{ title: "SaDam 상세 분석권" }];
};

export const loader = loadSadamProfile;

const premiumItems = [
  "수호동물 상세 리포트",
  "음력/진태양시/자시 보정 정밀 분석",
  "AI 캐릭터 코치의 실행 조언",
];

export default function PremiumPage() {
  const data = useLoaderData() as SadamProfileLoaderData;
  const [status, setStatus] = useState<"idle" | "loading" | "done">("idle");
  const [message, setMessage] = useState("");

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

  const name = data.profile.display_name;
  const identity = data.calculation.identity;

  const handlePurchase = async () => {
    setStatus("loading");
    const result = await requestPremiumPurchase();
    setMessage(result.message);
    setStatus("done");
  };

  return (
    <ZodiacElementBackground elementName={identity.elementName}>
      <div className="mx-auto flex min-h-screen w-full max-w-md flex-col px-5 py-6">
        <header>
          <p className="text-xs font-semibold uppercase text-white/65">
            Premium Analysis
          </p>
          <h1 className="mt-1 text-2xl font-bold">상세 분석권</h1>
        </header>

        <section className="mt-6 overflow-hidden rounded-lg border border-white/10 bg-white/[0.06]">
          <div className={identity.colorClass}>
            <ZodiacRevealCard
              elementName={identity.elementName}
              emoji={identity.animalEmoji}
              imageUrl={identity.largeImageUrl}
              fullName={identity.fullName}
              ganjiHanja={identity.ganjiHanja}
              subtitle={`${name}님 전용 상세 분석`}
            />
          </div>

          <div className="p-5">
          <div className="flex items-center justify-between">
            <div className="rounded-md bg-white/10 p-2">
              <LockKeyholeIcon className="size-5" />
            </div>
            <Badge className="rounded-md bg-white/10 text-white">Mock IAP</Badge>
          </div>

          <h2 className="mt-8 text-2xl font-bold">
            {name}님 전용 AI 분석을 더 깊게 확인하세요
          </h2>
          <p className="mt-2 text-sm leading-6 text-slate-300">
            토스 미니앱에서는 앱인토스 결제 정책에 맞는 디지털 분석권으로
            연결할 수 있게 결제 어댑터를 분리해 둡니다.
          </p>

          <div className="mt-5 space-y-3">
            {premiumItems.map((item) => (
              <div className="flex items-center gap-3 text-sm" key={item}>
                <span className="rounded-full bg-emerald-400 p-1 text-slate-950">
                  <CheckIcon className="size-3" />
                </span>
                {item}
              </div>
            ))}
          </div>

          {status === "done" ? (
            <div className="mt-6 rounded-lg bg-emerald-400/10 p-4 text-sm leading-6 text-emerald-100">
              {message} 실제 앱인토스 연동 시 이 위치에서 구매 완료 이벤트를
              확인합니다.
            </div>
          ) : (
            <Button
              className="mt-6 h-12 w-full rounded-md bg-blue-500 text-white hover:bg-blue-400"
              disabled={status === "loading"}
              onClick={handlePurchase}
            >
              <CreditCardIcon className="size-4" />
              {status === "loading" ? "결제 확인 중" : "상세 분석권 열기"}
            </Button>
          )}
          </div>
        </section>

        <div className="mt-auto pt-5">
          <Button asChild className="h-12 w-full rounded-md" variant="secondary">
            <Link to={`/result?${data.query}`}>결과 카드로 돌아가기</Link>
          </Button>
        </div>
      </div>
    </ZodiacElementBackground>
  );
}
