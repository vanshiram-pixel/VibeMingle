import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_config.dart';

class MatchingResult {
  const MatchingResult({required this.status,this.sessionId,this.partnerId});
  final String status; final String? sessionId,partnerId;
  factory MatchingResult.fromJson(Map<String,dynamic> j)=>MatchingResult(status:j['status'] as String,sessionId:j['sessionId'] as String?,partnerId:j['partnerId'] as String?);
}
class MatchingService {
 String get _base=>AppConfig.apiBaseUrl;
 Map<String,String> get _headers=>{'Authorization':'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken??''}','Content-Type':'application/json'};
 Future<MatchingResult> start({String language='en',String region='global'}) async {
  final r=await http.post(Uri.parse('$_base/v1/matching/queue'),headers:_headers,body:jsonEncode({'language':language,'region':region})).timeout(const Duration(seconds:12));
  if(r.statusCode<200||r.statusCode>=300) throw Exception(_message(r));
  return MatchingResult.fromJson(jsonDecode(r.body) as Map<String,dynamic>);
 }
 Future<MatchingResult> status() async {
  final r=await http.get(Uri.parse('$_base/v1/matching/status'),headers:_headers).timeout(const Duration(seconds:10));
  if(r.statusCode<200||r.statusCode>=300) throw Exception(_message(r));
  return MatchingResult.fromJson(jsonDecode(r.body) as Map<String,dynamic>);
 }
 Future<void> cancel() async {final r=await http.delete(Uri.parse('$_base/v1/matching/queue'),headers:_headers).timeout(const Duration(seconds:10));if(r.statusCode!=204&&r.statusCode!=200)throw Exception(_message(r));}
 String _message(http.Response r){try{return (jsonDecode(r.body)['error']['message'] as String?)??'Matching request failed (${r.statusCode})';}catch(_){return 'Matching request failed (${r.statusCode})';}}
}