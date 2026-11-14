import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_config.dart';

class AiConsentScreen extends StatefulWidget {
  const AiConsentScreen({super.key});
  @override
  State<AiConsentScreen> createState() => _AiConsentScreenState();
}

class _AiConsentScreenState extends State<AiConsentScreen> {
  bool? _granted;
  bool _loading = true;
  bool _saving = false;
  String? _message;

  Map<String, String> get _headers {
    final token = Supabase.instance.client.auth.currentSession?.accessToken ?? '';
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  Future<void> _load() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/v1/ai/consent'), headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) throw Exception();
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (mounted) setState(() => _granted = data['granted'] == true);
    } catch (_) {
      if (mounted) setState(() => _message = 'Consent status नहीं मिल पाया। API/server जाँचें।');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setConsent(bool granted) async {
    setState(() { _saving = true; _message = null; });
    try {
      final response = await http.put(Uri.parse('${AppConfig.apiBaseUrl}/v1/ai/consent'), headers: _headers, body: jsonEncode({'granted': granted})).timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception();
      if (mounted) setState(() { _granted = granted; _message = granted ? 'AI translation consent चालू है।' : 'AI translation consent वापस ले लिया।'; });
    } catch (_) {
      if (mounted) setState(() => _message = 'Consent update नहीं हुआ। कृपया फिर कोशिश करें।');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI & Translation Privacy')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Icon(Icons.translate, size: 54),
      const SizedBox(height: 12),
      const Text('AI Translation Consent', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      const Text('अनुवाद सुविधा इस्तेमाल करने के लिए आपकी स्पष्ट अनुमति आवश्यक है। अनुमति कभी भी वापस ली जा सकती है। अनुवाद के लिए भेजा गया टेक्स्ट AI provider तक जा सकता है।'),
      const SizedBox(height: 18),
      if (_loading) const Center(child: CircularProgressIndicator()) else SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Allow AI translation'),
        subtitle: Text(_granted == true ? 'Consent granted' : 'Consent not granted'),
        value: _granted == true,
        onChanged: _saving ? null : _setConsent,
      ),
      if (_saving) const LinearProgressIndicator(),
      if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!)),
      const SizedBox(height: 16),
      const Text('Privacy safeguards: feature default-off, server-side provider key, daily limits, और usage में केवल character counts दर्ज होते हैं—message text नहीं।', style: TextStyle(color: Colors.grey)),
    ]),
  );
}
