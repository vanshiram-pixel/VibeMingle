// V4.1 server-side matchmaking worker. Deploy only to a dedicated VibeMingle Supabase project.
// Secrets: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, MATCH_WORKER_SECRET.
// This worker never accepts a peer identity from a client and never broadens filters.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "access-control-allow-origin": "https://vibemingle.app",
  "access-control-allow-headers": "authorization, x-match-worker-secret, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "content-type": "application/json",
};
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: cors });
const intersects = (a: string[] | null, b: string[] | null) =>
  (a ?? []).some((x) => (b ?? []).includes(x));

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const secret = Deno.env.get("MATCH_WORKER_SECRET");
  if (!secret || req.headers.get("x-match-worker-secret") !== secret) return json({ error: "unauthorized" }, 401);

  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceKey) return json({ error: "worker_configuration_missing" }, 500);
  const db = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });

  try {
    const { data: queue, error: qe } = await db.from("match_queue")
      .select("user_id,age_band,gender_preference,languages,interests,queued_at")
      .eq("queue_state", "waiting").gte("heartbeat_at", new Date(Date.now() - 30_000).toISOString())
      .order("queued_at", { ascending: true }).limit(100);
    if (qe) throw qe;
    if (!queue || queue.length < 2) return json({ scanned: queue?.length ?? 0, reserved: 0 });

    const ids = queue.map((q) => q.user_id);
    const [{ data: profiles, error: pe }, { data: consents, error: ce }, { data: eligibility, error: ee }] = await Promise.all([
      db.from("profiles").select("id,age_band,gender,languages,interests,discoverable").in("id", ids),
      db.from("match_user_consent").select("user_id,enabled").in("user_id", ids),
      db.from("match_eligibility").select("user_id,age_verified").in("user_id", ids),
    ]);
    if (pe || ce || ee) throw pe ?? ce ?? ee;
    const p = new Map((profiles ?? []).map((x) => [x.id, x]));
    const consent = new Set((consents ?? []).filter((x) => x.enabled).map((x) => x.user_id));
    const eligible = new Set((eligibility ?? []).filter((x) => x.age_verified).map((x) => x.user_id));
    const active = queue.filter((q) => p.get(q.user_id)?.discoverable && consent.has(q.user_id) && eligible.has(q.user_id));
    let reserved = 0;
    const attempted = new Set<string>();

    // Oldest-first, strict bilateral matching. RPC locks/revalidates all critical facts.
    outer: for (let i = 0; i < active.length; i++) {
      const a = active[i];
      if (attempted.has(a.user_id)) continue;
      const pa = p.get(a.user_id);
      for (let j = i + 1; j < active.length; j++) {
        const b = active[j];
        if (attempted.has(b.user_id)) continue;
        const pb = p.get(b.user_id);
        if (!pa || !pb || a.user_id === b.user_id) continue;
        // Age bands are exact target bands until a reviewed range model is implemented.
        if ((a.age_band && a.age_band !== pb.age_band) || (b.age_band && b.age_band !== pa.age_band)) continue;
        if (a.gender_preference && a.gender_preference !== "any" && a.gender_preference !== pb.gender) continue;
        if (b.gender_preference && b.gender_preference !== "any" && b.gender_preference !== pa.gender) continue;
        if ((a.languages?.length && !intersects(a.languages, pb.languages)) ||
            (b.languages?.length && !intersects(b.languages, pa.languages))) continue;
        if ((a.interests?.length && !intersects(a.interests, pb.interests)) ||
            (b.interests?.length && !intersects(b.interests, pa.interests))) continue;
        const { data, error } = await db.rpc("match_reserve_pair", {
          p_user_a: a.user_id, p_user_b: b.user_id, p_session_id: crypto.randomUUID(),
        });
        if (error) {
          // Never silently fall back or widen a user's preferences.
          console.error("reservation RPC rejected pair", error.code);
          continue;
        }
        if (data === true) {
          attempted.add(a.user_id); attempted.add(b.user_id); reserved++;
          continue outer;
        }
      }
    }
    return json({ scanned: queue.length, eligible: active.length, reserved });
  } catch (e) {
    console.error("match worker failed", e);
    return json({ error: "worker_failed" }, 500);
  }
});
