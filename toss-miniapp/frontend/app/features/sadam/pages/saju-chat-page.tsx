import {
  Form,
  redirect,
  type ActionFunctionArgs,
  type MetaFunction,
  useActionData,
  useLoaderData,
  useNavigation,
} from "react-router";
import {
  BotIcon,
  HeartHandshakeIcon,
  Loader2Icon,
  MessageCircleIcon,
  SendIcon,
  UserRoundIcon,
} from "lucide-react";
import { Badge } from "~/common/components/ui/badge";
import { Button } from "~/common/components/ui/button";
import {
  buildProfileQuery,
  createChatMessage,
  getChatMessages,
  getChatTypeLabel,
  getOrCreateChatSession,
  requestAiChatAnswer,
  resolveChatRouteOptions,
  updateChatSessionAfterExchange,
} from "../data/chat";
import { getOwnedProfileWithAnalysis, getSajuBaseSummary } from "../data/queries";
import { loadSadamProfile, type SadamProfileLoaderData } from "../data/route-loaders";
import {
  createClientFromRequest,
  getAccessTokenFromRequest,
} from "../data/supabase-server";
import {
  ErrorState,
  PageShell,
  ProfileSummary,
  SajuNavButtons,
} from "./saju-page-utils";

export const meta: MetaFunction = () => [{ title: "SaDam AI 사주 상담" }];
export const loader = loadSadamProfile;

type ActionData = {
  error?: string;
};

export async function action({ request, context }: ActionFunctionArgs) {
  const url = new URL(request.url);
  const optionsFromUrl = resolveChatRouteOptions(url);

  try {
    const formData = await request.formData();
    const message = String(formData.get("message") ?? "").trim();
    const profileId = String(formData.get("profileId") ?? "").trim();
    const formType = String(formData.get("type") ?? "").trim();
    const formTargetProfileId = String(formData.get("targetProfileId") ?? "").trim();
    const formAutoMention = String(formData.get("autoMention") ?? "") === "true";
    const options = resolveChatRouteOptions(
      new URL(
        `/saju/chat?${buildProfileQuery(profileId, {
          chatType: formType ? (formType as typeof optionsFromUrl.chatType) : optionsFromUrl.chatType,
          targetProfileId: formTargetProfileId || optionsFromUrl.targetProfileId,
          autoMention: formAutoMention || optionsFromUrl.autoMention,
        })}`,
        url.origin,
      ),
    );

    if (!profileId) throw new Error("프로필 정보가 없습니다. 처음부터 다시 입력해 주세요.");
    if (!message) throw new Error("상담 내용을 입력해 주세요.");
    if (message.length > 600) throw new Error("질문은 600자 이내로 입력해 주세요.");

    const env = context.cloudflare.env as CloudflareEnvironment;
    const client = createClientFromRequest(request, env);
    const accessToken = getAccessTokenFromRequest(request);
    if (!client || !accessToken) {
      throw new Error("로그인 세션이 없습니다. 처음부터 다시 입력해 주세요.");
    }

    const { data: userData, error: userError } = await client.auth.getUser(accessToken);
    if (userError || !userData.user) {
      throw new Error("로그인 세션이 만료되었습니다. 처음부터 다시 입력해 주세요.");
    }

    const owned = await getOwnedProfileWithAnalysis(client, profileId);
    if (!owned) throw new Error("프로필을 찾을 수 없습니다.");

    const session = await getOrCreateChatSession(client, owned.profile, options);
    const history = await getChatMessages(client, session.id, 30);
    const summary = await getSajuBaseSummary(
      client,
      owned.profile.id,
      owned.profile.locale || "ko",
    ).catch(() => null);

    await createChatMessage(client, {
      id: crypto.randomUUID(),
      session_id: session.id,
      role: "user",
      content: message,
      suggested_questions: null,
      tokens_used: null,
      status: "sent",
    });

    const answer = await requestAiChatAnswer({
      client,
      userId: userData.user.id,
      profile: owned.profile,
      analysis: owned.analysis,
      summary,
      session,
      history,
      message,
      options,
    });

    await createChatMessage(client, {
      id: crypto.randomUUID(),
      session_id: session.id,
      role: "assistant",
      content: answer.content,
      suggested_questions: answer.suggestedQuestions,
      tokens_used: answer.tokensUsed,
      status: "sent",
    });
    await updateChatSessionAfterExchange({
      client,
      session,
      lastUserMessage: message,
      tokensUsed: answer.tokensUsed,
    });

    return redirect(`/saju/chat?${buildProfileQuery(profileId, options)}`);
  } catch (error) {
    return {
      error:
        error instanceof Error
          ? error.message
          : "AI 상담 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.",
    } satisfies ActionData;
  }
}

