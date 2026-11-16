"use client";
import { useState } from "react";
import { createSupabaseBrowserClient } from "@/lib/supabase";
export default function AuthPage(){
 const [mode,setMode]=useState<"signin"|"signup">("signin");
 const [email,setEmail]=useState("");const [password,setPassword]=useState("");const [name,setName]=useState("");
 const [busy,setBusy]=useState(false);const [notice,setNotice]=useState("");
 async function submit(e:React.FormEvent){e.preventDefault();setBusy(true);setNotice("");
 try{const supabase=createSupabaseBrowserClient();if(mode==="signup"){
 const {error}=await supabase.auth.signUp({email,password,options:{data:{display_name:name},emailRedirectTo:location.origin+"/auth"}});
 if(error)throw error;setNotice("Account request created. Check your email to verify and continue.");
 }else{const {error}=await supabase.auth.signInWithPassword({email,password});if(error)throw error;location.href="/app";}
 }catch(err){setNotice(err instanceof Error?err.message:"Authentication failed");}finally{setBusy(false)}}
 return <main className="shell auth-shell"><a className="brand" href="/">Vibe<span>Mingle</span></a><section className="auth-card"><div className="eyebrow">Your people are here</div><h1>{mode==="signin"?"Welcome back":"Create your account"}</h1><p className="muted">Secure sign-in powered by Supabase Auth.</p><form onSubmit={submit} className="auth-form">{mode==="signup"&&<label>Display name<input required maxLength={60} value={name} onChange={e=>setName(e.target.value)} placeholder="Your name"/></label>}<label>Email<input type="email" required autoComplete="email" value={email} onChange={e=>setEmail(e.target.value)} placeholder="you@example.com"/></label><label>Password<input type="password" required minLength={6} autoComplete={mode==="signin"?"current-password":"new-password"} value={password} onChange={e=>setPassword(e.target.value)} placeholder="At least 6 characters"/></label><button className="primary" disabled={busy}>{busy?"Please wait…":mode==="signin"?"Sign in":"Create account"}</button></form>{notice&&<p className="notice" role="status">{notice}</p>}<button className="text-button" onClick={()=>{setMode(mode==="signin"?"signup":"signin");setNotice("")}}>{mode==="signin"?"New here? Create an account":"Already registered? Sign in"}</button><a className="muted back" href="/">← Back to home</a></section></main>
}