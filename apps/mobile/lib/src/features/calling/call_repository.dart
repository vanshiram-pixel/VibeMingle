import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'call_models.dart';

/// Thin authenticated call-session API. Server RPCs must enforce participant,
/// friendship/block policy and state transitions (never trust client status).
class CallRepository {
  CallRepository(this._db);

  final SupabaseClient _db;
  RealtimeChannel? _channel;

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

  Future<CallSession> transition({
    required String callId,
    required String action,
  }) async {
    final row = await _db.rpc('call_transition', params: {
      'p_call_id': callId,
      'p_action': action,
    });
    return CallSession.fromJson(Map<String, dynamic>.from(row as Map));
  }

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

  /// Subscribe to server-authorized call events for this user.
  /// Realtime RLS/channel authorization must restrict events to participants.
  Stream<CallStateEvent> eventsForUser() {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw StateError('Sign in before listening for calls');
    final controller = StreamController<CallStateEvent>();
    _channel = _db.channel('call-events-$uid')
      .onBroadcast(event: 'call_state', callback: (payload) {
        if (!controller.isClosed) {
          controller.add(CallStateEvent.fromJson(payload));
        }
      }).subscribe();
    controller.onCancel = () async {
      if (_channel != null) {
        await _db.removeChannel(_channel!);
        _channel = null;
      }
    };
    return controller.stream;
  }

  Future<void> dispose() async {
    if (_channel != null) {
      await _db.removeChannel(_channel!);
      _channel = null;
    }
  }
}
