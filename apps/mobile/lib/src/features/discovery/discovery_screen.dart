import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Public-profile discovery; profile RLS remains the source of visibility truth.
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});
  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final _db = Supabase.instance.client;
  final _query = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  final Set<String> _requested = {};
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final term = _query.text.trim().replaceAll('%', '').replaceAll('_', '');
    if (term.length < 2) {
      setState(() { _error = 'कम से कम 2 अक्षर लिखें।'; _results = []; });
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final uid = _db.auth.currentUser!.id;
      final rows = await _db.from('profiles')
        .select('id,username,display_name,bio,avatar_url')
        .neq('id', uid)
        .or('username.ilike.%$term%,display_name.ilike.%$term%')
        .limit(30);
      if (mounted) setState(() => _results = List<Map<String, dynamic>>.from(rows));
    } catch (e) {
      if (mounted) setState(() => _error = 'Search failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendRequest(String id) async {
    if (_requested.contains(id)) return;
    setState(() => _requested.add(id));
    try {
      final result = await _db.rpc('friend_request', params: {'p_friend': id});
      if (!mounted) return;
      final msg = result == 'accepted' ? 'Friend connection accepted!' : 'Friend request sent.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted) setState(() => _requested.remove(id));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Discover people')),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: TextField(controller: _query, textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: const InputDecoration(labelText: 'Username or name',
            prefixIcon: Icon(Icons.search), border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        IconButton(onPressed: _busy ? null : _search, icon: const Icon(Icons.search)),
      ])),
      if (_busy) const LinearProgressIndicator(),
      if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
      Expanded(child: _results.isEmpty
        ? const Center(child: Text('Public profiles खोजने के लिए search करें।'))
        : ListView.builder(itemCount: _results.length, itemBuilder: (context, i) {
          final p = _results[i];
          final avatar = p['avatar_url']?.toString();
          return ListTile(
            leading: CircleAvatar(backgroundImage: avatar == null || avatar.isEmpty ? null : NetworkImage(avatar),
              child: avatar == null || avatar.isEmpty ? const Icon(Icons.person) : null),
            title: Text((p['display_name'] as String?)?.isNotEmpty == true
              ? p['display_name'] as String : '@${p['username']}'),
            subtitle: Text('@${p['username']} • ${p['bio'] ?? ''}', maxLines: 2,
              overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: Icon(_requested.contains(p['id'].toString()) ? Icons.check_circle : Icons.person_add_alt_1),
              tooltip: _requested.contains(p['id'].toString()) ? 'Request sent' : 'Add friend',
              onPressed: _requested.contains(p['id'].toString()) ? null : () => _sendRequest(p['id'].toString())),
          );
        })),
    ]),
  );
}
