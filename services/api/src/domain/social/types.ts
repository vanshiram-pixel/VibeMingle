export type FriendRequestStatus="pending"|"accepted"|"rejected"|"cancelled";
export type FriendRequest={id:string;senderId:string;receiverId:string;status:FriendRequestStatus;createdAt:number};
export type Friendship={userA:string;userB:string;createdAt:number};
export type PresenceVisibility="everyone"|"friends"|"nobody";
export type PresenceState={userId:string;online:boolean;lastSeenAt:number|null;visibility:PresenceVisibility};
