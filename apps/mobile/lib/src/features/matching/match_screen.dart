import 'dart:async';
import 'package:flutter/material.dart';
import 'match_queue_repository.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});
  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final _repo = MatchQueueRepository();
  bool _consent = false, _queued = false, _busy = false;
  String _mode = 'random';
  Timer? _heartbeat;
  StreamSubscription<Map<String,dynamic>>? _events;
  String? _sessionId;
  String _sessionState='waiting';

  @override
  void dispose() {
    _heartbeat?.cancel();
    _events?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    if (!_consent) throw Exception('Please enable matching consent first.');
    await _repo.setConsent(enabled: true, version: 'v4.1-consent-1');
    await _repo.enter(mode: _mode);
    await _events?.cancel();
    _events=_repo.matchEvents().listen((event){
      if(!mounted)return;
      setState((){
        if(event['event_type']=='matched'){_sessionId=event['session_id']?.toString();_sessionState=event['state']?.toString()??'reserved';}
        else if(event['session_id']==_sessionId){_sessionState=event['state']?.toString()??_sessionState;if(_sessionState=='ended'||_sessionState=='failed'||_sessionState=='cancelled'){_sessionId=null;}}
      });
    },onError:(_){if(mounted)setState(()=>_sessionState='reconnecting');});
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        await _repo.heartbeat();
      } catch (_) {
        _heartbeat?.cancel();
        if (mounted) setState(() => _queued = false);
      }
    });
    if (mounted) setState(() => _queued = true);
  }

  Future<void> _acceptMatch() async {
    final id=_sessionId;
    if(id==null)throw StateError('No match session');
    final row=await _repo.acceptSession(sessionId:id);
    if(mounted)setState(()=>_sessionState=row['state']?.toString()??'connecting');
  }

  Future<void> _declineMatch() async {
    final id=_sessionId;
    if(id==null)throw StateError('No match session');
    await _repo.declineSession(sessionId:id);
    if(mounted)setState(()=>_sessionId=null);
  }

  Future<void> _leave() async {
    _heartbeat?.cancel();
    await _repo.leave();
    await _events?.cancel();
    _events = null;
    if (mounted) setState(() {
      _queued = false;
      _sessionId = null;
      _sessionState = 'waiting';
    });
  }

  Future<void> _revoke() async {
    _heartbeat?.cancel();
    if (_queued) await _repo.leave();
    await _events?.cancel();
    _events = null;
    await _repo.setConsent(enabled: false, version: 'v4.1-consent-1');
    if (mounted) setState(() {
      _queued = false;
      _sessionId = null;
      _sessionState = 'waiting';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Stranger Match')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.video_call, size: 72),
            const Text('Meet someone new', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Matching requires verified age eligibility, an available profile, online presence, and explicit consent. Your exact location is never shown.'),
            SwitchListTile(
              value: _consent,
              onChanged: (v) {
                setState(() => _consent = v);
                if (!v) _run(_revoke);
              },
              title: const Text('I consent to stranger matching'),
              subtitle: const Text('You can leave the queue or revoke consent anytime.'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _mode,
              decoration: const InputDecoration(labelText: 'Matching mode'),
              items: const [
                DropdownMenuItem(value: 'random', child: Text('Random')),
                DropdownMenuItem(value: 'manual', child: Text('Preferences')),
                DropdownMenuItem(value: 'next', child: Text('Next / Switch')),
              ],
              onChanged: (v) => setState(() => _mode = v ?? 'random'),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : () => _run(_queued ? _leave : _join),
              icon: Icon(_queued ? Icons.stop : Icons.search),
              label: Text(_busy ? 'Please wait…' : _queued ? 'Leave queue' : 'Start matching'),
            ),
            const SizedBox(height: 12),
            Text(_sessionId!=null?'Match session: $_sessionState':_queued ? 'Queue active — searching for a compatible person…' : 'Queue inactive',
                textAlign: TextAlign.center),
            if(_sessionId!=null && _sessionState=='reserved') ...[
              const SizedBox(height: 16),
              FilledButton.icon(onPressed:_busy?null:()=>_run(_acceptMatch),icon:const Icon(Icons.check_circle),label:const Text('Accept match')),
              OutlinedButton.icon(onPressed:_busy?null:()=>_run(_declineMatch),icon:const Icon(Icons.close),label:const Text('Decline match')),
            ],
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _busy ? null : () => _run(_revoke),
              child: const Text('Revoke matching consent'),
            ),
          ],
        ),
      );
}
