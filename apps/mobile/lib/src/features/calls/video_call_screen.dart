import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'call_service.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key, required this.sessionId});
  final String sessionId;
  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _service = CallService();
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _connecting = true, _mic = true, _camera = true, _leaving = false, _reconnecting = false;
  String? _error;

  @override
  void initState() { super.initState(); _connect(); }

  Future<void> _connect() async {
    try {
      final credentials = await _service.requestToken(widget.sessionId);
      final room = Room();
      _listener = room.createListener();
      _listener!
        ..on<RoomReconnectingEvent>((_) { if (mounted) setState(() => _reconnecting = true); })
        ..on<RoomResumingEvent>((_) { if (mounted) setState(() => _reconnecting = true); })
        ..on<RoomReconnectedEvent>((_) { if (mounted) setState(() => _reconnecting = false); })
        ..on<ParticipantConnectedEvent>((_) { if (mounted) setState(() {}); })
        ..on<ParticipantDisconnectedEvent>((_) { if (mounted) setState(() {}); })
        ..on<TrackSubscribedEvent>((_) { if (mounted) setState(() {}); })
        ..on<TrackUnsubscribedEvent>((_) { if (mounted) setState(() {}); })
        ..on<TrackPublishedEvent>((_) { if (mounted) setState(() {}); });
      await room.connect(credentials.url, credentials.token);
      await room.localParticipant?.setMicrophoneEnabled(true);
      await room.localParticipant?.setCameraEnabled(true);
      if (!mounted) { await room.disconnect(); return; }
      setState(() => _room = room);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  VideoTrack? _localTrack() {
    final participant = _room?.localParticipant;
    if (participant == null) return null;
    for (final publication in participant.videoTrackPublications) {
      final track = publication.track;
      if (track is VideoTrack) return track;
    }
    return null;
  }

  VideoTrack? _remoteTrack() {
    final room = _room;
    if (room == null) return null;
    for (final participant in room.remoteParticipants.values) {
      for (final publication in participant.videoTrackPublications) {
        final track = publication.track;
        if (track is VideoTrack && publication.subscribed) return track;
      }
    }
    return null;
  }

  Future<void> _toggleMic() async {
    final p = _room?.localParticipant; if (p == null) return;
    try { await p.setMicrophoneEnabled(!_mic); if (mounted) setState(() => _mic = !_mic); }
    catch (e) { _show(e.toString()); }
  }
  Future<void> _toggleCamera() async {
    final p = _room?.localParticipant; if (p == null) return;
    try { await p.setCameraEnabled(!_camera); if (mounted) setState(() => _camera = !_camera); }
    catch (e) { _show(e.toString()); }
  }

  Future<void> _report() async {
    const choices = <String,String>{'harassment':'Harassment','sexual_content':'Sexual content','minor_safety':'Minor safety','spam':'Spam','hate':'Hate or abuse','violence':'Violence','impersonation':'Impersonation','scam':'Scam','other':'Other'};
    final category = await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(
      title: const Text('Report this person'),
      content: Column(mainAxisSize:MainAxisSize.min,children:choices.entries.map((e)=>ListTile(title:Text(e.value),onTap:()=>Navigator.pop(ctx,e.key))).toList()),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel'))]));
    if(category==null||!mounted)return;
    try { await _service.report(widget.sessionId,category); if(mounted)_show('Report submitted. Thank you.'); }
    catch(e){if(mounted)_show(e.toString());}
  }
\n  Future<void> _end() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    try { await _room?.disconnect(); await _service.leave(widget.sessionId); }
    catch (e) { _show('Call ended locally. Server update: $e'); }
    if (mounted) Navigator.pop(context);
  }
  void _show(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  void dispose() { _listener?.dispose(); _room?.disconnect(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final track = _remoteTrack();
    final localTrack = _localTrack();
    return Scaffold(
      backgroundColor: const Color(0xFF090912),
      appBar: AppBar(title: const Text('VibeMingle call'), backgroundColor: Colors.transparent, actions:[IconButton(tooltip:'Report',onPressed:_leaving?null:_report,icon:const Icon(Icons.flag_outlined))]),
      body: SafeArea(child: Column(children: [
        Expanded(child: _connecting
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
            : Stack(
                fit: StackFit.expand,
                children: [
                  if (_reconnecting)
                    const Positioned(top: 12, left: 12, right: 12, child: Material(color: Colors.orange, borderRadius: BorderRadius.all(Radius.circular(10)), child: Padding(padding: EdgeInsets.all(10), child: Text('Reconnecting… please wait', textAlign: TextAlign.center, style: TextStyle(color: Colors.black))))),
                  if (track != null)
                    ClipRRect(borderRadius: BorderRadius.circular(18), child: VideoTrackRenderer(track))
                  else
                    const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.person, size: 100, color: Colors.deepPurpleAccent),
                      SizedBox(height: 12), Text('Waiting for partner video…'),
                    ])),
                  if (localTrack != null)
                    Positioned(
                      right: 16, top: 16, width: 112, height: 160,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: VideoTrackRenderer(localTrack),
                      ),
                    ),
                ],
              )),
        Padding(padding: const EdgeInsets.all(22), child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _btn(_mic ? Icons.mic : Icons.mic_off, _mic ? 'Mute' : 'Unmute', _toggleMic),
            _btn(_camera ? Icons.videocam : Icons.videocam_off, _camera ? 'Camera off' : 'Camera on', _toggleCamera),
            _btn(Icons.call_end, 'End', _end, danger: true),
          ],
        )),
      ])),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback action, {bool danger = false}) =>
    Column(children: [
      IconButton(onPressed: _leaving ? null : action, icon: Icon(icon),
        style: IconButton.styleFrom(backgroundColor: danger ? Colors.red : const Color(0xFF292943), foregroundColor: Colors.white)),
      Text(label),
    ]);
}
