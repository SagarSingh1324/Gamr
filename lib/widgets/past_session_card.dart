import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamr/providers/game_library_provider.dart';
import '../models/past_session.dart';
import '../models/current_session.dart';
import '../providers/current_session_provider.dart';

class PastSessionCard extends ConsumerWidget {
  final PastSession session;
  final VoidCallback? onRemove;

  const PastSessionCard({
    super.key,
    required this.session,
    this.onRemove,
  });

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = session.completedAt.millisecondsSinceEpoch != 0;
    final completedText = isCompleted
        ? session.completedAt.toLocal().toString().split(' ')[0]
        : "Not yet";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game info
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Image.network(
                'https:${session.game.cover.url.replaceFirst('t_thumb', 't_thumb')}',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
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

            // Action buttons (only if not completed)
            if (!isCompleted)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      final controller = ref.read(currentSessionProvider.notifier);
                      controller.startGame(session.game);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Session resumed!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                  onPressed: () {
                    final gameSessionController = ref.read(currentSessionProvider.notifier);
                    final gameLibraryController = ref.read(gameLibraryProvider.notifier);

                    final currentSession = CurrentSession(
                      game: session.game,
                      startTime: session.startedAt,
                      totalPlaytime: session.totalPlaytime,
                      elapsed: Duration(seconds:0),
                      isPlaying: false,
                    );

                    gameLibraryController.addToCompleted(currentSession);
                    gameSessionController.markCompleted();

                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Marked as completed!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                    icon: const Icon(Icons.check),
                    label: const Text('Mark Completed'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
