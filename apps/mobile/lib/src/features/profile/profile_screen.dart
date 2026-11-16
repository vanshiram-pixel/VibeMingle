import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _bio = TextEditingController();
  String _visibility = 'private';
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _notice;

  SupabaseClient get _db => Supabase.instance.client;
  User? get _user => _db.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; _notice = null; });
    try {
      final user = _user;
      if (user == null) throw Exception('Please sign in again.');
      final row = await _db.from('profiles').select(
        'username,display_name,bio,visibility',
      ).eq('id', user.id).maybeSingle();
      if (row != null) {
        _username.text = row['username'] as String? ?? '';
        _displayName.text = row['display_name'] as String? ?? '';
        _bio.text = row['bio'] as String? ?? '';
        _visibility = row['visibility'] as String? ?? 'private';
      } else {
        final meta = user.userMetadata ?? const <String, dynamic>{};
        _displayName.text = (meta['full_name'] ?? meta['name'] ?? '').toString();
        _username.text = 'user_${user.id.replaceAll('-', '').substring(0, 6)}';
      }
    } catch (e) {
      _error = 'Profile load failed. Ensure profiles migration is applied. ($e)';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = _user;
    if (user == null) return;
    final username = _username.text.trim().toLowerCase();
    final displayName = _displayName.text.trim();
    final bio = _bio.text.trim();
    if (!RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(username)) {
      setState(() => _error = 'Username: 3–24 lowercase letters, numbers or underscore.');
      return;
    }
    if (displayName.isEmpty || displayName.length > 60 || bio.length > 240) {
      setState(() => _error = 'Display name (1–60) and bio (up to 240) are required/limited.');
      return;
    }
    setState(() { _saving = true; _error = null; _notice = null; });
    try {
      await _db.from('profiles').upsert({
        'id': user.id,
        'username': username,
        'display_name': displayName,
        'bio': bio,
        'visibility': _visibility,
      });
      if (mounted) setState(() => _notice = 'Profile saved successfully.');
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.code == '23505'
          ? 'This username is already taken.' : 'Profile save failed: ${e.message}');
    } catch (e) {
      if (mounted) setState(() => _error = 'Profile save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final avatar = metadata['avatar_url']?.toString();
    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(child: CircleAvatar(
                  radius: 42,
                  backgroundImage: avatar == null || avatar.isEmpty ? null : NetworkImage(avatar),
                  child: avatar == null || avatar.isEmpty ? const Icon(Icons.person, size: 40) : null,
                )),
                const SizedBox(height: 8),
                Center(child: Text(user?.email ?? 'Email unavailable')),
                const SizedBox(height: 20),
                TextField(
                  controller: _username,
                  maxLength: 24,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Username', prefixText: '@',
                    helperText: '3–24 lowercase letters, numbers or underscore'),
                ),
                const SizedBox(height: 12),
                TextField(controller: _displayName, maxLength: 60,
                  decoration: const InputDecoration(labelText: 'Display name')),
                const SizedBox(height: 12),
                TextField(controller: _bio, maxLength: 240, maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Bio', alignLabelWithHint: true)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _visibility,
                  decoration: const InputDecoration(labelText: 'Profile visibility'),
                  items: const [
                    DropdownMenuItem(value: 'private', child: Text('Private')),
                    DropdownMenuItem(value: 'public', child: Text('Public')),
                    DropdownMenuItem(value: 'friends', child: Text('Friends only')),
                  ],
                  onChanged: (v) { if (v != null) setState(() => _visibility = v); },
                ),
                const SizedBox(height: 16),
                if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                if (_notice != null) Text(_notice!, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                FilledButton.icon(
                  onPressed: _saving ? null : _saveProfile,
                  icon: _saving ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving…' : 'Save profile'),
                ),
                const Divider(height: 32),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                  title: const Text('Delete account', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('यह स्थायी कार्रवाई है; account data deletion request'),
                  onTap: _saving ? null : () async {
                    final confirm = await showDialog<bool>(context: context, builder: (ctx) =>
                      AlertDialog(title: const Text('Delete account?'),
                        content: const Text('यह irreversible है। आगे बढ़ने पर deletion request भेजी जाएगी।'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
                        ]));
                    if (confirm != true || !context.mounted) return;
                    final reason = TextEditingController();
                    final submitted = await showDialog<bool>(context: context, builder: (ctx) =>
                      AlertDialog(title: const Text('Confirm account deletion'),
                        content: TextField(controller: reason, decoration: const InputDecoration(
                          labelText: 'Type DELETE to confirm')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, reason.text.trim() == 'DELETE'),
                            child: const Text('Submit request')),
                        ]));
                    reason.dispose();
                    if (submitted != true || !context.mounted) return;
                    try {
                      await _db.rpc('account_deletion_request');
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Deletion request submitted. Support/admin will process it.')));
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Request unavailable: apply account deletion migration first. $e')));
                    }
                  },
                ),
                const ListTile(leading: Icon(Icons.verified_user_outlined),
                  title: Text('Account security'), subtitle: Text('Google sign-in')),
                const ListTile(leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Privacy & safety'), subtitle: Text('Safety controls are being built')),
                const ListTile(leading: Icon(Icons.info_outline),
                  title: Text('VibeMingle'), subtitle: Text('V4.1 • Development build')),
                OutlinedButton.icon(
                  onPressed: () async {
                    final yes = await showDialog<bool>(context: context, builder: (ctx) =>
                      AlertDialog(title: const Text('Sign out?'),
                        content: const Text('आप अपने account से sign out हो जाएंगे।'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
                        ]));
                    if (yes == true && context.mounted) await _db.auth.signOut();
                  },
                  icon: const Icon(Icons.logout), label: const Text('Sign out')),
              ],
            ),
    );
  }
}
