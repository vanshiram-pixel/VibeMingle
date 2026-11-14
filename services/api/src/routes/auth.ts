import type { FastifyInstance } from "fastify";
import { authenticatedSupabase } from "../plugins/supabase-user.js";

export async function registerAuthRoutes(app: FastifyInstance): Promise<void> {
  // Google OAuth is initiated by Supabase Auth on the client. This endpoint validates
  // the resulting access token and returns only a minimal identity confirmation.
  app.get("/v1/auth/session", async (request, reply) => {
    const { user } = await authenticatedSupabase(request);
    return reply.send({ data: { userId: user.id, authenticated: true } });
  });
}
