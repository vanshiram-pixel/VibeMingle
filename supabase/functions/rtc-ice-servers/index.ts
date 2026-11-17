import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function response(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

function encodeBase64(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return response({ error: "Method not allowed" }, 405);

  const authorization = req.headers.get("Authorization");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!authorization || !supabaseUrl || !anonKey) {
    return response({ error: "Authentication required" }, 401);
  }

  const supabase = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) return response({ error: "Invalid session" }, 401);

  const stunUrls = (Deno.env.get("RTC_STUN_URLS") ??
    "stun:stun.l.google.com:19302").split(",").map((v) => v.trim()).filter(Boolean);
  const iceServers: Record<string, unknown>[] = stunUrls.map((urls) => ({ urls }));

  // TURN uses Coturn REST API credentials: the shared secret stays server-side.
  // The client receives a short-lived username/password pair, never the shared secret.
  const turnUrls = (Deno.env.get("RTC_TURN_URLS") ?? "")
    .split(",").map((v) => v.trim()).filter(Boolean);
  const sharedSecret = Deno.env.get("RTC_TURN_SHARED_SECRET");
  if (turnUrls.length && sharedSecret) {
    const expiresAt = Math.floor(Date.now() / 1000) + 3600;
    const username = `${expiresAt}:${user.id}`;
    const key = await crypto.subtle.importKey(
      "raw",
      new TextEncoder().encode(sharedSecret),
      { name: "HMAC", hash: "SHA-1" },
      false,
      ["sign"],
    );
    const signature = await crypto.subtle.sign(
      "HMAC",
      key,
      new TextEncoder().encode(username),
    );
    iceServers.push({
      urls: turnUrls,
      username,
      credential: encodeBase64(new Uint8Array(signature)),
    });
  }

  return response({ iceServers, expiresIn: 3600 });
});
