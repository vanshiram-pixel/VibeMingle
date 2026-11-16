import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Private call invitations and lifecycle. WebRTC media is not yet wired here.
class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});
  @override
  State<CallsScreen> createState() => _CallsScreenState();
}
class _CallsScreenState extends State<CallsScreen> {
  final _db = Supabase.instance.client;
  final _peer = TextEditingController();
  bool _busy = false;
  String? _error, _notice;
  List<Map<String,dynamic>> _calls = [];
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _load();
    _refresh = Timer.periodic(const Duration(seconds: 6), (_) => _load());
  }

  Future<void> _load() async {
    try {
      final uid = _db.auth.currentUser!.id;
      final rows = await _db.from('call_requests')
        .select('id,caller_id,callee_id,call_type,status,created_at')
        .or('caller_id.eq.$uid,callee_id.eq.$uid')
        .order('created_at',ascending:false).limit(30);
      if(mounted) setState(()=>_calls=List<Map<String,dynamic>>.from(rows));
    } catch(e) { if(mounted && _calls.isEmpty) setState(()=>_error=e.toString()); }
  }

  Future<void> _start(String type) async {
    final peer=_peer.text.trim();
    if(peer.isEmpty) return;
    setState(()=>_busy=true);
    try {
      final id=await _db.rpc('call_request_create',params:{'p_callee':peer,'p_type':type});
      if(mounted) setState(()=>_notice='${type=='video'?'Video':'Audio'} call request sent • ${id.toString().substring(0,8)}');
      await _load();
    } catch(e) { if(mounted) setState(()=>_error=e.toString()); }
    finally { if(mounted) setState(()=>_busy=false); }
  }

  Future<void> _respond(String id,bool accept) async {
    setState(()=>_busy=true);
    try {
      await _db.rpc('call_request_respond',params:{'p_call':id,'p_accept':accept});
      if(mounted) setState(()=>_notice=accept?'Call accepted. Media connection is a separate step.':'Call declined.');
      await _load();
    } catch(e) { if(mounted) setState(()=>_error=e.toString()); }
    finally { if(mounted) setState(()=>_busy=false); }
  }

  Future<void> _cancel(String id) async {
    try { await _db.rpc('call_request_cancel',params:{'p_call':id}); await _load(); }
    catch(e) { if(mounted) setState(()=>_error=e.toString()); }
  }

  Future<void> _end(String id) async {
    try { await _db.rpc('call_request_end',params:{'p_call':id}); await _load(); }
    catch(e) { if(mounted) setState(()=>_error=e.toString()); }
  }

  @override
  void dispose(){_refresh?.cancel();_peer.dispose();super.dispose();}

  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Private calls'),actions:[
      IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Text('Call a friend',style:Theme.of(context).textTheme.titleLarge),
      const SizedBox(height:8),
      TextField(controller:_peer,decoration:const InputDecoration(labelText:'Friend user ID (UUID)',border:OutlineInputBorder())),
      const SizedBox(height:8),
      Row(children:[
        Expanded(child:FilledButton.icon(onPressed:_busy?null:()=>_start('audio'),icon:const Icon(Icons.call),label:const Text('Audio'))),
        const SizedBox(width:8),
        Expanded(child:FilledButton.icon(onPressed:_busy?null:()=>_start('video'),icon:const Icon(Icons.video_call),label:const Text('Video'))),
      ]),
      if(_busy)const LinearProgressIndicator(),
      if(_notice!=null)Padding(padding:const EdgeInsets.only(top:8),child:Text(_notice!)),
      if(_error!=null)Padding(padding:const EdgeInsets.only(top:8),child:Text(_error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
      const Divider(height:32),
      Text('Recent & incoming requests',style:Theme.of(context).textTheme.titleLarge),
      ..._calls.map((c){
        final incoming=c['callee_id']==_db.auth.currentUser!.id;
        final st=c['status'].toString();
        final active=st=='ringing'&&incoming;
        return Card(child:ListTile(
          leading:Icon(c['call_type']=='video'?Icons.video_call:Icons.call),
          title:Text('${incoming?'From':'To'} • ${(incoming?c['caller_id']:c['callee_id']).toString().substring(0,8)}…'),
          subtitle:Text('${c['call_type']} • $st'),
          trailing:active?Wrap(children:[
            IconButton(onPressed:_busy?null:()=>_respond(c['id'].toString(),true),icon:const Icon(Icons.check,color:Colors.green),tooltip:'Accept'),
            IconButton(onPressed:_busy?null:()=>_respond(c['id'].toString(),false),icon:const Icon(Icons.close),tooltip:'Decline'),
          ]):st=='ringing'&&!incoming?IconButton(onPressed:()=>_cancel(c['id'].toString()),icon:const Icon(Icons.cancel),tooltip:'Cancel'):st=='accepted'?IconButton(onPressed:()=>_end(c['id'].toString()),icon:const Icon(Icons.call_end),tooltip:'End'):null,
        ));
      }),
      const Padding(padding:EdgeInsets.only(top:12),child:Text('Note: invitations and accept/decline are implemented. Live audio/video media (WebRTC) is not connected yet.')),
    ]),
  );
}
