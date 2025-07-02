import 'package:flutter/material.dart';

class IconPreserver {
  static const Map<String, IconData> iconMap = {
    'star': Icons.star,
    'favorite': Icons.favorite,
    'home': Icons.home,
    'videogame': Icons.videogame_asset,
    'bookmark': Icons.bookmark,
    'rocket': Icons.rocket_launch,
    'play': Icons.play_arrow,
    'stop': Icons.stop,
    'pause': Icons.pause,
    'done': Icons.done,
    'schedule': Icons.schedule,
    'history': Icons.history,
    'list': Icons.list,
    'trending': Icons.trending_up,
    'new': Icons.fiber_new,
    'fire': Icons.whatshot,
    'thumbs_up': Icons.thumb_up,
    'settings': Icons.settings,
    'explore': Icons.explore,
    'search': Icons.search,
    'checklist': Icons.checklist,
    'check_circle': Icons.check_circle,
    'download': Icons.download,
    'upload': Icons.upload,
    'lock': Icons.lock,
    'unlock': Icons.lock_open,
    'refresh': Icons.refresh,
    'person': Icons.person,
    'group': Icons.group,
    'calendar': Icons.calendar_today,
    'alarm': Icons.alarm,
    'note': Icons.note,
    'music': Icons.music_note,
    'movie': Icons.movie,
    'gamepad': Icons.sports_esports,
    'trophy': Icons.emoji_events,
    'medal': Icons.military_tech,
    'flag': Icons.flag,
    'gift': Icons.card_giftcard,
    'info': Icons.info,
    'warning': Icons.warning,
    'edit': Icons.edit,
    'delete': Icons.delete,
  };

  static void preserveIcons() {
    for (final icon in iconMap.values) {
      Icon(icon);
    }
  }
}
