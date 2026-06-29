import { createClientFromRequest } from "./supabase-server";
import { getOwnedProfileWithAnalysis, getSajuBaseSummary } from "./queries";
import {
  getChatMessages,
  getLatestChatSession,
  type ChatMessageRow,
  type ChatSessionRow,
} from "./chat";
import {
  getActiveSubscription,
  type SubscriptionRow,
} from "./subscriptions";
import {
  resolveCalculationFromProfile,
  type AiSummaryRow,
  type SajuAnalysisRow,
  type SajuProfileRow,
} from "./models";

export type SadamProfileLoaderData =
  | {
      error: string;
      profile: null;
      analysis: null;
      summary: null;
      chatSession: null;
      chatMessages: [];
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
  const query = profileId ? `profileId=${encodeURIComponent(profileId)}` : "";

  if (!profileId) {
    return emptyLoaderData("프로필 정보가 없습니다. 다시 입력해 주세요.", query);
  }

  const client = createClientFromRequest(request, context.cloudflare.env);
  if (!client) {
    return emptyLoaderData("로그인 세션이 없습니다. 다시 입력해 주세요.", query);
  }

  let result: Awaited<ReturnType<typeof getOwnedProfileWithAnalysis>>;
  try {
    result = await getOwnedProfileWithAnalysis(client, profileId);
  } catch (error) {
    return emptyLoaderData(
      error instanceof Error ? error.message : "프로필을 불러오지 못했습니다.",
      query,
    );
  }

  if (!result) {
    return emptyLoaderData(
      "프로필을 찾을 수 없습니다. 다시 입력해 주세요.",
      query,
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
    chatSession = await getLatestChatSession(client, result.profile.id);
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
    subscription,
    calculation: resolveCalculationFromProfile(result.profile),
    query,
  };
}

function emptyLoaderData(error: string, query: string): SadamProfileLoaderData {
  return {
    error,
    profile: null,
    analysis: null,
    summary: null,
    chatSession: null,
    chatMessages: [],
    subscription: null,
    calculation: null,
    query,
  };
}
