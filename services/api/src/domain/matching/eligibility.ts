export type EligibilityReason = "eligible"|"profile_missing"|"terms_missing"|"privacy_missing"|"age_assurance_missing"|"blocked_edge_exists"|"sanctioned"|"underage"|"age_verification_required"|"rate_limited";
export type EligibilityResult = {eligible:true;reason:"eligible"}|{eligible:false;reason:Exclude<EligibilityReason,"eligible">};
export type MatchCandidate = {userId:string;region:string|null;language:string|null};
/** Pair check must reject a block in either direction; never trust client filters. */
export function pairIsBlocked(a:string,b:string,edges:ReadonlyArray<{blockerId:string;blockedId:string}>):boolean {
 return edges.some(e=>(e.blockerId===a&&e.blockedId===b)||(e.blockerId===b&&e.blockedId===a));
}
export function eligibleForMatch(input:{profileExists:boolean;terms:boolean;privacy:boolean;ageAssurance:boolean;sanctioned:boolean;ageVerified:boolean;rateLimited:boolean}):EligibilityResult {
 if(!input.profileExists)return {eligible:false,reason:"profile_missing"};
 if(!input.terms)return {eligible:false,reason:"terms_missing"};
 if(!input.privacy)return {eligible:false,reason:"privacy_missing"};
 if(!input.ageAssurance)return {eligible:false,reason:"age_assurance_missing"};
 if(!input.ageVerified)return {eligible:false,reason:"age_verification_required"};
 if(input.sanctioned)return {eligible:false,reason:"sanctioned"};
 if(input.rateLimited)return {eligible:false,reason:"rate_limited"};
 return {eligible:true,reason:"eligible"};
}
