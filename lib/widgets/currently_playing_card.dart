import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_instance.dart';

class CurrentlyPlayingCard extends StatefulWidget {
  final GameInstance game;
  final DateTime startDate;
  final Duration previouslyPlayed;
  final Duration? expectedTime; // Optional for finite games
  final VoidCallback onMarkCompleted;

  const CurrentlyPlayingCard({
    super.key,
    required this.game,
    required this.startDate,
    required this.previouslyPlayed,
    this.expectedTime,
    required this.onMarkCompleted,
  });

  @override
  State<CurrentlyPlayingCard> createState() => _CurrentlyPlayingCardState();
}

class _CurrentlyPlayingCardState extends State<CurrentlyPlayingCard> {
  bool _isTracking = false;
  Timer? _timer;
  Duration _currentSession = Duration.zero;

  void _toggleTracking() {
    setState(() {
      _isTracking = !_isTracking;
      if (_isTracking) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {
            _currentSession += const Duration(seconds: 1);
          });
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  bool _isFiniteGame() {
    // Treat as finite if:
    // Only singleplayer(1) or co-op(3), and no multiplayer(2)
    final modes = widget.game.gameModes;
    return (modes.contains(1) || modes.contains(3)) && !modes.contains(2);
  }

  Duration? _getExpectedCompletionTime() {
    // Return expected time from parameter first, then try to get from game data
    if (widget.expectedTime != null) {
      return widget.expectedTime;
    }
    
    // Return normal completion time if available and game is finite
    if (_isFiniteGame() && widget.game.hasTimeToBeat) {
      final normalTime = widget.game.normalCompletionTime;
      if (normalTime != null) {
        return Duration(seconds: normalTime);
      }
    }
    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPlayed = widget.previouslyPlayed + _currentSession;
    final genreText = widget.game.genres.isNotEmpty
        ? widget.game.genres.map((g) => g.name).join(', ')
        : "Unknown Genre";

    final isFinite = _isFiniteGame();
    // final isFinite = false;
    final expectedTime = _getExpectedCompletionTime();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              'https:${widget.game.cover.url.replaceFirst('t_thumb', 't_1080p')}',
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

          // Game Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.game.name,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  "Started on: ${widget.startDate.toLocal().toString().split(' ')[0]}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: widget.onMarkCompleted,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Mark as Completed"),
                ),
                const SizedBox(height: 12),

                // Genre row
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

                // Time display logic
                if (isFinite && expectedTime != null) ...[
                  Text(
                      "Progress: ${_formatDuration(totalPlayed)} / ${_formatDuration(expectedTime)}"),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: expectedTime.inSeconds > 0 
                        ? (totalPlayed.inSeconds / expectedTime.inSeconds).clamp(0.0, 1.0)
                        : 0.0,
                    backgroundColor: Colors.grey[300],
                    color: Theme.of(context).colorScheme.primary,
                    minHeight: 6,
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  Text("Total Time Played: ${_formatDuration(totalPlayed)}"),
                  const SizedBox(height: 4),
                  Text(
                    "Current Session: ${_formatDuration(_currentSession)}",
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                ],

                // Start/Pause Button
                OutlinedButton.icon(
                  onPressed: _toggleTracking,
                  icon: Icon(_isTracking ? Icons.pause : Icons.play_arrow),
                  label: Text(_isTracking ? 'Pause' : 'Start'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}