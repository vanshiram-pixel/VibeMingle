"use client";
import {useEffect,useRef,useState} from "react";
import {createSupabaseBrowserClient} from "@/lib/supabase";
type Call={id:string;caller_id:string;callee_id:string;call_type:"audio"|"video";status:string};
type Signal={id:string;sender_id:string;recipient_id:string;signal_type:"offer"|"answer"|"ice";payload:RTCSessionDescriptionInit|RTCIceCandidateInit;created_at:string};
export default function WebRtcMedia({call,me}:{call:Call;me:string}){
 const localRef=useRef<HTMLVideoElement>(null),remoteRef=useRef<HTMLVideoElement>(null),pcRef=useRef<RTCPeerConnection|null>(null),streamRef=useRef<MediaStream|null>(null),seen=useRef(new Set<string>()),queued=useRef<RTCIceCandidateInit[]>([]);
 const [status,setStatus]=useState("Preparing media…"),[muted,setMuted]=useState(false),[camera,setCamera]=useState(true);
 useEffect(()=>{let alive=true;const db=createSupabaseBrowserClient();const peer=call.caller_id===me?call.callee_id:call.caller_id;let channel:any;
 const run=async()=>{try{
 const stream=await navigator.mediaDevices.getUserMedia({audio:true,video:call.call_type==="video"});if(!alive)return;streamRef.current=stream;if(localRef.current)localRef.current.srcObject=stream;
 let iceServers:RTCIceServer[]=[{urls:"stun:stun.l.google.com:19302"}];
 const {data:iceConfig,error:iceConfigError}=await db.functions.invoke("rtc-ice-servers");
 if(!iceConfigError&&iceConfig&&Array.isArray((iceConfig as {iceServers?:unknown}).iceServers)){
   iceServers=(iceConfig as {iceServers:RTCIceServer[]}).iceServers;
 }
 if(!alive){stream.getTracks().forEach(t=>t.stop());return;}
 const pc=new RTCPeerConnection({iceServers});pcRef.current=pc;stream.getTracks().forEach(t=>pc.addTrack(t,stream));
 pc.ontrack=e=>{if(remoteRef.current)remoteRef.current.srcObject=e.streams[0]};pc.onconnectionstatechange=()=>setStatus("Connection: "+pc.connectionState);pc.onicecandidate=e=>{if(e.candidate)void db.rpc("call_signal_send",{p_call:call.id,p_recipient:peer,p_type:"ice",p_payload:e.candidate.toJSON()}).then(({error})=>{if(error&&alive)setStatus("ICE signaling failed: "+error.message)})};
 const apply=async(s:Signal)=>{if(seen.current.has(s.id)||s.recipient_id!==me)return;seen.current.add(s.id);if(s.signal_type==="offer"){await pc.setRemoteDescription(s.payload as RTCSessionDescriptionInit);for(const c of queued.current)await pc.addIceCandidate(c);queued.current=[];const answer=await pc.createAnswer();await pc.setLocalDescription(answer);await db.rpc("call_signal_send",{p_call:call.id,p_recipient:peer,p_type:"answer",p_payload:answer});setStatus("Answer sent · connecting…")}else if(s.signal_type==="answer"){if(!pc.remoteDescription){await pc.setRemoteDescription(s.payload as RTCSessionDescriptionInit);for(const c of queued.current)await pc.addIceCandidate(c);queued.current=[];setStatus("Answer received · connecting…")}}else{const candidate=s.payload as RTCIceCandidateInit;if(pc.remoteDescription)await pc.addIceCandidate(candidate);else queued.current.push(candidate)}};
 const signalQueue={current:Promise.resolve() as Promise<void>};
 const enqueue=(s:Signal)=>{signalQueue.current=signalQueue.current.then(()=>apply(s)).catch(e=>{if(alive)setStatus(e instanceof Error?e.message:"Signaling queue failed")});return signalQueue.current};
 channel=db.channel("rtc-"+call.id).on("postgres_changes",{event:"INSERT",schema:"public",table:"call_signals",filter:"call_id=eq."+call.id},payload=>{void enqueue(payload.new as Signal)}).subscribe();
 const {data}=await db.from("call_signals").select("id,sender_id,recipient_id,signal_type,payload,created_at").eq("call_id",call.id).eq("recipient_id",me).order("created_at");for(const s of (data??[]) as Signal[])await enqueue(s);
 if(call.caller_id===me){const offer=await pc.createOffer();await pc.setLocalDescription(offer);const {error}=await db.rpc("call_signal_send",{p_call:call.id,p_recipient:peer,p_type:"offer",p_payload:offer});if(error)throw error;setStatus("Offer sent · ringing peer…")}else setStatus("Waiting for caller offer…");
 }catch(e){setStatus(e instanceof Error?e.message:"Media initialization failed")}};
 void run();return()=>{alive=false;if(channel)void db.removeChannel(channel);pcRef.current?.close();streamRef.current?.getTracks().forEach(t=>t.stop());pcRef.current=null;streamRef.current=null}},[call.id,call.caller_id,call.callee_id,call.call_type,me]);
 return <div className="media-card"><h3>Live {call.call_type} session</h3><p className="muted" role="status">{status}</p><div className="media-grid"><video ref={localRef} autoPlay muted playsInline/><video ref={remoteRef} autoPlay playsInline/></div><div className="media-controls"><button className="pill" onClick={()=>{const s=streamRef.current;const next=!muted;s?.getAudioTracks().forEach(t=>t.enabled=!next);setMuted(next)}}>{muted?"Unmute":"Mute"}</button>{call.call_type==="video"&&<button className="pill" onClick={()=>{const next=!camera;streamRef.current?.getVideoTracks().forEach(t=>t.enabled=next);setCamera(next)}}>{camera?"Camera off":"Camera on"}</button>}</div></div>
}