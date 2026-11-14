import {NextRequest,NextResponse} from "next/server";
import {requireAdminSession} from "../../../../../../lib/admin-auth";
export async function PATCH(req:NextRequest,{params}:{params:Promise<{reportId:string}>}){
 const {supabase,user,aal2}=await requireAdminSession();if(!user)return NextResponse.json({error:{message:"Sign in required"}},{status:401});if(!aal2)return NextResponse.json({error:{message:"MFA AAL2 required"}},{status:403});
 const {data:{session}}=await supabase.auth.getSession();const base=process.env.VIBEMINGLE_API_URL;if(!session?.access_token||!base)return NextResponse.json({error:{message:"API configuration missing"}},{status:503});
 const {reportId}=await params;const upstream=await fetch(base.replace(/\/$/,"")+"/v1/admin/moderation/reports/"+encodeURIComponent(reportId),{method:"PATCH",headers:{authorization:"Bearer "+session.access_token,"content-type":"application/json"},body:await req.text(),cache:"no-store"});
 return new NextResponse(await upstream.text(),{status:upstream.status,headers:{"content-type":"application/json"}});
}