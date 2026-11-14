export type CallState="created"|"connecting"|"active"|"ended"|"failed";
export type CallParticipantRole="host"|"guest";
export type CallSession={id:string;matchSessionId:string;roomName:string;state:CallState;startedAt:number|null;endedAt:number|null;endReason:string|null};
export type LiveKitGrantInput={roomName:string;identity:string;canPublish:boolean;canSubscribe:boolean;ttlSeconds:number};
export type LiveKitTokenResult={token:string;expiresAt:number};
