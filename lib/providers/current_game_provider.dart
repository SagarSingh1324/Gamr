import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/current_session_notifier.dart';
import '../models/current_session.dart';

final currentGameProvider =
    NotifierProvider<CurrentSessionNotifier, CurrentSession?>(
  () => CurrentSessionNotifier(),
);
