import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('VibeMingle')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.forum_rounded, size: 72),
                const SizedBox(height: 16),
                Text('Connect privately.', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('Chat, voice and video with your friends.'),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/auth'),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in / Create account'),
                ),
              ],
            ),
          ),
        ),
      );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creating = false;
  bool _busy = false;
  bool get _configured => Supabase.instance.isInitialized;
  bool get _configured => Supabase.instance.isInitialized;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Welcome to VibeMingle')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(_creating ? 'Create your account' : 'Sign in',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              TextField(controller: _email, keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _password, obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : () => _submit(context),
                child: _busy ? const CircularProgressIndicator() : Text(_creating ? 'Create account' : 'Sign in'),
              ),
              TextButton(
                onPressed: _busy ? null : () => setState(() => _creating = !_creating),
                child: Text(_creating ? 'Already registered? Sign in' : 'New here? Create account'),
              ),
              Text(_configured ? 'Supabase Auth configured.' : 'Supabase credentials not configured.',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  Future<void> _submit(BuildContext context) async {
    if (_email.text.trim().isEmpty || _password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email भरें और password कम से कम 6 characters रखें.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      if (!_configured) throw const AuthException('Supabase configuration missing');
      final auth = Supabase.instance.client.auth;
      if (_creating) {
        await auth.signUp(email: _email.text.trim(), password: _password.text);
      } else {
        await auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_creating ? 'Signup submitted. Check email if confirmation is enabled.' : 'Signed in successfully.')));
      }
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auth error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
