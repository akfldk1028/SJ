export const profilesTable = "saju_profiles";
export const analysesTable = "saju_analyses";
export const aiSummariesTable = "ai_summaries";
export const chatSessionsTable = "chat_sessions";
export const chatMessagesTable = "chat_messages";
export const subscriptionsTable = "subscriptions";
export const profileRelationsTable = "profile_relations";
export const compatibilityAnalysesTable = "compatibility_analyses";

export const profileColumns = {
  id: "id",
  userId: "user_id",
  displayName: "display_name",
  relationType: "relation_type",
  memo: "memo",
  birthDate: "birth_date",
  birthTimeMinutes: "birth_time_minutes",
  birthTimeUnknown: "birth_time_unknown",
  isLunar: "is_lunar",
  isLeapMonth: "is_leap_month",
  gender: "gender",
  birthCity: "birth_city",
  timeCorrection: "time_correction",
  useYaJasi: "use_ya_jasi",
  profileType: "profile_type",
  countryCode: "country_code",
  locale: "locale",
  zodiacAnimal: "zodiac_animal",
  zodiacElement: "zodiac_element",
  zodiacGanji: "zodiac_ganji",
  createdAt: "created_at",
  updatedAt: "updated_at",
} as const;

export const analysisColumns = {
  id: "id",
  profileId: "profile_id",
  yearGan: "year_gan",
  yearJi: "year_ji",
  monthGan: "month_gan",
  monthJi: "month_ji",
  dayGan: "day_gan",
  dayJi: "day_ji",
  hourGan: "hour_gan",
  hourJi: "hour_ji",
  correctedDatetime: "corrected_datetime",
  ohengDistribution: "oheng_distribution",
  dayStrength: "day_strength",
  yongsin: "yongsin",
  gyeokguk: "gyeokguk",
  sipsinInfo: "sipsin_info",
  jijangganInfo: "jijanggan_info",
  sinsalList: "sinsal_list",
  daeun: "daeun",
  currentSeun: "current_seun",
  aiSummary: "ai_summary",
  calculatedAt: "calculated_at",
  updatedAt: "updated_at",
  twelveUnsung: "twelve_unsung",
  twelveSinsal: "twelve_sinsal",
  gilseong: "gilseong",
  hapchung: "hapchung",
} as const;

export const aiSummaryColumns = {
  id: "id",
  userId: "user_id",
  profileId: "profile_id",
  summaryType: "summary_type",
  content: "content",
  inputData: "input_data",
  modelProvider: "model_provider",
  modelName: "model_name",
  promptTokens: "prompt_tokens",
  completionTokens: "completion_tokens",
  totalTokens: "total_tokens",
  cachedTokens: "cached_tokens",
  totalCostUsd: "total_cost_usd",
  processingTimeMs: "processing_time_ms",
  status: "status",
  isCached: "is_cached",
  promptVersion: "prompt_version",
  locale: "locale",
  createdAt: "created_at",
  updatedAt: "updated_at",
} as const;

export const chatSessionColumns = {
  id: "id",
  profileId: "profile_id",
  title: "title",
  chatType: "chat_type",
  messageCount: "message_count",
  lastMessagePreview: "last_message_preview",
  contextSummary: "context_summary",
  targetProfileId: "target_profile_id",
  totalTokensUsed: "total_tokens_used",
  userMessageCount: "user_message_count",
  assistantMessageCount: "assistant_message_count",
  chatPersona: "chat_persona",
  mbtiQuadrant: "mbti_quadrant",
  locale: "locale",
  createdAt: "created_at",
  updatedAt: "updated_at",
} as const;

export const chatMessageColumns = {
  id: "id",
  sessionId: "session_id",
  role: "role",
  content: "content",
  suggestedQuestions: "suggested_questions",
  tokensUsed: "tokens_used",
  status: "status",
  createdAt: "created_at",
} as const;

export const subscriptionColumns = {
  id: "id",
  userId: "user_id",
  productId: "product_id",
  platform: "platform",
  status: "status",
  originalTransactionId: "original_transaction_id",
  startsAt: "starts_at",
  expiresAt: "expires_at",
  isLifetime: "is_lifetime",
  cancelledAt: "cancelled_at",
  createdAt: "created_at",
  updatedAt: "updated_at",
} as const;

export const profileSelectColumns = `
  id,
  user_id,
  display_name,
  relation_type,
  memo,
  birth_date,
  birth_time_minutes,
  birth_time_unknown,
  is_lunar,
  is_leap_month,
  gender,
  birth_city,
  time_correction,
  use_ya_jasi,
  profile_type,
  country_code,
  locale,
  zodiac_animal,
  zodiac_element,
  zodiac_ganji,
  created_at,
  updated_at
`;

export const analysisSelectColumns = `
  id,
  profile_id,
  year_gan,
  year_ji,
  month_gan,
  month_ji,
  day_gan,
  day_ji,
  hour_gan,
  hour_ji,
  corrected_datetime,
  oheng_distribution,
  day_strength,
  yongsin,
  gyeokguk,
  sipsin_info,
  jijanggan_info,
  sinsal_list,
  daeun,
  current_seun,
  twelve_unsung,
  twelve_sinsal,
  gilseong,
  hapchung,
  calculated_at,
  updated_at
`;

export const aiSummarySelectColumns = `
  id,
  user_id,
  profile_id,
  summary_type,
  content,
  input_data,
  model_provider,
  model_name,
  prompt_tokens,
  completion_tokens,
  total_tokens,
  cached_tokens,
  total_cost_usd,
  processing_time_ms,
  status,
  is_cached,
  prompt_version,
  locale,
  created_at,
  updated_at
`;

export const chatSessionSelectColumns = `
  id,
  profile_id,
  title,
  chat_type,
  message_count,
  last_message_preview,
  context_summary,
  target_profile_id,
  total_tokens_used,
  user_message_count,
  assistant_message_count,
  chat_persona,
  mbti_quadrant,
  locale,
  created_at,
  updated_at
`;

export const chatMessageSelectColumns = `
  id,
  session_id,
  role,
  content,
  suggested_questions,
  tokens_used,
  status,
  created_at
`;

export const subscriptionSelectColumns = `
  id,
  user_id,
  product_id,
  platform,
  status,
  original_transaction_id,
  starts_at,
  expires_at,
  is_lifetime,
  cancelled_at,
  created_at,
  updated_at
`;

export const profileRelationSelectColumns = `
  id,
  user_id,
  from_profile_id,
  to_profile_id,
  relation_type,
  display_name,
  memo,
  is_favorite,
  sort_order,
  created_at,
  updated_at,
  from_profile_analysis_id,
  to_profile_analysis_id,
  analysis_status,
  analysis_requested_at,
  compatibility_analysis_id,
  analysis_completed_at,
  pair_hapchung
`;
