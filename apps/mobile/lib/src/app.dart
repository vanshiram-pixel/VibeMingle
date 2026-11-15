import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
              CircleAvatar(radius: 34, child: Text((user.email ?? 'V')[0].toUpperCase())),
              const SizedBox(height: 12),
              Text(user.email ?? 'VibeMingle user', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              const _HomeAction(icon: Icons.people_alt, title: 'Friends', subtitle: 'Friend list and requests — next integration'),
              const _HomeAction(icon: Icons.chat_bubble, title: 'Private Chats', subtitle: 'Your conversations — next integration'),
              const _HomeAction(icon: Icons.call, title: 'Calls', subtitle: 'Voice and video calling — next integration'),
            ],
          ),
        );
      },
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right)),
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
