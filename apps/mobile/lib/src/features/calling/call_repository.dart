import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'call_models.dart';

/// Thin authenticated call-session API. Server RPCs must enforce participant,
/// friendship/block policy and state transitions (never trust client status).
class CallRepository {
  CallRepository(this._db);

  final SupabaseClient _db;
  RealtimeChannel? _channel;
  String? get currentUserId => _db.auth.currentUser?.id;

  Future<CallSession> startCall({
    required String friendId,
    required CallType type,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw StateError('Sign in before calling');
    final row = await _db.rpc('call_start', params: {
      'p_callee': friendId,
      'p_call_type': type.name,
    });
    return CallSession.fromJson(Map<String, dynamic>.from(row as Map));
  }

  /// Server RPC parameter is p_next_status (not p_action).
  /// Restrict client actions to the state machine's known transitions.
  Future<CallSession> transition({
    required String callId,
    required String action,
    String? reason,
  }) async {
    const allowed = {'accepted', 'connecting', 'connected', 'declined', 'missed', 'ended', 'failed'};
    if (!allowed.contains(action)) throw ArgumentError.value(action, 'action', 'Unsupported call transition');
    final row = await _db.rpc('call_transition', params: {
      'p_call_id': callId,
      'p_next_status': action,
      'p_end_reason': reason,
    });
    return CallSession.fromJson(Map<String, dynamic>.from(row as Map));
  }

  Future<CallSession> accept(String callId) => transition(callId: callId, action: 'accepted');
  Future<CallSession> decline(String callId) => transition(callId: callId, action: 'declined');
  Future<CallSession> end(String callId, {String reason = 'user_ended'}) =>
      transition(callId: callId, action: 'ended', reason: reason);

  Future<List<CallSession>> history({int limit = 50}) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw StateError('Sign in to view call history');
    final rows = await _db.from('call_sessions')
      .select()
      .or('caller_id.eq.$uid,callee_id.eq.$uid')
      .order('created_at', ascending: false)
      .limit(limit.clamp(1, 100));
    return List<Map<String, dynamic>>.from(rows)
      .map(CallSession.fromJson).toList();
  }

  /// Send SDP/ICE only to the other authenticated call participant.
  /// Database RLS rejects non-participants, wrong recipients and inactive calls.
  Future<void> sendSignal({
    required String callId,
    required String recipientId,
    required String kind,
    required Map<String, dynamic> payload,
  }) async {
    if (!const {'offer', 'answer', 'ice', 'renegotiate', 'hangup'}.contains(kind)) {
      throw ArgumentError.value(kind, 'kind');
    }
    if (payload.toString().length > 60000) {
      throw ArgumentError('Call signal payload is too large');
    }
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw StateError('Sign in before signaling');
    await _db.from('call_signals').insert({
      'call_id': callId,
      'sender_id': uid,
      'recipient_id': recipientId,
      'kind': kind,
      'payload': payload,
      'expires_at': DateTime.now().toUtc().add(const Duration(minutes: 10)).toIso8601String(),
    });
  }

  /// Listen only to signals addressed to this user for this call.
  /// PostgreSQL changes are filtered by call ID and further constrained by RLS.
  Stream<Map<String, dynamic>> signalsForCall(String callId) {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw StateError('Sign in before signaling');
    late final RealtimeChannel channel;
    final controller = StreamController<Map<String, dynamic>>(onCancel: () async {
      await _db.removeChannel(channel);
    });
    channel = _db.channel('call-signals-$callId-$uid')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'call_signals',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'call_id',
          value: callId,
        ),
        callback: (event) {
          final row = event.newRecord;
          if (row['recipient_id'] == uid && !controller.isClosed) {
            controller.add(Map<String, dynamic>.from(row));
          }
        },
      ).subscribe();
    return controller.stream;
  }

  /// Fetch a participant's current session state (recovery after missed realtime events).
  Future<CallSession> getSession(String callId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw StateError('Sign in to inspect call state');
    final row = await _db.from('call_sessions').select().eq('id', callId).single();
    if (row['caller_id'] != uid && row['callee_id'] != uid) {
      throw StateError('Not a participant in this call');
    }
    return CallSession.fromJson(Map<String, dynamic>.from(row));
  }

  /// Live incoming ringing sessions addressed to the signed-in user.
  /// call_sessions is published to Supabase Realtime by migration 0021;
  /// the callback rechecks callee/status rather than trusting the filter alone.
  Stream<CallSession> incomingCalls() {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw StateError('Sign in before listening for calls');
    late final RealtimeChannel channel;
    final controller = StreamController<CallSession>(onCancel: () async {
      await _db.removeChannel(channel);
    });
    channel = _db.channel('incoming-calls-$uid')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'call_sessions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'callee_id',
          value: uid,
        ),
        callback: (event) {
          final row = event.newRecord;
          if (row['callee_id'] == uid && row['status'] == 'ringing' &&
              !controller.isClosed) {
            controller.add(CallSession.fromJson(Map<String, dynamic>.from(row)));
          }
        },
      ).subscribe();
    return controller.stream;
  }

  /// Recover ringing calls after app launch or a missed realtime INSERT.
  Future<List<CallSession>> pendingIncomingCalls() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw StateError('Sign in before checking incoming calls');
    final rows = await _db.from('call_sessions').select()
      .eq('callee_id', uid).eq('status', 'ringing')
      .order('created_at', ascending: true).limit(10);
    return List<Map<String, dynamic>>.from(rows).map(CallSession.fromJson).toList();
  }

  /// Realtime status changes for one participant-authorized call session.
  Stream<CallSession> sessionUpdates(String callId) {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw StateError('Sign in before listening for calls');
    late final RealtimeChannel channel;
    final controller = StreamController<CallSession>(onCancel: () async {
      await _db.removeChannel(channel);
    });
    channel = _db.channel('call-session-$callId-$uid')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'call_sessions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: callId,
        ),
        callback: (event) {
          final row = event.newRecord;
          if ((row['caller_id'] == uid || row['callee_id'] == uid) &&
              !controller.isClosed) {
            controller.add(CallSession.fromJson(Map<String, dynamic>.from(row)));
          }
        },
      ).subscribe();
    return controller.stream;
  }

  /// Subscribe to server-authorized call events for this user.
  /// Realtime RLS/channel authorization must restrict events to participants.
  Stream<CallStateEvent> eventsForUser() {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw StateError('Sign in before listening for calls');
    late final RealtimeChannel channel;
    final controller = StreamController<CallStateEvent>(onCancel: () async {
      await _db.removeChannel(channel);
      if (identical(_channel, channel)) _channel = null;
    });
    channel = _db.channel('call-events-$uid')
      .onBroadcast(event: 'call_state', callback: (payload) {
        if (!controller.isClosed) {
          controller.add(CallStateEvent.fromJson(payload));
        }
      }).subscribe();
    return controller.stream;
  }

  Future<void> dispose() async {
    if (_channel != null) {
      await _db.removeChannel(_channel!);
      _channel = null;
    }
  }
}
