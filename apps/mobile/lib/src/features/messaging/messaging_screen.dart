import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../discovery/discovery_screen.dart';
import '../friends/friends_screen.dart';
import '../profile/profile_screen.dart';\nimport '../matching/matching_screen.dart';

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
    final id = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Open friend chat'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Friend user ID (UUID)')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Open')),
      ],
    ));
    ctrl.dispose();
    if (id == null || id.isEmpty) return;
    try {
      final conversation = await _db.rpc('conversation_open', params: {'p_friend': id});
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) =>
        ConversationScreen(conversationId: conversation.toString())));
      if (mounted) setState(() => _future = _load());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chat नहीं खुला: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Messages'), actions: [\n      IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchingScreen())),\n        icon: const Icon(Icons.travel_explore), tooltip: 'Meet someone');
      IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiscoveryScreen())),
        icon: const Icon(Icons.explore_outlined), tooltip: 'Discover'),
      IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
        icon: const Icon(Icons.account_circle), tooltip: 'My profile'),
      IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen())),
        icon: const Icon(Icons.people_alt), tooltip: 'Friends & requests'),
      IconButton(onPressed: _openFriend, icon: const Icon(Icons.add_comment), tooltip: 'New chat')
    ]),
    body: FutureBuilder<List<Map<String, dynamic>>>(future: _future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Text('Messages load नहीं हुए: ${snapshot.error}'));
      final rows = snapshot.data ?? [];
      if (rows.isEmpty) return const Center(child: Text('अभी कोई chat नहीं। Discover से friend बनाएं।'));
      return ListView.builder(itemCount: rows.length, itemBuilder: (context, index) {
        final conv = rows[index]['conversations'] as Map<String, dynamic>?;
        final uid = _db.auth.currentUser!.id;
        final peer = conv == null ? 'Friend' : (conv['user_a'] == uid ? conv['user_b'] : conv['user_a']);
        return ListTile(leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text('Friend • ${peer.toString().substring(0, 8)}…'),
          subtitle: const Text('Private conversation'), trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) =>
              ConversationScreen(conversationId: rows[index]['conversation_id'].toString())));
            if (mounted) setState(() => _future = _load());
          });
      });
    }),
  );
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
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _channel = _db.channel('messages-${widget.conversationId}')
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'messages',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'conversation_id', value: widget.conversationId),
        callback: (_) => _load()).subscribe();
  }

  Future<void> _load() async {
    try {
      final rows = await _db.from('messages').select('id,sender_id,body,created_at,edited_at,deleted_at')
        .eq('conversation_id', widget.conversationId).order('created_at');
      if (mounted) setState(() { _messages = List<Map<String, dynamic>>.from(rows); _loading = false; });
      await _db.rpc('conversation_mark_read', params: {'p_conversation': widget.conversationId});
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _editMessage(Map<String, dynamic> message) async {
    final controller = TextEditingController(text: message['body']?.toString() ?? '');
    final body = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Edit message'),
      content: TextField(controller: controller, autofocus: true, maxLines: 5, minLines: 1),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
      ],
    ));
    controller.dispose();
    if (body == null || body.isEmpty || body == message['body']) return;
    try {
      await _db.rpc('message_edit', params: {'p_message': message['id'], 'p_body': body});
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit failed: $e')));
    }
  }

  Future<void> _deleteMessage(Map<String, dynamic> message) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete message?'),
      content: const Text('यह message हटाया जाएगा।'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
      ],
    ));
    if (yes != true) return;
    try {
      await _db.rpc('message_delete', params: {'p_message': message['id']});
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _reportMessage(Map<String, dynamic> message) async {
    const categories = ['harassment', 'sexual_content', 'spam', 'hate', 'violence', 'scam', 'other'];
    final category = await showDialog<String>(context: context, builder: (ctx) => SimpleDialog(
      title: const Text('Report message'),
      children: categories.map((c) => SimpleDialogOption(
        onPressed: () => Navigator.pop(ctx, c), child: Text(c.replaceAll('_', ' ')))).toList(),
    ));
    if (category == null) return;
    try {
      await _db.rpc('message_report', params: {'p_message': message['id'], 'p_category': category, 'p_description': ''});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report failed: $e')));
    }
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _db.rpc('message_send', params: {'p_conversation': widget.conversationId, 'p_body': body});
      _input.clear();
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message नहीं भेजा: $e')));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  @override
  void dispose() {
    _input.dispose();
    if (_channel != null) _db.removeChannel(_channel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Private chat')),
    body: Column(children: [
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) :
        ListView.builder(itemCount: _messages.length, itemBuilder: (context, i) {
          final m = _messages[i];
          final mine = m['sender_id'] == _db.auth.currentUser!.id;
          final deleted = m['deleted_at'] != null;
          return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(margin: const EdgeInsets.all(6), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(color: mine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(deleted ? 'Message deleted' : m['body'].toString()),
                  if (!deleted && m['edited_at'] != null)
                    Text('edited', style: Theme.of(context).textTheme.labelSmall),
                ])),
                if (!deleted) PopupMenuButton<String>(
                  tooltip: 'Message actions', iconSize: 18, padding: EdgeInsets.zero,
                  onSelected: (action) {
                    if (action == 'edit') _editMessage(m);
                    if (action == 'delete') _deleteMessage(m);
                    if (action == 'report') _reportMessage(m);
                  },
                  itemBuilder: (_) => [
                    if (mine) const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (mine) const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    if (!mine) const PopupMenuItem(value: 'report', child: Text('Report')),
                  ],
                ),
              ]),
            ));
        })),
      SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
        Expanded(child: TextField(controller: _input, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(),
          decoration: const InputDecoration(hintText: 'Message…', border: OutlineInputBorder()))),
        IconButton(onPressed: _sending ? null : _send, icon: const Icon(Icons.send))
      ])))
    ]),
  );
}
