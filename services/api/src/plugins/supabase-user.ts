import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { FastifyRequest } from "fastify";
import { env } from "../config/env.js";

export type AuthenticatedUser = { id: string; accessToken: string };

export class AuthenticationError extends Error {
  readonly statusCode = 401;
  constructor(message = "A valid sign-in session is required.") { super(message); }
}

export function bearerToken(request: FastifyRequest): string {
  const header = request.headers.authorization;
  if (!header?.startsWith("Bearer ")) throw new AuthenticationError();
  const token = header.slice(7).trim();
  if (!token) throw new AuthenticationError();
  return token;
}

/** Verify tokens remotely with Supabase Auth (never trust a decoded JWT alone). */
export async function authenticatedSupabase(request: FastifyRequest): Promise<{
  user: AuthenticatedUser; client: SupabaseClient;
}> {
  if (!env.supabaseUrl || !env.supabaseAnonKey) {
    throw new Error("Supabase Auth is not configured (SUPABASE_URL / SUPABASE_ANON_KEY).");
  }
  const token = bearerToken(request);
  const client = createClient(env.supabaseUrl, env.supabaseAnonKey, {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data, error } = await client.auth.getUser(token);
  if (error || !data.user) throw new AuthenticationError();
  return { user: { id: data.user.id, accessToken: token }, client };
}
