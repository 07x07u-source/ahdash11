import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AhdashPictogram {
  win('assets/pictograms/ahdash_win.png'),
  champion('assets/pictograms/ahdash_champion.png'),
  tournament('assets/pictograms/ahdash_tournament.png'),
  draw('assets/pictograms/ahdash_draw.png'),
  premium('assets/pictograms/ahdash_premium.png'),
  categoriesStep('assets/pictograms/ahdash_categories_step.png'),
  teamsStep('assets/pictograms/ahdash_teams_step.png'),
  questionStep('assets/pictograms/ahdash_question_step.png'),
  emptyGames('assets/pictograms/ahdash_empty_games.png'),
  emptyFriends('assets/pictograms/ahdash_empty_friends.png'),
  twoChances('assets/pictograms/helpers/ahdash_two_chances.png'),
  callFriend('assets/pictograms/helpers/ahdash_call_friend.png'),
  risk('assets/pictograms/helpers/ahdash_risk.png'),
  bench('assets/pictograms/helpers/ahdash_bench.png'),
  pass('assets/pictograms/helpers/ahdash_pass.png');

  const AhdashPictogram(this.assetPath);

  final String assetPath;
}

enum AhdashPictogramTone { standard, achievement, inverse, success, muted }

enum AhdashPictogramScale {
  inline,
  helper,
  compactFeature,
  emptyState,
  sectionIdentity,
  result,
  tournamentDraw,
  premium,
  howToPlay,
  champion,
  hero;

  double resolve(BuildContext context, BoxConstraints constraints) {
    final viewport = MediaQuery.sizeOf(context);
    final widthFactor = ((viewport.width - 844) / (1280 - 844))
        .clamp(0.0, 1.0)
        .toDouble();
    final heightFactor = ((viewport.height - 390) / (720 - 390))
        .clamp(0.0, 1.0)
        .toDouble();
    final factor = math.min(widthFactor, heightFactor);
    final range = switch (this) {
      AhdashPictogramScale.inline => (32.0, 40.0),
      AhdashPictogramScale.helper => (52.0, 64.0),
      AhdashPictogramScale.compactFeature => (56.0, 72.0),
      AhdashPictogramScale.emptyState => (72.0, 96.0),
      AhdashPictogramScale.sectionIdentity => (72.0, 96.0),
      AhdashPictogramScale.result => (96.0, 128.0),
      AhdashPictogramScale.tournamentDraw => (96.0, 128.0),
      AhdashPictogramScale.premium => (88.0, 112.0),
      AhdashPictogramScale.howToPlay => (72.0, 104.0),
      AhdashPictogramScale.champion => (104.0, 152.0),
      AhdashPictogramScale.hero => (120.0, 160.0),
    };
    var resolved = range.$1 + ((range.$2 - range.$1) * factor);
    final finiteWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : resolved;
    final finiteHeight = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : resolved;
    resolved = math.min(resolved, math.min(finiteWidth, finiteHeight));
    return math.max(0, resolved);
  }
}

final class AhdashPictogramView extends StatelessWidget {
  const AhdashPictogramView({
    required this.pictogram,
    this.size,
    this.scale,
    this.tone = AhdashPictogramTone.standard,
    this.color,
    this.semanticLabel,
    super.key,
  }) : assert(size == null || scale == null);

  final AhdashPictogram pictogram;
  static const sourcePixelSize = 1024;

  final double? size;
  final AhdashPictogramScale? scale;
  final AhdashPictogramTone tone;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (scale case final adaptiveScale?) {
      return LayoutBuilder(
        builder: (context, constraints) =>
            _buildImage(context, adaptiveScale.resolve(context, constraints)),
      );
    }
    return _buildImage(context, size ?? 48);
  }

  Widget _buildImage(BuildContext context, double resolvedSize) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = math.min(
      sourcePixelSize,
      (resolvedSize * devicePixelRatio).ceil(),
    );
    final tint = color ?? _toneColor(context);
    return SizedBox.square(
      dimension: resolvedSize,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
        child: Image.asset(
          pictogram.assetPath,
          width: resolvedSize,
          height: resolvedSize,
          fit: BoxFit.contain,
          cacheWidth: cacheSize,
          cacheHeight: cacheSize,
          filterQuality: FilterQuality.high,
          semanticLabel: semanticLabel,
          excludeFromSemantics: semanticLabel == null,
        ),
      ),
    );
  }

  Color _toneColor(BuildContext context) {
    final colors = context.ahdashColors;
    return switch (tone) {
      AhdashPictogramTone.standard => colors.textPrimary,
      AhdashPictogramTone.achievement => colors.gold,
      AhdashPictogramTone.inverse => colors.primaryForeground,
      AhdashPictogramTone.success => colors.success,
      AhdashPictogramTone.muted => colors.disabled,
    };
  }
}

final class AhdashPictogramReveal extends StatelessWidget {
  const AhdashPictogramReveal({
    required this.child,
    this.duration = const Duration(milliseconds: 420),
    super.key,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.88, end: 1),
      duration: duration,
      curve: Curves.easeOutBack,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: ((value - 0.88) / 0.12).clamp(0, 1),
        child: Transform.scale(scale: value, child: child),
      ),
    );
  }
}
