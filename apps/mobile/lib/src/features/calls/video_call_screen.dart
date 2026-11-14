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
  bool _connecting = true, _mic = true, _camera = true, _leaving = false;
  String? _error;

  @override
  void initState() { super.initState(); _connect(); }

  Future<void> _connect() async {
    try {
      final credentials = await _service.requestToken(widget.sessionId);
      final room = Room();
      _listener = room.createListener();
      _listener!
        ..on<ParticipantConnected>((_) { if (mounted) setState(() {}); })
        ..on<ParticipantDisconnected>((_) { if (mounted) setState(() {}); })
        ..on<TrackSubscribed>((_) { if (mounted) setState(() {}); })
        ..on<TrackUnsubscribed>((_) { if (mounted) setState(() {}); })
        ..on<TrackPublished>((_) { if (mounted) setState(() {}); });
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

  VideoTrack? _remoteTrack() {
    final room = _room;
    if (room == null) return null;
    for (final participant in room.remoteParticipants.values) {
      for (final publication in participant.videoTrackPublications.values) {
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
  Future<void> _end() async {
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
    return Scaffold(
      backgroundColor: const Color(0xFF090912),
      appBar: AppBar(title: const Text('VibeMingle call'), backgroundColor: Colors.transparent),
      body: SafeArea(child: Column(children: [
        Expanded(child: _connecting
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
            : track != null
              ? ClipRRect(borderRadius: BorderRadius.circular(18), child: VideoTrackRenderer(track))
              : const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.person, size: 100, color: Colors.deepPurpleAccent),
                  SizedBox(height: 12), Text('Waiting for partner video…'),
                ]))),
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
