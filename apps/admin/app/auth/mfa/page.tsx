"use client";
import {useState} from "react";
import {createBrowserClient} from "@supabase/ssr";
export default function MfaPage(){
 const [factor,setFactor]=useState<any>(null),[qr,setQr]=useState(""),[code,setCode]=useState(""),[msg,setMsg]=useState("");
 const supabase=createBrowserClient(process.env.NEXT_PUBLIC_SUPABASE_URL!,process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!);
 async function enroll(){const {data,error}=await supabase.auth.mfa.enroll({factorType:"totp"});if(error){setMsg(error.message);return}setFactor(data);setQr(data.totp.qr_code);setMsg("Scan QR in authenticator app, then enter 6-digit code.");}
 async function verify(){if(!factor)return;const {data,error}=await supabase.auth.mfa.challengeAndVerify({factorId:factor.id,code});if(error){setMsg(error.message);return}setMsg("MFA verified (AAL2). You may open Moderation Console.");}
 return <main className="admin"><header><strong>VibeMingle</strong><span>SECURITY · MFA</span></header><section><p className="tag">AUTHENTICATOR</p><h1>Enable MFA</h1><p>Use an authenticator app to enroll a TOTP factor.</p><button onClick={()=>void enroll()}>Enroll authenticator</button>{qr&&<div className="notice"><img alt="Authenticator QR" src={qr} style={{maxWidth:220}}/><p>Secret: {factor?.totp?.secret}</p></div>}<label>6-digit code <input value={code} onChange={e=>setCode(e.target.value)} maxLength={6}/></label><button onClick={()=>void verify()} disabled={!factor||code.length!==6}>Verify code</button>{msg&&<p>{msg}</p>}</section></main>
}