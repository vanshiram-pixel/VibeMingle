import 'dart:async';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/friends/friends_screen.dart';
import 'features/messaging/chat_thread_screen.dart';
import 'features/matching/match_screen.dart';
import 'features/calling/call_repository.dart';
import 'features/calling/call_signaling_coordinator.dart';
import 'features/calling/webrtc_call_controller.dart';
import 'features/calling/incoming_call_screen.dart';
import 'features/calling/active_call_screen.dart';

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(path: '/friends', builder: (context, state) => const FriendsScreen()),
    GoRoute(path: '/messages', builder: (context, state) => const ChatInboxScreen()),
    GoRoute(path: '/match', builder: (context, state) => const MatchScreen()),
  ],
);

class VibeMingleApp extends StatelessWidget {
  const VibeMingleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'VibeMingle',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
          useMaterial3: true,
        ),
        routerConfig: _router,
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Supabase.instance.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('VibeMingle')),
        body: Center(child: FilledButton(
          onPressed: () => context.go('/auth'),
          child: const Text('Sign in / Create account'),
        )),
      );
    }
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('VibeMingle')),
            body: Center(child: FilledButton.icon(
              onPressed: () => context.go('/auth'),
              icon: const Icon(Icons.login),
              label: const Text('Sign in / Create account'),
            )),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('VibeMingle'),
            actions: [IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/auth');
              },
            )],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const IncomingCallListener(),
              CircleAvatar(radius: 34, child: Text((user.email ?? 'V')[0].toUpperCase())),
              const SizedBox(height: 12),
              Text(user.email ?? 'VibeMingle user', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              _HomeAction(icon: Icons.people_alt, title: 'Friends', subtitle: 'Find people and manage requests', onTap: () => context.go('/friends')),
              _HomeAction(icon: Icons.chat_bubble, title: 'Private Chats', subtitle: 'Open your messages', onTap: () => context.go('/messages')),
              _HomeAction(icon: Icons.video_call, title: 'Stranger Match', subtitle: 'Consent-based matching queue', onTap: () => context.go('/match')),
            ],
          ),
        );
      },
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(onTap: onTap, leading: Icon(icon), title: Text(title), subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right)),
  );
}

/// Google-only authentication (V4.1). OAuth redirect URI must be configured
/// in Supabase + Android intent filters / web allowed redirect URLs.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _busy = false;
  bool get _configured => Supabase.instance.isInitialized;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Welcome to VibeMingle')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.video_call_rounded, size: 72),
                    const SizedBox(height: 16),
                    Text('Meet. Chat. Connect.',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    const Text(
                      'Continue securely with your Google account.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: _busy
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.login),
                        label: Text(_busy ? 'Connecting…' : 'Continue with Google'),
                        onPressed: _busy ? null : _signInWithGoogle,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _configured
                          ? 'Google sign-in uses Supabase OAuth.'
                          : 'App configuration is required before sign-in.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> _signInWithGoogle() async {
    if (!_configured) {
      _showMessage('Supabase configuration missing. Please try again later.');
      return;
    }
    setState(() => _busy = true);
    try {
      // Supabase handles provider OAuth; callback URI must be allow-listed
      // and registered for Android/web in the deployment configuration.
      await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google);
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Google sign-in could not start. Check connection and OAuth setup.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}


/// Keeps incoming call realtime subscription active while the user is on Home.
class IncomingCallListener extends StatefulWidget {
  const IncomingCallListener({super.key});
  @override
  State<IncomingCallListener> createState() => _IncomingCallListenerState();
}

class _IncomingCallListenerState extends State<IncomingCallListener> {
  late final CallRepository _calls = CallRepository(Supabase.instance.client);
  StreamSubscription? _subscription;
  final Set<String> _presented = {};

  @override
  void initState() {
    super.initState();
    _subscription = _calls.incomingCalls().listen((session) {
      if (!mounted || !_presented.add(session.id)) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showIncoming(session);
      });
    });
  }

  Future<void> _showIncoming(dynamic session) async {
    final navigator = Navigator.of(context);
    await navigator.push(MaterialPageRoute<void>(builder: (_) => IncomingCallScreen(
      callerName: 'VibeMingle user',
      session: session,
      onDecline: () => _calls.decline(session.id),
      onAccept: () async {
        await _calls.accept(session.id);
        await _calls.transition(callId: session.id, action: 'connecting');
        late CallSignalingCoordinator signaling;
        final controller = WebRtcCallController(
          sendSignal: (signal) => signaling.send(signal),
          onRemoteStream: (_) {},
          onConnectionState: (_) {},
        );
        await controller.initialize(video: session.type.name == 'video');
        signaling = CallSignalingCoordinator(
          repository: _calls, controller: controller, callId: session.id,
          remoteUserId: session.callerId,
        );
        await signaling.startListening();
        if (!mounted) {
          await signaling.close();
          await controller.close();
          return;
        }
        navigator.push(MaterialPageRoute<void>(builder: (_) => ActiveCallScreen(
          session: session, peerName: 'VibeMingle user', controller: controller,
          signaling: signaling,
          onEnd: () => _calls.end(session.id),
        )));
      },
    )));
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_calls.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
