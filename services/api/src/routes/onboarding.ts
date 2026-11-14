import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { authenticatedSupabase } from "../plugins/supabase-user.js";

const onboardingSchema = z.object({
  display_name: z.string().trim().min(2).max(40),
  preferred_language: z.string().trim().min(2).max(12).default("en"),
  interests: z.array(z.string().trim().min(1).max(32)).max(20).default([]),
  accepted_terms_version: z.string().trim().min(1).max(40,
  ),
  accepted_privacy_version: z.string().trim().min(1).max(40,
  ),
  age_confirmed: z.literal(true),
}).strict();

export async function registerOnboardingRoutes(app: FastifyInstance): Promise<void> {
  app.post("/v1/onboarding/complete", async (request, reply) => {
    const parsed = onboardingSchema.safeParse(request.body);
    if (!parsed.success) return reply.code(400).send({
      error: { code: "ONBOARDING_INVALID", message: "Required onboarding fields are missing or invalid.", details: parsed.error.flatten() },
    });
    const { user, client } = await authenticatedSupabase(request);
    const { data: profile, error: profileError } = await client.from("profiles").upsert({
      id: user.id, display_name: parsed.data.display_name,
      preferred_language: parsed.data.preferred_language, interests: parsed.data.interests,
    }, { onConflict: "id" }).select("id,display_name,preferred_language,interests").single();
    if (profileError) return reply.code(400).send({
      error: { code: "ONBOARDING_PROFILE_FAILED", message: "Profile could not be saved." },
    });
    // Consent history is intentionally server-only. A dedicated trusted consent
    // service/migration will persist terms/privacy versions and age assurance.
    return reply.code(202).send({
      data: { profile, consentPending: true, next: "consent-recording-service" },
    });
  });
}
