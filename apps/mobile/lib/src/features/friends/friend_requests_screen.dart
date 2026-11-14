import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_config.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});
  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final _target = TextEditingController();
  List<dynamic> _requests = [];
  bool _loading = true, _busy = false;
  String? _message;
  String get _myId => Supabase.instance.client.auth.currentUser?.id ?? '';
  Map<String,String> get _headers => {
    'Authorization':'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken ?? ''}',
    'Content-Type':'application/json',
  };
  Uri _uri(String path)=>Uri.parse('${AppConfig.apiBaseUrl}$path');

  @override
  void initState(){super.initState();load();}
  @override
  void dispose(){_target.dispose();super.dispose();}

  Future<void> load() async {
    setState(()=>_loading=true);
    try{
      final res=await http.get(_uri('/v1/friends/requests'),headers:_headers);
      final body=jsonDecode(res.body);
      if(res.statusCode<200||res.statusCode>=300)throw Exception();
      if(mounted)setState(()=>_requests=body['data'] is List?body['data']:[]);
    }catch(_){if(mounted)setState(()=>_message='Requests load नहीं हुए। API/migration जाँचें.');}
    finally{if(mounted)setState(()=>_loading=false);}
  }

  Future<void> send() async {
    final id=_target.text.trim();
    if(id.isEmpty)return;
    setState(()=>_busy=true);
    try{
      final res=await http.post(_uri('/v1/friends/requests'),headers:_headers,body:jsonEncode({'targetUserId':id}));
      final body=jsonDecode(res.body);
      if(res.statusCode<200||res.statusCode>=300)throw Exception(body['error']?['message']??'Failed');
      _target.clear();if(mounted)setState(()=>_message='Friend request sent.');
      await load();
    }catch(_){if(mounted)setState(()=>_message='Request नहीं भेजा। User UUID और API जाँचें.');}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  Future<void> act(String requestId,{String? action,bool cancel=false}) async {
    setState(()=>_busy=true);
    try{
      final res=cancel
        ?await http.delete(_uri('/v1/friends/requests/$requestId'),headers:_headers)
        :await http.post(_uri('/v1/friends/requests/$requestId/respond'),headers:_headers,body:jsonEncode({'action':action}));
      if(res.statusCode<200||res.statusCode>=300)throw Exception();
      await load();
    }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Action complete नहीं हुआ।')));}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Friend Requests')),
    body:Column(children:[
      Padding(padding:const EdgeInsets.all(16),child:Column(children:[
        TextField(controller:_target,decoration:const InputDecoration(labelText:'Target user UUID',hintText:'Paste exact user ID')),
        const SizedBox(height:8),SizedBox(width:double.infinity,child:FilledButton(onPressed:_busy?null:send,child:const Text('Send Friend Request'))),
        if(_message!=null)Text(_message!,style:const TextStyle(color:Colors.amber)),
      ])),
      const Divider(),
      Expanded(child:_loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView.builder(
        itemCount:_requests.length,itemBuilder:(context,index){
          final item=_requests[index] as Map<String,dynamic>;
          final incoming=item['receiver_id']==_myId;
          final pending=item['status']=='pending';
          final other=incoming?item['sender_id']:item['receiver_id'];
          return ListTile(
            leading:Icon(incoming?Icons.call_received:Icons.call_made),
            title:Text(incoming?'Incoming request':'Outgoing request'),
            subtitle:Text('$other • ${item['status']}'),
            trailing:pending?PopupMenuButton<String>(enabled:!_busy,onSelected:(v){
              if(v=='accept'||v=='reject')act(item['id'].toString(),action:v);
              if(v=='cancel')act(item['id'].toString(),cancel:true);
            },itemBuilder:(_)=>[
              if(incoming)const PopupMenuItem(value:'accept',child:Text('Accept')),
              if(incoming)const PopupMenuItem(value:'reject',child:Text('Reject')),
              if(!incoming)const PopupMenuItem(value:'cancel',child:Text('Cancel')),
            ]):null,
          );
        },
      ))),
    ]),
  );
}
