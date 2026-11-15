import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_repository_v2.dart';

class ChatInboxScreen extends StatefulWidget {
 const ChatInboxScreen({super.key});
 @override State<ChatInboxScreen> createState()=>_ChatInboxScreenState();
}
class _ChatInboxScreenState extends State<ChatInboxScreen>{
 final db=Supabase.instance.client; bool loading=true;
 List<Map<String,dynamic>> friends=[];
 @override void initState(){super.initState();load();}
 Future<void> load()async{
  try{final uid=db.auth.currentUser!.id;
   final fs=await db.from('friendships').select('user_low,user_high').or('user_low.eq.$uid,user_high.eq.$uid');
   final ids=fs.map((r)=>r['user_low']==uid?r['user_high']:r['user_low']).toList();
   final p=ids.isEmpty?[]:await db.from('profiles').select('id,username,display_name').inFilter('id',ids);
   if(mounted)setState(()=>friends=List<Map<String,dynamic>>.from(p));
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}
  finally{if(mounted)setState(()=>loading=false);}
 }
 String name(Map p)=>((p['display_name'] as String? ?? '').trim().isNotEmpty)?p['display_name'] as String:p['username'] as String? ?? 'Friend';
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Private Chats'),actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),body:loading?const Center(child:CircularProgressIndicator()):ListView(children:friends.map((p)=>ListTile(title:Text(name(p)),subtitle:Text('@${p['username']??''}'),leading:const CircleAvatar(child:Icon(Icons.person)),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>ChatThreadScreen(peerId:p['id'] as String,peerName:name(p))))).toList()));
}

class ChatThreadScreen extends StatefulWidget {
 const ChatThreadScreen({super.key,required this.peerId,required this.peerName});
 final String peerId,peerName;
 @override State<ChatThreadScreen> createState()=>_ChatThreadScreenState();
}
class _ChatThreadScreenState extends State<ChatThreadScreen>{
 final repo=ChatRepository(),input=TextEditingController();List<Map<String,dynamic>> rows=[];
 StreamSubscription<Map<String,dynamic>>? sub;RealtimeChannel? typing;Timer? timer;bool busy=false,peerTyping=false;
 @override void initState(){super.initState();refresh();sub=repo.watch(widget.peerId).listen((m){if(mounted)setState(()=>upsert(m));});
 typing=Supabase.instance.client.channel('typing-${repo.pairKey(Supabase.instance.client.auth.currentUser!.id,widget.peerId)}').onBroadcast(event:'typing',callback:(p){if(p['user_id']==widget.peerId&&mounted)setState(()=>peerTyping=p['typing']==true);}).subscribe();
 }
 void upsert(Map<String,dynamic> m){final i=rows.indexWhere((x)=>x['id']==m['id']);if(i<0)rows.add(m);else rows[i]=m;rows.sort((a,b)=>a['created_at'].toString().compareTo(b['created_at'].toString()));}
 Future<void> refresh()async{try{final x=await repo.messages(widget.peerId);if(mounted)setState(()=>rows=x);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}}
 void typingChanged(String v){typing?.sendBroadcastMessage(event:'typing',payload:{'user_id':Supabase.instance.client.auth.currentUser!.id,'typing':v.trim().isNotEmpty});timer?.cancel();if(v.trim().isNotEmpty)timer=Timer(const Duration(milliseconds:1200),()=>typing?.sendBroadcastMessage(event:'typing',payload:{'user_id':Supabase.instance.client.auth.currentUser!.id,'typing':false}));}
 Future<void> send()async{final text=input.text.trim();if(text.isEmpty||busy)return;setState(()=>busy=true);try{final m=await repo.send(widget.peerId,text);setState(()=>upsert(m));input.clear();typingChanged('');}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Send failed: $e')));}finally{if(mounted)setState(()=>busy=false);}}
 @override void dispose(){input.dispose();sub?.cancel();timer?.cancel();if(typing!=null)Supabase.instance.client.removeChannel(typing!);super.dispose();}
 @override Widget build(BuildContext c){final uid=Supabase.instance.client.auth.currentUser!.id;return Scaffold(appBar:AppBar(title:Text(widget.peerName)),body:Column(children:[Expanded(child:ListView.builder(itemCount:rows.length,itemBuilder:(c,i){final m=rows[i],mine=m['sender_id']==uid;return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(margin:const EdgeInsets.all(5),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:mine?Theme.of(c).colorScheme.primaryContainer:Theme.of(c).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(14)),child:Text(m['deleted_at']!=null?'Message deleted':m['body'].toString())));})),if(peerTyping)const Text('Typing…'),SafeArea(child:Row(children:[Expanded(child:TextField(controller:input,onChanged:typingChanged,decoration:const InputDecoration(hintText:'Message…'))),IconButton(onPressed:busy?null:send,icon:const Icon(Icons.send))]))]));}
}