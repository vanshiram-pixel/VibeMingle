import {NextRequest,NextResponse} from "next/server";
export async function GET(req:NextRequest){
 const token=req.cookies.get("sb-access-token")?.value;
 const base=process.env.VIBEMINGLE_API_URL;
 if(!token||!base)return NextResponse.json({error:{message:"Admin session/API configuration missing. Sign in with Google and complete MFA."}},{status:401});
 const upstream=await fetch(base.replace(/\/$/,"")+"/v1/admin/moderation/reports"+req.nextUrl.search,{headers:{authorization:"Bearer "+token},cache:"no-store"});
 return new NextResponse(await upstream.text(),{status:upstream.status,headers:{"content-type":"application/json"}});
}