import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_config.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<dynamic> _friends = [];
  bool _loading = true;
  String? _error;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken ?? ''}',
    'Content-Type': 'application/json',
  };

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  @override
  void initState() {
    super.initState();
    loadFriends();
  }

  Future<void> loadFriends() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await http.get(_uri('/v1/friends'), headers: _headers);
      final body = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(body is Map ? (body['error']?['message'] ?? 'Friends unavailable') : 'Friends unavailable');
      }
      final data = body['data'];
      if (!mounted) return;
      setState(() { _friends = data is List ? data : []; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Friends load नहीं हो पाए। API URL और server जाँचें।'; _loading = false; });
    }
  }

  Future<void> _removeFriend(String id) async {
    try {
      final response = await http.delete(_uri('/v1/friends/$id'), headers: _headers);
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception();
      await loadFriends();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unfriend नहीं हो पाया।')));
    }
  }

  Future<void> _block(String id) async {
    try {
      final response = await http.post(_uri('/v1/blocks/$id'), headers: _headers);
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception();
      await loadFriends();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Block नहीं हो पाया।')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Friends')),
    body: _loading ? const Center(child: CircularProgressIndicator())
      : _error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!), const SizedBox(height: 12), FilledButton(onPressed: loadFriends, child: const Text('Retry'))
        ]))
      : _friends.isEmpty ? const Center(child: Text('अभी कोई friend नहीं है।'))
      : RefreshIndicator(onRefresh: loadFriends, child: ListView.builder(
          itemCount: _friends.length,
          itemBuilder: (context, index) {
            final friend = _friends[index] as Map<String, dynamic>;
            final id = friend['friend_id']?.toString() ?? '';
            final name = friend['display_name']?.toString() ?? 'VibeMingle User';
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(name),
              subtitle: const Text('Friend'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'unfriend') await _removeFriend(id);
                  if (value == 'block') await _block(id);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'unfriend', child: Text('Unfriend')),
                  PopupMenuItem(value: 'block', child: Text('Block')),
                ],
              ),
            );
          },
        )),
  );
}
