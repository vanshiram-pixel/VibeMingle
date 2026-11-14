import {NextRequest,NextResponse} from "next/server";
export async function PATCH(req:NextRequest,{params}:{params:Promise<{reportId:string}>}){
 const token=req.cookies.get("sb-access-token")?.value,base=process.env.VIBEMINGLE_API_URL;
 if(!token||!base)return NextResponse.json({error:{message:"Admin session/API configuration missing."}},{status:401});
 const {reportId}=await params;const body=await req.text();
 const upstream=await fetch(base.replace(/\/$/,"")+"/v1/admin/moderation/reports/"+encodeURIComponent(reportId),{method:"PATCH",headers:{authorization:"Bearer "+token,"content-type":"application/json"},body,cache:"no-store"});
 return new NextResponse(await upstream.text(),{status:upstream.status,headers:{"content-type":"application/json"}});
}