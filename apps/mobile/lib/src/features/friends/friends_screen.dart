import 'package:flutter/material.dart';
import 'friend_repository.dart';

class FriendsScreen extends StatefulWidget {
 const FriendsScreen({super.key});
 @override State<FriendsScreen> createState()=>_FriendsScreenState();
}
class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
 final _repo=FriendRepository(),_search=TextEditingController();
 late final _tabs=TabController(length:4,vsync:this);
 List<Map<String,dynamic>> _results=[],_friends=[],_incoming=[],_followers=[],_following=[];
 bool _loading=true,_searching=false;
 @override void initState(){super.initState();_load();}
 @override void dispose(){_search.dispose();_tabs.dispose();super.dispose();}
 String _name(Map<String,dynamic> p){final d=(p['display_name'] as String? ?? '').trim();return d.isNotEmpty?d:(p['username'] as String? ??'User');}
 void _toast(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
 Future<void> _load() async {
  setState(()=>_loading=true);
  try {final v=await Future.wait([_repo.friends(),_repo.incomingRequests(),_repo.followers(),_repo.following()]);
   if(mounted)setState(()=>_friends=v[0],_incoming=v[1],_followers=v[2],_following=v[3],_loading=false);
  } catch(e){if(mounted)setState(()=>_loading=false);_toast('Load error: $e');}
 }
 Future<void> _find(String q) async {
  if(q.trim().length<2){setState(()=>_results=[]);return;}
  setState(()=>_searching=true);
  try{final v=await _repo.searchProfiles(q);if(mounted)setState(()=>_results=v);}
  catch(e){_toast('Search error: $e');}finally{if(mounted)setState(()=>_searching=false);}
 }
 Future<void> _act(Future<void> Function() fn,String msg) async {
  try{await fn();_toast(msg);await _load();if(_search.text.trim().length>=2)await _find(_search.text);}
  catch(e){_toast('Action failed: $e');}
 }
 Widget _profiles(List<Map<String,dynamic>> people,{bool allowUnfollow=false}) {
  if(people.isEmpty)return const Center(child:Text('No users yet'));
  return ListView(children:people.map((p)=>ListTile(
   leading:CircleAvatar(child:Text(_name(p).isEmpty?'?':_name(p)[0].toUpperCase())),
   title:Text(_name(p)),subtitle:Text('@${p['username']??''}'),
   trailing:allowUnfollow?IconButton(tooltip:'Unfollow',icon:const Icon(Icons.person_remove),onPressed:()=>_act(()=>_repo.unfollow(p['id'] as String),'Unfollowed')):null
  )).toList());
 }
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:const Text('Connections'),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))],
   bottom:TabBar(isScrollable:true,controller:_tabs,tabs:[
    Tab(text:'Friends ${_friends.length}'),Tab(text:'Requests ${_incoming.length}'),
    Tab(text:'Followers ${_followers.length}'),Tab(text:'Following ${_following.length}')
   ])),
  body:Column(children:[
   Padding(padding:const EdgeInsets.all(12),child:TextField(controller:_search,onChanged:_find,
    decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:'Search name or username',
    suffixIcon:_searching?const SizedBox(width:20,height:20,child:CircularProgressIndicator()):null,border:const OutlineInputBorder()))),
   if(_search.text.trim().length>=2) ..._results.map((p)=>ListTile(
    title:Text(_name(p)),subtitle:Text('@${p['username']??''}'),
    trailing:Wrap(spacing:4,children:[
     IconButton(tooltip:'Follow',icon:const Icon(Icons.person_add_alt_1),onPressed:()=>_act(()=>_repo.follow(p['id'] as String),'Followed')),
     IconButton(tooltip:'Friend request',icon:const Icon(Icons.people_alt),onPressed:()=>_act(()=>_repo.sendRequest(p['id'] as String),'Request sent'))
    ]))),
   Expanded(child:_loading?const Center(child:CircularProgressIndicator()):TabBarView(controller:_tabs,children:[
    _friends.isEmpty?const Center(child:Text('No friends yet')):ListView(children:_friends.map((p)=>ListTile(
     title:Text(_name(p)),subtitle:Text('@${p['username']??''}'),
     trailing:PopupMenuButton<String>(onSelected:(v){if(v=='remove')_act(()=>_repo.removeFriend(p['id'] as String),'Friend removed');if(v=='block')_act(()=>_repo.block(p['id'] as String),'Blocked');},
      itemBuilder:(_)=>const [PopupMenuItem(value:'remove',child:Text('Remove friend')),PopupMenuItem(value:'block',child:Text('Block user'))]))).toList()),
    _incoming.isEmpty?const Center(child:Text('No requests')):ListView(children:_incoming.map((r)=>ListTile(
     title:Text('Request from ${r['sender_id']}'),trailing:Wrap(children:[
      IconButton(icon:const Icon(Icons.check),onPressed:()=>_act(()=>_repo.respond(r['id'] as String,true),'Accepted')),
      IconButton(icon:const Icon(Icons.close),onPressed:()=>_act(()=>_repo.respond(r['id'] as String,false),'Rejected'))
     ]))).toList()),
    _profiles(_followers),_profiles(_following,allowUnfollow:true)
   ])))
  ]));
}
