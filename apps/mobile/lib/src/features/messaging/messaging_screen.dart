import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagingScreen extends StatefulWidget {
 const MessagingScreen({super.key});
 @override State<MessagingScreen> createState()=>_MessagingScreenState();
}
class _MessagingScreenState extends State<MessagingScreen>{
 final _db=Supabase.instance.client; late Future<List<Map<String,dynamic>>> _future;
 @override void initState(){super.initState();_future=_load();}
 Future<List<Map<String,dynamic>>> _load() async {
  final uid=_db.auth.currentUser!.id;
  final rows=await _db.from('conversation_members').select('conversation_id,last_read_at,conversations(id,user_a,user_b,updated_at)').eq('user_id',uid).order('last_read_at',ascending:false);
  return List<Map<String,dynamic>>.from(rows);
 }
 Future<void> _openFriend() async {
  final ctrl=TextEditingController();
  final id=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Open friend chat'),content:TextField(controller:ctrl,decoration:const InputDecoration(labelText:'Friend user ID (UUID)')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,ctrl.text.trim()),child:const Text('Open'))]));
  if(id==null||id.isEmpty)return;
  try{final conversation=await _db.rpc('conversation_open',params:{'p_friend':id});if(!mounted)return;Navigator.push(context,MaterialPageRoute(builder:(_)=>ConversationScreen(conversationId:conversation.toString()))).then((_)=>setState(()=>_future=_load()));}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Chat नहीं खुला: $e')));}
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Messages'),actions:[IconButton(onPressed:_openFriend,icon:const Icon(Icons.add_comment),tooltip:'New chat')]),body:FutureBuilder<List<Map<String,dynamic>>>(future:_future,builder:(c,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('Messages load नहीं हुए: ${s.error}'));final rows=s.data??[];if(rows.isEmpty)return const Center(child:Text('अभी कोई chat नहीं। + से friend chat खोलें।'));return ListView.builder(itemCount:rows.length,itemBuilder:(c,i){final conv=rows[i]['conversations'] as Map<String,dynamic>?;final uid=_db.auth.currentUser!.id;final peer=conv==null?'Friend':(conv['user_a']==uid?conv['user_b']:conv['user_a']);return ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text('Friend • ${peer.toString().substring(0,8)}…'),subtitle:const Text('Private conversation'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ConversationScreen(conversationId:rows[i]['conversation_id'].toString()))).then((_)=>setState(()=>_future=_load()));});}));
}
}

class ConversationScreen extends StatefulWidget{
 const ConversationScreen({super.key,required this.conversationId});final String conversationId;
 @override State<ConversationScreen> createState()=>_ConversationScreenState();
}
class _ConversationScreenState extends State<ConversationScreen>{
 final _db=Supabase.instance.client;final _input=TextEditingController();List<Map<String,dynamic>> _messages=[];bool _loading=true,_sending=false;RealtimeChannel? _channel;
 @override void initState(){super.initState();_load();_channel=_db.channel('messages-${widget.conversationId}').onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'messages',filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'conversation_id',value:widget.conversationId),callback:(_)=>_load()).subscribe();}
 Future<void> _load()async{try{final rows=await _db.from('messages').select('id,sender_id,body,created_at,edited_at,deleted_at').eq('conversation_id',widget.conversationId).order('created_at');if(mounted)setState(()=>_messages=List<Map<String,dynamic>>.from(rows));await _db.rpc('conversation_mark_read',params:{'p_conversation':widget.conversationId});}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Messages load error: $e')));}finally{if(mounted)setState(()=>_loading=false);}}
 Future<void> _send()async{final body=_input.text.trim();if(body.isEmpty||_sending)return;setState(()=>_sending=true);try{await _db.rpc('message_send',params:{'p_conversation':widget.conversationId,'p_body':body});_input.clear();await _load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Message नहीं भेजा: $e')));}finally{if(mounted)setState(()=>_sending=false);}}
 Future<void> _delete(String id)async{try{await _db.rpc('message_delete',params:{'p_message':id});await _load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Delete failed: $e')));}}
 @override void dispose(){_input.dispose();if(_channel!=null)_db.removeChannel(_channel!);super.dispose();}
 @override Widget build(BuildContext context){final uid=_db.auth.currentUser!.id;return Scaffold(appBar:AppBar(title:const Text('Private chat')),body:Column(children:[Expanded(child:_loading?const Center(child:CircularProgressIndicator()):ListView.builder(padding:const EdgeInsets.all(12),itemCount:_messages.length,itemBuilder:(c,i){final m=_messages[i];final mine=m['sender_id']==uid;return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:GestureDetector(onLongPress:mine&&m['deleted_at']==null?()=>_delete(m['id'].toString()):null,child:Container(margin:const EdgeInsets.symmetric(vertical:5),padding:const EdgeInsets.all(12),constraints:const BoxConstraints(maxWidth:300),decoration:BoxDecoration(color:mine?Theme.of(context).colorScheme.primaryContainer:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(16)),child:Text(m['deleted_at']!=null?'Message deleted':m['body'].toString()))));})),SafeArea(child:Padding(padding:const EdgeInsets.all(8),child:Row(children:[Expanded(child:TextField(controller:_input,minLines:1,maxLines:4,decoration:const InputDecoration(hintText:'Write a message…',border:OutlineInputBorder()))),IconButton(onPressed:_sending?null:_send,icon:_sending?const CircularProgressIndicator():const Icon(Icons.send))])))]));}
}
