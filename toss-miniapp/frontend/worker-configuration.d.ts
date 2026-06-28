// Generated Wrangler env types, redacted for repository safety.

interface Env {
	DATABASE_PASSWORD: string;
	DATABASE_URL: string;
	SUPABASE_URL: string;
	SUPABASE_ANON_KEY: string;
	TOSS_PAYMENTS_SECRET_KEY: string;
	SUPABASE_SERVICE_ROLE_KEY: string;
	POSTHOG_API_KEY?: string;
	POSTHOG_HOST?: string;
}

interface ImportMetaEnv {
	readonly VITE_TOSS_PAYMENTS_CLIENT_KEY?: string;
}

interface ImportMeta {
	readonly env: ImportMetaEnv;
}
