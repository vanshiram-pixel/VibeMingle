import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
 ChatRepository([SupabaseClient? client]):_db=client??Supabase.instance.client;
 final SupabaseClient _db;
 String pairKey(String a,String b)=>a.compareTo(b)<0?'$a:$b':'$b:$a';
 Future<List<Map<String,dynamic>>> messages(String peer,{int limit=50,DateTime? before}) async {
  final uid=_db.auth.currentUser!.id;final key=pairKey(uid,peer);
  var q=_db.from('chat_messages').select().eq('conversation_id',key);
  if(before!=null)q=q.lt('created_at',before.toUtc().toIso8601String());
  final rows=await q.order('created_at',ascending:false).limit(limit.clamp(1,100));
  return rows.map((x)=>Map<String,dynamic>.from(x)).toList().reversed.toList();
 }
 Future<Map<String,dynamic>> send(String peer,String body) async=>Map<String,dynamic>.from(await _db.rpc('chat_send',params:{'p_recipient_id':peer,'p_body':body,'p_conversation_id':pairKey(_db.auth.currentUser!.id,peer)}) as Map);
 Future<void> read(String id) async{await _db.rpc('chat_mark_read',params:{'p_message_id':id});}
 Future<void> delivered(String id) async{await _db.rpc('chat_mark_delivered',params:{'p_message_id':id});}
 Future<void> edit(String id,String body) async{await _db.rpc('chat_edit',params:{'p_message_id':id,'p_body':body});}
 Future<void> delete(String id) async{await _db.rpc('chat_delete',params:{'p_message_id':id});}
 Stream<Map<String,dynamic>> watch(String peer) {
  final uid=_db.auth.currentUser!.id,key=pairKey(uid,peer);
  final c=StreamController<Map<String,dynamic>>();
  final channel=_db.channel('chat-row-$key').onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'chat_messages',filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'conversation_id',value:key),callback:(p){c.add(Map<String,dynamic>.from(p.newRecord.isNotEmpty?p.newRecord:p.oldRecord));}).subscribe();
  c.onCancel=()=>_db.removeChannel(channel);return c.stream;
 }
}