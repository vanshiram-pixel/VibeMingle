import 'dart:async';
import 'package:flutter/material.dart';
import 'match_queue_repository.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});
  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final _repo = MatchQueueRepository();
  bool _consent = false, _queued = false, _busy = false;
  String _mode = 'random';
  Timer? _heartbeat;

  @override
  void dispose() {
    _heartbeat?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    if (!_consent) throw Exception('Please enable matching consent first.');
    await _repo.setConsent(enabled: true, version: 'v4.1-consent-1');
    await _repo.enter(mode: _mode);
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        await _repo.heartbeat();
      } catch (_) {
        _heartbeat?.cancel();
        if (mounted) setState(() => _queued = false);
      }
    });
    if (mounted) setState(() => _queued = true);
  }

  Future<void> _leave() async {
    _heartbeat?.cancel();
    await _repo.leave();
    if (mounted) setState(() => _queued = false);
  }

  Future<void> _revoke() async {
    _heartbeat?.cancel();
    if (_queued) await _repo.leave();
    await _repo.setConsent(enabled: false, version: 'v4.1-consent-1');
    if (mounted) setState(() => _queued = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Stranger Match')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.video_call, size: 72),
            const Text('Meet someone new', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Matching requires verified age eligibility, an available profile, online presence, and explicit consent. Your exact location is never shown.'),
            SwitchListTile(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v),
              title: const Text('I consent to stranger matching'),
              subtitle: const Text('You can leave the queue or revoke consent anytime.'),
            ),
            DropdownButtonFormField<String>(
              value: _mode,
              decoration: const InputDecoration(labelText: 'Matching mode'),
              items: const [
                DropdownMenuItem(value: 'random', child: Text('Random')),
                DropdownMenuItem(value: 'manual', child: Text('Preferences')),
                DropdownMenuItem(value: 'next', child: Text('Next / Switch')),
              ],
              onChanged: (v) => setState(() => _mode = v ?? 'random'),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : () => _run(_queued ? _leave : _join),
              icon: Icon(_queued ? Icons.stop : Icons.search),
              label: Text(_busy ? 'Please wait…' : _queued ? 'Leave queue' : 'Start matching'),
            ),
            const SizedBox(height: 12),
            Text(_queued ? 'Queue active — searching for a compatible person…' : 'Queue inactive',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _busy ? null : () => _run(_revoke),
              child: const Text('Revoke matching consent'),
            ),
          ],
        ),
      );
}
