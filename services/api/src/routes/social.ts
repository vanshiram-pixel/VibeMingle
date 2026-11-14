import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { authenticatedSupabase } from "../plugins/supabase-user.js";

const requestSchema = z.object({ targetUserId: z.string().uuid() }).strict();
const requestIdSchema = z.object({ requestId: z.string().uuid() }).strict();
const responseSchema = z.object({ action: z.enum(["accept", "reject"]) }).strict();

function rpcError(reply: any, error: { code?: string; message?: string }) {
  const code = error.code;
  if (code === "28000") return reply.code(401).send({ error: { code: "UNAUTHENTICATED", message: "Sign in again." } });
  if (code === "42501") return reply.code(403).send({ error: { code: "REQUEST_UNAVAILABLE", message: "Request is unavailable or access is not allowed." } });
  if (code === "23505") return reply.code(409).send({ error: { code: "REQUEST_CONFLICT", message: "Request is no longer pending or a friendship already exists." } });
  if (code === "22023") return reply.code(400).send({ error: { code: "INVALID_REQUEST", message: "Request action or target is invalid." } });
  return reply.code(400).send({ error: { code: "SOCIAL_ACTION_FAILED", message: "Social action could not be completed." } });
}

export async function registerSocialRoutes(app: FastifyInstance): Promise<void> {

  app.get("/v1/users/discover", async (request, reply) => {
    const query = z.object({ q: z.string().max(64).optional(), limit: z.coerce.number().int().min(1).max(30).optional() }).safeParse(request.query);
    if (!query.success) return reply.code(400).send({ error: { code: "INVALID_QUERY", message: "Search query is invalid." } });
    const { client } = await authenticatedSupabase(request);
    const { data, error } = await client.rpc("user_discover", { p_query: query.data.q ?? "", p_limit: query.data.limit ?? 20 });
    if (error) return rpcError(reply, error);
    return reply.send({ data });
  });

  app.post("/v1/friends/requests", async (request, reply) => {
    const parsed = requestSchema.safeParse(request.body);
    if (!parsed.success) return reply.code(400).send({ error: { code: "INVALID_TARGET", message: "Target user id is invalid." } });
    const { user, client } = await authenticatedSupabase(request);
    if (user.id === parsed.data.targetUserId) return reply.code(400).send({ error: { code: "SELF_REQUEST", message: "You cannot friend yourself." } });
    const { data, error } = await client.rpc("friend_request_create", { p_target: parsed.data.targetUserId });
    if (error) return rpcError(reply, error);
    return reply.code(201).send({ data });
  });

  app.post("/v1/friends/requests/:requestId/respond", async (request, reply) => {
    const params = requestIdSchema.safeParse(request.params);
    const body = responseSchema.safeParse(request.body);
    if (!params.success || !body.success) return reply.code(400).send({ error: { code: "INVALID_REQUEST", message: "Request id or action is invalid." } });
    const { client } = await authenticatedSupabase(request);
    const { data, error } = await client.rpc("friend_request_respond", { p_request: params.data.requestId, p_action: body.data.action });
    if (error) return rpcError(reply, error);
    return reply.send({ data });
  });

  app.delete("/v1/friends/requests/:requestId", async (request, reply) => {
    const params = requestIdSchema.safeParse(request.params);
    if (!params.success) return reply.code(400).send({ error: { code: "INVALID_REQUEST", message: "Request id is invalid." } });
    const { client } = await authenticatedSupabase(request);
    const { data, error } = await client.rpc("friend_request_cancel", { p_request: params.data.requestId });
    if (error) return rpcError(reply, error);
    return reply.send({ data });
  });

  app.get("/v1/friends/requests", async (request, reply) => {
    const { user, client } = await authenticatedSupabase(request);
    const { data, error } = await client.from("friend_requests")
      .select("id,sender_id,receiver_id,status,created_at,responded_at")
      .or(`sender_id.eq.${user.id},receiver_id.eq.${user.id}`)
      .order("created_at", { ascending: false }).limit(100);
    if (error) return reply.code(400).send({ error: { code: "FRIEND_REQUESTS_READ_FAILED", message: "Friend requests unavailable." } });
    return reply.send({ data });
  });

  app.get("/v1/friends", async (request, reply) => {
    const { client } = await authenticatedSupabase(request);
    const { data, error } = await client.rpc("friend_list_safe");
    if (error) return rpcError(reply, error);
    return reply.send({ data });
  });

  app.delete("/v1/friends/:friendId", async (request, reply) => {
    const params = z.object({ friendId: z.string().uuid() }).safeParse(request.params);
    if (!params.success) return reply.code(400).send({ error: { code: "INVALID_TARGET", message: "Friend id is invalid." } });
    const { client } = await authenticatedSupabase(request);
    const { data, error } = await client.rpc("friendship_remove", { p_friend: params.data.friendId });
    if (error) return rpcError(reply, error);
    return reply.send({ data });
  });

  app.post("/v1/blocks/:userId", async (request, reply) => {
    const params = z.object({ userId: z.string().uuid() }).safeParse(request.params);
    if (!params.success) return reply.code(400).send({ error: { code: "INVALID_TARGET", message: "User id is invalid." } });
    const { client } = await authenticatedSupabase(request);
    const { data, error } = await client.rpc("user_block_create", { p_target: params.data.userId });
    if (error) return rpcError(reply, error);
    return reply.send({ data });
  });

  app.delete("/v1/blocks/:userId", async (request, reply) => {
    const params = z.object({ userId: z.string().uuid() }).safeParse(request.params);
    if (!params.success) return reply.code(400).send({ error: { code: "INVALID_TARGET", message: "User id is invalid." } });
    const { client } = await authenticatedSupabase(request);
    const { data, error } = await client.rpc("user_block_remove", { p_target: params.data.userId });
    if (error) return rpcError(reply, error);
    return reply.send({ data });
  });

  app.post("/v1/presence/heartbeat", async (request, reply) => {
    const { client } = await authenticatedSupabase(request);
    const { data, error } = await client.rpc("presence_heartbeat");
    if (error) return rpcError(reply, error);
    return reply.send({ data });
  });

  app.patch("/v1/presence/settings", async (request, reply) => {
    const body = z.object({ visibility: z.enum(["everyone", "friends", "nobody"]), showOnline: z.boolean() }).strict().safeParse(request.body);
    if (!body.success) return reply.code(400).send({ error: { code: "INVALID_PRESENCE_SETTINGS", message: "Presence settings are invalid." } });
    const { client } = await authenticatedSupabase(request);
    const { data, error } = await client.rpc("presence_settings_update", { p_visibility: body.data.visibility, p_show_online: body.data.showOnline });
    if (error) return rpcError(reply, error);
    return reply.send({ data });
  });
}
