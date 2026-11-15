import 'package:supabase_flutter/supabase_flutter.dart';

/// Client queue intent only. Pairing remains server-worker authoritative.
class MatchQueueRepository {
 MatchQueueRepository([SupabaseClient? client]):_client=client??Supabase.instance.client;
 final SupabaseClient _client;
 Future<Map<String,dynamic>> enter({String mode='random',String? ageBand,String genderPreference='any',List<String> languages=const [],List<String> interests=const []}) async {
  final r=await _client.rpc('match_queue_enter',params:{'p_mode':mode,'p_age_band':ageBand,'p_gender_preference':genderPreference,'p_languages':languages,'p_interests':interests});
  return Map<String,dynamic>.from(r as Map);
 }
 Future<bool> heartbeat() async=>await _client.rpc('match_queue_heartbeat') as bool;
 Future<bool> leave() async=>await _client.rpc('match_queue_leave') as bool;
}
