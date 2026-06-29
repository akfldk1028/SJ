import type { SupabaseClient } from "@supabase/supabase-js";
import type { AiSummaryRow, SajuAnalysisRow, SajuProfileRow } from "./models";
import {
  chatMessageColumns,
  chatMessagesTable,
  chatMessageSelectColumns,
  chatSessionColumns,
  chatSessionsTable,
  chatSessionSelectColumns,
} from "./schema";

export type ChatRole = "user" | "assistant" | "system";
export type SadamChatType =
  | "general"
  | "sajuAnalysis"
  | "dailyFortune"
  | "newYearFortune"
  | "compatibility";

export type ChatRouteOptions = {
  chatType: SadamChatType;
  targetProfileId: string | null;
  autoMention: boolean;
};

export type ChatSessionRow = {
  id: string;
  profile_id: string;
  title: string;
  chat_type: string;
  message_count: number | null;
  last_message_preview: string | null;
  context_summary: string | null;
  target_profile_id: string | null;
  total_tokens_used: number | null;
  user_message_count: number | null;
  assistant_message_count: number | null;
  chat_persona: string | null;
  mbti_quadrant: string | null;
  locale: string | null;
  created_at: string | null;
  updated_at: string | null;
};

export type ChatMessageRow = {
  id: string;
  session_id: string;
  role: ChatRole;
  content: string;
  suggested_questions: string[] | null;
  tokens_used: number | null;
  status: string | null;
  created_at: string | null;
};

type AiGeminiResponse = {
  success?: boolean;
  content?: string;
  usage?: {
    prompt_tokens?: number;
    completion_tokens?: number;
    total_tokens?: number;
  };
  model?: string;
  finish_reason?: string;
  error?: string;
};

const validChatTypes = new Set<SadamChatType>([
  "general",
  "sajuAnalysis",
  "dailyFortune",
  "newYearFortune",
  "compatibility",
]);

const chatTypeLabels: Record<SadamChatType, string> = {
  general: "사주 상담",
  sajuAnalysis: "사주 분석 상담",
  dailyFortune: "오늘 운세 상담",
  newYearFortune: "신년 운세 상담",
  compatibility: "궁합 상담",
};

export function resolveChatRouteOptions(url: URL): ChatRouteOptions {
  const type = url.searchParams.get("type");
  const chatType = validChatTypes.has(type as SadamChatType)
    ? (type as SadamChatType)
    : "general";
  const targetProfileId = normalizeOptionalId(url.searchParams.get("targetProfileId"));

  return {
    chatType,
    targetProfileId,
    autoMention: url.searchParams.get("autoMention") === "true",
  };
}

export function getChatTypeLabel(chatType: SadamChatType) {
  return chatTypeLabels[chatType] ?? chatTypeLabels.general;
}

export function buildProfileQuery(
  profileId: string | null,
  options?: Partial<ChatRouteOptions>,
) {
  const params = new URLSearchParams();
  if (profileId) params.set("profileId", profileId);
  if (options?.chatType && options.chatType !== "general") {
    params.set("type", options.chatType);
  }
  if (options?.targetProfileId) {
    params.set("targetProfileId", options.targetProfileId);
  }
  if (options?.autoMention) {
    params.set("autoMention", "true");
  }
  return params.toString();
}

export async function getLatestChatSession(
  client: SupabaseClient,
  profileId: string,
  options: ChatRouteOptions = {
    chatType: "general",
    targetProfileId: null,
    autoMention: false,
  },
) {
  let query = client
    .from(chatSessionsTable)
    .select(chatSessionSelectColumns)
    .eq(chatSessionColumns.profileId, profileId)
    .eq(chatSessionColumns.chatType, options.chatType);

  query = options.targetProfileId
    ? query.eq(chatSessionColumns.targetProfileId, options.targetProfileId)
    : query.is(chatSessionColumns.targetProfileId, null);

  const { data, error } = await query
    .order(chatSessionColumns.updatedAt, { ascending: false })
    .limit(1)
    .maybeSingle<ChatSessionRow>();

  if (error) throw new Error(`채팅 세션 조회 실패: ${error.message}`);
  return data;
}

