import { useState } from "react";
import { Link, type MetaFunction, useSearchParams } from "react-router";
import { CheckCircle2Icon, PlayCircleIcon } from "lucide-react";
import { Button } from "~/common/components/ui/button";
import {
  ZodiacElementBackground,
  ZodiacSpeechPanel,
} from "../components/zodiac-widgets";
import { resolveIdentityFromBirthDate } from "../personas";
import { requestRewardedAd } from "../toss-adapters";

export const meta: MetaFunction = () => {
  return [{ title: "SaDam 추가 질문" }];
};

export default function ExtraPage() {
  const [searchParams] = useSearchParams();
  const [status, setStatus] = useState<"idle" | "loading" | "done">("idle");
  const [message, setMessage] = useState("");
  const name = searchParams.get("name") || "나";
  const birthDate = searchParams.get("birthDate") || "19950101";
  const identity = resolveIdentityFromBirthDate(birthDate);

  const handleReward = async () => {
    setStatus("loading");
    const result = await requestRewardedAd();
    setMessage(result.message);
    setStatus("done");
  };

  return (
    <ZodiacElementBackground elementName={identity.elementName}>
      <div className="mx-auto flex min-h-screen w-full max-w-md flex-col px-5 py-6">
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
            <div className="rounded-lg bg-white/10 p-4">
              <p className="text-sm font-semibold text-white/60">추천 질문</p>
              <p className="mt-2 text-lg font-bold leading-7 text-white">
                관계에서 어떤 방식으로 마음을 표현하면 좋을까요?
              </p>
            </div>

            {status === "done" ? (
              <div className="mt-5 rounded-lg border border-emerald-200/40 bg-emerald-400/10 p-4">
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
            <Link to={`/result?${searchParams.toString()}`}>결과 카드로 돌아가기</Link>
          </Button>
        </div>
      </div>
    </ZodiacElementBackground>
  );
}
