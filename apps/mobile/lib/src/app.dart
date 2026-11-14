import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

class VibeMingleApp extends StatelessWidget {
 const VibeMingleApp({super.key});
 @override Widget build(BuildContext context) {
  final configured=Supabase.instance.isInitialized;
  return MaterialApp(
   title:'VibeMingle',debugShowCheckedModeBanner:false,
   theme:ThemeData(brightness:Brightness.dark,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF8B5CF6),brightness:Brightness.dark),scaffoldBackgroundColor:const Color(0xFF0B0B12),useMaterial3:true),
   home:!configured?const LoginScreen():StreamBuilder<AuthState>(
    stream:Supabase.instance.client.auth.onAuthStateChange,
    initialData:AuthState(AuthChangeEvent.initialSession,Supabase.instance.client.auth.currentSession),
    builder:(context,snapshot){
     final session=snapshot.data?.session;
     if(session==null)return const LoginScreen();
     // Profile-completion routing is pending a reliable server profile lookup.
     return const OnboardingScreen();
    }),
  );
 }
}
