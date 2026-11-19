import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'chat_repository_v2.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final db = Supabase.instance.client;
  bool loading = true;
  List<Map<String, dynamic>> friends = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final uid = db.auth.currentUser!.id;
      final fs = await db
          .from('friendships')
          .select('user_low,user_high')
          .or('user_low.eq.$uid,user_high.eq.$uid');
      final ids = fs
          .map((r) => r['user_low'] == uid ? r['user_high'] : r['user_low'])
          .toList();
      final p = ids.isEmpty
          ? []
          : await db
                .from('profiles')
                .select('id,username,display_name')
                .inFilter('id', ids);
      if (mounted) setState(() => friends = List<Map<String, dynamic>>.from(p));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String name(Map p) {
    final display = (p['display_name'] as String? ?? '').trim();
    return display.isNotEmpty ? display : p['username'] as String? ?? 'Friend';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Private Chats'),
          actions: [
            IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: friends
                    .map((p) => ListTile(
                          title: Text(name(p)),
                          subtitle: Text('@${p['username'] ?? ''}'),
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatThreadScreen(
                                peerId: p['id'] as String,
                                peerName: name(p),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
      );
}

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key, required this.peerId, required this.peerName});

  final String peerId;
  final String peerName;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final repo = ChatRepository();
  final input = TextEditingController();
  final List<Map<String, dynamic>> rows = [];
  StreamSubscription<Map<String, dynamic>>? sub;
  RealtimeChannel? typing;
  Timer? timer;
  bool busy = false;
  bool peerTyping = false;
  final Set<String> acknowledgedMessageIds = {};

  @override
  void initState() {
    super.initState();
    refresh();
    sub = repo.watch(widget.peerId).listen((m) {
      if (mounted) setState(() => upsert(m));
      acknowledgeIncoming(m);
    });
    final uid = Supabase.instance.client.auth.currentUser!.id;
    typing = Supabase.instance.client
        .channel('typing-${repo.pairKey(uid, widget.peerId)}')
        .onBroadcast(
          event: 'typing',
          callback: (p) {
            if (p['user_id'] == widget.peerId && mounted) {
              setState(() => peerTyping = p['typing'] == true);
            }
          },
        )
        .subscribe();
  }

  void acknowledgeIncoming(Map<String, dynamic> message) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final id = message['id']?.toString();
    if (uid == null || id == null || message['sender_id'] == uid ||
        message['deleted_at'] != null || !acknowledgedMessageIds.add(id)) return;
    // Delivery/read receipts are best-effort; message rendering must not wait on RPCs.
    unawaited(repo.delivered(id).catchError((_) {}));
    unawaited(repo.read(id).catchError((_) {}));
  }

  void upsert(Map<String, dynamic> message) {
    final index = rows.indexWhere((x) => x['id'] == message['id']);
    if (index < 0) {
      rows.add(message);
    } else {
      rows[index] = message;
    }
    rows.sort((a, b) =>
        a['created_at'].toString().compareTo(b['created_at'].toString()));
  }

  Future<void> refresh() async {
    try {
      final messages = await repo.messages(widget.peerId);
      if (mounted) setState(() {
        rows
          ..clear()
          ..addAll(messages);
        for (final message in messages) {
          acknowledgeIncoming(message);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void typingChanged(String value) {
    final uid = Supabase.instance.client.auth.currentUser!.id;
    typing?.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': uid, 'typing': value.trim().isNotEmpty},
    );
    timer?.cancel();
    if (value.trim().isNotEmpty) {
      timer = Timer(const Duration(milliseconds: 1200), () {
        typing?.sendBroadcastMessage(
          event: 'typing',
          payload: {'user_id': uid, 'typing': false},
        );
      });
    }
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty || busy) return;
    setState(() => busy = true);
    try {
      final message = await repo.send(widget.peerId, text);
      if (mounted) setState(() => upsert(message));
      input.clear();
      typingChanged('');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    input.dispose();
    sub?.cancel();
    timer?.cancel();
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      unawaited(typing?.sendBroadcastMessage(
        event: 'typing', payload: {'user_id': uid, 'typing': false},
      ));
    }
    if (typing != null) Supabase.instance.client.removeChannel(typing!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = Supabase.instance.client.auth.currentUser!.id;
    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final message = rows[index];
                final mine = message['sender_id'] == uid;
                return Align(
                  alignment:
                      mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: mine
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(message['deleted_at'] != null
                        ? 'Message deleted'
                        : message['body'].toString()),
                  ),
                );
              },
            ),
          ),
          if (peerTyping) const Text('Typing…'),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    onChanged: typingChanged,
                    decoration: const InputDecoration(hintText: 'Message…'),
                  ),
                ),
                IconButton(
                  onPressed: busy ? null : send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
