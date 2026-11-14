import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_config.dart';

class AiConsentScreen extends StatefulWidget {
  const AiConsentScreen({super.key});
  @override
  State<AiConsentScreen> createState() => _AiConsentScreenState();
}

class _AiConsentScreenState extends State<AiConsentScreen> {
  final _textController = TextEditingController();
  bool? _granted;
  bool _loading = true;
  bool _saving = false;
  bool _translating = false;
  String _targetLanguage = 'hi';
  String? _message;
  String? _translation;

  Map<String, String> get _headers {
    final token = Supabase.instance.client.auth.currentSession?.accessToken ?? '';
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _textController.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/v1/ai/consent'), headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) throw Exception();
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final consent = data['data'] as Map<String, dynamic>?;\n      if (mounted) setState(() => _granted = consent?['granted'] == true && consent?['withdrawn_at'] == null);
    } catch (_) {
      if (mounted) setState(() => _message = 'Consent status नहीं मिल पाया। API/server जाँचें।');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setConsent(bool granted) async {
    setState(() { _saving = true; _message = null; _translation = null; });
    try {
      final response = await http.put(Uri.parse('${AppConfig.apiBaseUrl}/v1/ai/consent'), headers: _headers, body: jsonEncode({'granted': granted, 'policyVersion': 'ai-translation-v1'})).timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception();
      if (mounted) setState(() { _granted = granted; _message = granted ? 'AI translation consent चालू है।' : 'AI translation consent वापस ले लिया।'; });
    } catch (_) {
      if (mounted) setState(() => _message = 'Consent update नहीं हुआ। कृपया फिर कोशिश करें।');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _translate() async {
    final text = _textController.text.trim();
    if (_granted != true) { setState(() => _message = 'पहले AI translation consent चालू करें।'); return; }
    if (text.isEmpty || text.length > 4000) { setState(() => _message = 'Text 1 से 4,000 characters के बीच होना चाहिए।'); return; }
    setState(() { _translating = true; _message = null; _translation = null; });
    try {
      final response = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/v1/ai/translate'), headers: _headers, body: jsonEncode({'text': text, 'targetLanguage': _targetLanguage})).timeout(const Duration(seconds: 18));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        final code = body['error'] is Map ? body['error']['code'] : '';
        final message = switch (code) {
          'AI_DISABLED' => 'AI Translation अभी server पर बंद है।',
          'AI_DAILY_LIMIT' => 'आज की translation limit पूरी हो गई।',
          'AI_CONSENT_REQUIRED' => 'Consent जरूरी है—इसे फिर से enable करें।',
          'AI_RATE_LIMIT' => 'थोड़ी देर बाद retry करें।',
          _ => 'Translation नहीं हो पाया। Server/API जाँचें।',
        };
        throw Exception(message);
      }
      final data = body['data'] as Map<String, dynamic>;
      if (mounted) setState(() => _translation = data['translated'] as String?);
    } catch (e) {
      if (mounted) setState(() => _message = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI & Translation Privacy')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Icon(Icons.translate, size: 54),
      const SizedBox(height: 12),
      const Text('AI Translation', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      const Text('अनुवाद के लिए भेजा गया टेक्स्ट AI provider तक जाएगा। अनुमति कभी भी वापस ली जा सकती है।'),
      const SizedBox(height: 18),
      if (_loading) const Center(child: CircularProgressIndicator()) else SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Allow AI translation'),
        subtitle: Text(_granted == true ? 'Consent granted' : 'Consent not granted'),
        value: _granted == true,
        onChanged: _saving ? null : _setConsent,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _textController,
        minLines: 3,
        maxLines: 6,
        maxLength: 4000,
        decoration: const InputDecoration(labelText: 'Text to translate', hintText: 'यहाँ text लिखें…', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _targetLanguage,
        decoration: const InputDecoration(labelText: 'Target language', border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'hi', child: Text('Hindi')),
          DropdownMenuItem(value: 'en', child: Text('English')),
          DropdownMenuItem(value: 'es', child: Text('Spanish')),
          DropdownMenuItem(value: 'fr', child: Text('French')),
          DropdownMenuItem(value: 'de', child: Text('German')),
          DropdownMenuItem(value: 'ar', child: Text('Arabic')),
          DropdownMenuItem(value: 'ja', child: Text('Japanese')),
          DropdownMenuItem(value: 'bn', child: Text('Bengali')),
          DropdownMenuItem(value: 'ur', child: Text('Urdu')),
        ],
        onChanged: _translating ? null : (value) => setState(() => _targetLanguage = value ?? 'hi'),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _translating || _saving || _loading ? null : _translate,
        icon: const Icon(Icons.g_translate),
        label: Text(_translating ? 'Translating…' : 'Translate'),
      ),
      if (_translating || _saving) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
      if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!, style: const TextStyle(color: Colors.orangeAccent))),
      if (_translation != null) ...[
        const SizedBox(height: 18),
        const Text('Translation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SelectableText(_translation!, style: const TextStyle(fontSize: 16)),
        Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: _translation!)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'))); }, icon: const Icon(Icons.copy), label: const Text('Copy'))),
      ],
      const SizedBox(height: 20),
      const Text('Safety: feature default-off, server-side provider key, daily limits; usage में केवल character counts दर्ज होते हैं—message text नहीं।', style: TextStyle(color: Colors.grey)),
    ]),
  );
}
