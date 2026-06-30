import { useState } from "react";
import { Link, type MetaFunction, useLoaderData } from "react-router";
import { CheckCircle2Icon, PlayCircleIcon } from "lucide-react";
import { Button } from "~/common/components/ui/button";
import {
  ZodiacElementBackground,
  ZodiacSpeechPanel,
} from "../components/zodiac-widgets";
import { loadSadamProfile, type SadamProfileLoaderData } from "../data/route-loaders";
import { requestRewardedAd } from "../toss-adapters";
import { ErrorState } from "./saju-page-utils";

export const meta: MetaFunction = () => {
  return [{ title: "SaDam 추가 질문" }];
};

export const loader = loadSadamProfile;

export default function ExtraPage() {
  const data = useLoaderData() as SadamProfileLoaderData;
  const [status, setStatus] = useState<"idle" | "loading" | "done" | "error">("idle");
  const [message, setMessage] = useState("");

  if (data.error || !data.profile || !data.calculation) {
    return <ErrorState data={data} />;
  }

  const name = data.profile.display_name;
  const identity = data.calculation.identity;

  const handleReward = async () => {
    setStatus("loading");
    const result = await requestRewardedAd();
    setMessage(result.message);
    setStatus(result.ok ? "done" : "error");
  };

  return (
    <ZodiacElementBackground elementName={identity.elementName}>
      <div className="mx-auto flex min-h-screen w-full max-w-md flex-col px-4 py-5 sm:px-5 lg:max-w-3xl lg:py-7">
        <header>
          <p className="text-xs font-semibold uppercase text-white/65">
            Reward Question
          </p>
          <h1 className="mt-1 text-2xl font-bold text-white">
            추가 질문 1개 열기
          </h1>
        </header>

        <section className="mt-6">
          <ZodiacSpeechPanel
            elementName={identity.elementName}
            emoji={identity.animalEmoji}
            imageUrl={identity.largeImageUrl}
            title={`${name}님의 ${identity.fullName}에게 더 물어볼까요?`}
          >
            <div className="rounded-lg border border-white/10 bg-white/10 p-4 shadow-lg shadow-black/10">
              <p className="text-sm font-semibold text-white/60">추천 질문</p>
              <p className="mt-2 text-lg font-bold leading-7 text-white">
                관계에서 어떤 방식으로 마음을 표현하면 좋을까요?
              </p>
            </div>

            {status === "done" || status === "error" ? (
              <div className="mt-5 rounded-lg border border-emerald-200/40 bg-emerald-400/10 p-4 shadow-lg shadow-black/10">
                <div className="flex items-center gap-2 text-sm font-semibold text-emerald-100">
                  <CheckCircle2Icon className="size-4" />
                  광고 리워드 확인
                </div>
                <p className="mt-2 text-sm leading-6 text-emerald-50">
                  {message} 실제 앱인토스 연동 시 이 위치에서 보상형 광고 완료
                  이벤트를 확인합니다.
                </p>
              </div>
            ) : (
              <Button
                className="mt-5 h-12 w-full rounded-md bg-sky-500 text-white hover:bg-sky-400"
                disabled={status === "loading"}
                onClick={handleReward}
              >
                <PlayCircleIcon className="size-4" />
                {status === "loading" ? "광고 확인 중" : "광고 보고 답변 열기"}
              </Button>
            )}
          </ZodiacSpeechPanel>
        </section>

        <div className="mt-auto pt-5">
          <Button asChild className="h-12 w-full rounded-md" variant="outline">
            <Link to={`/result?${data.query}`}>결과 카드로 돌아가기</Link>
          </Button>
        </div>
      </div>
    </ZodiacElementBackground>
  );
}
