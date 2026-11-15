import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'video_call_screen.dart';

/// Friend-only private call request inbox and outgoing requests.
class CallRequestsScreen extends StatefulWidget {
  const CallRequestsScreen({super.key});
  @override
  State<CallRequestsScreen> createState() => _CallRequestsScreenState();
}

class _CallRequestsScreenState extends State<CallRequestsScreen> {
  final _db = Supabase.instance.client;
  bool _busy = false;
  String? _selectedFriend;
  List<Map<String, dynamic>> _friends = [], _incoming = [], _outgoing = [];

  @override
  void initState() { super.initState(); _refresh(); }

  Future<void> _refresh() async {
    try {
      final uid = _db.auth.currentUser!.id;
      final friends = await _db.rpc('friend_list_safe');
      final incoming = await _db.from('call_requests').select('id,caller_id,status,created_at,expires_at').eq('recipient_id', uid).eq('status', 'pending').order('created_at', ascending: false);
      final outgoing = await _db.from('call_requests').select('id,recipient_id,status,created_at,expires_at').eq('caller_id', uid).order('created_at', ascending: false).limit(30);
      if (mounted) setState(() {
        _friends = List<Map<String, dynamic>>.from(friends);
        if (_selectedFriend == null || !_friends.any((f) => f['friend_id'].toString() == _selectedFriend)) _selectedFriend = _friends.isEmpty ? null : _friends.first['friend_id'].toString();
        _incoming = List<Map<String, dynamic>>.from(incoming);
        _outgoing = List<Map<String, dynamic>>.from(outgoing);
      });
    } catch (e) { if (mounted) _notice('Requests load नहीं हुए: $e'); }
  }

  void _notice(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _sendRequest() async {
    final peer = _selectedFriend;
    if (peer == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _db.rpc('call_request_create', params: {'p_recipient': peer});
      _notice('Call request भेज दी गई।'); await _refresh();
    } catch (e) { _notice('Request नहीं भेजी: $e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _respond(String id, bool accept) async {
    setState(() => _busy = true);
    try {
      final result = await _db.rpc('call_request_respond', params: {'p_request': id, 'p_accept': accept});
      if (accept) {
        final row = (result as List).first as Map<String, dynamic>;
        final session = row['session_id']?.toString();
        if (session != null && mounted) await Navigator.push(context, MaterialPageRoute(builder: (_) => VideoCallScreen(sessionId: session)));
      } else { _notice('Call request decline कर दी।'); }
      await _refresh();
    } catch (e) { _notice('Action नहीं हुई: $e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _cancel(String id) async {
    try { await _db.rpc('call_request_cancel', params: {'p_request': id}); await _refresh(); }
    catch (e) { _notice('Request cancel नहीं हुई: $e'); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Private Calls & Requests'), actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh), tooltip: 'Refresh')]),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Start a private call', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _selectedFriend,
        decoration: const InputDecoration(labelText: 'Choose a friend', border: OutlineInputBorder()),
        items: _friends.map((f) => DropdownMenuItem<String>(value: f['friend_id'].toString(), child: Text((f['display_name'] ?? 'Friend').toString()))).toList(),
        onChanged: _busy ? null : (v) => setState(() => _selectedFriend = v),
      ),
      const SizedBox(height: 8),
      FilledButton.icon(onPressed: _busy || _selectedFriend == null ? null : _sendRequest, icon: const Icon(Icons.video_call), label: const Text('Send call request')),
      const SizedBox(height: 24),
      const Text('Incoming requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      if (_incoming.isEmpty) const ListTile(title: Text('कोई incoming request नहीं।')),
      ..._incoming.map((r) => Card(child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.call_received)),
        title: Text('From ${r['caller_id'].toString().substring(0,8)}…'),
        subtitle: const Text('Expires shortly • Accept only if you know this person'),
        trailing: Wrap(children: [
          IconButton(onPressed: _busy ? null : () => _respond(r['id'].toString(), false), icon: const Icon(Icons.close), tooltip: 'Decline'),
          IconButton(onPressed: _busy ? null : () => _respond(r['id'].toString(), true), icon: const Icon(Icons.call), tooltip: 'Accept'),
        ]),
      ))),
      const SizedBox(height: 24),
      const Text('Outgoing requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      if (_outgoing.isEmpty) const ListTile(title: Text('कोई outgoing request नहीं।')),
      ..._outgoing.map((r) => ListTile(
        leading: const Icon(Icons.call_made),
        title: Text('To ${r['recipient_id'].toString().substring(0,8)}…'),
        subtitle: Text('Status: ${r['status']}'),
        trailing: r['status']=='pending' ? IconButton(onPressed: () => _cancel(r['id'].toString()), icon: const Icon(Icons.cancel_outlined), tooltip: 'Cancel request') : null,
      )),
    ]),
  );
}
