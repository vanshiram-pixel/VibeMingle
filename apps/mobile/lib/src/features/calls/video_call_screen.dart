import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'call_service.dart';

/// LiveKit connection shell. Video rendering and full call event UX follow next.
class VideoCallScreen extends StatefulWidget {const VideoCallScreen({super.key,required this.sessionId});final String sessionId;@override State<VideoCallScreen> createState()=>_VideoCallScreenState();}
class _VideoCallScreenState extends State<VideoCallScreen> {
 final _service=CallService();Room? _room;bool _connecting=true,_mic=true,_camera=true,_leaving=false;String? _error;
 @override void initState(){super.initState();_connect();}
 Future<void> _connect() async {try{final credentials=await _service.requestToken(widget.sessionId);final room=Room();await room.connect(credentials.url,credentials.token);await room.localParticipant?.setMicrophoneEnabled(true);await room.localParticipant?.setCameraEnabled(true);if(!mounted){await room.disconnect();return;}setState(()=>_room=room);}catch(e){if(mounted)setState(()=>_error=e.toString());}finally{if(mounted)setState(()=>_connecting=false);}}
 Future<void> _toggleMic()async{final p=_room?.localParticipant;if(p==null)return;try{await p.setMicrophoneEnabled(!_mic);if(mounted)setState(()=>_mic=!_mic);}catch(e){_show(e.toString());}}
 Future<void> _toggleCamera()async{final p=_room?.localParticipant;if(p==null)return;try{await p.setCameraEnabled(!_camera);if(mounted)setState(()=>_camera=!_camera);}catch(e){_show(e.toString());}}
 Future<void> _end()async{if(_leaving)return;setState(()=>_leaving=true);try{await _room?.disconnect();await _service.leave(widget.sessionId);}catch(e){_show('Call ended locally. Server update: $e');}if(mounted)Navigator.pop(context);}
 void _show(String m)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m)));
 @override void dispose(){_room?.disconnect();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:const Color(0xFF090912),appBar:AppBar(title:const Text('VibeMingle call'),backgroundColor:Colors.transparent),body:SafeArea(child:Column(children:[const SizedBox(height:12),Expanded(child:Center(child:_connecting?const CircularProgressIndicator():_error!=null?Padding(padding:const EdgeInsets.all(24),child:Text(_error!,textAlign:TextAlign.center)):Column(mainAxisAlignment:MainAxisAlignment.center,children:[const Icon(Icons.video_call,size:90,color:Colors.deepPurpleAccent),const SizedBox(height:12),const Text('LiveKit connected',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:8),Text('Room: ${_room?.name??'—'}'),Text('Participants: ${_room?.remoteParticipants.length??0}'),const SizedBox(height:12),const Text('Camera and microphone are enabled',style:TextStyle(color:Colors.white60))]))),Padding(padding:const EdgeInsets.all(22),child:Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[_btn(_mic?Icons.mic:Icons.mic_off,'Mic',_toggleMic),_btn(_camera?Icons.videocam:Icons.videocam_off,'Camera',_toggleCamera),_btn(Icons.call_end,'End',_end,danger:true)]))])));
 Widget _btn(IconData icon,String label,VoidCallback action,{bool danger=false})=>Column(children:[IconButton(onPressed:action,icon:Icon(icon),style:IconButton.styleFrom(backgroundColor:danger?Colors.red:const Color(0xFF292943),foregroundColor:Colors.white)),Text(label)]);
}