import 'package:supabase_flutter/supabase_flutter.dart';

/// Presence RPC access. UI/app lifecycle should call setState/heartbeat and
/// stop heartbeat on background; never expose presence to non-friends.
class PresenceRepository {
  PresenceRepository(this._client);
  final SupabaseClient _client;

  Future<void> setState(String state) async {
    if (!const {'online', 'away', 'offline'}.contains(state)) {
      throw ArgumentError.value(state, 'state');
    }
    await _client.rpc('presence_set', params: {'p_state': state});
  }

  Future<void> heartbeat() async {
    await _client.rpc('presence_heartbeat');
  }

  Future<Map<String, String>> friendsPresence(Set<String> friendIds) async {
    if (friendIds.isEmpty) return const {};
    final rows = await _client
        .from('user_presence')
        .select('user_id,state')
        .inFilter('user_id', friendIds.toList());
    return {
      for (final row in rows)
        row['user_id'] as String: row['state'] as String,
    };
  }
}
