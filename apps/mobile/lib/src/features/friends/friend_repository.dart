import 'package:supabase_flutter/supabase_flutter.dart';
class FriendRepository {
 FriendRepository([SupabaseClient? client]):_client=client??Supabase.instance.client;
 final SupabaseClient _client;
 Future<List<Map<String,dynamic>>> searchProfiles(String q) async {final t=q.trim();if(t.length<2)return [];
 return await _client.from('profiles').select('id,username,display_name,avatar_url').or('username.ilike.%$t%,display_name.ilike.%$t%').neq('id',_client.auth.currentUser!.id).limit(25);}
 Future<List<Map<String,dynamic>>> friends() async {final u=_client.auth.currentUser!.id;final r=await _client.from('friendships').select('user_low,user_high,created_at').or('user_low.eq.$u,user_high.eq.$u');
 final ids=r.map((x)=>x['user_low']==u?x['user_high']:x['user_low']).toList();if(ids.isEmpty)return [];return await _client.from('profiles').select('id,username,display_name,avatar_url').inFilter('id',ids);}
 Future<List<Map<String,dynamic>>> incomingRequests() async=>await _client.from('friend_requests').select('id,sender_id,created_at').eq('recipient_id',_client.auth.currentUser!.id).eq('status','pending');
 Future<void> sendRequest(String id) async{await _client.rpc('friend_request_send',params:{'p_recipient_id':id});}
 Future<void> respond(String id,bool accept) async{await _client.rpc('friend_request_respond',params:{'p_request_id':id,'p_accept':accept});}
 Future<void> removeFriend(String id) async{await _client.rpc('friend_remove',params:{'p_friend_id':id});}
 Future<void> block(String id) async{await _client.rpc('user_block',params:{'p_blocked_id':id});}
}