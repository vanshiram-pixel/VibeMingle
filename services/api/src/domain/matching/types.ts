export type MatchPreferences = { region?: string; language?: string; interests?: string[]; genderFilter?: "any" | "women" | "men" | "other"; };
export type QueueTicket = { userId:string; queuedAt:number; preferences:MatchPreferences; requestId:string };
export type MatchPair = { sessionId:string; firstUserId:string; secondUserId:string; matchedAt:number; };
export type MatchOutcome = { status:"matched"; match:MatchPair } | { status:"queued"; position:number; estimatedWaitSeconds:number } | { status:"already_active" };
