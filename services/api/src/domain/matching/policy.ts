import type { MatchPreferences, QueueTicket } from "./types.js";
export const MATCH_POLICY = { minAge:18, maxQueueWaitMs:90_000, maxWaitEstimateSeconds:45, pairLockTtlSeconds:12, regionFallback:"global", excludeSameUser:true } as const;
export function compatible(a:QueueTicket,b:QueueTicket):boolean {
 if(a.userId===b.userId)return false;
 if(a.preferences.region && b.preferences.region && a.preferences.region!==b.preferences.region)return false;
 if(a.preferences.language && b.preferences.language && a.preferences.language!==b.preferences.language)return false;
 const ag=a.preferences.genderFilter??"any",bg=b.preferences.genderFilter??"any";
 if(ag!=="any" && bg!=="any" && ag!==bg)return false;
 return true;
}
export function sanitizePreferences(input:MatchPreferences):MatchPreferences {
 return { ...(input.region ? {region:input.region.slice(0,12)} : {}), ...(input.language ? {language:input.language.slice(0,12)} : {}), interests:[...(input.interests??[])].slice(0,10).map(x=>x.slice(0,32)),genderFilter:input.genderFilter??"any"};
}
