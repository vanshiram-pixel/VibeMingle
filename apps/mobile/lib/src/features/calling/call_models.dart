enum CallType { audio, video }

enum CallStatus {
  created,
  ringing,
  accepted,
  connecting,
  connected,
  ended,
  declined,
  missed,
  cancelled,
  busy,
  failed,
}

class CallSession {
  const CallSession({
    required this.id,
    required this.callerId,
    required this.calleeId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.connectedAt,
    this.endedAt,
    this.endReason,
  });

  final String id;
  final String callerId;
  final String calleeId;
  final CallType type;
  final CallStatus status;
  final DateTime createdAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final String? endReason;

  factory CallSession.fromJson(Map<String, dynamic> json) => CallSession(
    id: json['id'].toString(),
    callerId: json['caller_id'].toString(),
    calleeId: json['callee_id'].toString(),
    type: json['call_type'] == 'video' ? CallType.video : CallType.audio,
    status: CallStatus.values.firstWhere(
      (s) => s.name == json['status'], orElse: () => CallStatus.failed),
    createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
    connectedAt: json['connected_at'] == null ? null :
      DateTime.parse(json['connected_at'].toString()).toLocal(),
    endedAt: json['ended_at'] == null ? null :
      DateTime.parse(json['ended_at'].toString()).toLocal(),
    endReason: json['end_reason']?.toString(),
  );

  bool get isTerminal => const {
    CallStatus.ended, CallStatus.declined, CallStatus.missed,
    CallStatus.cancelled, CallStatus.busy, CallStatus.failed,
  }.contains(status);
}

class CallStateEvent {
  const CallStateEvent({
    required this.callId,
    required this.status,
    required this.actorId,
    this.reason,
  });

  final String callId;
  final CallStatus status;
  final String actorId;
  final String? reason;

  factory CallStateEvent.fromJson(Map<String, dynamic> json) => CallStateEvent(
    callId: json['call_id'].toString(),
    status: CallStatus.values.firstWhere(
      (s) => s.name == json['status'], orElse: () => CallStatus.failed),
    actorId: json['actor_id'].toString(),
    reason: json['reason']?.toString(),
  );
}
