import 'package:flutter/material.dart';
import '../models/past_session.dart';

class PastSessionCard extends StatelessWidget {
  final PastSession session;
  final VoidCallback? onRemove; 

  const PastSessionCard({super.key, required this.session, this.onRemove});

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
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
            Text('Playtime: ${_formatDuration(session.totalPlaytime)}'),
          ],
        ),
      ),
    );
  }
}