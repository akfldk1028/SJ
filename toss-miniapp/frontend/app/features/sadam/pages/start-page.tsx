import { Form, redirect, type MetaFunction, useActionData } from "react-router";
import {
  ArrowRightIcon,
  CalendarDaysIcon,
  ClockIcon,
  SparklesIcon,
  UserRoundIcon,
} from "lucide-react";
import { Button } from "~/common/components/ui/button";
import {
  ZodiacChatBubble,
  ZodiacElementBackground,
  ZodiacSpeechPanel,
} from "../components/zodiac-widgets";
import { resolveIdentityFromBirthYear } from "../personas";
import { ensureAnonymousSession } from "../data/supabase-server";
import { createProfile, upsertAnalysis } from "../data/mutations";
import { ensureSajuBaseSummary } from "../data/ai-summary";
import {
  parseProfileForm,
  toAnalysisUpsert,
  toProfileInsert,
} from "../data/models";
import { resolveSadamIdentity } from "../saju-calculation";

export const meta: MetaFunction = () => {
  return [
    { title: "SaDam AI 수호동물" },
    {
      name: "description",
      content: "토스에서 빠르게 확인하는 AI 수호동물 성향 카드",
    },
  ];
};

const currentYearIdentity = resolveIdentityFromBirthYear(new Date().getFullYear());

type ActionData = {
  error?: string;
};

export async function action({
  request,
  context,
}: {
  request: Request;
  context: { cloudflare: { env: CloudflareEnvironment; ctx?: ExecutionContext } };
}) {
  try {
    const formData = await request.formData();
    const values = parseProfileForm(formData);
    const session = await ensureAnonymousSession(request, context.cloudflare.env);
    const calculation = resolveSadamIdentity({
      birthDate: values.birthDate,
      birthTime: values.birthTime,
      birthTimeUnknown: values.birthTime === "unknown",
      calendar: values.calendar,
      birthCity: values.birthCity,
      useYaJasi: values.useYaJasi,
    });
    const profileId = crypto.randomUUID();
    const analysisId = crypto.randomUUID();

    const profile = await createProfile(
      session.client,
      toProfileInsert(profileId, session.userId, values, calculation),
    );
    const analysis = await upsertAnalysis(
      session.client,
      toAnalysisUpsert(analysisId, profileId, calculation),
    );
    const summaryPromise = ensureSajuBaseSummary({
      client: session.client,
      userId: session.userId,
      profile,
      analysis,
    }).catch((summaryError) => {
      console.error("[sadam] AI summary generation failed", summaryError);
    });

    if (context.cloudflare.ctx) {
      context.cloudflare.ctx.waitUntil(summaryPromise);
    } else {
      await summaryPromise;
    }

    return redirect(`/result?profileId=${profileId}`, {
      headers: session.cookieHeader
        ? { "Set-Cookie": session.cookieHeader }
        : undefined,
    });
  } catch (error) {
    return {
      error: error instanceof Error ? error.message : "프로필 저장에 실패했습니다.",
    } satisfies ActionData;
  }
}

