import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One-to-one WebRTC media for an already accepted private call.
class CallMediaScreen extends StatefulWidget {
  const CallMediaScreen({super.key, required this.call});
  final Map<String, dynamic> call;

  @override
  State<CallMediaScreen> createState() => _CallMediaScreenState();
}

class _CallMediaScreenState extends State<CallMediaScreen> {
  final _db = Supabase.instance.client;
  final _local = RTCVideoRenderer();
  final _remote = RTCVideoRenderer();
  final _seen = <String>{};
  final _pendingIce = <RTCIceCandidate>[];
  RTCPeerConnection? _pc;
  MediaStream? _stream;
  RealtimeChannel? _channel;
  String _status = 'Preparing camera and microphone…';
  bool _muted = false;
  bool _camera = true;
  bool _busy = true;

  String get _me => _db.auth.currentUser!.id;
  String get _peer => widget.call['caller_id'] == _me
      ? widget.call['callee_id'].toString()
      : widget.call['caller_id'].toString();
  bool get _video => widget.call['call_type'] == 'video';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      await _local.initialize();
      await _remote.initialize();
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': _video
            ? {'facingMode': 'user', 'width': 640, 'height': 480}
            : false,
      });
      _stream = stream;
      _local.srcObject = stream;
      final pc = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'}
        ],
        'sdpSemantics': 'unified-plan',
      });
      _pc = pc;
      for (final track in stream.getTracks()) {
        await pc.addTrack(track, stream);
      }
      pc.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          _remote.srcObject = event.streams.first;
          if (mounted) setState(() => _status = 'Remote media connected');
        }
      };
      pc.onIceCandidate = (candidate) {
        if (candidate.candidate != null) {
          unawaited(_send('ice', {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          }));
        }
      };
      pc.onConnectionState = (state) {
        if (mounted) setState(() => _status = 'Connection: ${state.name}');
      };

      _channel = _db.channel('mobile-rtc-${widget.call['id']}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'call_signals',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'call_id',
            value: widget.call['id'].toString(),
          ),
          callback: (payload) {
            unawaited(_apply(Map<String, dynamic>.from(payload.newRecord)));
          },
        )
        .subscribe();

      // Process any signal created before this device subscribed.
      final existing = await _db.from('call_signals')
          .select('id,sender_id,recipient_id,signal_type,payload')
          .eq('call_id', widget.call['id'].toString())
          .eq('recipient_id', _me)
          .order('created_at');
      for (final row in existing) {
        await _apply(Map<String, dynamic>.from(row));
      }

      if (widget.call['caller_id'] == _me) {
        final offer = await pc.createOffer();
        await pc.setLocalDescription(offer);
        await _send('offer', {'sdp': offer.sdp, 'type': offer.type});
        if (mounted) setState(() => _status = 'Calling… waiting for friend');
      } else if (mounted) {
        setState(() => _status = 'Waiting for caller media…');
      }
      if (mounted) setState(() => _busy = false);
    } catch (error) {
      if (mounted) setState(() {
        _status = 'Media setup failed: $error';
        _busy = false;
      });
    }
  }

  Future<void> _send(String type, Map<String, dynamic> payload) async {
    final result = await _db.rpc('call_signal_send', params: {
      'p_call': widget.call['id'].toString(),
      'p_recipient': _peer,
      'p_type': type,
      'p_payload': payload,
    });
    if (result == null) {
      // RPC returns a UUID on success; a null response is not expected.
    }
  }

  Future<void> _apply(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null || _seen.contains(id) || row['recipient_id'] != _me) return;
    _seen.add(id);
    final payload = Map<String, dynamic>.from(row['payload'] as Map);
    final pc = _pc;
    if (pc == null) return;
    try {
      switch (row['signal_type']) {
        case 'offer':
          await pc.setRemoteDescription(RTCSessionDescription(
            payload['sdp']?.toString(), payload['type']?.toString()));
          for (final candidate in _pendingIce) {
            await pc.addCandidate(candidate);
          }
          _pendingIce.clear();
          final answer = await pc.createAnswer();
          await pc.setLocalDescription(answer);
          await _send('answer', {'sdp': answer.sdp, 'type': answer.type});
          if (mounted) setState(() => _status = 'Answer sent… connecting');
          break;
        case 'answer':
          if (pc.remoteDescription == null) {
            await pc.setRemoteDescription(RTCSessionDescription(
              payload['sdp']?.toString(), payload['type']?.toString()));
            for (final candidate in _pendingIce) {
              await pc.addCandidate(candidate);
            }
            _pendingIce.clear();
            if (mounted) setState(() => _status = 'Answer received… connecting');
          }
          break;
        case 'ice':
          final candidate = RTCIceCandidate(
            payload['candidate']?.toString(),
            payload['sdpMid']?.toString(),
            (payload['sdpMLineIndex'] as num?)?.toInt(),
          );
          if (pc.remoteDescription == null) {
            _pendingIce.add(candidate);
          } else {
            await pc.addCandidate(candidate);
          }
          break;
      }
    } catch (error) {
      if (mounted) setState(() => _status = 'Signaling error: $error');
    }
  }

  void _toggleMute() {
    final next = !_muted;
    _stream?.getAudioTracks().forEach((track) => track.enabled = !next);
    setState(() => _muted = next);
  }

  void _toggleCamera() {
    final next = !_camera;
    _stream?.getVideoTracks().forEach((track) => track.enabled = next);
    setState(() => _camera = next);
  }

  Future<void> _end() async {
    try {
      await _db.rpc('call_request_end', params: {'p_call': widget.call['id']});
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    if (_channel != null) unawaited(_db.removeChannel(_channel!));
    _pc?.close();
    _stream?.getTracks().forEach((track) => track.stop());
    _local.srcObject = null;
    _remote.srcObject = null;
    _local.dispose();
    _remote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_video ? 'Video call' : 'Audio call')),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text(_status, textAlign: TextAlign.center),
      ),
      if (_video) Expanded(
        child: Stack(children: [
          Positioned.fill(child: RTCVideoView(_remote, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)),
          Positioned(
            right: 12, top: 12, width: 112, height: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RTCVideoView(_local, mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            ),
          ),
        ]),
      ) else const Expanded(
        child: Center(child: Icon(Icons.account_circle, size: 120)),
      ),
      if (_busy) const LinearProgressIndicator(),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          IconButton.filledTonal(
            onPressed: _toggleMute,
            icon: Icon(_muted ? Icons.mic_off : Icons.mic),
            tooltip: _muted ? 'Unmute' : 'Mute',
          ),
          if (_video) IconButton.filledTonal(
            onPressed: _toggleCamera,
            icon: Icon(_camera ? Icons.videocam : Icons.videocam_off),
            tooltip: _camera ? 'Turn camera off' : 'Turn camera on',
          ),
          IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _end,
            icon: const Icon(Icons.call_end),
            tooltip: 'End call',
          ),
        ]),
      ),
    ]),
  );
}
