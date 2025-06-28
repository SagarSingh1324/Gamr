import 'package:flutter/material.dart';
import '../models/past_session.dart';

class PastSessionCard extends StatelessWidget {
  final PastSession session;
  final VoidCallback? onRemove; 

  const PastSessionCard({super.key, required this.session, this.onRemove});

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final completedText = session.completedAt.millisecondsSinceEpoch == 0
        ? "Not yet"
        : session.completedAt.toLocal().toString().split(' ')[0];

    return Card(
      child: ListTile(
        leading: Image.network('https:${session.game.cover.url}'),
        title: Text(session.game.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Started: ${session.startedAt.toLocal().toString().split(' ')[0]}'),
            Text('Completed: $completedText'),
            Text('Playtime: ${_formatDuration(session.totalPlayTime)}'),
          ],
        ),
      ),
    );
  }
}