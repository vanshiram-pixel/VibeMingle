import Fastify from "fastify";
import { createHealthResponse } from "@vibemingle/contracts/health";
import { env } from "./config/env.js";
import { registerAuthRoutes } from "./routes/auth.js";
import { registerMeRoutes } from "./routes/me.js";
import { registerOnboardingRoutes } from "./routes/onboarding.js";
import { registerMatchingRoutes } from "./routes/matching.js";
import { registerSocialRoutes } from "./routes/social.js";
import { registerCallRoutes } from "./routes/calls.js";
import { registerMessagingRoutes } from "./routes/messaging.js";\nimport { registerAiRoutes } from "./routes/ai.js";
import { AuthenticationError } from "./plugins/supabase-user.js";

const app = Fastify({
  logger: { level: env.logLevel },
  requestIdHeader: "x-request-id",
  disableRequestLogging: false,
});

await app.register(registerAuthRoutes);
await app.register(registerMeRoutes);
await app.register(registerOnboardingRoutes);
await app.register(registerMatchingRoutes);
await app.register(registerSocialRoutes);
await app.register(registerCallRoutes);
await app.register(registerMessagingRoutes);\nawait app.register(registerAiRoutes);

app.get("/health", async () => createHealthResponse(env.appVersion));
app.get("/ready", async (_request, reply) => {
  // Readiness will check DB/provider dependencies once integrations are configured.
  return reply.code(200).send({ ready: true, checks: { scaffold: "ok" } });
});

app.setErrorHandler((error: import("fastify").FastifyError, request, reply) => {
  request.log.error({ err: error }, "request failed");
  const statusCode = error instanceof AuthenticationError ? 401 : (error.statusCode && error.statusCode >= 400 ? error.statusCode : 500);
  return reply.code(statusCode).send({
    error: { code: statusCode >= 500 ? "INTERNAL_ERROR" : "REQUEST_ERROR",
      message: statusCode >= 500 ? "An unexpected error occurred." : error.message,
      requestId: request.id },
  });
});

try {
  await app.listen({ host: env.host, port: env.port });
} catch (error) {
  app.log.error(error instanceof Error ? error : new Error(String(error)));
  process.exitCode = 1;
}