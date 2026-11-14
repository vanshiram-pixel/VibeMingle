import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_config.dart';

class PresenceSettingsScreen extends StatefulWidget {
  const PresenceSettingsScreen({super.key});
  @override
  State<PresenceSettingsScreen> createState() => _PresenceSettingsScreenState();
}

class _PresenceSettingsScreenState extends State<PresenceSettingsScreen> {
  String _visibility = 'friends';
  bool _showOnline = true;
  bool _saving = false;
  String? _message;

  Future<void> _save() async {
    setState(() { _saving = true; _message = null; });
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      final response = await http.patch(
        Uri.parse('${AppConfig.apiBaseUrl}/v1/presence/settings'),
        headers: {'Authorization': 'Bearer ${token ?? ''}', 'Content-Type': 'application/json'},
        body: jsonEncode({'visibility': _visibility, 'showOnline': _showOnline}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception();
      if (mounted) setState(() => _message = 'Privacy settings saved.');
    } catch (_) {
      if (mounted) setState(() => _message = 'Save नहीं हुआ। API और server जाँचें।');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Presence Privacy')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('कौन आपकी online presence देख सकता है?'),
      const SizedBox(height: 8),
      RadioListTile<String>(value: 'everyone', groupValue: _visibility, title: const Text('Everyone'), onChanged: (v) => setState(() => _visibility = v!)),
      RadioListTile<String>(value: 'friends', groupValue: _visibility, title: const Text('Friends only'), onChanged: (v) => setState(() => _visibility = v!)),
      RadioListTile<String>(value: 'nobody', groupValue: _visibility, title: const Text('Nobody'), onChanged: (v) => setState(() => _visibility = v!)),
      SwitchListTile(value: _showOnline, title: const Text('Show online status'), onChanged: (v) => setState(() => _showOnline = v)),
      const SizedBox(height: 16),
      FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save settings')),
      if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!)),
      const SizedBox(height: 12),
      const Text('नोट: ये preference server पर save होती है। वास्तविक realtime online/offline visibility engine अभी अलग implementation चरण में है.', style: TextStyle(color: Colors.grey)),
    ]),
  );
}
