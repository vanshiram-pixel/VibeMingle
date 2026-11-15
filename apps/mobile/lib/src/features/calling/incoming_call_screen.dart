import 'package:flutter/material.dart';

import 'call_models.dart';

/// UI shell for a server-validated incoming call. Parent must route only
/// authorized incoming sessions and call accept/decline RPCs before navigation.
class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.session,
    required this.onAccept,
    required this.onDecline,
  });

  final String callerName;
  final CallSession session;
  final Future<void> Function() onAccept;
  final Future<void> Function() onDecline;

  @override
  Widget build(BuildContext context) {
    final video = session.type == CallType.video;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircleAvatar(radius: 54, child: Icon(Icons.person, size: 54)),
          const SizedBox(height: 24),
          Text(callerName, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(video ? 'Incoming video call' : 'Incoming audio call'),
          const SizedBox(height: 48),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _CallAction(
              label: 'Decline',
              icon: Icons.call_end,
              color: Colors.red,
              onTap: () async { await onDecline(); if (context.mounted) Navigator.pop(context); },
            ),
            _CallAction(
              label: 'Accept',
              icon: video ? Icons.videocam : Icons.call,
              color: Colors.green,
              onTap: () async { await onAccept(); },
            ),
          ]),
        ]),
      ))),
    );
  }
}

class _CallAction extends StatelessWidget {
  const _CallAction({required this.label, required this.icon,
    required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(children: [
    FloatingActionButton(
      heroTag: label,
      backgroundColor: color,
      foregroundColor: Colors.white,
      onPressed: onTap,
      child: Icon(icon),
    ),
    const SizedBox(height: 8),
    Text(label),
  ]);
}
