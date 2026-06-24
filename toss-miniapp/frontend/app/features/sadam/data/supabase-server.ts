import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const accessCookieName = "sadam_toss_access_token";

export type SupabaseEnv = {
  SUPABASE_URL?: string;
  SUPABASE_ANON_KEY?: string;
};

function getRequiredSupabaseEnv(env: SupabaseEnv) {
  if (!env.SUPABASE_URL || !env.SUPABASE_ANON_KEY) {
    throw new Error("Supabase 환경변수가 설정되지 않았습니다.");
  }

  return {
    url: env.SUPABASE_URL,
    anonKey: env.SUPABASE_ANON_KEY,
  };
}

export function createAnonSupabase(env: SupabaseEnv) {
  const { url, anonKey } = getRequiredSupabaseEnv(env);
  return createClient(url, anonKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

export function createUserSupabase(env: SupabaseEnv, accessToken: string) {
  const { url, anonKey } = getRequiredSupabaseEnv(env);
  return createClient(url, anonKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
    global: {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    },
  });
}

function parseCookie(header: string | null) {
  const cookies = new Map<string, string>();
  if (!header) return cookies;

  for (const part of header.split(";")) {
    const [rawKey, ...rawValue] = part.trim().split("=");
    if (!rawKey) continue;
    cookies.set(rawKey, decodeURIComponent(rawValue.join("=")));
  }

  return cookies;
}

export function getAccessTokenFromRequest(request: Request) {
  return parseCookie(request.headers.get("Cookie")).get(accessCookieName) ?? null;
}

export async function ensureAnonymousSession(
  request: Request,
  env: SupabaseEnv,
): Promise<{
  accessToken: string;
  userId: string;
  client: SupabaseClient;
  cookieHeader: string | null;
}> {
  const existingToken = getAccessTokenFromRequest(request);

  if (existingToken) {
    const client = createUserSupabase(env, existingToken);
    const { data, error } = await client.auth.getUser(existingToken);
    if (!error && data.user) {
      return {
        accessToken: existingToken,
        userId: data.user.id,
        client,
        cookieHeader: null,
      };
    }
  }

  const anonClient = createAnonSupabase(env);
  const { data, error } = await anonClient.auth.signInAnonymously();

  if (error || !data.session || !data.user) {
    throw new Error(error?.message ?? "Supabase 익명 로그인에 실패했습니다.");
  }

  const accessToken = data.session.access_token;
  return {
    accessToken,
    userId: data.user.id,
    client: createUserSupabase(env, accessToken),
    cookieHeader: `${accessCookieName}=${encodeURIComponent(accessToken)}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${60 * 60 * 24 * 30}`,
  };
}

export function createClientFromRequest(request: Request, env: SupabaseEnv) {
  const accessToken = getAccessTokenFromRequest(request);
  if (!accessToken) return null;
  return createUserSupabase(env, accessToken);
}
