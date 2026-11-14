import Fastify from "fastify";
import { createHealthResponse } from "@vibemingle/contracts/health";
import { env } from "./config/env.js";

const app = Fastify({
  logger: { level: env.logLevel },
  requestIdHeader: "x-request-id",
  disableRequestLogging: false,
});

app.get("/health", async () => createHealthResponse(env.appVersion));
app.get("/ready", async (_request, reply) => {
  // Readiness will check DB/provider dependencies once integrations are configured.
  return reply.code(200).send({ ready: true, checks: { scaffold: "ok" } });
});

app.setErrorHandler((error, request, reply) => {
  request.log.error({ err: error }, "request failed");
  const statusCode = error.statusCode && error.statusCode >= 400 ? error.statusCode : 500;
  return reply.code(statusCode).send({
    error: { code: statusCode >= 500 ? "INTERNAL_ERROR" : "REQUEST_ERROR",
      message: statusCode >= 500 ? "An unexpected error occurred." : error.message,
      requestId: request.id },
  });
});

try {
  await app.listen({ host: env.host, port: env.port });
} catch (error) {
  app.log.error(error);
  process.exitCode = 1;
}