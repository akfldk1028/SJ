import {
  getChatMessages,
  getLatestChatSession,
  resolveChatRouteOptions,
  buildProfileQuery,
  type ChatMessageRow,
  type ChatRouteOptions,
  type ChatSessionRow,
} from "./chat";
import { resolveCalculationFromProfile } from "./models";
import type {
  AiSummaryRow,
  SajuAnalysisRow,
  SajuProfileRow,
} from "./models";
import { getOwnedProfileWithAnalysis, getSajuBaseSummary } from "./queries";
import { getActiveSubscription, type SubscriptionRow } from "./subscriptions";
import { createClientFromRequest } from "./supabase-server";

export type SadamProfileLoaderData =
  | {
      error: string;
      profile: null;
      analysis: null;
      summary: null;
      chatSession: null;
      chatMessages: [];
      chatOptions: ChatRouteOptions;
      subscription: null;
      calculation: null;
      query: string;
    }
  | {
      error: null;
      profile: SajuProfileRow;
      analysis: SajuAnalysisRow | null;
      summary: AiSummaryRow | null;
      chatSession: ChatSessionRow | null;
      chatMessages: ChatMessageRow[];
      chatOptions: ChatRouteOptions;
      subscription: SubscriptionRow | null;
      calculation: ReturnType<typeof resolveCalculationFromProfile>;
      query: string;
    };

export async function loadSadamProfile({
  request,
  context,
}: {
  request: Request;
  context: { cloudflare: { env: CloudflareEnvironment } };
}): Promise<SadamProfileLoaderData> {
  const url = new URL(request.url);
  const profileId = url.searchParams.get("profileId");
  const chatOptions = resolveChatRouteOptions(url);
  const query = buildProfileQuery(profileId, chatOptions);

  if (!profileId) {
    return emptyLoaderData("프로필 정보가 없습니다. 다시 입력해 주세요.", query, chatOptions);
  }

  const client = createClientFromRequest(request, context.cloudflare.env);
  if (!client) {
    return emptyLoaderData("로그인 세션이 없습니다. 다시 입력해 주세요.", query, chatOptions);
  }

  let result: Awaited<ReturnType<typeof getOwnedProfileWithAnalysis>>;
  try {
    result = await getOwnedProfileWithAnalysis(client, profileId);
  } catch (error) {
    return emptyLoaderData(
      error instanceof Error ? error.message : "프로필을 불러오지 못했습니다.",
      query,
      chatOptions,
    );
  }

  if (!result) {
    return emptyLoaderData(
      "프로필을 찾을 수 없습니다. 다시 입력해 주세요.",
      query,
      chatOptions,
    );
  }

  let summary: AiSummaryRow | null = null;
  try {
    summary = await getSajuBaseSummary(
      client,
      result.profile.id,
      result.profile.locale || "ko",
    );
  } catch (error) {
    console.error("[sadam] AI summary load failed", error);
  }

  let chatSession: ChatSessionRow | null = null;
  let chatMessages: ChatMessageRow[] = [];
  try {
    chatSession = await getLatestChatSession(client, result.profile.id, chatOptions);
    if (chatSession) {
      chatMessages = await getChatMessages(client, chatSession.id);
    }
  } catch (error) {
    console.error("[sadam] chat load failed", error);
  }

  let subscription: SubscriptionRow | null = null;
  try {
    subscription = await getActiveSubscription(client, result.profile.user_id);
  } catch (error) {
    console.error("[sadam] subscription load failed", error);
  }

  return {
    error: null,
    profile: result.profile,
    analysis: result.analysis,
    summary,
    chatSession,
    chatMessages,
    chatOptions,
    subscription,
    calculation: resolveCalculationFromProfile(result.profile),
    query,
  };
}

function emptyLoaderData(
  error: string,
  query: string,
  chatOptions: ChatRouteOptions,
): SadamProfileLoaderData {
  return {
    error,
    profile: null,
    analysis: null,
    summary: null,
    chatSession: null,
    chatMessages: [],
    chatOptions,
    subscription: null,
    calculation: null,
    query,
  };
}
