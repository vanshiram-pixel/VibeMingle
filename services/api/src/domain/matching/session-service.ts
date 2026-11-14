import { randomUUID } from "node:crypto";
import { pairIsBlocked, eligibleForMatch } from "./eligibility.js";
import type { EligibilityResult } from "./eligibility.js";
export type SessionRecord={id:string;participantA:string;participantB:string;status:"created"|"active"|"ended"|"cancelled"|"reported";createdAt:number};
/** Pure guard/reference logic; persistence + atomic transaction adapter is still required. */
export function createSessionGuard(input:{a:string;b:string;eligibilityA:Parameters<typeof eligibleForMatch>[0];eligibilityB:Parameters<typeof eligibleForMatch>[0];blockEdges:ReadonlyArray<{blockerId:string;blockedId:string}>}):{ok:true;record:SessionRecord}|{ok:false;reason:string}{
 if(input.a===input.b)return {ok:false,reason:"same_user"};
 const ea=eligibleForMatch(input.eligibilityA),eb=eligibleForMatch(input.eligibilityB);
 if(!ea.eligible)return {ok:false,reason:"participant_a_"+ea.reason};
 if(!eb.eligible)return {ok:false,reason:"participant_b_"+eb.reason};
 if(pairIsBlocked(input.a,input.b,input.blockEdges))return {ok:false,reason:"blocked_pair"};
 return {ok:true,record:{id:randomUUID(),participantA:input.a,participantB:input.b,status:"created",createdAt:Date.now()}};
}
