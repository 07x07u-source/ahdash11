import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/ahdash_pictograms.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/game_ui.dart';
import '../../../shared/presentation/measured_v9.dart';
import '../../party/presentation/party_game_controller.dart';
import '../domain/game_mode.dart';

final class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({
    required this.gameType,
    this.initialFormat,
    super.key,
  });

  final GameType gameType;
  final String? initialFormat;

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

final class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  late GameFormat _format;

  @override
  void initState() {
    super.initState();
    _format = switch (widget.initialFormat) {
      'practice' => GameFormat.practice,
      _ => GameFormat.localParty,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    if (!widget.gameType.isEnabled) {
      return BrandScaffold(
        appBar: AppBar(title: Text(widget.gameType.titleAr)),
        body: const SafeArea(
          top: false,
          child: ResponsiveContent(
            child: Center(
              child: Text('هذا النوع قريبًا بعد اكتمال التحقق من الخادم.'),
            ),
          ),
        ),
      );
    }
    final metrics = context.v9Metrics;
    return BrandScaffold(
      body: AhdashGameWorld(
        child: AhdashV9Frame(
          child: Column(
            children: [
              AhdashV9TopBar(
                title: 'تجهيز المباراة',
                kicker: widget.gameType.titleAr,
              ),
              SizedBox(height: metrics.sectionGap),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'كيف ودك تلعب؟',
                                    style: TextStyle(
                                      fontSize: metrics.heroSize,
                                      height: 1.05,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.gameType.descriptionAr} • ${_format == GameFormat.localParty ? '36' : '15'} سؤالًا',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: metrics.bodySize,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!metrics.compact)
                              Text(
                                'اختر المسار ثم ابدأ مباشرة',
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: metrics.metadataSize,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: metrics.sectionGap),
                        SizedBox(
                          height: metrics.touchTarget,
                          child: Row(
                            children: [
                              for (final format in const [
                                GameFormat.localParty,
                                GameFormat.practice,
                              ]) ...[
                                Expanded(
                                  child: _FormatTab(
                                    format: format,
                                    selected: _format == format,
                                    onTap: () =>
                                        setState(() => _format = format),
                                  ),
                                ),
                                if (format != GameFormat.practice)
                                  SizedBox(width: metrics.compact ? 6 : 8),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: metrics.sectionGap),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 220),
                            child: Center(
                              key: ValueKey(_format),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 720,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        AhdashPictogramView(
                                          pictogram:
                                              _format == GameFormat.localParty
                                              ? AhdashPictogram.teamsStep
                                              : AhdashPictogram.questionStep,
                                          scale: metrics.compact
                                              ? AhdashPictogramScale
                                                    .compactFeature
                                              : AhdashPictogramScale
                                                    .sectionIdentity,
                                        ),
                                        SizedBox(
                                          width: metrics.compact ? 18 : 32,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _format.titleAr,
                                                style: TextStyle(
                                                  fontSize: metrics.heroSize,
                                                  height: 1.05,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _format.descriptionAr,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: colors.textSecondary,
                                                  fontSize: metrics.bodySize,
                                                  height: 1.4,
                                                ),
                                              ),
                                              if (!metrics.compact) ...[
                                                const SizedBox(height: 10),
                                                Text(
                                                  _format == GameFormat.practice
                                                      ? 'تدريب غير مصنّف وبدون XP.'
                                                      : 'المضيف يكشف الإجابة ويعتمد النتيجة محليًا.',
                                                  style: TextStyle(
                                                    color: colors.textMuted,
                                                    fontSize:
                                                        metrics.metadataSize,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: metrics.compact ? 14 : 24),
                                    SizedBox(
                                      width: metrics.compact ? 280 : 360,
                                      child: AhdashV9PrimaryAction(
                                        label: _format == GameFormat.practice
                                            ? 'ابدأ التدريب'
                                            : 'جهّز اللعبة الجماعية',
                                        onPressed: _start,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _start() {
    switch (_format) {
      case GameFormat.localParty:
        ref.read(partyGameControllerProvider.notifier).beginNewGame();
        context.go('/party/categories');
      case GameFormat.practice:
        context.push('/solo?gameType=${widget.gameType.slug}');
      case GameFormat.teamChallenge || GameFormat.dailyChallenge:
        context.push('/teams');
    }
  }
}

final class _FormatTab extends StatelessWidget {
  const _FormatTab({
    required this.format,
    required this.selected,
    required this.onTap,
  });

  final GameFormat format;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return Semantics(
      button: true,
      selected: selected,
      label: '${format.titleAr}، ${format.descriptionAr}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? colors.selected : colors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            format.titleAr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? colors.primary : colors.textPrimary,
              fontSize: context.v9Metrics.compact ? 14 : 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
