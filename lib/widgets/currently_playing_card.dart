import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_instance.dart';
import '../providers/current_session_provider.dart';
import '../widgets/time_to_beat.dart'; 

class CurrentlyPlayingCard extends ConsumerWidget {
  final VoidCallback onMarkCompleted;
  final VoidCallback onLogSession;

  const CurrentlyPlayingCard({
    super.key, 
    required this.onMarkCompleted, 
    required this.onLogSession,
    });

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  bool _isFiniteGame(GameInstance game) {
    final modes = game.gameModes;
    return (modes.contains(1) || modes.contains(3)) && !modes.contains(2);
  }

  Duration? _getExpectedCompletionTime(GameInstance game) {
    if (game.hasTimeToBeat && _isFiniteGame(game)) {
      final normalTime = game.normalCompletionTime;
      if (normalTime != null) return Duration(seconds: normalTime);
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final controller = ref.read(currentSessionProvider.notifier);

    if (session == null) {
      return const Center(child: Text("No game is currently being tracked."));
    }

    final game = session.game;
    final isTracking = session.isPlaying;
    final elapsed = session.elapsed;

    final totalPlayed = session.totalPlaytime;
    final genreText = game.genres.isNotEmpty
        ? game.genres.map((g) => g.name).join(', ')
        : "Unknown Genre";

    final isFinite = _isFiniteGame(game);
    final expectedTime = _getExpectedCompletionTime(game);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game cover
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              'https:${game.cover.url.replaceFirst('t_thumb', 't_1080p')}',
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),

                if (session.startTime != null)
                  Text(
                    "Started on: ${session.startTime!.toLocal().toString().split(' ')[0]}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          controller.markCompleted();
                          onMarkCompleted();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Mark as Completed"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          controller.logSession();
                          onLogSession(); 
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Log Session"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(Icons.videogame_asset, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        genreText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Progress section
                if (isFinite && expectedTime != null) ...[
                  Text("Progress: ${_formatDuration(totalPlayed)} / ${_formatDuration(expectedTime)}"),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: expectedTime.inSeconds > 0
                        ? (totalPlayed.inSeconds / expectedTime.inSeconds).clamp(0.0, 1.0)
                        : 0.0,
                    backgroundColor: Colors.grey[300],
                    color: Theme.of(context).colorScheme.primary,
                    minHeight: 6,
                  ),
                  const SizedBox(height: 12),

                  // TimeToBeatWidget below the progress bar
                  TimeToBeatWidget(game: game),
                ] else ...[
                  Text("Total Time Played: ${_formatDuration(totalPlayed)}"),
                  const SizedBox(height: 4),
                  Text(
                    "Current Session: ${_formatDuration(elapsed)}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Still show TimeToBeatWidget even if not progressable
                  TimeToBeatWidget(game: game),
                ],

                OutlinedButton.icon(
                  onPressed: () {
                    isTracking ? controller.pause() : controller.resume();
                  },
                  icon: Icon(isTracking ? Icons.pause : Icons.play_arrow),
                  label: Text(isTracking ? 'Pause' : 'Start'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
