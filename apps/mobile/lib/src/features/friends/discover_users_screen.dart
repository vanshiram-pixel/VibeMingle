import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_config.dart';

class DiscoverUsersScreen extends StatefulWidget {
  const DiscoverUsersScreen({super.key});
  @override
  State<DiscoverUsersScreen> createState()=>_DiscoverUsersScreenState();
}
class _DiscoverUsersScreenState extends State<DiscoverUsersScreen>{
  final _search=TextEditingController();
  List<dynamic> _users=[];
  bool _loading=false;
  String? _message;
  Map<String,String> get _headers=>{'Authorization':'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken??''}','Content-Type':'application/json'};
  Uri _uri(String path)=>Uri.parse('${AppConfig.apiBaseUrl}$path');

  @override void dispose(){_search.dispose();super.dispose();}
  Future<void> find() async{
    setState(()=>_loading=true);
    try{
      final q=Uri.encodeQueryComponent(_search.text.trim());
      final res=await http.get(_uri('/v1/users/discover?q=$q&limit=20'),headers:_headers);
      final body=jsonDecode(res.body);
      if(res.statusCode<200||res.statusCode>=300)throw Exception();
      if(mounted)setState(()=>_users=body['data'] is List?body['data']:[]);
    }catch(_){if(mounted)setState(()=>_message='Search नहीं हो सकी। API/migration जाँचें.');}
    finally{if(mounted)setState(()=>_loading=false);}
  }
  Future<void> add(String id)async{
    try{
      final res=await http.post(_uri('/v1/friends/requests'),headers:_headers,body:jsonEncode({'targetUserId':id}));
      if(res.statusCode<200||res.statusCode>=300)throw Exception();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Friend request sent.')));
    }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Request नहीं भेजा जा सका।')));}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Discover People')),
    body:Column(children:[
      Padding(padding:const EdgeInsets.all(16),child:Row(children:[
        Expanded(child:TextField(controller:_search,onSubmitted:(_)=>find(),decoration:const InputDecoration(hintText:'Search display name'))),
        IconButton(onPressed:_loading?null:find,icon:const Icon(Icons.search)),
      ])),
      if(_message!=null)Text(_message!),
      Expanded(child:_loading?const Center(child:CircularProgressIndicator()):ListView.builder(
        itemCount:_users.length,itemBuilder:(context,index){
          final u=_users[index] as Map<String,dynamic>;
          final avatar=u['avatar_path']?.toString(); return ListTile(leading:CircleAvatar(backgroundImage:avatar!=null&&avatar.startsWith('http')?NetworkImage(avatar):null,child:avatar!=null&&avatar.startsWith('http')?null:const Icon(Icons.person)),title:Text(u['display_name']?.toString()??'VibeMingle User'),trailing:IconButton(icon:const Icon(Icons.person_add_alt_1),onPressed:()=>add(u['user_id'].toString())));
        },
      )),
    ]),
  );
}
