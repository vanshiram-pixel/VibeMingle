"use client";
import {useEffect,useState} from "react";
import {createSupabaseBrowserClient} from "@/lib/supabase";
import WebChat from "./chat";
import WebFriends from "./friends";
import WebDiscover from "./discover";\nimport WebCalls from "./calls";
type User={id:string;email?:string};
export default function AppHome(){const [user,setUser]=useState<User|null>(null);const [loading,setLoading]=useState(true);const [error,setError]=useState("");
 useEffect(()=>{let active=true;try{const db=createSupabaseBrowserClient();db.auth.getUser().then(({data,error})=>{if(!active)return;if(error)setError(error.message);setUser(data.user?{id:data.user.id,email:data.user.email}:null);setLoading(false)});const {data}=db.auth.onAuthStateChange((_event,session)=>{if(active)setUser(session?.user?{id:session.user.id,email:session.user.email}:null)});return()=>{active=false;data.subscription.unsubscribe()}}catch(e){setError(e instanceof Error?e.message:"Supabase setup missing");setLoading(false)}},[]);
 async function signOut(){await createSupabaseBrowserClient().auth.signOut();location.href="/auth"}
 if(loading)return <main className="shell"><p className="muted">Loading your account…</p></main>;
 if(!user)return <main className="shell"><section className="auth-card"><h1>Sign in required</h1><p>Log in to open your VibeMingle workspace.</p><a className="primary" href="/auth">Continue to sign in</a>{error&&<p className="notice">{error}</p>}</section></main>;
 return <main className="shell"><nav className="nav"><a className="brand" href="/">Vibe<span>Mingle</span></a><button className="pill" onClick={signOut}>Sign out</button></nav><section className="hero"><div className="eyebrow">Your workspace</div><h1>Welcome to<br/><em>VibeMingle.</em></h1><p>Signed in as {user.email??user.id}. Your account session is active.</p><div className="cards"><article className="feature"><h3>💬 Messages</h3><p>Messaging module is being connected to the web client.</p></article><article className="feature"><h3>📞 Calls</h3><p>Private call experience is in the next integration phase.</p></article><article className="feature"><h3>🧭 Discover</h3><p>Find profiles and build new connections.</p></article></div><WebDiscover/><WebFriends/><WebCalls/><WebChat/></section></main>
}