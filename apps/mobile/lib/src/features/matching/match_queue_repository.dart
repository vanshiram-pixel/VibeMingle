import 'package:supabase_flutter/supabase_flutter.dart';

/// Client queue intent only. Pairing remains server-worker authoritative.
/// Consent must be called from an explicit, user-confirmed UI action.
class MatchQueueRepository {
 MatchQueueRepository([SupabaseClient? client]):_client=client??Supabase.instance.client;
 final SupabaseClient _client;

 Future<Map<String,dynamic>> setConsent({required bool enabled,required String version}) async {
  final r=await _client.rpc('match_consent_set',params:{'p_enabled':enabled,'p_version':version});
  return Map<String,dynamic>.from(r as Map);
 }

 Future<Map<String,dynamic>> enter({String mode='random',String? ageBand,String genderPreference='any',List<String> languages=const [],List<String> interests=const []}) async {
  final r=await _client.rpc('match_queue_enter',params:{'p_mode':mode,'p_age_band':ageBand,'p_gender_preference':genderPreference,'p_languages':languages,'p_interests':interests});
  return Map<String,dynamic>.from(r as Map);
 }
 Future<bool> heartbeat() async=>await _client.rpc('match_queue_heartbeat') as bool;
 Future<bool> leave() async=>await _client.rpc('match_queue_leave') as bool;

 /// Ends only a session in which the signed-in user is a participant.
 /// Server RPC enforces participant authorization and valid terminal states.
 Future<bool> endSession({required String sessionId,String reason='ended'}) async {
  return await _client.rpc('match_session_end',params:{'p_session_id':sessionId,'p_reason':reason}) as bool;
 }

 /// Listen to only this authenticated user's server-generated match events.
 Stream<Map<String,dynamic>> matchEvents() {
  final uid=_client.auth.currentUser?.id;
  if(uid==null)throw StateError('Match events require authentication');
  return _client.from('match_session_events').stream(primaryKey:['id'])
    .eq('recipient_id',uid).map((rows)=>rows.map((row)=>Map<String,dynamic>.from(row)).toList())
    .expand((rows)=>rows).map((row)=>row);
 }

 /// Participant-scoped realtime stream. RLS is the authorization boundary.
 Stream<List<Map<String,dynamic>>> sessionChanges(String sessionId) =>
  _client.from('match_sessions').stream(primaryKey:['id']).eq('id',sessionId);
}
