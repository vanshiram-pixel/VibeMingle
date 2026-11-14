export const MAX_CALL_TOKEN_TTL_SECONDS=300;
export function buildRoomName(sessionId:string):string{return `vm-session-${sessionId}`;}
export function validateTokenGrant(input:{actorId:string;sessionId:string;participantIds:string[];sessionState:"created"|"connecting"|"active"|"ended"|"failed";ageVerified:boolean;sanctioned:boolean;blockedWithParticipant:boolean}):{allowed:boolean;reason?:string}{
 if(!input.participantIds.includes(input.actorId))return {allowed:false,reason:"not_session_participant"};
 if(input.sessionState==="ended"||input.sessionState==="failed")return {allowed:false,reason:"session_not_joinable"};
 if(!input.ageVerified)return {allowed:false,reason:"age_not_verified"};
 if(input.sanctioned)return {allowed:false,reason:"account_restricted"};
 if(input.blockedWithParticipant)return {allowed:false,reason:"blocked"};
 return {allowed:true};
}
export function clampTokenTtl(seconds:number):number{return Math.max(30,Math.min(MAX_CALL_TOKEN_TTL_SECONDS,Math.floor(seconds)));}
