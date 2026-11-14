import {NextResponse} from "next/server";
import {createSupabaseServerClient} from "../../../../lib/supabase/server";
export async function GET(request:Request){
 const supabase=await createSupabaseServerClient();const url=new URL(request.url);
 const {data,error}=await supabase.auth.signInWithOAuth({provider:"google",options:{redirectTo:url.origin+"/auth/callback",queryParams:{access_type:"offline",prompt:"select_account"}}});
 if(error||!data.url)return NextResponse.redirect(new URL("/?auth_error=oauth_start",url.origin));
 return NextResponse.redirect(data.url);
}