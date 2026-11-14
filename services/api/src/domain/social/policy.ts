export function canonicalPair(a:string,b:string):[string,string]{return a<b?[a,b]:[b,a];}
export function canSendFriendRequest(input:{actor:string;target:string;alreadyFriends:boolean;pendingEitherDirection:boolean;blockedEitherDirection:boolean;targetSanctioned:boolean}):{allowed:boolean;reason?:string}{
 if(input.actor===input.target)return {allowed:false,reason:"self_request"};
 if(input.alreadyFriends)return {allowed:false,reason:"already_friends"};
 if(input.pendingEitherDirection)return {allowed:false,reason:"request_pending"};
 if(input.blockedEitherDirection)return {allowed:false,reason:"blocked"};
 if(input.targetSanctioned)return {allowed:false,reason:"unavailable"};
 return {allowed:true};
}
export function canViewPresence(input:{viewer:string;subject:string;visibility:"everyone"|"friends"|"nobody";areFriends:boolean;blockedEitherDirection:boolean;showOnline:boolean}):boolean{
 if(input.viewer===input.subject)return true;
 if(input.blockedEitherDirection||!input.showOnline||input.visibility==="nobody")return false;
 if(input.visibility==="friends"&&!input.areFriends)return false;
 return true;
}
