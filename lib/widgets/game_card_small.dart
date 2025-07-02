import 'package:flutter/material.dart';
import '../models/game_instance.dart';

class GameInstanceCardSmall extends StatelessWidget {
  final GameInstance item;

  const GameInstanceCardSmall({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: SizedBox(
        height: 80,
        child: Row(
          children: [
            // Small Cover Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              child: Image.network(
                'https:${item.cover.url.replaceFirst('t_thumb', 't_thumb')}',
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
            ),
            const SizedBox(width: 12),
            // Game Name
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Info Button
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showGameInfoDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showGameInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${item.name}'),
            const SizedBox(height: 8),
            Text('Genres: ${item.genres.isNotEmpty 
                ? item.genres.map((genre) => genre.name).join(', ')
                : 'No genres available'}'),
            const SizedBox(height: 8),
            Text('Modes: ${item.gameModes.isEmpty ? 'Not specified' : item.gameModes.map((mode) {
              switch (mode) {
                case 1:
                  return 'Singleplayer';
                case 2:
                  return 'Multiplayer';
                case 3:
                  return 'Co-Op';
                default:
                  return 'Unknown';
              }
            }).join(', ')}'),
            const SizedBox(height: 8),
            Text('Summary: ${item.summary}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
