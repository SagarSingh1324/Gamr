import 'package:flutter/material.dart';
import '../models/game_instance.dart'; 

class CurrentlyPlayingCard extends StatelessWidget {
  final GameInstance game;
  final DateTime startDate;
  final double progress;
  final VoidCallback onMarkCompleted;

  const CurrentlyPlayingCard({
    super.key,
    required this.game,
    required this.startDate,
    required this.progress,
    required this.onMarkCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final String genreText = game.genres.isNotEmpty
        ? game.genres.map((genre) => genre.name).join(', ')
        : "Unknown Genre";

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
                'https:${game.cover.url.replaceFirst('t_thumb', 't_1080p')}',
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 180,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            ),

          // Game Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  "Started on: ${startDate.toLocal().toString().split(' ')[0]}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: onMarkCompleted,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Mark as Completed"),
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
                    const SizedBox(width: 6),
                    Text("${(progress * 100).round()}%"),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    color: Theme.of(context).colorScheme.primary,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
