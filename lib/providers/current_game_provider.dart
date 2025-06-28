import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/current_game_notifier.dart';
import '../models/current_game_session.dart';

final currentGameProvider =
    NotifierProvider<CurrentGameNotifier, CurrentGameSession?>(
  () => CurrentGameNotifier(),
);
