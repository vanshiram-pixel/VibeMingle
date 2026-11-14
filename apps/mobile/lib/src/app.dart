import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/login_screen.dart'; import 'features/onboarding/onboarding_screen.dart';
class VibeMingleApp extends StatelessWidget { const VibeMingleApp({super.key});
 @override Widget build(BuildContext context) {
  final configured=Supabase.instance.isInitialized; final session=configured?Supabase.instance.client.auth.currentSession:null;
  return MaterialApp(title:'VibeMingle',debugShowCheckedModeBanner:false,
   theme:ThemeData(brightness:Brightness.dark,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF8B5CF6),brightness:Brightness.dark),scaffoldBackgroundColor:const Color(0xFF0B0B12),useMaterial3:true),
   home:!configured||session==null?const LoginScreen():const OnboardingScreen());
 }
}