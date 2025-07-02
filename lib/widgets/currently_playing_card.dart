import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_instance.dart';
import '../providers/current_session_provider.dart';
import '../widgets/time_to_beat.dart';
import '../models/current_session.dart';
import '../notifiers/current_session_notifier.dart';

class CurrentlyPlayingCard extends ConsumerStatefulWidget {
  final VoidCallback onMarkCompleted;
  final VoidCallback onLogSession;

  const CurrentlyPlayingCard({
    super.key,
    required this.onMarkCompleted,
    required this.onLogSession,
  });

  @override
  ConsumerState<CurrentlyPlayingCard> createState() => _CurrentlyPlayingCardState();
}

class _CurrentlyPlayingCardState extends ConsumerState<CurrentlyPlayingCard> {
  bool _isCompact = false;

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  Duration? _getExpectedCompletionTime(GameInstance game) {
    if (game.hasTimeToBeat) {
      final normalTime = game.normalCompletionTime;
      if (normalTime != null) return Duration(seconds: normalTime);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
    final expectedTime = _getExpectedCompletionTime(game);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(12),
      child: _isCompact ? _buildCompactView(context, game, elapsed, isTracking, controller) : _buildExpandedView(context, game, session, elapsed, totalPlayed, genreText, expectedTime, isTracking, controller),
    );
  }

  Widget _buildCompactView(BuildContext context, GameInstance game, Duration elapsed, bool isTracking, CurrentSessionNotifier controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https:${game.cover.url}',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  width: 60,
                  height: 60,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Game Name and Session Playtime
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Session: ${_formatDuration(elapsed)}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Toggle Button
          IconButton(
            icon: const Icon(Icons.expand_more),
            onPressed: () => setState(() => _isCompact = false),
            tooltip: 'Expand',
          ),
          // Pause/Resume Button
          IconButton(
            icon: Icon(isTracking ? Icons.pause : Icons.play_arrow),
            onPressed: () => isTracking ? controller.pause() : controller.resume(),
            tooltip: isTracking ? 'Pause' : 'Start',
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedView(
    BuildContext context,
    GameInstance game,
    CurrentSession session,
    Duration elapsed,
    Duration totalPlayed,
    String genreText,
    Duration? expectedTime,
    bool isTracking,
    CurrentSessionNotifier controller,
  ) {
    return Column(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      game.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.expand_less),
                    onPressed: () => setState(() => _isCompact = true),
                    tooltip: 'Collapse',
                  ),
                ],
              ),
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
                        widget.onMarkCompleted();
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
                        widget.onLogSession();
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
              Text("Previous playtime: ${_formatDuration(totalPlayed)}"),
              Text("Session playtime: ${_formatDuration(elapsed)}"),
              const SizedBox(height: 10),
              if (expectedTime != null) ...[
                Text("Progress: ${_formatDuration(totalPlayed + elapsed)} / ${_formatDuration(expectedTime)}"),
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
    );
  }
}
