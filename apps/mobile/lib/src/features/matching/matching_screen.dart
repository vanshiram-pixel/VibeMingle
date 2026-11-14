import 'dart:async';
import 'package:flutter/material.dart';
import '../calls/video_call_screen.dart';
import 'matching_service.dart';

class MatchingScreen extends StatefulWidget {const MatchingScreen({super.key});@override State<MatchingScreen> createState()=>_MatchingScreenState();}
class _MatchingScreenState extends State<MatchingScreen>{
 final _service=MatchingService();Timer? _poll;bool _busy=false,_queued=false;String _message='Ready to meet someone new?';
 Future<void> _start()async{if(_busy)return;setState(()=>_busy=true);try{final r=await _service.start();if(r.status=='matched'&&r.sessionId!=null){_openCall(r.sessionId!);return;}setState(()=>_queued=true);_message='Finding someone…';_poll=Timer.periodic(const Duration(seconds:4),(_)=>_check());}catch(e){setState(()=>_message=e.toString());}finally{if(mounted)setState(()=>_busy=false);}}
 Future<void> _check()async{try{final r=await _service.status();if(r.status=='matched'&&r.sessionId!=null){_poll?.cancel();_openCall(r.sessionId!);}}catch(_){}}
 void _openCall(String id){if(!mounted)return;setState(()=>_queued=false);Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>VideoCallScreen(sessionId:id)));}
 Future<void> _cancel()async{_poll?.cancel();try{await _service.cancel();if(mounted)setState(()=>_queued=false);_message='Matching cancelled.';}catch(e){_message=e.toString();}if(mounted)setState(()=>_busy=false);}
 @override void dispose(){_poll?.cancel();super.dispose();}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Random video matching')),body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.public,size:76,color:Color(0xFFA78BFA)),const SizedBox(height:18),Text(_message,textAlign:TextAlign.center,style:const TextStyle(fontSize:18)),const SizedBox(height:24),if(_queued)...[const CircularProgressIndicator(),const SizedBox(height:18),FilledButton.tonal(onPressed:_busy?null:_cancel,child:const Text('Cancel search'))]else SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:_busy?null:_start,icon:const Icon(Icons.video_call),label:Text(_busy?'Starting…':'Start matching'))),const SizedBox(height:12),const Text('18+ • Respectful connections • Report/block anytime',textAlign:TextAlign.center,style:TextStyle(color:Colors.white54,fontSize:12))]))));}
}