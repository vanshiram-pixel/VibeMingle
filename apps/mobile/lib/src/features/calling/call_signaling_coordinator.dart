import 'dart:async';

import 'call_repository.dart';
import 'webrtc_call_controller.dart';

/// Bridges participant-authorized Supabase signal rows to WebRTC.
/// Create only after the server marks the call accepted/connecting.
class CallSignalingCoordinator {
  CallSignalingCoordinator({
    required this.repository,
    required this.controller,
    required this.callId,
    required this.remoteUserId,
  });

  final CallRepository repository;
  final WebRtcCallController controller;
  final String callId;
  final String remoteUserId;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  bool _closed = false;

  Future<void> startListening() async {
    if (_closed) throw StateError('Signaling coordinator is closed');
    if (_subscription != null) return;
    _subscription = repository.signalsForCall(callId).listen(
      (row) => unawaited(_handle(row)),
      onError: (Object error, StackTrace stack) {},
    );
  }

  Future<void> send(Map<String, dynamic> signal) async {
    if (_closed) throw StateError('Signaling coordinator is closed');
    final kind = signal['kind']?.toString();
    if (kind == null) throw ArgumentError('Signal kind missing');
    final payload = Map<String, dynamic>.from(signal)..remove('kind');
    await repository.sendSignal(
      callId: callId,
      recipientId: remoteUserId,
      kind: kind,
      payload: payload,
    );
  }

  Future<void> _handle(Map<String, dynamic> row) async {
    if (_closed || row['call_id'] != callId ||
        row['sender_id'] != remoteUserId ||
        row['recipient_id'] != repository.currentUserId) return;
    final kind = row['kind']?.toString();
    final raw = row['payload'];
    if (raw is! Map) return;
    final payload = Map<String, dynamic>.from(raw);
    try {
      switch (kind) {
        case 'offer':
          final sdp = payload['sdp'];
          if (sdp is String && sdp.isNotEmpty) await controller.acceptOffer(sdp);
        case 'answer':
          final sdp = payload['sdp'];
          if (sdp is String && sdp.isNotEmpty) await controller.acceptAnswer(sdp);
        case 'ice':
          final candidate = payload['candidate'];
          if (candidate is String && candidate.isNotEmpty) {
            await controller.addRemoteIce(
              candidate: candidate,
              sdpMid: payload['sdpMid'] as String?,
              sdpMLineIndex: (payload['sdpMLineIndex'] as num?)?.toInt(),
            );
          }
        case 'hangup':
          await close();
        default:
          break;
      }
    } catch (_) {
      // Invalid/stale signaling is ignored; call state is controlled by RPC.
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription?.cancel();
    _subscription = null;
  }
}
