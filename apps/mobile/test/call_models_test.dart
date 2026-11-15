import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_mingle/src/features/calling/call_models.dart';

void main() {
  group('CallSession', () {
    test('parses server session fields and call type', () {
      final session = CallSession.fromJson({
        'id': 'call-1',
        'caller_id': 'user-a',
        'callee_id': 'user-b',
        'call_type': 'video',
        'status': 'ringing',
        'created_at': '2026-11-15T10:00:00Z',
      });
      expect(session.id, 'call-1');
      expect(session.type, CallType.video);
      expect(session.status, CallStatus.ringing);
      expect(session.isTerminal, isFalse);
    });

    test('unknown status fails closed and terminal statuses are recognized', () {
      final session = CallSession.fromJson({
        'id': 'call-2',
        'caller_id': 'user-a',
        'callee_id': 'user-b',
        'call_type': 'audio',
        'status': 'unexpected-server-state',
        'created_at': '2026-11-15T10:00:00Z',
      });
      expect(session.status, CallStatus.failed);
      expect(session.isTerminal, isTrue);
    });
  });

  test('CallStateEvent parses participant-scoped event payload', () {
    final event = CallStateEvent.fromJson({
      'call_id': 'call-3',
      'status': 'connected',
      'actor_id': 'user-b',
      'reason': null,
    });
    expect(event.callId, 'call-3');
    expect(event.status, CallStatus.connected);
    expect(event.actorId, 'user-b');
    expect(event.reason, isNull);
  });
}
