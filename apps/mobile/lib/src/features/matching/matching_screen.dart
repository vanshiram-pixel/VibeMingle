import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Consent-based stranger matching queue. Voice/video transport is a separate feature.
class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});
  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}
class _MatchingScreenState extends State<MatchingScreen> {
  final _db = Supabase.instance.client;
  String _status = 'idle';
  String? _sessionId, _peerId, _error;
  bool _busy = false;
  Timer? _poll;

  Future<void> _join() async {
    setState(() { _busy = true; _error = null; });
    try {
      final result = Map<String, dynamic>.from(await _db.rpc('matchmaking_join'));
      if (!mounted) return;
      setState(() {
        _status = result['status']?.toString() ?? 'waiting';
        _sessionId = result['session_id']?.toString();
        _peerId = result['peer_id']?.toString();
      });
      if (_status == 'waiting') {
        _poll?.cancel();
        _poll = Timer.periodic(const Duration(seconds: 4), (_) => _joinQuietly());
      } else {
        _poll?.cancel();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _joinQuietly() async {
    if (_busy || !mounted || _status != 'waiting') return;
    try {
      final result = Map<String, dynamic>.from(await _db.rpc('matchmaking_join'));
      if (!mounted) return;
      setState(() {
        _status = result['status']?.toString() ?? 'waiting';
        _sessionId = result['session_id']?.toString();
        _peerId = result['peer_id']?.toString();
      });
      if (_status == 'matched') _poll?.cancel();
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
  }

  Future<void> _leave() async {
    _poll?.cancel();
    setState(() => _busy = true);
    try {
      await _db.rpc('matchmaking_leave');
      if (mounted) setState(() { _status = 'idle'; _sessionId = null; _peerId = null; });
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  void dispose() { _poll?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meet someone new')),
    body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        Icon(_status == 'matched' ? Icons.favorite : Icons.travel_explore, size: 72,
          color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 18),
        Text(_status == 'matched' ? 'You are matched!' :
          _status == 'waiting' ? 'Finding someone…' : 'Ready to meet someone?',
          style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(_status == 'matched' ? 'Partner: ${_peerId ?? 'connected'}\nSession: ${_sessionId ?? ''}' :
          _status == 'waiting' ? 'Matching queue में हैं। आप कभी भी cancel कर सकते हैं।' :
          'Start matching to join the queue.', textAlign: TextAlign.center),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12),
          child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 24),
        if (_status == 'idle') FilledButton.icon(onPressed: _busy ? null : _join,
          icon: const Icon(Icons.search), label: const Text('Start matching'))
        else OutlinedButton.icon(onPressed: _busy ? null : _leave,
          icon: const Icon(Icons.stop_circle_outlined), label: const Text('Leave matching')),
        if (_busy) const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
        if (_status == 'matched') const Padding(padding: EdgeInsets.only(top: 16),
          child: Text('Call connection अभी अलग चरण में है।', textAlign: TextAlign.center)),
      ],
    ))),
  );
}
