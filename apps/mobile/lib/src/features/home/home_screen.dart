import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../calls/video_call_screen.dart';
import '../friends/friends_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('VibeMingle'),
      actions: [IconButton(
        tooltip: 'Sign out',
        onPressed: () => Supabase.instance.client.auth.signOut(),
        icon: const Icon(Icons.logout),
      )],
    ),
    body: Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.public, size: 68, color: Color(0xFFA78BFA)),
        const SizedBox(height: 16),
        const Text('Connect Beyond Borders', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Welcome to VibeMingle'),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoCallScreen())),
          icon: const Icon(Icons.video_call), label: const Text('Open call UI preview'),
        )),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen())),
          icon: const Icon(Icons.people), label: const Text('Friends'),
        )),
      ]),
    )),
  );
}
