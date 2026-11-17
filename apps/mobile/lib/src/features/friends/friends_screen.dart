import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Friends/request UI backed by the friendship RLS policies and RPCs.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _db = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _future;
  bool _busy = false;

  String get _uid => _db.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await _db.from('friendships').select('user_low,user_high,requested_by,status,created_at')
      .or('user_low.eq.$_uid,user_high.eq.$_uid').order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  String _peer(Map<String, dynamic> row) =>
      row['user_low'] == _uid ? row['user_high'].toString() : row['user_low'].toString();

  Future<void> _request() async {
    final ctrl = TextEditingController();
    final peer = await showDialog<String>(context: context, builder: (ctx) =>
      AlertDialog(title: const Text('Friend request'),
        content: TextField(controller: ctrl, autofocus: true,
          decoration: const InputDecoration(labelText: 'User ID (UUID)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Send')),
        ]));
    ctrl.dispose();
    if (peer == null || peer.isEmpty || peer == _uid) return;
    await _run(() => _db.rpc('friend_request', params: {'p_friend': peer}),
      'Friend request भेज दी।');
  }

  Future<void> _accept(String peer) async => _run(
    () => _db.rpc('friend_accept', params: {'p_friend': peer}),
    'Friend request स्वीकार हुई।');

  Future<void> _reject(String peer) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) =>
      AlertDialog(title: const Text('Reject request?'),
        content: const Text('यह friend request हट जाएगी।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reject')),
        ]));
    if (yes == true) await _run(
      () => _db.rpc('friend_remove', params: {'p_friend': peer}),
      'Friend request अस्वीकार की गई।');
  }

  Future<void> _call(String peer, String type) async => _run(
    () => _db.rpc('call_request_create', params: {'p_callee': peer, 'p_type': type}),
    type == 'video' ? 'Video call request भेजी।' : 'Audio call request भेजी।');

  Future<void> _remove(String peer) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) =>
      AlertDialog(title: const Text('Remove friend?'),
        content: const Text('यह connection हट जाएगा।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ]));
    if (yes == true) await _run(() => _db.rpc('friend_remove', params: {'p_friend': peer}),
      'Friend हटाया गया।');
  }

  Future<void> _run(Future<dynamic> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      setState(() => _future = _load());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('काम नहीं हुआ: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Friends & Requests'), actions: [
      IconButton(onPressed: _busy ? null : _request, icon: const Icon(Icons.person_add_alt_1),
        tooltip: 'Add friend'),
      IconButton(onPressed: _busy ? null : () => setState(() => _future = _load()),
        icon: const Icon(Icons.refresh)),
    ]),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('Friends load नहीं हुए: ${snapshot.error}'));
        final rows = snapshot.data ?? [];
        final incoming = rows.where((r) => r['status'] == 'pending' && r['requested_by'] != _uid).toList();
        final accepted = rows.where((r) => r['status'] == 'accepted').toList();
        if (rows.isEmpty) return const Center(child: Text('अभी कोई friend या request नहीं। + से request भेजें।'));
        return ListView(
          children: [
            if (incoming.isNotEmpty) const ListTile(title: Text('Incoming requests')),
            ...incoming.map((r) {
              final peer = _peer(r);
              return ListTile(leading: const CircleAvatar(child: Icon(Icons.person_add)),
                title: Text('Request • ${peer.substring(0, 8)}…'),
                subtitle: const Text('Pending'),
                trailing: Wrap(spacing: 6, children: [
                  FilledButton(onPressed: _busy ? null : () => _accept(peer),
                    child: const Text('Accept')),
                  IconButton(onPressed: _busy ? null : () => _reject(peer),
                    tooltip: 'Reject request', icon: const Icon(Icons.close)),
                ]));
            }),
            if (accepted.isNotEmpty) const ListTile(title: Text('Friends')),
            ...accepted.map((r) {
              final peer = _peer(r);
              return ListTile(leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text('Friend • ${peer.substring(0, 8)}…'),
                subtitle: const Text('Connected'),
                trailing: PopupMenuButton<String>(
                  enabled: !_busy,
                  tooltip: 'Friend actions',
                  onSelected: (action) {
                    if (action == 'audio') _call(peer, 'audio');
                    if (action == 'video') _call(peer, 'video');
                    if (action == 'remove') _remove(peer);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'audio', child: Text('Audio call')),
                    PopupMenuItem(value: 'video', child: Text('Video call')),
                    PopupMenuItem(value: 'remove', child: Text('Remove friend')),
                  ],
                ));
            }),
            if (rows.any((r) => r['status'] == 'pending' && r['requested_by'] == _uid))
              const ListTile(title: Text('Outgoing requests'), subtitle: Text('आपकी भेजी हुई requests pending हैं।')),
          ],
        );
      },
    ),
  );
}
