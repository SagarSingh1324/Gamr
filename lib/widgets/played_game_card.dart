import 'package:flutter/material.dart';
import '../models/played_game.dart';

class PlayedGameCard extends StatelessWidget {
  final PlayedGame playedGame;
  final VoidCallback? onRemove; 

  const PlayedGameCard({super.key, required this.playedGame, this.onRemove});

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final completedText = playedGame.completedAt.millisecondsSinceEpoch == 0
        ? "Not yet"
        : playedGame.completedAt.toLocal().toString().split(' ')[0];

    return Card(
      child: ListTile(
        leading: Image.network('https:${playedGame.game.cover.url}'),
        title: Text(playedGame.game.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Started: ${playedGame.startedAt.toLocal().toString().split(' ')[0]}'),
            Text('Completed: $completedText'),
            Text('Playtime: ${_formatDuration(playedGame.totalPlayTime)}'),
          ],
        ),
      ),
    );
  }
}