const fallbackQuestions = [
  "내 사주에서 지금 가장 강한 기운은 뭐야?",
  "올해 조심해야 할 관계 패턴을 알려줘",
  "일과 돈의 흐름에서 먼저 챙길 점은 뭐야?",
];

export default function SajuChatPage() {
  const data = useLoaderData() as SadamProfileLoaderData;
  const actionData = useActionData() as ActionData | undefined;
  const navigation = useNavigation();
  if (data.error || !data.profile || !data.calculation) return <ErrorState data={data} />;

  const isSubmitting = navigation.state === "submitting";
  const messages = data.chatMessages;
  const chatTypeLabel = getChatTypeLabel(data.chatOptions.chatType);
  const lastAssistant = [...messages].reverse().find((message) => message.role === "assistant");
  const suggestedQuestions =
    lastAssistant?.suggested_questions && lastAssistant.suggested_questions.length > 0
      ? lastAssistant.suggested_questions
      : fallbackQuestions;

  return (
    <PageShell calculation={data.calculation} eyebrow="Saju Chat" title="AI 사주 상담">
      <ProfileSummary data={data} />

      <section className="mt-5 rounded-lg border border-white/15 bg-white/[0.96] p-4 text-slate-950 shadow-xl shadow-black/10">
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            {data.chatOptions.chatType === "compatibility" ? (
              <HeartHandshakeIcon className="size-5 text-rose-600" />
            ) : (
              <MessageCircleIcon className="size-5 text-sky-600" />
            )}
            <h2 className="text-lg font-bold">{data.profile.display_name} 상담방</h2>
          </div>
          <Badge className="rounded-md bg-sky-50 text-sky-700">
            {messages.length > 0 ? `${messages.length} messages` : "new"}
          </Badge>
        </div>
        <p className="mt-3 text-sm leading-6 text-slate-700">
          Flutter 본앱처럼 저장된 사주 분석, 상담 유형, 대화 히스토리를 바탕으로 AI 상담을 이어갑니다.
        </p>
        <div className="mt-3 flex flex-wrap gap-2">
          <Badge className="rounded-md bg-slate-100 text-slate-700">{chatTypeLabel}</Badge>
          {data.chatOptions.autoMention ? (
            <Badge className="rounded-md bg-amber-100 text-amber-800">자동 멘션</Badge>
          ) : null}
          {data.subscription ? (
            <Badge className="rounded-md bg-emerald-100 text-emerald-800">프리미엄</Badge>
          ) : null}
        </div>
      </section>

      <section className="mt-5 min-h-[280px] space-y-3 rounded-lg border border-white/15 bg-slate-950/70 p-4 shadow-xl shadow-black/10">
        {messages.length === 0 ? (
          <div className="rounded-lg border border-dashed border-white/15 bg-white/[0.06] p-4 text-sm leading-6 text-slate-200">
            아직 대화가 없습니다. 아래 질문을 누르거나 직접 궁금한 점을 입력해 주세요.
          </div>
        ) : (
          messages.map((message) => (
            <article
              className={`flex gap-3 ${message.role === "user" ? "justify-end" : "justify-start"}`}
              key={message.id}
            >
              {message.role === "assistant" ? (
                <div className="mt-1 flex size-8 shrink-0 items-center justify-center rounded-md bg-sky-400/15 text-sky-200">
                  <BotIcon className="size-4" />
                </div>
              ) : null}
              <div
                className={`max-w-[82%] rounded-lg px-4 py-3 text-sm leading-6 shadow-sm ${
                  message.role === "user"
                    ? "bg-sky-500 text-white"
                    : "border border-white/10 bg-white text-slate-900"
                }`}
              >
                <p className="whitespace-pre-wrap">{message.content}</p>
              </div>
              {message.role === "user" ? (
                <div className="mt-1 flex size-8 shrink-0 items-center justify-center rounded-md bg-white/10 text-slate-200">
                  <UserRoundIcon className="size-4" />
                </div>
              ) : null}
            </article>
          ))
        )}

        {isSubmitting ? (
          <div className="flex items-center gap-2 rounded-lg border border-sky-300/20 bg-sky-300/10 px-4 py-3 text-sm text-sky-100">
            <Loader2Icon className="size-4 animate-spin" />
            AI가 사주 맥락을 읽고 답변을 준비하고 있습니다.
          </div>
        ) : null}
      </section>

      {actionData?.error ? (
        <div className="mt-4 rounded-lg border border-red-200 bg-red-50 p-4 text-sm leading-6 text-red-900">
          {actionData.error}
        </div>
      ) : null}

      <section className="mt-5 rounded-lg border border-white/15 bg-white/[0.96] p-4 text-slate-950 shadow-xl shadow-black/10">
        <h3 className="text-sm font-bold">추천 질문</h3>
        <div className="mt-3 space-y-2">
          {suggestedQuestions.map((question) => (
            <Form key={question} method="post">
              <ChatHiddenFields data={data} />
              <input name="message" type="hidden" value={question} />
              <button
                className="w-full rounded-md border border-slate-200 bg-slate-50 px-3 py-3 text-left text-sm leading-5 text-slate-800 shadow-sm transition hover:border-sky-200 hover:bg-sky-50 disabled:opacity-60"
                disabled={isSubmitting}
                type="submit"
              >
                {question}
              </button>
            </Form>
          ))}
        </div>
      </section>

      <Form className="mt-5 rounded-lg border border-white/15 bg-white/[0.96] p-3 shadow-xl shadow-black/10" method="post">
        <ChatHiddenFields data={data} />
        <label className="sr-only" htmlFor="message">
          상담 질문
        </label>
        <div className="flex gap-2">
          <textarea
            className="min-h-12 flex-1 resize-none rounded-md border border-slate-200 bg-white px-3 py-3 text-sm leading-5 text-slate-950 outline-none focus:border-sky-400"
            id="message"
            maxLength={600}
            name="message"
            placeholder="궁금한 점을 물어보세요"
            required
            rows={1}
          />
          <Button
            className="h-auto min-h-12 rounded-md bg-sky-500 px-4 text-white hover:bg-sky-400 disabled:opacity-60"
            disabled={isSubmitting}
            type="submit"
          >
            {isSubmitting ? (
              <Loader2Icon className="size-4 animate-spin" />
            ) : (
              <SendIcon className="size-4" />
            )}
            <span className="sr-only">전송</span>
          </Button>
        </div>
      </Form>

      <SajuNavButtons query={data.query} />
    </PageShell>
  );
}

function ChatHiddenFields({
  data,
}: {
  data: Extract<SadamProfileLoaderData, { error: null }>;
}) {
  return (
    <>
      <input name="profileId" type="hidden" value={data.profile.id} />
      <input name="type" type="hidden" value={data.chatOptions.chatType} />
      <input name="targetProfileId" type="hidden" value={data.chatOptions.targetProfileId ?? ""} />
      <input name="autoMention" type="hidden" value={data.chatOptions.autoMention ? "true" : "false"} />
    </>
  );
}
