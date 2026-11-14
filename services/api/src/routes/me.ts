import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { authenticatedSupabase } from "../plugins/supabase-user.js";

const profilePatch = z.object({
  display_name: z.string().trim().min(2).max(40).optional(),
  bio: z.string().trim().max(240).optional(),
  avatar_path: z.string().max(500).nullable().optional(),
  preferred_language: z.string().trim().min(2).max(12).optional(),
  interests: z.array(z.string().trim().min(1).max(32)).max(20).optional(),
}).strict().refine((v) => Object.keys(v).length > 0, "At least one profile field is required.");

export async function registerMeRoutes(app: FastifyInstance): Promise<void> {
  app.get("/v1/me", async (request, reply) => {
    const { user, client } = await authenticatedSupabase(request);
    const { data, error } = await client.from("profiles").select(
      "id,display_name,bio,avatar_path,preferred_language,interests,created_at,updated_at"
    ).eq("id", user.id).maybeSingle();
    if (error) throw new Error("Profile lookup failed.");
    return reply.send({ data: data ?? null });
  });

  app.patch("/v1/me/profile", async (request, reply) => {
    const parsed = profilePatch.safeParse(request.body);
    if (!parsed.success) return reply.code(400).send({
      error: { code: "VALIDATION_ERROR", message: "Profile fields are invalid.", details: parsed.error.flatten() },
    });
    const { user, client } = await authenticatedSupabase(request);
    const { data, error } = await client.from("profiles").upsert(
      { id: user.id, ...parsed.data }, { onConflict: "id" }
    ).select("id,display_name,bio,avatar_path,preferred_language,interests,created_at,updated_at").single();
    if (error) {
      request.log.warn({ code: error.code }, "profile update rejected by database policy");
      return reply.code(error.code === "42501" ? 403 : 400).send({
        error: { code: "PROFILE_UPDATE_FAILED", message: "Profile could not be saved." },
      });
    }
    return reply.send({ data });
  });
}
