import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class CallCredentials {
 const CallCredentials({required this.url,required this.token,required this.roomName,required this.expiresAt});
 final String url,token,roomName; final DateTime expiresAt;
 factory CallCredentials.fromJson(Map<String,dynamic> json)=>CallCredentials(url:json['url'] as String,token:json['token'] as String,roomName:json['roomName'] as String,expiresAt:DateTime.parse(json['expiresAt'] as String));
}

/// Authenticated call API client; LiveKit/service secrets never live in Flutter.
class CallService {
 CallService({String? apiBaseUrl}):_base=(apiBaseUrl??const String.fromEnvironment('VIBEMINGLE_API_URL')).trim();
 final String _base;
 Future<String> _accessToken() async {final token=Supabase.instance.client.auth.currentSession?.accessToken;if(token==null||token.isEmpty)throw StateError('Please sign in again.');return token;}
 Future<CallCredentials> requestToken(String sessionId) async {
  if(_base.isEmpty)throw StateError('API URL is not configured (VIBEMINGLE_API_URL).');
  final response=await http.post(Uri.parse('$_base/v1/calls/token'),headers:{'Authorization':'Bearer ${await _accessToken()}','Content-Type':'application/json'},body:jsonEncode({'sessionId':sessionId}));
  final body=jsonDecode(response.body);
  if(response.statusCode<200||response.statusCode>=300){final message=body is Map&&body['error'] is Map?body['error']['message']:'Call authorization failed.';throw StateError(message.toString());}
  if(body is! Map<String,dynamic>)throw const FormatException('Invalid call token response');return CallCredentials.fromJson(body);
 }
 Future<void> leave(String sessionId,{String reason='participant_left'}) async {
  if(_base.isEmpty)throw StateError('API URL is not configured.');
  final response=await http.post(Uri.parse('$_base/v1/calls/$sessionId/leave'),headers:{'Authorization':'Bearer ${await _accessToken()}','Content-Type':'application/json'},body:jsonEncode({'reason':reason}));
  if(response.statusCode!=204&&(response.statusCode<200||response.statusCode>=300))throw StateError('Call could not be ended (${response.statusCode}).');
 }
}