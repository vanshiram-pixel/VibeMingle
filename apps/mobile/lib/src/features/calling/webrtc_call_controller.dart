import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

/// WebRTC media lifecycle for a single accepted call.
///
/// The signaling transport is intentionally injected: server authorization and
/// offer/answer/ICE exchange must be implemented separately. Never connect this
/// controller to untrusted broadcast signaling.
class WebRtcCallController {
  WebRtcCallController({
    required this.sendSignal,
    required this.onRemoteStream,
    required this.onConnectionState,
  });

  /// Sends an authenticated, participant-checked signal to the peer.
  final Future<void> Function(Map<String, dynamic> signal) sendSignal;
  final void Function(MediaStream stream) onRemoteStream;
  final void Function(RTCPeerConnectionState state) onConnectionState;

  RTCPeerConnection? _peer;
  MediaStream? _local;
  MediaStream? _remote;
  bool _closed = false;
  bool _hasRemoteDescription = false;
  final List<RTCIceCandidate> _pendingIce = [];

  MediaStream? get localStream => _local;
  MediaStream? get remoteStream => _remote;

  Future<void> initialize({required bool video}) async {
    if (_closed) throw StateError('Call controller is closed');
    _local = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video ? {'facingMode': 'user'} : false,
    });
    _peer = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        // Production must configure authenticated TURN credentials from server.
      ],
      'sdpSemantics': 'unified-plan',
    });
    for (final track in _local!.getTracks()) {
      await _peer!.addTrack(track, _local!);
    }
    _peer!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remote = event.streams.first;
        onRemoteStream(_remote!);
      }
    };
    _peer!.onIceCandidate = (candidate) {
      if (candidate.candidate == null || _closed) return;
      unawaited(sendSignal({
        'kind': 'ice',
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      }));
    };
    _peer!.onConnectionState = onConnectionState;
  }

  /// Caller creates offer after the server has accepted/authorized the session.
  Future<void> createOffer() async {
    final pc = _peer ?? (throw StateError('Initialize media first'));
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    await sendSignal({'kind': 'offer', 'sdp': offer.sdp});
  }

  Future<void> acceptOffer(String sdp) async {
    final pc = _peer ?? (throw StateError('Initialize media first'));
    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
    _hasRemoteDescription = true;
    await _flushPendingIce();
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    await sendSignal({'kind': 'answer', 'sdp': answer.sdp});
  }

  Future<void> acceptAnswer(String sdp) async {
    await (_peer ?? (throw StateError('Initialize media first')))
        .setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
    _hasRemoteDescription = true;
    await _flushPendingIce();
  }

  Future<void> addRemoteIce({
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) async {
    final ice = RTCIceCandidate(candidate, sdpMid, sdpMLineIndex);
    if (!_hasRemoteDescription) {
      _pendingIce.add(ice);
      return;
    }
    await (_peer ?? (throw StateError('Initialize media first'))).addCandidate(ice);
  }

  Future<void> _flushPendingIce() async {
    final pc = _peer ?? (throw StateError('Initialize media first'));
    for (final candidate in List<RTCIceCandidate>.of(_pendingIce)) {
      await pc.addCandidate(candidate);
    }
    _pendingIce.clear();
  }

  Future<void> setMicrophoneMuted(bool muted) async {
    for (final track in _local?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  Future<void> setCameraEnabled(bool enabled) async {
    for (final track in _local?.getVideoTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = enabled;
    }
  }

  Future<void> switchCamera() async {
    final tracks = _local?.getVideoTracks() ?? <MediaStreamTrack>[];
    if (tracks.isNotEmpty) await Helper.switchCamera(tracks.first);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _peer?.close();
    await _peer?.dispose();
    for (final track in _local?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _local?.dispose();
    await _remote?.dispose();
    _peer = null;
    _local = null;
    _remote = null;
    _pendingIce.clear();
  }
}
