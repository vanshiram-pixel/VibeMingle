import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});
  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final _db = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final uid = _db.auth.currentUser!.id;
    final rows = await _db.from('conversation_members')
        .select('conversation_id,last_read_at,conversations(id,user_a,user_b,updated_at)')
        .eq('user_id', uid).order('last_read_at', ascending: false);
    final items = List<Map<String, dynamic>>.from(rows);
    items.sort((a, b) {
      final ca = a['conversations'] as Map<String, dynamic>?;
      final cb = b['conversations'] as Map<String, dynamic>?;
      final ta = DateTime.tryParse(ca?['updated_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = DateTime.tryParse(cb?['updated_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });
    return items;
  }

  Future<void> _openFriend() async {
    final ctrl = TextEditingController();
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Open friend chat'),
        content: TextField(controller: ctrl,
          decoration: const InputDecoration(labelText: 'Friend user ID (UUID)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Open')),
        ],
      ),
    );
    ctrl.dispose();
    if (id == null || id.isEmpty) return;
    try {
      final conversation = await _db.rpc('conversation_open', params: {'p_friend': id});
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => ConversationScreen(conversationId: conversation.toString())));
      if (mounted) setState(() => _future = _load());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat नहीं खुला: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages'), actions: [
        IconButton(onPressed: _openFriend, icon: const Icon(Icons.add_comment),
          tooltip: 'New chat')
      ]),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Messages load नहीं हुए: ${snapshot.error}'));
          final rows = snapshot.data ?? [];
          if (rows.isEmpty)
            return const Center(child: Text('अभी कोई chat नहीं। + से friend chat खोलें।'));
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final conv = rows[index]['conversations'] as Map<String, dynamic>?;
              final uid = _db.auth.currentUser!.id;
              final peer = conv == null ? 'Friend' :
                (conv['user_a'] == uid ? conv['user_b'] : conv['user_a']);
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text('Friend • ${peer.toString().substring(0, 8)}…'),
                subtitle: const Text('Private conversation'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ConversationScreen(
                      conversationId: rows[index]['conversation_id'].toString())));
                  if (mounted) setState(() => _future = _load());
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.conversationId});
  final String conversationId;
  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _db = Supabase.instance.client;
  final _input = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true, _sending = false;
  DateTime? _peerReadAt;
  bool _searchOpen = false;
  Map<String, dynamic>? _replyTo;
  final _search = TextEditingController();
  RealtimeChannel? _channel;
  RealtimeChannel? _typingChannel;
  Timer? _typingTimer;
  bool _peerTyping = false;
  final _picker = ImagePicker();
  final Map<String, String> _attachmentUrls = {};

  @override
  void initState() {
    super.initState();
    _load();
    _channel = _db.channel('messages-${widget.conversationId}')
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq,
          column: 'conversation_id', value: widget.conversationId),
        callback: (_) => _load()).subscribe();
    final uid = _db.auth.currentUser!.id;
    _typingChannel = _db.channel('typing-${widget.conversationId}')
      .onBroadcast(event: 'typing', callback: (payload) {
        if (!mounted || payload['user_id'] == uid) return;
        setState(() => _peerTyping = payload['typing'] == true);
      }).subscribe();
  }

  Future<void> _load() async {
    try {
      final rows = await _db.from('messages')
        .select('id,sender_id,body,created_at,edited_at,deleted_at,reply_to_message:messages!messages_reply_to_message_fkey(id,body,sender_id),message_reactions(user_id,emoji)')
        .eq('conversation_id', widget.conversationId).order('created_at');
      final uid = _db.auth.currentUser!.id;
      final member = await _db.from('conversation_members').select('user_id,last_read_at')
        .eq('conversation_id', widget.conversationId).neq('user_id', uid).maybeSingle();
      if (mounted) setState(() {
        _messages = List<Map<String, dynamic>>.from(rows);
        _attachmentUrls.clear();
        _peerReadAt = DateTime.tryParse(member?['last_read_at']?.toString() ?? '');
      });
      for (final row in rows) {\n        final attachments = List<Map<String, dynamic>>.from(row['message_attachments'] ?? []);\n        for (final a in attachments) {\n          try { _attachmentUrls[a['id'].toString()] = await _db.storage.from('chat-media').createSignedUrl(a['storage_path'].toString(), 3600); } catch (_) {}\n        }\n      }\n      if (mounted) setState(() {});\n      await _db.rpc('conversation_mark_read', params: {'p_conversation': widget.conversationId});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Messages load error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleReaction(String messageId, String emoji) async {
    final uid = _db.auth.currentUser!.id;
    try {
      final existing = await _db.from('message_reactions').select('message_id')
        .eq('message_id', messageId).eq('user_id', uid).eq('emoji', emoji).maybeSingle();
      if (existing != null) {
        await _db.from('message_reactions').delete().eq('message_id', messageId).eq('user_id', uid).eq('emoji', emoji);
      } else {
        await _db.from('message_reactions').insert({'message_id': messageId, 'user_id': uid, 'emoji': emoji});
      }
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reaction नहीं लगी: $e')));
    }
  }

  Future<void> _pickReaction(String messageId) async {
    const choices = ['👍','❤️','😂','😮','😢','🙏','🔥','🎉'];
    final emoji = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          spacing: 12,
          children: choices.map((e) => TextButton(
            onPressed: () => Navigator.pop(ctx, e),
            child: Text(e, style: const TextStyle(fontSize: 26)),
          )).toList(),
        ),
      ),
    );
    if (emoji != null) await _toggleReaction(messageId, emoji);
  }

  Future<void> _showEmojiPicker() async {
    const emojis = ['😀','😂','🥰','😍','😊','👍','❤️','🔥','🎉','🙏','😎','🤔','😭','🤣','🙌','💯'];
    final emoji = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: emojis.map<Widget>((e) => InkWell(
              onTap: () => Navigator.pop(ctx, e),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(e, style: const TextStyle(fontSize: 28)),
              ),
            )).toList(),
          ),
        ),
      ),
    );
    if (emoji == null) return;
    final text = _input.text;
    final selection = _input.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    _input.value = TextEditingValue(
      text: text.replaceRange(start, end, emoji),
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  Future<void> _pickAndSendMedia(bool video) async {\n    if (_sending) return;\n    final picked = video ? await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 2)) : await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);\n    if (picked == null) return;\n    final file = File(picked.path);\n    final size = await file.length();\n    if (size > 25 * 1024 * 1024) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File 25 MB से छोटा होना चाहिए'))); return; }\n    setState(() => _sending = true);\n    try {\n      final uid = _db.auth.currentUser!.id;\n      final mime = video ? (picked.mimeType ?? 'video/mp4') : (picked.mimeType ?? 'image/jpeg');\n      final safeName = picked.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');\n      final path = '${widget.conversationId}/$uid/${DateTime.now().millisecondsSinceEpoch}_$safeName';\n      await _db.storage.from('chat-media').upload(path, file, fileOptions: FileOptions(contentType: mime, upsert: false));\n      final message = await _db.rpc('message_send', params: {'p_conversation': widget.conversationId, 'p_body': video ? '🎥 Video' : '📷 Photo'});\n      await _db.from('message_attachments').insert({'message_id': message['id'], 'conversation_id': widget.conversationId, 'uploader_id': uid, 'storage_path': path, 'file_name': picked.name, 'mime_type': mime, 'byte_size': size, 'media_kind': video ? 'video' : 'image'});\n      await _load();\n    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Media upload नहीं हुआ: $e'))); }\n    finally { if (mounted) setState(() => _sending = false); }\n  }\n\n  void _broadcastTyping(String text) {
    final channel = _typingChannel;
    if (channel == null) return;
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    channel.sendBroadcastMessage(event: 'typing', payload: {'user_id': uid, 'typing': text.trim().isNotEmpty});
    _typingTimer?.cancel();
    if (text.trim().isNotEmpty) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        channel.sendBroadcastMessage(event: 'typing', payload: {'user_id': uid, 'typing': false});
      });
    }
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _db.rpc('message_send', params: {
        'p_conversation': widget.conversationId, 'p_body': body, 'p_reply_to': _replyTo?['id']});
      _input.clear();
      _broadcastTyping('');
      if (mounted) setState(() => _replyTo = null);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message नहीं भेजा: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _edit(String id, String current) async {
    final ctrl = TextEditingController(text: current);
    final edited = await showDialog<String>(context: context, builder: (ctx) =>
      AlertDialog(title: const Text('Edit message'), content: TextField(
        controller: ctrl, autofocus: true, maxLines: 4, maxLength: 4000),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save')),
        ]));
    ctrl.dispose();
    if (edited == null || edited.isEmpty || edited == current) return;
    try {
      await _db.rpc('message_edit', params: {'p_message': id, 'p_body': edited});
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Edit failed: $e')));
    }
  }

  Future<void> _messageActions(Map<String, dynamic> message, bool mine) async {
    final id = message['id'].toString();
    if (!mine) {
      final choice = await showModalBottomSheet<String>(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.reply), title: const Text('Reply'), onTap: () => Navigator.pop(ctx, 'reply')),
        ListTile(leading: const Icon(Icons.flag), title: const Text('Report'), onTap: () => Navigator.pop(ctx, 'report')),
      ])));
      if (choice == 'reply' && mounted) setState(() => _replyTo = message);
      if (choice == 'report') await _report(id);
      return;
    }
    final action = await showModalBottomSheet<String>(context: context, builder: (ctx) =>
      SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.reply), title: const Text('Reply'), onTap: () => Navigator.pop(ctx, 'reply')),
        ListTile(leading: const Icon(Icons.edit), title: const Text('Edit message'),
          onTap: () => Navigator.pop(ctx, 'edit')),
        ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Delete message'),
          onTap: () => Navigator.pop(ctx, 'delete')),
      ])));
    if (action == 'reply' && mounted) setState(() => _replyTo = message);
    if (action == 'edit') await _edit(id, message['body'].toString());
    if (action == 'delete') await _delete(id);
  }

  Future<void> _delete(String id) async {
    try {
      await _db.rpc('message_delete', params: {'p_message': id});
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _report(String id) async {
    const categories = <String, String>{
      'harassment': 'Harassment',
      'sexual_content': 'Sexual content',
      'minor_safety': 'Minor safety',
      'spam': 'Spam',
      'hate': 'Hate',
      'violence': 'Violence',
      'impersonation': 'Impersonation',
      'scam': 'Scam',
      'other': 'Other',
    };
    final category = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Report message'),
            subtitle: Text('कारण चुनें')),
          ...categories.entries.map((entry) => ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(entry.value),
            onTap: () => Navigator.pop(ctx, entry.key))),
        const SizedBox(height: 12),
        ],
      )),
    );
    if (category == null) return;
    try {
      await _db.rpc('message_report', params: {
        'p_message': id, 'p_category': category, 'p_description': ''});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted. धन्यवाद।')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report नहीं भेजी गई: $e')));
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _typingChannel?.sendBroadcastMessage(event: 'typing', payload: {'user_id': _db.auth.currentUser?.id, 'typing': false});
    _typingChannel?.unsubscribe();
    _input.dispose();
    _search.dispose();
    if (_channel != null) _db.removeChannel(_channel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _db.auth.currentUser!.id;
    return Scaffold(
      appBar: AppBar(title: _searchOpen ? TextField(controller: _search, autofocus: true, decoration: const InputDecoration(hintText: 'Search messages', border: InputBorder.none), onChanged: (_) => setState(() {})) : const Text('Private chat'), actions: [IconButton(icon: Icon(_searchOpen ? Icons.close : Icons.search), onPressed: () => setState(() { _searchOpen = !_searchOpen; if (!_searchOpen) _search.clear(); }), tooltip: 'Search messages')]),
      body: Column(children: [
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) :
          ListView.builder(
            padding: const EdgeInsets.all(12), itemCount: _messages.where((m) => _search.text.trim().isEmpty || m['body'].toString().toLowerCase().contains(_search.text.trim().toLowerCase())).length,
            itemBuilder: (context, index) {
              final visible = _messages.where((m) => _search.text.trim().isEmpty || m['body'].toString().toLowerCase().contains(_search.text.trim().toLowerCase())).toList();
              final message = visible[index];
              final mine = message['sender_id'] == uid;
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: GestureDetector(
                  onLongPress: message['deleted_at'] != null ? null :
                    () => _messageActions(message, mine),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: mine ? Theme.of(context).colorScheme.primaryContainer :
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min, children: [
                        if (message['reply_to_message'] is Map) Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: .35),
                            borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            "↪ ${(message['reply_to_message'] as Map)['body'] ?? 'Reply'}",
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                        ),
                        if (message['message_attachments'] is List && (message['message_attachments'] as List).isNotEmpty) ...((message['message_attachments'] as List).map((raw) { final a = Map<String,dynamic>.from(raw as Map); final url = _attachmentUrls[a['id'].toString()]; return Padding(padding: const EdgeInsets.only(bottom: 5), child: url == null ? const Text('Attachment loading…') : a['media_kind']=='image' ? Image.network(url, width: 220, fit: BoxFit.cover) : InkWell(onTap: () {}, child: Row(children: [const Icon(Icons.play_circle), Flexible(child: Text(a['file_name'].toString()))]))); })),\n                        Text(message['deleted_at'] != null ? 'Message deleted' :
                          message['body'].toString()),
                        if (message['deleted_at'] == null) ...[
                          const SizedBox(height: 5),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            ...(() {
                              final reactions = List<Map<String, dynamic>>.from(message['message_reactions'] ?? []);
                              final counts = <String, int>{};
                              for (final r in reactions) { final e = r['emoji'].toString(); counts[e] = (counts[e] ?? 0) + 1; }
                              return counts.entries.map((e) => Padding(padding: const EdgeInsets.only(right: 3),
                                child: InkWell(onTap: () => _toggleReaction(message['id'].toString(), e.key),
                                  child: Chip(label: Text('${e.key} ${e.value}', style: const TextStyle(fontSize: 11)),
                                    visualDensity: VisualDensity.compact, padding: EdgeInsets.zero))));
                            })(),
                            InkWell(onTap: () => _pickReaction(message['id'].toString()),
                              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.add_reaction_outlined, size: 17))),
                          ]),
                        ],
                        const SizedBox(height: 3),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          if (message['edited_at'] != null && message['deleted_at'] == null)
                            const Text('edited · ', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                          Text(DateTime.tryParse(message['created_at'].toString())?.toLocal().toString().substring(11, 16) ?? '',
                            style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          if (mine) Padding(padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              _peerReadAt != null && _peerReadAt!.isAfter(DateTime.tryParse(message['created_at'].toString()) ?? DateTime.fromMillisecondsSinceEpoch(0))
                                ? Icons.done_all : Icons.done,
                              size: 13, color: _peerReadAt != null && _peerReadAt!.isAfter(DateTime.tryParse(message['created_at'].toString()) ?? DateTime.fromMillisecondsSinceEpoch(0))
                                ? Theme.of(context).colorScheme.primary : null)),
                        ]),
                      ]),
                  ),
                ),
              );
            },
          )),
        if (_replyTo != null) ListTile(dense: true, leading: const Icon(Icons.reply), title: Text('Replying: ${_replyTo!['body']}', maxLines: 1, overflow: TextOverflow.ellipsis), trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _replyTo = null))),
        if (_peerTyping) const Padding(padding: EdgeInsets.only(left: 16, bottom: 4), child: Text('Friend is typing…', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic))),
        SafeArea(child: Padding(padding: const EdgeInsets.all(8),
          child: Row(children: [
            IconButton(onPressed: () => _pickAndSendMedia(false), tooltip: 'Photo', icon: const Icon(Icons.image)),\n            IconButton(onPressed: () => _pickAndSendMedia(true), tooltip: 'Video', icon: const Icon(Icons.video_library)),\n            IconButton(onPressed: _showEmojiPicker, tooltip: 'Emoji',
              icon: const Icon(Icons.emoji_emotions_outlined)),
            Expanded(child: TextField(controller: _input, onChanged: _broadcastTyping, minLines: 1, maxLines: 4,
              decoration: const InputDecoration(hintText: 'Message',
                border: OutlineInputBorder()))),
            IconButton(onPressed: _sending ? null : _send,
              icon: _sending ? const CircularProgressIndicator() : const Icon(Icons.send)),
          ]),
        )),
      ]),
    );
  }
}
