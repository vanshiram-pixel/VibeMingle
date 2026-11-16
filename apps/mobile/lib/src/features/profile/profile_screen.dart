import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Account basics; profile editing/onboarding will be layered onto this route.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final name = (metadata['full_name'] ?? metadata['name'] ?? 'VibeMingle user').toString();
    final avatar = metadata['avatar_url']?.toString();
    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: CircleAvatar(radius: 44,
            backgroundImage: avatar == null || avatar.isEmpty ? null : NetworkImage(avatar),
            child: avatar == null || avatar.isEmpty ? const Icon(Icons.person, size: 42) : null)),
          const SizedBox(height: 12),
          Center(child: Text(name, style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: 4),
          Center(child: Text(user?.email ?? 'Email unavailable')),
          const SizedBox(height: 24),
          const ListTile(leading: Icon(Icons.verified_user_outlined),
            title: Text('Account security'), subtitle: Text('Google sign-in')),
          const ListTile(leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy & safety'), subtitle: Text('Safety controls are being built')),
          const ListTile(leading: Icon(Icons.info_outline),
            title: Text('VibeMingle'), subtitle: Text('V4.1 • Development build')),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final yes = await showDialog<bool>(context: context, builder: (ctx) =>
                AlertDialog(title: const Text('Sign out?'),
                  content: const Text('आप अपने account से sign out हो जाएंगे।'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
                  ]));
              if (yes == true && context.mounted) {
                await Supabase.instance.client.auth.signOut();
              }
            },
            icon: const Icon(Icons.logout), label: const Text('Sign out')),
        ],
      ),
    );
  }
}
