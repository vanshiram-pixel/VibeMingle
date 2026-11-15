import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'call_models.dart';
import 'call_signaling_coordinator.dart';
import 'webrtc_call_controller.dart';

/// In-call controls for an already-authorized/accepted session.
/// The owner must perform the server end RPC before leaving this screen.
class ActiveCallScreen extends StatefulWidget {
  const ActiveCallScreen({
    super.key,
    required this.session,
    required this.peerName,
    required this.controller,
    required this.signaling,
    required this.onEnd,
  });

  final CallSession session;
  final String peerName;
  final WebRtcCallController controller;
  final CallSignalingCoordinator signaling;
  final Future<void> Function() onEnd;

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _muted = false;
  bool _cameraEnabled = true;
  bool _ending = false;
  bool _renderersReady = false;
  RTCPeerConnectionState _connection = RTCPeerConnectionState.RTCPeerConnectionStateNew;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareRenderers());
    widget.controller.onRemoteStream = (stream) {
      _remoteRenderer.srcObject = stream;
      if (mounted) setState(() {});
    };
    widget.controller.onConnectionState = (state) {
      if (mounted) setState(() => _connection = state);
    };
  }

  Future<void> _prepareRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _localRenderer.srcObject = widget.controller.localStream;
    _remoteRenderer.srcObject = widget.controller.remoteStream;
    if (mounted) setState(() => _renderersReady = true);
  }

  Future<void> _toggleMute() async {
    final next = !_muted;
    await widget.controller.setMicrophoneMuted(next);
    if (mounted) setState(() => _muted = next);
  }

  Future<void> _toggleCamera() async {
    final next = !_cameraEnabled;
    await widget.controller.setCameraEnabled(next);
    if (mounted) setState(() => _cameraEnabled = next);
  }

  Future<void> _endCall() async {
    if (_ending) return;
    setState(() => _ending = true);
    try {
      await widget.onEnd();
    } finally {
      await widget.signaling.close();
      await widget.controller.close();
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    unawaited(_localRenderer.dispose());
    unawaited(_remoteRenderer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.session.type == CallType.video;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.peerName),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              if (video && _renderersReady && widget.controller.remoteStream != null)
                RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
              else
                const Center(child: CircleAvatar(radius: 64, child: Icon(Icons.person, size: 64))),
              if (video && _renderersReady && widget.controller.localStream != null)
                Positioned(
                  right: 16, top: 16, width: 112, height: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: RTCVideoView(_localRenderer, mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                  ),
                ),
              Positioned(
                left: 16, bottom: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Text(_connection.name.replaceAll('RTCPeerConnectionState', ''),
                      style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _Control(icon: _muted ? Icons.mic_off : Icons.mic, label: _muted ? 'Unmute' : 'Mute', onTap: _toggleMute),
              if (video) _Control(icon: _cameraEnabled ? Icons.videocam : Icons.videocam_off,
                  label: 'Camera', onTap: _toggleCamera),
              if (video) _Control(icon: Icons.flip_camera_ios, label: 'Flip', onTap: widget.controller.switchCamera),
              _Control(icon: Icons.call_end, label: 'End', color: Colors.red, onTap: _endCall, busy: _ending),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Control extends StatelessWidget {
  const _Control({required this.icon, required this.label, required this.onTap,
    this.color, this.busy = false});
  final IconData icon;
  final String label;
  final Future<void> Function() onTap;
  final Color? color;
  final bool busy;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    FloatingActionButton(
      heroTag: label,
      backgroundColor: color ?? Colors.white24,
      foregroundColor: Colors.white,
      onPressed: busy ? null : () => unawaited(onTap()),
      child: busy ? const CircularProgressIndicator() : Icon(icon),
    ),
    const SizedBox(height: 8),
    Text(label, style: const TextStyle(color: Colors.white)),
  ]);
}