export async function createChatSession(
  client: SupabaseClient,
  profile: SajuProfileRow,
  options: ChatRouteOptions,
) {
  const now = new Date().toISOString();
  const label = getChatTypeLabel(options.chatType);
  const { data, error } = await client
    .from(chatSessionsTable)
    .insert({
      id: crypto.randomUUID(),
      profile_id: profile.id,
      title: `${profile.display_name} ${label}`,
      chat_type: options.chatType,
      message_count: 0,
      last_message_preview: null,
      context_summary: null,
      target_profile_id: options.targetProfileId,
      total_tokens_used: 0,
      user_message_count: 0,
      assistant_message_count: 0,
      chat_persona: "basePerson",
      locale: profile.locale || "ko",
      created_at: now,
      updated_at: now,
    })
    .select(chatSessionSelectColumns)
    .single<ChatSessionRow>();

  if (error) throw new Error(`채팅 세션 생성 실패: ${error.message}`);
  return data;
}

export async function getOrCreateChatSession(
  client: SupabaseClient,
  profile: SajuProfileRow,
  options: ChatRouteOptions,
) {
  const existing = await getLatestChatSession(client, profile.id, options);
  if (existing) return existing;
  return createChatSession(client, profile, options);
}

export async function getChatMessages(
  client: SupabaseClient,
  sessionId: string,
  limit = 30,
) {
  const { data, error } = await client
    .from(chatMessagesTable)
    .select(chatMessageSelectColumns)
    .eq(chatMessageColumns.sessionId, sessionId)
    .order(chatMessageColumns.createdAt, { ascending: false })
    .limit(limit)
    .returns<ChatMessageRow[]>();

  if (error) throw new Error(`채팅 메시지 조회 실패: ${error.message}`);
  return [...(data ?? [])].reverse();
}

export async function createChatMessage(
  client: SupabaseClient,
  message: Omit<ChatMessageRow, "created_at"> & { created_at?: string | null },
) {
  const { data, error } = await client
    .from(chatMessagesTable)
    .insert({
      id: message.id,
      session_id: message.session_id,
      role: message.role,
      content: message.content,
      suggested_questions: message.suggested_questions,
      tokens_used: message.tokens_used,
      status: message.status ?? "sent",
      created_at: message.created_at ?? new Date().toISOString(),
    })
    .select(chatMessageSelectColumns)
    .single<ChatMessageRow>();

  if (error) throw new Error(`채팅 메시지 저장 실패: ${error.message}`);
  return data;
}

export async function updateChatSessionAfterExchange({
  client,
  session,
  lastUserMessage,
  tokensUsed,
}: {
  client: SupabaseClient;
  session: ChatSessionRow;
  lastUserMessage: string;
  tokensUsed: number | null;
}) {
  await client
    .from(chatSessionsTable)
    .update({
      title:
        session.message_count && session.message_count > 0
          ? session.title
          : buildSessionTitle(lastUserMessage),
      last_message_preview: truncate(lastUserMessage, 50),
      message_count: (session.message_count ?? 0) + 2,
      user_message_count: (session.user_message_count ?? 0) + 1,
      assistant_message_count: (session.assistant_message_count ?? 0) + 1,
      total_tokens_used: (session.total_tokens_used ?? 0) + (tokensUsed ?? 0),
      updated_at: new Date().toISOString(),
    })
    .eq(chatSessionColumns.id, session.id);
}

