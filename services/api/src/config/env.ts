import "dotenv/config";

function required(name: string, fallback?: string): string {
  const value = process.env[name] ?? fallback;
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function positiveInteger(name: string, fallback: number): number {
  const raw = process.env[name];
  if (!raw) return fallback;
  const value = Number(raw);
  if (!Number.isInteger(value) || value <= 0) throw new Error(`${name} must be a positive integer`);
  return value;
}

export const env = {
  nodeEnv: process.env.NODE_ENV ?? "development",
  host: process.env.API_HOST ?? "127.0.0.1",
  port: positiveInteger("API_PORT", 4000),
  appVersion: process.env.APP_VERSION ?? "0.1.0",
  logLevel: process.env.LOG_LEVEL ?? "info",
  // Supabase/provider secrets are intentionally not required for the health-only scaffold.
  supabaseUrl: process.env.SUPABASE_URL,  supabaseAnonKey: process.env.SUPABASE_ANON_KEY,
  supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
  livekitUrl: process.env.LIVEKIT_URL,
  livekitApiKey: process.env.LIVEKIT_API_KEY,
  livekitApiSecret: process.env.LIVEKIT_API_SECRET,\n  openaiApiKey: process.env.OPENAI_API_KEY,\n  aiTranslationEnabled: process.env.AI_TRANSLATION_ENABLED === "true",\n  aiTranslationModel: process.env.AI_TRANSLATION_MODEL ?? "gpt-4o-mini",
} as const;

export function assertProductionSecrets(): void {
  if (env.nodeEnv !== "production") return;
  required("SUPABASE_URL");
  required("SUPABASE_SERVICE_ROLE_KEY");
}