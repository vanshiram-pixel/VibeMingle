import { AccessToken } from "livekit-server-sdk";
import { env } from "../../config/env.js";
import { clampTokenTtl } from "./policy.js";
import type { LiveKitTokenResult } from "./types.js";
export function liveKitConfigured():boolean{return Boolean(env.livekitUrl&&env.livekitApiKey&&env.livekitApiSecret);}
export async function mintLiveKitToken(input:{roomName:string;identity:string;ttlSeconds?:number}):Promise<LiveKitTokenResult>{
 if(!liveKitConfigured())throw new Error("LiveKit provider is not configured");
 const ttl=clampTokenTtl(input.ttlSeconds??120);
 const token=new AccessToken(env.livekitApiKey!,env.livekitApiSecret!,{identity:input.identity,ttl:ttl});
 token.addGrant({roomJoin:true,room:input.roomName,canPublish:true,canSubscribe:true,canPublishData:true});
 return {token:await token.toJwt(),expiresAt:Date.now()+ttl*1000};
}
