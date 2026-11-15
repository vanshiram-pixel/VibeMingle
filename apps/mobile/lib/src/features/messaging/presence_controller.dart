import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Minimal friend-presence state. UI must only display it to an authorized
/// conversation participant and must respect the user's privacy preferences.
class FriendPresence {
  const FriendPresence({required this.online, this.lastSeenAt});

  final bool online;
  final DateTime? lastSeenAt;

  factory FriendPresence.fromPayload(Map<String, dynamic> payload) {
    final raw = payload['last_seen_at']?.toString();
    return FriendPresence(
      online: payload['online'] == true,
      lastSeenAt: raw == null ? null : DateTime.tryParse(raw)?.toLocal(),
    );
  }
}

/// Presence channel lifecycle helper for a single signed-in account.
///
/// Call start() only after authentication. Track only the minimum presence
/// fields; do not include device IDs, location, or personal profile data.
/// Server-side Realtime authorization and privacy policy are mandatory.
class PresenceController {
  PresenceController(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;
  StreamController<Map<String, FriendPresence>>? _changes;
  bool _started = false;

  Stream<Map<String, FriendPresence>> get changes {
    _changes ??= StreamController<Map<String, FriendPresence>>.broadcast();
    return _changes!.stream;
  }

  Future<void> start() async {
    if (_started) return;
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Presence requires authentication');

    _changes ??= StreamController<Map<String, FriendPresence>>.broadcast();
    _channel = _client.channel('presence:${user.id}',
      opts: const RealtimeChannelConfig(
        key: 'user_id',
      ),
    );
    _channel!
      .onPresenceSync((_) => _publish())
      .onPresenceJoin((_) => _publish())
      .onPresenceLeave((_) => _publish());
    await _channel!.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _channel!.track({
          'user_id': user.id,
          'online': true,
          'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        });
        _started = true;
      }
    });
  }

  void _publish() {
    final state = _channel?.presenceState() as Map<String, List<Presence>>? ?? <String, List<Presence>>{};
    final result = <String, FriendPresence>{};
    for (final entries in state.values) {
      for (final entry in entries) {
        final payload = Map<String, dynamic>.from(entry.payload);
        final id = payload['user_id']?.toString();
        if (id == null) continue;
        result[id] = FriendPresence.fromPayload(payload);
      }
    }
    if (!(_changes?.isClosed ?? true)) _changes?.add(result);
  }

  /// Call when app enters background or user signs out.
  Future<void> stop() async {
    if (_channel != null) {
      try {
        await _channel!.untrack();
      } catch (_) {
        // Disconnect cleanup is best-effort; server presence TTL is fallback.
      }
      await _client.removeChannel(_channel!);
      _channel = null;
    }
    _started = false;
  }

  Future<void> dispose() async {
    await stop();
    await _changes?.close();
    _changes = null;
  }
}
