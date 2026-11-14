import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_config.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final name = TextEditingController();
  final language = TextEditingController(text: 'en');
  bool age = false, terms = false, privacy = false, busy = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    language.dispose();
    super.dispose();
  }

  Future<void> finish() async {
    if (!age || !terms || !privacy || name.text.trim().length < 2) {
      setState(() => error = 'Name, 18+ confirmation, Terms and Privacy acceptance required.');
      return;
    }
    final base = AppConfig.apiBaseUrl.trim();
    if (base.isEmpty) {
      setState(() => error = 'API_BASE_URL is missing in app build configuration.');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('Session expired. Sign in again.');
      final response = await http.post(
        Uri.parse('${base.replaceFirst(RegExp(r'/+$'), '')}/v1/onboarding/complete'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'display_name': name.text.trim(),
          'preferred_language': language.text.trim().isEmpty ? 'en' : language.text.trim(),
          'interests': <String>[],
          'accepted_terms_version': 'v1',
          'accepted_privacy_version': 'v1',
          'age_confirmed': true,
        }),
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Onboarding API returned ${response.statusCode}');
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = payload['data'] as Map<String, dynamic>?;
      if (data?['consentPending'] == true) {
        throw Exception('Consent service is not active yet; profile saved but access remains pending.');
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      if (mounted) setState(() => error = 'Onboarding failed: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create your profile')),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      const Text('A few details before you connect.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 18),
      TextField(controller: name, maxLength: 40, decoration: const InputDecoration(labelText: 'Display name', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: language, maxLength: 12, decoration: const InputDecoration(labelText: 'Language (en, hi…)', border: OutlineInputBorder())),
      CheckboxListTile(value: age, onChanged: (v) => setState(() => age = v ?? false), title: const Text('I confirm I am 18 or older.'), contentPadding: EdgeInsets.zero),
      CheckboxListTile(value: terms, onChanged: (v) => setState(() => terms = v ?? false), title: const Text('I accept Terms of Service.'), contentPadding: EdgeInsets.zero),
      CheckboxListTile(value: privacy, onChanged: (v) => setState(() => privacy = v ?? false), title: const Text('I accept Privacy Policy.'), contentPadding: EdgeInsets.zero),
      if (error != null) Text(error!, style: const TextStyle(color: Colors.orangeAccent)),
      FilledButton(onPressed: busy ? null : finish, child: Text(busy ? 'Saving…' : 'Complete onboarding')),
      const Text('Age checkbox is not jurisdiction-grade verification; stronger assurance may be required.', style: TextStyle(fontSize: 12, color: Colors.white60)),
    ]),
  );
}
