import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_instance.dart';

class TimeToBeatWidget extends ConsumerWidget {
  final GameInstance game;

  const TimeToBeatWidget({super.key, required this.game});

  String _formatTime(int seconds) {
    final hours = (seconds / 3600).round();
    return '$hours hours';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    if ( game.timeToBeat == null) {
      return const Text('Time to Beat: Not available');
    }

    final ttb = game.timeToBeat!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Time to Beat:'),
        const SizedBox(height: 4),
        if (ttb.hastily != null)
          Text('  Hastily: ${_formatTime(ttb.hastily!)}'),
        if (ttb.normally != null)
          Text('  Normally: ${_formatTime(ttb.normally!)}'),
        if (ttb.completely != null)
          Text('  Completely: ${_formatTime(ttb.completely!)}'),
      ],
    );
  }
}
