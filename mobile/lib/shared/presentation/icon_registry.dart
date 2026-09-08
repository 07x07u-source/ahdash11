import 'package:flutter/material.dart';

IconData iconForName(String name) => switch (name) {
  'visibility' => Icons.visibility_rounded,
  'swap_horiz' => Icons.swap_horiz_rounded,
  'emoji_events' => Icons.emoji_events_rounded,
  'groups' => Icons.groups_rounded,
  'stadium' => Icons.stadium_rounded,
  'workspace_premium' => Icons.workspace_premium_rounded,
  _ => Icons.sports_soccer_rounded,
};
