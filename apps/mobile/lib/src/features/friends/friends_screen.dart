import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../calling/call_models.dart';
import '../calling/call_repository.dart';
import '../calling/call_signaling_coordinator.dart';
import '../calling/webrtc_call_controller.dart';
import '../calling/active_call_screen.dart';
import 'friend_repository.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  final _repo = FriendRepository();
  final _calls = CallRepository(Supabase.instance.client);
  final _search = TextEditingController();
  late final _tabs = TabController(length: 4, vsync: this);
  List<Map<String, dynamic>> _results = [], _friends = [], _incoming = [];
  List<Map<String, dynamic>> _followers = [], _following = [];
  bool _loading = true, _searching = false;
  final Set<StreamSubscription<CallSession>> _callSubscriptions = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final subscription in _callSubscriptions) {
      subscription.cancel();
    }
    _callSubscriptions.clear();
    _search.dispose();
    _tabs.dispose();
    super.dispose();
  }

  String _name(Map<String, dynamic> p) {
    final display = (p['display_name'] as String? ?? '').trim();
    return display.isNotEmpty ? display : (p['username'] as String? ?? 'User');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startCall(Map<String, dynamic> friend, CallType type) async {
    StreamSubscription<CallSession>? statusSub;
    var connecting = false;
    try {
      final session = await _calls.startCall(friendId: friend['id'] as String, type: type);
      if (!mounted) return;
      _toast('${type == CallType.video ? 'Video' : 'Audio'} call request sent. Waiting for ${_name(friend)}…');

      Future<void> connectAccepted(CallSession updated) async {
        if (connecting || !mounted) return;
        connecting = true;
        await statusSub.cancel();
        if (statusSub != null) _callSubscriptions.remove(statusSub);
        WebRtcCallController? controller;
        CallSignalingCoordinator? signaling;
        try {
          await _calls.transition(callId: session.id, action: 'connecting');
          controller = WebRtcCallController(
            sendSignal: (signal) => signaling!.send(signal),
            onRemoteStream: (_) {}, onConnectionState: (_) {},
          );
          await controller.initialize(video: type == CallType.video);
          signaling = CallSignalingCoordinator(repository: _calls, controller: controller,
            callId: session.id, remoteUserId: session.calleeId);
          await signaling.startListening();
          await controller.createOffer();
          if (!mounted) { await signaling.close(); await controller.close(); return; }
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ActiveCallScreen(
            session: session, peerName: _name(friend), controller: controller!,
            signaling: signaling!, onEnd: () => _calls.end(session.id),
            onConnected: () async { await _calls.transition(callId: session.id, action: 'connected'); },
          )));
        } catch (e) {
          await signaling?.close();
          await controller?.close();
          try { await _calls.transition(callId: session.id, action: 'failed', reason: 'media_setup_failed'); } catch (_) {}
          if (mounted) _toast('Call connection failed: $e');
        }
      }

      statusSub = _calls.sessionUpdates(session.id).listen((updated) async {
        if (updated.status == CallStatus.accepted || updated.status == CallStatus.connecting) {
          await connectAccepted(updated);
        } else if (updated.status == CallStatus.declined || updated.status == CallStatus.ended || updated.status == CallStatus.failed || updated.status == CallStatus.missed) {
          await statusSub.cancel();
          if (statusSub != null) _callSubscriptions.remove(statusSub);
          if (mounted) _toast('Call ${updated.status.name}');
        }
      });
      _callSubscriptions.add(statusSub);

      // Reconcile current server state after subscribing so a fast accept
      // between call_start and realtime subscription cannot be missed.
      final current = await _calls.getSession(session.id);
      if (current.status == CallStatus.accepted || current.status == CallStatus.connecting) {
        await connectAccepted(current);
      } else if (current.status == CallStatus.declined || current.status == CallStatus.ended || current.status == CallStatus.failed || current.status == CallStatus.missed) {
        await statusSub.cancel();
        _callSubscriptions.remove(statusSub);
        if (mounted) _toast('Call ${current.status.name}');
      }
    } catch (e) {
      await statusSub.cancel();
      if (statusSub != null) _callSubscriptions.remove(statusSub);
      if (mounted) _toast('Call could not start: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final values = await Future.wait([
        _repo.friends(), _repo.incomingRequests(), _repo.followers(), _repo.following()
      ]);
      if (mounted) {
        setState(() {
          _friends = values[0]; _incoming = values[1];
          _followers = values[2]; _following = values[3]; _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _toast('Load error: $e');
    }
  }

  Future<void> _find(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final values = await _repo.searchProfiles(query);
      if (mounted) setState(() => _results = values);
    } catch (e) {
      _toast('Search error: $e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _act(Future<void> Function() action, String message) async {
    try {
      await action();
      _toast(message);
      await _load();
      if (_search.text.trim().length >= 2) await _find(_search.text);
    } catch (e) {
      _toast('Action failed: $e');
    }
  }

  Widget _profiles(List<Map<String, dynamic>> people, {bool allowUnfollow = false}) {
    if (people.isEmpty) return const Center(child: Text('No users yet'));
    return ListView(
      children: people.map((p) => ListTile(
        leading: CircleAvatar(child: Text(_name(p).isEmpty ? '?' : _name(p)[0].toUpperCase())),
        title: Text(_name(p)),
        subtitle: Text('@${p['username'] ?? ''}'),
        trailing: allowUnfollow
            ? IconButton(tooltip: 'Unfollow', icon: const Icon(Icons.person_remove),
                onPressed: () => _act(() => _repo.unfollow(p['id'] as String), 'Unfollowed'))
            : null,
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connections'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
        bottom: TabBar(
          isScrollable: true,
          controller: _tabs,
          tabs: [
            Tab(text: 'Friends ${_friends.length}'),
            Tab(text: 'Requests ${_incoming.length}'),
            Tab(text: 'Followers ${_followers.length}'),
            Tab(text: 'Following ${_following.length}'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: _find,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search name or username',
                suffixIcon: _searching
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (_search.text.trim().length >= 2)
            ..._results.map((p) => ListTile(
              title: Text(_name(p)),
              subtitle: Text('@${p['username'] ?? ''}'),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(tooltip: 'Follow', icon: const Icon(Icons.person_add_alt_1),
                    onPressed: () => _act(() => _repo.follow(p['id'] as String), 'Followed')),
                  IconButton(tooltip: 'Friend request', icon: const Icon(Icons.people_alt),
                    onPressed: () => _act(() => _repo.sendRequest(p['id'] as String), 'Request sent')),
                ],
              ),
            )),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _friends.isEmpty
                          ? const Center(child: Text('No friends yet'))
                          : ListView(
                              children: _friends.map((p) => ListTile(
                                title: Text(_name(p)),
                                subtitle: Text('@${p['username'] ?? ''}'),
                                trailing: Wrap(spacing: 0, children: [
                                  IconButton(tooltip: 'Audio call', icon: const Icon(Icons.call), onPressed: () => _startCall(p, CallType.audio)),
                                  IconButton(tooltip: 'Video call', icon: const Icon(Icons.video_call), onPressed: () => _startCall(p, CallType.video)),
                                  PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'remove') _act(() => _repo.removeFriend(p['id'] as String), 'Friend removed');
                                    if (v == 'block') _act(() => _repo.block(p['id'] as String), 'Blocked');
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'remove', child: Text('Remove friend')),
                                    PopupMenuItem(value: 'block', child: Text('Block user')),
                                  ],
                                  ),
                                ]),
                              )).toList(),
                            ),
                      _incoming.isEmpty
                          ? const Center(child: Text('No requests'))
                          : ListView(
                              children: _incoming.map((r) => ListTile(
                                title: Text('Request from ${r['sender_id']}'),
                                trailing: Wrap(children: [
                                  IconButton(icon: const Icon(Icons.check),
                                    onPressed: () => _act(() => _repo.respond(r['id'] as String, true), 'Accepted')),
                                  IconButton(icon: const Icon(Icons.close),
                                    onPressed: () => _act(() => _repo.respond(r['id'] as String, false), 'Rejected')),
                                ]),
                              )).toList(),
                            ),
                      _profiles(_followers),
                      _profiles(_following, allowUnfollow: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
