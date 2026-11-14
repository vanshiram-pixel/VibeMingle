import 'dart:async';
import 'package:flutter/material.dart';

/// UI shell only. LiveKit connection/token/session authorization are not wired yet.
class VideoCallScreen extends StatefulWidget {
 const VideoCallScreen({super.key});
 @override State<VideoCallScreen> createState()=>_VideoCallScreenState();
}
class _VideoCallScreenState extends State<VideoCallScreen>{
 bool micOn=true,cameraOn=true,frontCamera=true; int seconds=0; Timer? timer;
 @override void initState(){super.initState();startPreviewTimer();}\n @override void dispose(){timer?.cancel();super.dispose();}
 String get clock=>'${(seconds~/60).toString().padLeft(2,'0')}:${(seconds%60).toString().padLeft(2,'0')}';
 void startPreviewTimer(){timer?.cancel();timer=Timer.periodic(const Duration(seconds:1),(_){if(mounted)setState(()=>seconds++);});}
 @override Widget build(BuildContext context)=>Scaffold(
  backgroundColor:const Color(0xFF090912),
  appBar:AppBar(backgroundColor:Colors.transparent,title:const Text('Video call'),leading:IconButton(icon:const Icon(Icons.close),onPressed:()=>Navigator.pop(context))),
  body:SafeArea(child:Column(children:[
   const SizedBox(height:12),
   Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),decoration:BoxDecoration(color:Colors.amber.withOpacity(.12),borderRadius:BorderRadius.circular(20)),child:const Text('PREVIEW • LiveKit not connected',style:TextStyle(color:Colors.amber,fontWeight:FontWeight.w600))),
   const SizedBox(height:14),
   Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Container(width:double.infinity,decoration:BoxDecoration(color:const Color(0xFF171725),borderRadius:BorderRadius.circular(28),border:Border.all(color:const Color(0xFF34344A))),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[const Icon(Icons.person_outline_rounded,size:92,color:Color(0xFF77778D)),const SizedBox(height:12),const Text('Waiting for connection',style:TextStyle(fontSize:20,fontWeight:FontWeight.w600)),const SizedBox(height:8),Text('Preview timer ${clock}',style:const TextStyle(color:Colors.white60)),const SizedBox(height:22),const Text('Remote video will appear here',style:TextStyle(color:Colors.white38))]))),
   Align(alignment:Alignment.centerRight,child:Padding(padding:const EdgeInsets.all(16),child:Container(width:104,height:145,decoration:BoxDecoration(color:const Color(0xFF222235),borderRadius:BorderRadius.circular(18)),child:Center(child:Icon(cameraOn?Icons.person:Icons.videocam_off,size:38,color:Colors.white54)))) ,
   Padding(padding:const EdgeInsets.fromLTRB(18,12,18,24),child:Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[
    _control(micOn?Icons.mic:Icons.mic_off,'Mic',()=>setState(()=>micOn=!micOn),active:micOn),
    _control(cameraOn?Icons.videocam:Icons.videocam_off,'Camera',()=>setState(()=>cameraOn=!cameraOn),active:cameraOn),
    _control(Icons.cameraswitch,'Flip',()=>setState(()=>frontCamera=!frontCamera),active:true),
    _control(Icons.report_outlined,'Report',()=>_notice('Reporting will be connected to the safety API.'),active:true),
    _control(Icons.call_end,'End',()=>Navigator.pop(context),active:false,danger:true),
   ]))
  ])));
 Widget _control(IconData icon,String label,VoidCallback action,{required bool active,bool danger=false})=>Column(mainAxisSize:MainAxisSize.min,children:[InkWell(onTap:action,borderRadius:BorderRadius.circular(28),child:Container(width:52,height:52,decoration:BoxDecoration(color:danger?Colors.red.shade700:(active?const Color(0xFF292943):const Color(0xFF4A4A5B)),shape:BoxShape.circle),child:Icon(icon,color:Colors.white,size:22))),const SizedBox(height:7),Text(label,style:const TextStyle(fontSize:11,color:Colors.white70))]);
 void _notice(String message)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message)));
}
