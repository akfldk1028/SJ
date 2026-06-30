import type { SupabaseClient } from "@supabase/supabase-js";
import {
  aiSummariesTable,
  aiSummaryColumns,
  aiSummarySelectColumns,
  chatSessionsTable,
  chatSessionSelectColumns,
  compatibilityAnalysesTable,
  profileColumns,
  profileRelationSelectColumns,
  profileRelationsTable,
  profileSelectColumns,
  profilesTable,
  subscriptionColumns,
  subscriptionSelectColumns,
  subscriptionsTable,
} from "./schema";
import type { AiSummaryRow, SajuProfileRow } from "./models";
import type { ChatSessionRow } from "./chat";
import type { SubscriptionRow } from "./subscriptions";

export type ProfileRelationRow = {
  id: string;
  user_id: string;
  from_profile_id: string;
  to_profile_id: string;
  relation_type: string | null;
  display_name: string | null;
  memo: string | null;
  is_favorite: boolean | null;
  sort_order: number | null;
  created_at: string | null;
  updated_at: string | null;
  from_profile_analysis_id: string | null;
  to_profile_analysis_id: string | null;
  analysis_status: string | null;
  analysis_requested_at: string | null;
  compatibility_analysis_id: string | null;
  analysis_completed_at: string | null;
  pair_hapchung: Record<string, unknown> | null;
};

export type CompatibilityAnalysisRow = {
  id: string;
  profile1_id: string;
  profile2_id: string;
  analysis_type: string | null;
  relation_type: string | null;
  overall_score: number | null;
  category_scores: Record<string, unknown> | null;
  saju_analysis: Record<string, unknown> | null;
  summary: string | Record<string, unknown> | null;
  analysis_content: string | Record<string, unknown> | null;
  strengths: string[] | null;
  challenges: string[] | null;
  advice: string[] | null;
  created_at: string | null;
  updated_at: string | null;
  model_provider: string | null;
  model_name: string | null;
  tokens_used: number | null;
  processing_time_ms: number | null;
  owner_hapchung: Record<string, unknown> | null;
  pair_hapchung: Record<string, unknown> | null;
};

type SafeResult<T> = {
  data: T;
  error: string | null;
};

async function safeList<T>(
  fallback: T,
  load: () => Promise<{ data: T | null; error: { message: string } | null }>,
): Promise<SafeResult<T>> {
  const { data, error } = await load();
  if (error) return { data: fallback, error: error.message };
  return { data: data ?? fallback, error: null };
}

export async function getProfilesForUser(client: SupabaseClient, userId: string) {
  return safeList<SajuProfileRow[]>([], async () =>
    await client
      .from(profilesTable)
      .select(profileSelectColumns)
      .eq(profileColumns.userId, userId)
      .order(profileColumns.createdAt, { ascending: false })
      .returns<SajuProfileRow[]>(),
  );
}

export async function getRelationsForUser(client: SupabaseClient, userId: string) {
  return safeList<ProfileRelationRow[]>([], async () =>
    await client
      .from(profileRelationsTable)
      .select(profileRelationSelectColumns)
      .eq("user_id", userId)
      .order("is_favorite", { ascending: false })
      .order("sort_order", { ascending: true })
      .returns<ProfileRelationRow[]>(),
  );
}

export async function getCompatibilityForProfile(
  client: SupabaseClient,
  profileId: string | null,
) {
  let query = client
    .from(compatibilityAnalysesTable)
    .select("*")
    .order("created_at", { ascending: false })
    .limit(30);

  if (profileId) {
    query = query.or(`profile1_id.eq.${profileId},profile2_id.eq.${profileId}`);
  }

  return safeList<CompatibilityAnalysisRow[]>([], async () =>
    await query.returns<CompatibilityAnalysisRow[]>(),
  );
}

export async function getChatSessionsForProfile(
  client: SupabaseClient,
  profileId: string | null,
) {
  let query = client
    .from(chatSessionsTable)
    .select(chatSessionSelectColumns)
    .order("updated_at", { ascending: false })
    .limit(40);

  if (profileId) query = query.eq("profile_id", profileId);

  return safeList<ChatSessionRow[]>([], async () => await query.returns<ChatSessionRow[]>());
}

export async function getAiSummariesForProfile(
  client: SupabaseClient,
  profileId: string | null,
) {
  let query = client
    .from(aiSummariesTable)
    .select(aiSummarySelectColumns)
    .order(aiSummaryColumns.createdAt, { ascending: false })
    .limit(30);

  if (profileId) query = query.eq(aiSummaryColumns.profileId, profileId);

  return safeList<AiSummaryRow[]>([], async () => await query.returns<AiSummaryRow[]>());
}

export async function getSubscriptionsForUser(client: SupabaseClient, userId: string) {
  return safeList<SubscriptionRow[]>([], async () =>
    await client
      .from(subscriptionsTable)
      .select(subscriptionSelectColumns)
      .eq(subscriptionColumns.userId, userId)
      .order(subscriptionColumns.createdAt, { ascending: false })
      .returns<SubscriptionRow[]>(),
  );
}
