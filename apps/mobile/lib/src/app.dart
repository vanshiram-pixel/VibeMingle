import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/messaging/messaging_screen.dart';

class VibeMingleApp extends StatefulWidget {
  const VibeMingleApp({super.key});

  @override
  State<VibeMingleApp> createState() => _VibeMingleAppState();
}

class _VibeMingleAppState extends State<VibeMingleApp> {
  late Future<_BootstrapResult> _bootstrap;

  @override
  void initState() {
    super.initState();
    _bootstrap = _initialize();
  }

  Future<_BootstrapResult> _initialize() async {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty || key.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      return const _BootstrapResult.configurationMissing();
    }

    try {
      final initialization = Supabase.initialize(
        url: url,
        publishableKey: key,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      await Future.wait<void>([
        initialization.then<void>((_) {}),
        Future<void>.delayed(const Duration(milliseconds: 1100)),
      ]);
      return const _BootstrapResult.ready();
    } catch (error) {
      return _BootstrapResult.failed(error);
    }
  }

  void _retryStartup() {
    setState(() => _bootstrap = _initialize());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeMingle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7656E8),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF100D1C),
        useMaterial3: true,
      ),
      home: FutureBuilder<_BootstrapResult>(
        future: _bootstrap,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SplashScreen();
          }
          final result = snapshot.data;
          if (result == null || result.error != null) {
            return _StartupErrorScreen(
              message: result?.error?.toString() ??
                  'VibeMingle could not finish starting. Please try again.',
              onRetry: _retryStartup,
            );
          }
          if (result.configurationMissing) {
            return const _ConfigurationScreen();
          }
          return const _AuthGate();
        },
      ),
    );
  }
}

class _BootstrapResult {
  const _BootstrapResult.ready()
      : configurationMissing = false,
        error = null;

  const _BootstrapResult.configurationMissing()
      : configurationMissing = true,
        error = null;

  const _BootstrapResult.failed(this.error)
      : configurationMissing = false;

  final bool configurationMissing;
  final Object? error;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 0.86,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF21163D), Color(0xFF100D1C), Color(0xFF090812)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9A7BFF), Color(0xFF6846D8)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x556F4BE8),
                          blurRadius: 32,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'VibeMingle',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Meet  •  Talk  •  Connect',
                    style: TextStyle(
                      color: Color(0xFFBDB4D4),
                      fontSize: 14,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 52),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFB7A3FF),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Getting things ready…',
                    style: TextStyle(color: Color(0xFF9289A8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) return const MessagingScreen();
        return const _SignInScreen();
      },
    );
  }
}

class _SignInScreen extends StatefulWidget {
  const _SignInScreen();

  @override
  State<_SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<_SignInScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _googleSignIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.vibemingle://login-callback/',
      );
    } catch (error) {
      if (mounted) setState(() => _error = 'Google sign-in failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.forum_rounded, size: 72),
                const SizedBox(height: 20),
                Text('VibeMingle',
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                const Text('Meet • Talk • Connect'),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _googleSignIn,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigurationScreen extends StatelessWidget {
  const _ConfigurationScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'VibeMingle setup is incomplete. Add SUPABASE_URL and SUPABASE_ANON_KEY dart-defines, then restart the app.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48),
              const SizedBox(height: 16),
              const Text('Could not start VibeMingle',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
