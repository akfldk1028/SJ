import { createClientFromRequest } from "./supabase-server";
import { getOwnedProfileWithAnalysis } from "./queries";
import {
  resolveCalculationFromProfile,
  type SajuAnalysisRow,
  type SajuProfileRow,
} from "./models";

export type SadamProfileLoaderData =
  | {
      error: string;
      profile: null;
      analysis: null;
      calculation: null;
      query: string;
    }
  | {
      error: null;
      profile: SajuProfileRow;
      analysis: SajuAnalysisRow | null;
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
    return {
      error: "프로필 정보가 없습니다. 다시 입력해 주세요.",
      profile: null,
      analysis: null,
      calculation: null,
      query,
    };
  }

  const client = createClientFromRequest(request, context.cloudflare.env);
  if (!client) {
    return {
      error: "로그인 세션이 없습니다. 다시 입력해 주세요.",
      profile: null,
      analysis: null,
      calculation: null,
      query,
    };
  }

  let result: Awaited<ReturnType<typeof getOwnedProfileWithAnalysis>>;
  try {
    result = await getOwnedProfileWithAnalysis(client, profileId);
  } catch (error) {
    return {
      error: error instanceof Error ? error.message : "프로필을 불러오지 못했습니다.",
      profile: null,
      analysis: null,
      calculation: null,
      query,
    };
  }

  if (!result) {
    return {
      error: "프로필을 찾을 수 없습니다. 다시 입력해 주세요.",
      profile: null,
      analysis: null,
      calculation: null,
      query,
    };
  }

  return {
    error: null,
    profile: result.profile,
    analysis: result.analysis,
    calculation: resolveCalculationFromProfile(result.profile),
    query,
  };
}