export default function StartPage() {
  const actionData = useActionData() as ActionData | undefined;

  return (
    <ZodiacElementBackground elementName={currentYearIdentity.elementName}>
      <div className="mx-auto flex min-h-screen w-full max-w-md flex-col px-5 py-6">
        <header className="flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold uppercase text-sky-300">
              SaDam in Toss
            </p>
            <h1 className="mt-1 text-2xl font-bold">AI 수호동물 찾기</h1>
          </div>
          <div className="rounded-md bg-white/10 p-2">
            <SparklesIcon className="size-5 text-sky-200" />
          </div>
        </header>

        <section className="mt-6 space-y-3">
          <ZodiacChatBubble
            elementName={currentYearIdentity.elementName}
            emoji={currentYearIdentity.animalEmoji}
            imageUrl={currentYearIdentity.imageUrl}
          >
            <p className="font-semibold">올해의 기운</p>
            <p className="mt-1 text-lg font-bold">
              {currentYearIdentity.displayName}
            </p>
            <p className="mt-2">
              본앱 온보딩처럼 이름, 생년월일, 시간, 성별을 받아 간편 일주
              카드로 보여줄게요.
            </p>
          </ZodiacChatBubble>
        </section>

        <Form className="mt-5" method="post">
          <ZodiacSpeechPanel
            elementName={currentYearIdentity.elementName}
            emoji={currentYearIdentity.animalEmoji}
            imageUrl={currentYearIdentity.largeImageUrl}
            title="너의 수호동물을 찾기 위해 몇 가지만 알려줘."
          >
            <div className="space-y-4">
          {actionData?.error ? (
            <div className="rounded-lg border border-red-200 bg-red-50 p-4 text-sm leading-6 text-red-900">
              {actionData.error}
            </div>
          ) : null}

          <label className="block rounded-lg border border-white/10 bg-white/[0.06] p-4">
            <span className="flex items-center gap-2 text-sm font-semibold text-slate-100">
              <UserRoundIcon className="size-4 text-sky-300" />
              이름
            </span>
            <input
              className="mt-3 h-12 w-full rounded-md border border-white/10 bg-white px-3 text-base text-slate-950 outline-none focus:border-sky-400"
              defaultValue="도현"
              maxLength={12}
              name="name"
              required
            />
          </label>

          <section className="rounded-lg border border-white/10 bg-white/[0.06] p-4">
            <label className="block">
              <span className="flex items-center gap-2 text-sm font-semibold text-slate-100">
                <CalendarDaysIcon className="size-4 text-sky-300" />
                생년월일
              </span>
              <input
                className="mt-3 h-12 w-full rounded-md border border-white/10 bg-white px-3 text-base text-slate-950 outline-none focus:border-sky-400"
                defaultValue="19950101"
                inputMode="numeric"
                maxLength={8}
                name="birthDate"
                pattern="[0-9]{8}"
                placeholder="YYYYMMDD"
                required
              />
            </label>

            <div className="mt-3 grid grid-cols-2 gap-2">
              <label className="flex h-11 items-center justify-center rounded-md border border-white/10 bg-white/10 text-sm">
                <input
                  className="sr-only peer"
                  defaultChecked
                  name="calendar"
                  type="radio"
                  value="solar"
                />
                <span className="peer-checked:text-sky-200">양력</span>
              </label>
              <label className="flex h-11 items-center justify-center rounded-md border border-white/10 bg-white/10 text-sm">
                <input
                  className="sr-only peer"
                  name="calendar"
                  type="radio"
                  value="lunar"
                />
                <span className="peer-checked:text-sky-200">음력</span>
              </label>
            </div>
            <label className="mt-3 flex items-center gap-2 text-sm text-slate-100">
              <input
                className="size-4 rounded border-white/20"
                name="isLeapMonth"
                type="checkbox"
              />
              음력 윤달
            </label>
          </section>

          <section className="rounded-lg border border-white/10 bg-white/[0.06] p-4">
            <label className="block">
              <span className="flex items-center gap-2 text-sm font-semibold text-slate-100">
                <ClockIcon className="size-4 text-sky-300" />
                태어난 시간
              </span>
              <select
                className="mt-3 h-12 w-full rounded-md border border-white/10 bg-white px-3 text-base text-slate-950 outline-none focus:border-sky-400"
                defaultValue="unknown"
                name="birthTime"
              >
                <option value="unknown">잘 모르겠어요</option>
                <option value="00:00">00:00 - 00:59</option>
                <option value="01:00">01:00 - 02:59</option>
                <option value="03:00">03:00 - 04:59</option>
                <option value="05:00">05:00 - 06:59</option>
                <option value="07:00">07:00 - 08:59</option>
                <option value="09:00">09:00 - 10:59</option>
                <option value="11:00">11:00 - 12:59</option>
                <option value="13:00">13:00 - 14:59</option>
                <option value="15:00">15:00 - 16:59</option>
                <option value="17:00">17:00 - 18:59</option>
                <option value="19:00">19:00 - 20:59</option>
                <option value="21:00">21:00 - 22:59</option>
                <option value="23:00">23:00 - 23:59</option>
              </select>
            </label>
            <input name="useYaJasi" type="hidden" value="off" />
            <label className="mt-3 flex items-center gap-2 text-sm text-slate-100">
              <input
                className="size-4 rounded border-white/20"
                defaultChecked
                name="useYaJasi"
                type="checkbox"
                value="on"
              />
              야자시 기준 적용
            </label>
          </section>

          <section className="rounded-lg border border-white/10 bg-white/[0.06] p-4">
            <label className="block">
              <span className="text-sm font-semibold text-slate-100">
                출생 도시
              </span>
              <select
                className="mt-3 h-12 w-full rounded-md border border-white/10 bg-white px-3 text-base text-slate-950 outline-none focus:border-sky-400"
                defaultValue="서울"
                name="birthCity"
              >
                <option value="서울">서울</option>
                <option value="부산">부산</option>
                <option value="대구">대구</option>
                <option value="인천">인천</option>
                <option value="광주">광주</option>
                <option value="대전">대전</option>
                <option value="울산">울산</option>
                <option value="제주">제주</option>
              </select>
            </label>
          </section>

          <section className="rounded-lg border border-white/10 bg-white/[0.06] p-4">
            <p className="text-sm font-semibold text-slate-100">성별</p>
            <div className="mt-3 grid grid-cols-2 gap-2">
              <label className="flex h-11 items-center justify-center rounded-md border border-white/10 bg-white/10 text-sm">
                <input
                  className="sr-only peer"
                  defaultChecked
                  name="gender"
                  type="radio"
                  value="female"
                />
                <span className="peer-checked:text-sky-200">여성</span>
              </label>
              <label className="flex h-11 items-center justify-center rounded-md border border-white/10 bg-white/10 text-sm">
                <input
                  className="sr-only peer"
                  name="gender"
                  type="radio"
                  value="male"
                />
                <span className="peer-checked:text-sky-200">남성</span>
              </label>
            </div>
          </section>

          <Button className="h-12 w-full rounded-md bg-sky-500 text-base text-white hover:bg-sky-400">
            수호동물 보기
            <ArrowRightIcon className="size-4" />
          </Button>
            </div>
          </ZodiacSpeechPanel>
        </Form>

        <p className="mt-4 text-center text-xs leading-5 text-slate-400">
          결과는 자기 이해를 돕는 AI 콘텐츠입니다. 중요한 결정이나 의료,
          법률, 금융 판단을 대신하지 않습니다.
        </p>
      </div>
    </ZodiacElementBackground>
  );
}