function buildSystemPrompt({
  profile,
  analysis,
  summary,
  contextSummary,
  options,
}: {
  profile: SajuProfileRow;
  analysis: SajuAnalysisRow | null;
  summary?: AiSummaryRow | null;
  contextSummary?: string | null;
  options: ChatRouteOptions;
}) {
  const sajuLine = analysis
    ? `년주 ${analysis.year_gan}${analysis.year_ji}, 월주 ${analysis.month_gan}${analysis.month_ji}, 일주 ${analysis.day_gan}${analysis.day_ji}, 시주 ${analysis.hour_gan ?? ""}${analysis.hour_ji ?? ""}`
    : "저장된 만세력 분석 없음";
  const calendarLabel = profile.is_lunar ? "음력" : "양력";

  return [
    "너는 SaDam의 AI 사주 상담사다.",
    "한국어로 답하고, 사용자가 바로 실행할 수 있는 현실적인 조언을 준다.",
    "사주는 자기 이해를 돕는 참고 콘텐츠다. 의료, 법률, 금융 판단은 전문가 상담을 권한다.",
    "답변 끝에는 사용자가 이어서 물어볼 만한 후속 질문 2~3개를 [SUGGESTED_QUESTIONS] 블록에 한 줄씩 넣는다.",
    "",
    `상담 유형: ${getChatTypeLabel(options.chatType)}`,
    options.autoMention ? "진입 시 자동 멘션 맥락이 포함된 상담이다." : "",
    options.targetProfileId ? `대상 프로필 ID: ${options.targetProfileId}` : "",
    `프로필: ${profile.display_name}, 성별 ${profile.gender}, 생년월일 ${profile.birth_date}, ${calendarLabel}`,
    `사주: ${sajuLine}`,
    `오행 분포: ${safeJson(analysis?.oheng_distribution)}`,
    `용신: ${safeJson(analysis?.yongsin)}`,
    `격국: ${safeJson(analysis?.gyeokguk)}`,
    `십신: ${safeJson(analysis?.sipsin_info)}`,
    summary?.content ? `AI 평생 분석 요약: ${safeJson(summary.content)}` : "",
    contextSummary ? `이전 대화 요약: ${contextSummary}` : "",
  ]
    .filter(Boolean)
    .join("\n");
}

export function parseSuggestedQuestions(content: string) {
  const match = content.match(/\[SUGGESTED_QUESTIONS\]([\s\S]*?)(?:\[\/SUGGESTED_QUESTIONS\]|$)/);
  if (!match) return { content: content.trim(), questions: [] as string[] };

  const questions = match[1]
    .split(/\r?\n/)
    .map((line) => line.replace(/^[-*\d.\s]+/, "").trim())
    .filter(Boolean)
    .slice(0, 3);

  return {
    content: content.replace(match[0], "").trim(),
    questions,
  };
}

export async function requestAiChatAnswer({
  client,
  userId,
  profile,
  analysis,
  summary,
  session,
  history,
  message,
  options,
}: {
  client: SupabaseClient;
  userId: string;
  profile: SajuProfileRow;
  analysis: SajuAnalysisRow | null;
  summary?: AiSummaryRow | null;
  session: ChatSessionRow;
  history: ChatMessageRow[];
  message: string;
  options: ChatRouteOptions;
}) {
  const messages = [
    {
      role: "system",
      content: buildSystemPrompt({
        profile,
        analysis,
        summary,
        contextSummary: session.context_summary,
        options,
      }),
    },
    ...history.slice(-20).map((item) => ({
      role: item.role === "assistant" ? "assistant" : "user",
      content: item.content,
    })),
    { role: "user", content: message },
  ];

  const { data, error } = await client.functions.invoke<AiGeminiResponse>(
    "ai-gemini",
    {
      body: {
        messages,
        model: "gemini-2.5-flash-lite",
        max_tokens: 2048,
        temperature: 0.8,
        user_id: userId,
        session_id: session.id,
        stream: false,
      },
    },
  );

  if (error) throw new Error(`AI 응답 실패: ${error.message}`);
  if (!data?.success) throw new Error(data?.error ?? "AI 응답 생성 실패");

  const parsed = parseSuggestedQuestions(data.content ?? "");
  return {
    content: parsed.content,
    suggestedQuestions: parsed.questions,
    tokensUsed: data.usage?.completion_tokens ?? null,
  };
}

function normalizeOptionalId(value: string | null) {
  const trimmed = value?.trim();
  return trimmed && trimmed.length > 0 ? trimmed : null;
}

function truncate(value: string, length: number) {
  return value.length > length ? `${value.slice(0, length)}...` : value;
}

function buildSessionTitle(message: string) {
  return truncate(message, 30);
}

function safeJson(value: unknown) {
  try {
    return JSON.stringify(value ?? {}, null, 2);
  } catch {
    return "{}";
  }
}
