import { randomUUID } from "node:crypto";
import type { MatchOutcome, MatchPreferences, QueueTicket } from "./types.js";
import { compatible, sanitizePreferences } from "./policy.js";

/**
 * Local in-memory queue adapter for development only. Not multi-instance safe:
 * production MUST replace this with atomic Redis/Postgres queue + lease/lock.
 */
export class LocalMatchQueue {
 private queue:QueueTicket[]=[];
 private active=new Set<string>();
 enqueue(userId:string,prefs:MatchPreferences):MatchOutcome {
  if(this.active.has(userId)||this.queue.some(t=>t.userId===userId))return {status:"already_active"};
  const ticket:QueueTicket={userId,preferences:sanitizePreferences(prefs),queuedAt:Date.now(),requestId:randomUUID()};
  const idx=this.queue.findIndex(other=>compatible(ticket,other));
  if(idx>=0){
   const peer=this.queue.splice(idx,1)[0];this.active.add(userId);this.active.add(peer.userId);
   return {status:"matched",match:{sessionId:randomUUID(),firstUserId:peer.userId,secondUserId:userId,matchedAt:Date.now()}};
  }
  this.queue.push(ticket);return {status:"queued",position:this.queue.length,estimatedWaitSeconds:Math.min(45,this.queue.length*3)};
 }
 remove(userId:string):boolean {const n=this.queue.length;this.queue=this.queue.filter(t=>t.userId!==userId);return n!==this.queue.length;}
 markEnded(a:string,b:string):void {this.active.delete(a);this.active.delete(b);}
}
