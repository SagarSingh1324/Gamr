import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_instance.dart';
import '../notifiers/home_notifier.dart';

final homeProvider = AsyncNotifierProvider<HomeNotifier, Map<String, List<GameInstance>>>(
  HomeNotifier.new,
);
