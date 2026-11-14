import {createSupabaseServerClient} from "./supabase/server";
export async function requireAdminSession(){
 const supabase=await createSupabaseServerClient();
 const {data:{user},error}=await supabase.auth.getUser();
 if(error||!user)return {supabase,user:null,aal2:false};
 const {data:assurance}=await supabase.auth.mfa.getAuthenticatorAssuranceLevel();
 return {supabase,user,aal2:assurance?.currentLevel==="aal2"};
}