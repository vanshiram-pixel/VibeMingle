import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Private one-to-one chat data access. All writes use guarded RPCs.
class ChatRepository {
  ChatRepository(this._client);
  final SupabaseClient _client;

  String conversationKey(String a, String b) =>
      a.compareTo(b) < 0 ? '$a:$b' : '$b:$a';

  Future<List<Map<String, dynamic>>> loadMessages({
    required String conversationId,
    int limit = 40,
    DateTime? before,
  }) async {
    final boundedLimit = limit.clamp(1, 100);
    var query = _client.from('chat_messages').select()
        .eq('conversation_id', conversationId);
    if (before != null) query = query.lt('created_at', before.toUtc().toIso8601String());
    final rows = await query.order('created_at', ascending: false).limit(boundedLimit);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList().reversed.toList();
  }

  Future<Map<String, dynamic>> send({
    required String recipientId,
    required String body,
    required String conversationId,
  }) async {
    final result = await _client.rpc('chat_send', params: {
      'p_recipient_id': recipientId,
      'p_body': body,
      'p_conversation_id': conversationId,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> markDelivered(String messageId) async =>
      _client.rpc('chat_mark_delivered', params: {'p_message_id': messageId});

  Future<void> markRead(String messageId) async =>
      _client.rpc('chat_mark_read', params: {'p_message_id': messageId});

  Future<void> edit(String messageId, String body) async =>
      _client.rpc('chat_edit', params: {'p_message_id': messageId, 'p_body': body});

  Future<void> delete(String messageId) async =>
      _client.rpc('chat_delete', params: {'p_message_id': messageId});

  /// Requires Supabase private-channel authorization to be configured server-side.
  Stream<Map<String, dynamic>> subscribe({
    required String conversationId,
    required String currentUserId,
  }) {
    final controller = StreamController<Map<String, dynamic>>();
    final channel = _client.channel('private-chat:$conversationId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId,
      ),
      callback: (payload) {
        final row = Map<String, dynamic>.from(payload.newRecord);
        if (row['sender_id'] != currentUserId || row['recipient_id'] == currentUserId) {
          controller.add(row);
        }
      },
    );
    unawaited(channel.subscribe());
    controller.onCancel = () async {
      await _client.removeChannel(channel);
    };
    return controller.stream;
  }
}
