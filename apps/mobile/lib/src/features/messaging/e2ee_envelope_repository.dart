import 'package:supabase_flutter/supabase_flutter.dart';

/// Transport for V4.1 encrypted envelopes only.
///
/// Callers must encrypt locally with the selected audited protocol before
/// invoking send(). This class intentionally has no plaintext/body argument.
class E2eeEnvelopeRepository {
  E2eeEnvelopeRepository(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>> send({
    required String recipientId,
    required String clientMessageId,
    required String ciphertext,
    required String protocolVersion,
    required int keyEpoch,
  }) async {
    if (ciphertext.length < 16 || ciphertext.length > 65536) {
      throw ArgumentError.value(ciphertext.length, 'ciphertext.length');
    }
    final result = await _client.rpc('chat_send_e2ee', params: {
      'p_recipient_id': recipientId,
      'p_client_message_id': clientMessageId,
      'p_ciphertext': ciphertext,
      'p_protocol_version': protocolVersion,
      'p_key_epoch': keyEpoch,
    });
    if (result is! Map) {
      throw StateError('Unexpected encrypted-envelope RPC response');
    }
    return Map<String, dynamic>.from(result);
  }

  Future<bool> markDelivered(String messageId) async {
    final result = await _client.rpc(
      'chat_e2ee_mark_delivered',
      params: {'p_message_id': messageId},
    );
    return result == true;
  }

  Future<bool> markRead(String messageId) async {
    final result = await _client.rpc(
      'chat_e2ee_mark_read',
      params: {'p_message_id': messageId},
    );
    return result == true;
  }

  /// Explicit guard: do not call the legacy plaintext RPC from this path.
  Never rejectPlaintextSend() => throw StateError(
        'Plaintext chat send is not permitted by E2EE envelope repository.',
      );
}
