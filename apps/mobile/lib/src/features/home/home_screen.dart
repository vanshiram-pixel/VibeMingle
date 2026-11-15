import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_config.dart';
import '../friends/friends_screen.dart';
import '../matching/matching_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../messaging/messaging_screen.dart';
import '../calls/call_requests_screen.dart';
import '../settings/ai_consent_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _presenceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sendHeartbeat();
    _presenceTimer = Timer.periodic(const Duration(seconds: 45), (_) => _sendHeartbeat());
  }

  Future<void> _sendHeartbeat() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null || AppConfig.apiBaseUrl.isEmpty) return;
    try {
      await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/v1/presence/heartbeat'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Best-effort: missed heartbeat naturally expires online status.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sendHeartbeat();
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('VibeMingle'),
      actions: [IconButton(tooltip: 'Edit profile', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())), icon: const Icon(Icons.account_circle)), IconButton(
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
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchingScreen())),
          icon: const Icon(Icons.video_call), label: const Text('Random video matching'),
        )),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen())),
          icon: const Icon(Icons.people), label: const Text('Friends'),
        )),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagingScreen())),
          icon: const Icon(Icons.chat), label: const Text('Private messages'),
        )),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CallRequestsScreen())),
          icon: const Icon(Icons.video_call), label: const Text('Private calls & requests'),
        )),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiConsentScreen())),
          icon: const Icon(Icons.translate), label: const Text('AI & Translation Privacy'),
        )),
      ]),
    )),
  );
}
