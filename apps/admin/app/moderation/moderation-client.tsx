import {redirect} from "next/navigation";
import {requireAdminSession} from "../../lib/admin-auth";
import ModerationClient from "./moderation-client";
export default async function ModerationPage(){const {user,aal2}=await requireAdminSession();if(!user)redirect("/");if(!aal2)redirect("/?mfa_required=1");return <ModerationClient/>}
