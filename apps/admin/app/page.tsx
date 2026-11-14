import Link from "next/link";
import {requireAdminSession} from "../lib/admin-auth";
export default async function AdminHome(){
 const {user,aal2}=await requireAdminSession();
 return <main className="admin"><header><strong>VibeMingle</strong><span>ADMIN CONSOLE · RESTRICTED</span></header><section><p className="tag">ACCESS CONTROL</p><h1>Operations Console</h1>
 {!user?<><p>Google identity sign-in required. Access is limited by server-side RBAC.</p><Link className="login" href="/auth/login">Continue with Google</Link></>:<><p>Signed in as {user.email||user.id}</p>{!aal2?<div className="notice">MFA required. Enroll or verify an authenticator to reach AAL2 before accessing moderation.</div>:<div className="notice">MFA (AAL2) verified for this session. API still checks the enabled moderator/admin role.</div>}<Link className="login" href="/moderation">Open Moderation Console</Link></>}
 </section></main>;
}