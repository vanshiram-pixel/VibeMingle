import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';

class VibeMingleApp extends StatelessWidget {
  const VibeMingleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final configured = Supabase.instance.isInitialized;
    return MaterialApp(
      title: 'VibeMingle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0B12),
        useMaterial3: true,
      ),
      home: !configured
          ? const LoginScreen()
          : StreamBuilder<AuthState>(
              stream: Supabase.instance.client.auth.onAuthStateChange,
              initialData: AuthState(
                AuthChangeEvent.initialSession,
                Supabase.instance.client.auth.currentSession,
              ),
              builder: (context, snapshot) {
                final session = snapshot.data?.session;
                if (session == null) return const LoginScreen();
                return ProfileRouteGate(key: ValueKey(session.user.id));
              },
            ),
    );
  }
}

/// Routes authenticated users according to their own RLS-protected profile.
/// A missing profile or blank display name sends the user to onboarding.
class ProfileRouteGate extends StatefulWidget {
  const ProfileRouteGate({super.key});

  @override
  State<ProfileRouteGate> createState() => _ProfileRouteGateState();
}

class _ProfileRouteGateState extends State<ProfileRouteGate> {
  late Future<bool> _profileReady;

  @override
  void initState() {
    super.initState();
    _profileReady = _checkProfile();
  }

  Future<bool> _checkProfile() async {
    try {
      final result = await Supabase.instance.client
          .from('profiles')
          .select('display_name')
          .maybeSingle();
      final name = result?['display_name'];
      return name is String && name.trim().length >= 2;
    } catch (_) {
      // Fail closed to onboarding rather than assuming profile completion.
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _profileReady,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == true
            ? const HomeScreen()
            : const OnboardingScreen();
      },
    );
  }
}
