import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/app_services.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/theme/ahdash_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/presentation/ahdash_pictograms.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/measured_v9.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../../auth/domain/guest_capability_policy.dart';
import '../../auth/presentation/capability_provider.dart';
import '../../support/data/question_report_repository.dart';
import '../../support/domain/question_report.dart';
import '../../tournament/presentation/tournament_controller.dart';
import '../domain/party_game.dart';
import 'party_game_controller.dart';
import 'party_gameplay_visuals.dart';
import 'party_setup_flow.dart';
import 'party_setup_screens.dart';
import 'party_v2_ui.dart';

final class PartyBoardScreen extends ConsumerStatefulWidget {
  const PartyBoardScreen({super.key});

  @override
  ConsumerState<PartyBoardScreen> createState() => _PartyBoardScreenState();
}

final class _PartyBoardScreenState extends ConsumerState<PartyBoardScreen> {
  String? _openingQuestionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(partyGameControllerProvider).session;
      if (session == null) return;
      unawaited(
        ref.read(appServicesProvider).analytics.log('board_viewed', {
          'used_count': session.questions.where((item) => item.used).length,
          'question_count': session.questions.length,
        }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final partyState = ref.watch(partyGameControllerProvider);
    final session = partyState.session;
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/party/categories');
      });
      return const SizedBox.shrink();
    }
    if (session.activeQuestionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(PartySetupFlowResolver.routeForSession(session));
        }
      });
      return const SizedBox.shrink();
    }
    if (session.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/party/result');
      });
    }
    final activeTeam = session.teams[session.turnTeamIndex];
    final metrics = context.v9Metrics;
    final portrait = metrics.portrait;
    final beforeQuestionHelpers = activeTeam.selectedHelpers
        .where(
          (helper) =>
              session.helperDefinition(helper).timing ==
              PartyHelperTiming.beforeQuestion,
        )
        .toList(growable: false);
    final helperActions = beforeQuestionHelpers
        .map(
          (helper) => _CompactHelperAction(
            definition: session.helperDefinition(helper),
            used: activeTeam.usedHelpers.contains(helper),
            active: session.armedHelper == helper,
            onPressed: () {
              final activated = ref
                  .read(partyGameControllerProvider.notifier)
                  .useHelper(helper);
              if (activated) {
                ref.read(feedbackServiceProvider).play(FeedbackCue.selection);
              }
            },
          ),
        )
        .toList(growable: false);
    final undoButton = IconButton(
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      tooltip: 'تراجع عن آخر احتساب',
      onPressed: session.scoreEvents.isEmpty
          ? null
          : () =>
                ref.read(partyGameControllerProvider.notifier).undoLastScore(),
      icon: const Icon(AhdashIcons.undo, size: 20),
    );
    final closeButton = IconButton(
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      tooltip: 'حفظ وخروج',
      onPressed: () => _confirmExit(context),
      icon: const Icon(AhdashIcons.close, size: 20),
    );
    if (portrait) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmExit(context);
        },
        child: BrandScaffold(
          showDevelopmentBadge: false,
          body: PartyV2Canvas(
            child: SafeArea(
              child: _PortraitBoardLayout(
                session: session,
                helperActions: [
                  for (final helper in beforeQuestionHelpers)
                    _PortraitBoardHelperAction(
                      definition: session.helperDefinition(helper),
                      used: activeTeam.usedHelpers.contains(helper),
                      onPressed: () {
                        final activated = ref
                            .read(partyGameControllerProvider.notifier)
                            .useHelper(helper);
                        if (activated) {
                          ref
                              .read(feedbackServiceProvider)
                              .play(FeedbackCue.selection);
                        }
                      },
                    ),
                ],
                onQuestion: _openQuestion,
                interactionLocked: _openingQuestionId != null,
                selectedQuestionId: _openingQuestionId,
                actions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [undoButton, closeButton],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: BrandScaffold(
        body: PartyV2Canvas(
          child: AhdashV10Frame(
            padding: EdgeInsets.fromLTRB(
              AhdashV10Metrics.of(context).gutter,
              8,
              AhdashV10Metrics.of(context).gutter,
              10,
            ),
            child: Column(
              children: [
                if (!portrait && !metrics.compact) ...[
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'لوحة المنافسة',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'اختر مربعًا لبدء السؤال',
                              style: TextStyle(
                                color: context.ahdashColors.textMuted,
                                fontSize: metrics.metadataSize,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ...helperActions,
                        undoButton,
                        closeButton,
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                SizedBox(
                  height: portrait
                      ? 108
                      : metrics.compact
                      ? 48
                      : 50,
                  child: portrait
                      ? Column(
                          children: [
                            Expanded(child: _ScoreRibbon(session: session)),
                            Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(children: helperActions),
                                  ),
                                ),
                                undoButton,
                                closeButton,
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _ScoreRibbon(session: session)),
                            if (metrics.compact) ...[
                              const SizedBox(width: 6),
                              ...helperActions,
                              undoButton,
                              closeButton,
                            ],
                          ],
                        ),
                ),
                SizedBox(height: metrics.compact ? 4 : 10),
                Expanded(
                  child: RepaintBoundary(
                    key: const ValueKey('party-board-grid'),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        Widget boardColumn(int index) => _BoardColumn(
                          category: session.categories[index],
                          owner: session
                              .teams[session.categories[index].ownerTeamIndex],
                          interactionLocked: _openingQuestionId != null,
                          selectedQuestionId: _openingQuestionId,
                          onQuestion: _openQuestion,
                        );

                        if (portrait) {
                          final boardHeight = math.min(
                            constraints.maxHeight,
                            390.0,
                          );
                          return Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              height: boardHeight,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (
                                    var index = 0;
                                    index < session.categories.length;
                                    index++
                                  ) ...[
                                    Expanded(child: boardColumn(index)),
                                    if (index != session.categories.length - 1)
                                      const SizedBox(width: 4),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (
                              var index = 0;
                              index < session.categories.length;
                              index++
                            ) ...[
                              Expanded(child: boardColumn(index)),
                              if (index != session.categories.length - 1)
                                SizedBox(width: metrics.compact ? 3 : 7),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openQuestion(String id) async {
    if (_openingQuestionId != null) return;
    setState(() => _openingQuestionId = id);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final opened = ref
        .read(partyGameControllerProvider.notifier)
        .chooseQuestion(id);
    if (!opened) {
      setState(() => _openingQuestionId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح السؤال. حاول مرة أخرى.')),
      );
      return;
    }
    await ref.read(feedbackServiceProvider).play(FeedbackCue.navigation);
    if (mounted) context.go('/party/question');
  }
}

final class _PortraitBoardLayout extends StatelessWidget {
  const _PortraitBoardLayout({
    required this.session,
    required this.helperActions,
    required this.onQuestion,
    required this.interactionLocked,
    required this.selectedQuestionId,
    required this.actions,
  });

  final Widget actions;
  final PartyGameSession session;
  final List<Widget> helperActions;
  final ValueChanged<String> onQuestion;
  final bool interactionLocked;
  final String? selectedQuestionId;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    final boardHeight = compact ? 380.0 : 400.0;
    final horizontal = compact ? 12.0 : 24.0;
    return Column(
      children: [
        SizedBox(
          height: compact ? 55 : 57,
          child: _ScoreRibbon(session: session),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: AhdashPageHeader(
            title: 'لوحة اللعب',
            subtitle: 'اختر قيمة السؤال من إحدى الفئات',
            trailing: actions,
          ),
        ),
        SizedBox(
          key: const ValueKey('party-board-grid'),
          height: boardHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (
                  var index = 0;
                  index < session.categories.length;
                  index++
                ) ...[
                  Expanded(
                    child: _BoardColumn(
                      category: session.categories[index],
                      owner: session
                          .teams[session.categories[index].ownerTeamIndex],
                      interactionLocked: interactionLocked,
                      selectedQuestionId: selectedQuestionId,
                      onQuestion: onQuestion,
                    ),
                  ),
                  if (index != session.categories.length - 1)
                    SizedBox(width: compact ? 5 : 8),
                ],
              ],
            ),
          ),
        ),
        const Spacer(),
        if (helperActions.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 24 : 24),
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  for (
                    var index = 0;
                    index < helperActions.length;
                    index++
                  ) ...[
                    Expanded(child: helperActions[index]),
                    if (index != helperActions.length - 1)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

final class _PortraitBoardHelperAction extends StatelessWidget {
  const _PortraitBoardHelperAction({
    required this.definition,
    required this.used,
    required this.onPressed,
  });

  final PartyHelperDefinition definition;
  final bool used;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: used ? null : onPressed,
    icon: AhdashPictogramView(
      pictogram: partyHelperPictogram(definition.id, definition.iconKey),
      size: 18,
      tone: AhdashPictogramTone.success,
    ),
    label: Text(
      definition.id.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

final class _BoardColumn extends StatelessWidget {
  const _BoardColumn({
    required this.category,
    required this.owner,
    required this.interactionLocked,
    required this.selectedQuestionId,
    required this.onQuestion,
  });

  final PartyCategorySnapshot category;
  final PartyTeam owner;
  final bool interactionLocked;
  final String? selectedQuestionId;
  final ValueChanged<String> onQuestion;

  @override
  Widget build(BuildContext context) {
    final portrait =
        MediaQuery.sizeOf(context).height >= MediaQuery.sizeOf(context).width;
    return Column(
      children: [
        Container(
          height: portrait
              ? 64
              : context.v9Metrics.compact
              ? 45
              : 70,
          padding: EdgeInsets.symmetric(
            horizontal: context.v9Metrics.compact ? 5 : 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: portrait ? AppColors.ink : context.ahdashColors.surface,
            borderRadius: portrait ? BorderRadius.circular(11) : null,
            border: portrait
                ? Border(
                    bottom: BorderSide(
                      color: Color(category.colorValue),
                      width: 4,
                    ),
                  )
                : Border(
                    top: BorderSide(
                      color: Color(category.colorValue),
                      width: 3,
                    ),
                    bottom: BorderSide(color: context.ahdashColors.border),
                  ),
          ),
          child: portrait
              ? Tooltip(
                  message: category.name,
                  child: Center(
                    child: Text(
                      category.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: portrait ? Colors.white : null,
                        fontSize: portrait
                            ? 12
                            : context.v9Metrics.compact
                            ? 12
                            : 15,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (!context.v9Metrics.compact) ...[
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PartyTeamDot(color: Color(owner.colorValue), size: 6),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              owner.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(owner.colorValue),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
        ),
        SizedBox(height: portrait ? (context.v9Metrics.compact ? 2 : 4) : 4),
        for (final question in category.questions)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: portrait
                    ? (context.v9Metrics.compact ? 2 : 4)
                    : (context.v9Metrics.compact ? 1 : 2),
              ),
              child: _PointTile(
                question: question,
                color: Color(category.colorValue),
                enabled: !interactionLocked,
                selected: selectedQuestionId == question.id,
                onTap: () => onQuestion(question.id),
              ),
            ),
          ),
      ],
    );
  }
}

final class _PointTile extends StatelessWidget {
  const _PointTile({
    required this.question,
    required this.color,
    required this.enabled,
    required this.selected,
    required this.onTap,
  });

  final PartyQuestionSnapshot question;
  final Color color;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final portrait =
        MediaQuery.sizeOf(context).height >= MediaQuery.sizeOf(context).width;
    return Semantics(
      button: true,
      enabled: !question.used && enabled,
      selected: selected,
      label: question.used
          ? '${question.pointValue} نقطة، مستخدمة'
          : selected
          ? '${question.pointValue} نقطة، جارٍ فتح السؤال'
          : '${question.pointValue} نقطة',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: question.used || !enabled ? null : onTap,
          child: AnimatedScale(
            scale: selected ? 0.965 : 1,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : PartyV2Motion.page,
            child: AnimatedOpacity(
              opacity: question.used ? 0.52 : 1,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : PartyV2Motion.page,
              child: AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : PartyV2Motion.page,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : question.used
                      ? AppColors.paper2
                      : AppColors.paper0,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  border: Border.all(
                    color: selected
                        ? AppColors.ink
                        : question.used
                        ? context.ahdashColors.border.withValues(alpha: 0.55)
                        : color.withValues(alpha: 0.4),
                    width: selected ? 1.6 : 1,
                  ),
                  boxShadow: !question.used && !selected
                      ? const [
                          BoxShadow(
                            color: Color(0x14191714),
                            offset: Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Hero(
                    tag: 'party-question-${question.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: selected
                          ? SizedBox.square(
                              dimension: context.v9Metrics.compact ? 18 : 22,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.ink,
                              ),
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '${question.pointValue}',
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(
                                    color: question.used
                                        ? context.ahdashColors.textMuted
                                        : context.ahdashColors.textPrimary,
                                    decoration: question.used
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationThickness: question.used
                                        ? 2
                                        : null,
                                    fontWeight: FontWeight.w900,
                                    fontSize: portrait
                                        ? 15
                                        : context.v9Metrics.compact
                                        ? 20
                                        : 27,
                                  ),
                                ),
                                if (question.used)
                                  Transform.translate(
                                    offset: Offset(13, 13),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 11,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class PartyQuestionScreen extends ConsumerStatefulWidget {
  const PartyQuestionScreen({this.fixedNow, super.key});

  /// Deterministic clock seam for widget/Golden tests. Production leaves it
  /// null so the persisted timer start remains the only source of truth.
  final DateTime? fixedNow;

  @override
  ConsumerState<PartyQuestionScreen> createState() =>
      _PartyQuestionScreenState();
}

final class _PartyQuestionScreenState
    extends ConsumerState<PartyQuestionScreen> {
  String? _trackedQuestionId;

  void _handleTimerExpired() {
    if (!mounted) return;
    final controller = ref.read(partyGameControllerProvider.notifier);
    if (controller.offerSteal()) {
      ref.read(feedbackServiceProvider).play(FeedbackCue.tap);
      return;
    }
    if (controller.revealAnswer()) {
      ref.read(feedbackServiceProvider).play(FeedbackCue.navigation);
      context.go('/party/reveal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(partyGameControllerProvider).session;
    final question = session?.activeQuestion;
    if (session == null || question == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(
            session == null
                ? '/party/categories'
                : PartySetupFlowResolver.routeForSession(session),
          );
        }
      });
      return const SizedBox.shrink();
    }
    if (session.revealed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/party/reveal');
      });
      return const SizedBox.shrink();
    }
    if (_trackedQuestionId != question.id) {
      _trackedQuestionId = question.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          ref.read(appServicesProvider).analytics.log(
            'question_format_viewed',
            {
              'question_format': question.format.name,
              'points': question.pointValue,
            },
          ),
        );
      });
    }
    final category = session.categories.firstWhere(
      (value) => value.id == question.categoryId,
    );
    final activeTeam = session.teams[session.turnTeamIndex];
    final portrait = context.v9Metrics.portrait;
    final afterQuestionHelpers = activeTeam.selectedHelpers
        .where(
          (helper) =>
              session.helperDefinition(helper).timing ==
              PartyHelperTiming.afterQuestion,
        )
        .toList(growable: false);
    final helperActions = afterQuestionHelpers
        .map(
          (helper) => Padding(
            padding: const EdgeInsetsDirectional.only(end: 7),
            child: _CompactHelperAction(
              showLabel: portrait,
              definition: session.helperDefinition(helper),
              used: activeTeam.usedHelpers.contains(helper),
              active: session.armedHelper == helper,
              onPressed: () =>
                  _useAfterQuestionHelper(context, helper, session),
            ),
          ),
        )
        .toList(growable: false);
    final reportButton = portrait || context.v9Metrics.compact
        ? AhdashV9IconButton(
            onPressed: () =>
                _openQuestionReport(context, question.id, session.id),
            icon: AhdashIcons.flag,
            tooltip: 'الإبلاغ عن السؤال',
          )
        : TextButton.icon(
            onPressed: () =>
                _openQuestionReport(context, question.id, session.id),
            icon: const Icon(AhdashIcons.flag, size: 18),
            label: const Text('بلّغ عن السؤال'),
          );
    final canOfferSteal =
        session.ruleConfig.allowSteal &&
        !session.stealActive &&
        session.armedHelper != PartyHelperId.pass;
    final stealButton = OutlinedButton.icon(
      onPressed: canOfferSteal
          ? () {
              if (!ref
                  .read(partyGameControllerProvider.notifier)
                  .offerSteal()) {
                return;
              }
              ref.read(feedbackServiceProvider).play(FeedbackCue.tap);
            }
          : null,
      icon: const Icon(AhdashIcons.pass, size: 18),
      label: Text(portrait ? 'خطف' : 'فرصة خطف'),
    );
    final revealButton = PartyPrimaryButton(
      key: const ValueKey('party-reveal-answer'),
      label: 'اعرض الجواب',
      icon: AhdashIcons.visibility,
      feedback: false,
      onPressed: () {
        final revealed = ref
            .read(partyGameControllerProvider.notifier)
            .revealAnswer();
        if (!revealed) return;
        ref.read(feedbackServiceProvider).play(FeedbackCue.navigation);
        context.go('/party/reveal');
      },
    );
    if (portrait) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmExit(context);
        },
        child: BrandScaffold(
          showDevelopmentBadge: false,
          body: PartyV2Canvas(
            child: SafeArea(
              child: _PortraitQuestionLayout(
                session: session,
                category: category,
                question: question,
                fixedNow: widget.fixedNow,
                onTimerExpired: _handleTimerExpired,
                helperActions: helperActions,
                onSteal: canOfferSteal
                    ? () {
                        if (ref
                            .read(partyGameControllerProvider.notifier)
                            .offerSteal()) {
                          ref
                              .read(feedbackServiceProvider)
                              .play(FeedbackCue.tap);
                        }
                      }
                    : null,
                onReveal: () {
                  final revealed = ref
                      .read(partyGameControllerProvider.notifier)
                      .revealAnswer();
                  if (!revealed) return;
                  ref
                      .read(feedbackServiceProvider)
                      .play(FeedbackCue.navigation);
                  context.go('/party/reveal');
                },
                onReport: () =>
                    _openQuestionReport(context, question.id, session.id),
              ),
            ),
          ),
        ),
      );
    }
    return _PartyGameScaffold(
      portraitTopHeight: 82,
      portraitBottomHeight: 104,
      top: portrait
          ? Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${question.pointValue} نقطة',
                        style: TextStyle(
                          color: Color(category.colorValue),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (session.questionTimerStartedAt != null &&
                          session.questionTimerDurationSeconds != null) ...[
                        const SizedBox(width: 8),
                        _QuestionTimer(
                          startedAt: session.questionTimerStartedAt!,
                          total: session.questionTimerDurationSeconds!,
                          onExpired: _handleTimerExpired,
                          fixedNow: widget.fixedNow,
                        ),
                      ],
                    ],
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    session.stealActive
                        ? 'فرصة خطف · ${session.teams[session.answeringTeamIndex].name}'
                        : 'يجيب ${session.teams[session.answeringTeamIndex].name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: context.v9Metrics.metadataSize,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 8),
                Hero(
                  tag: 'party-question-${question.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      '${question.pointValue} نقطة',
                      style: TextStyle(
                        color: Color(category.colorValue),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  session.stealActive
                      ? 'فرصة خطف · ${session.teams[session.answeringTeamIndex].name}'
                      : 'يجيب ${session.teams[session.answeringTeamIndex].name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: context.v9Metrics.metadataSize,
                  ),
                ),
                if (session.questionTimerStartedAt != null &&
                    session.questionTimerDurationSeconds != null) ...[
                  const SizedBox(width: 12),
                  _QuestionTimer(
                    startedAt: session.questionTimerStartedAt!,
                    total: session.questionTimerDurationSeconds!,
                    onExpired: _handleTimerExpired,
                    fixedNow: widget.fixedNow,
                  ),
                ],
              ],
            ),
      bottom: portrait
          ? Column(
              children: [
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...helperActions,
                      reportButton,
                      const SizedBox(width: 6),
                      SizedBox(width: 104, child: stealButton),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: revealButton),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: helperActions),
                  ),
                ),
                reportButton,
                const SizedBox(width: 6),
                stealButton,
                const SizedBox(width: 6),
                revealButton,
              ],
            ),
      child: PartyEntrance(
        child: Column(
          children: [
            if (session.helperActionDetail != null) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  session.helperActionDetail!,
                  style: TextStyle(
                    color: context.ahdashColors.primary,
                    fontSize: context.v9Metrics.metadataSize,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 5),
            ],
            Expanded(child: PartyQuestionRenderer(question: question)),
          ],
        ),
      ),
    );
  }

  void _useAfterQuestionHelper(
    BuildContext context,
    PartyHelperId helper,
    PartyGameSession session,
  ) {
    if (helper == PartyHelperId.bench) {
      final players = session.teams[1 - session.turnTeamIndex].players;
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.all(18),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const SizedBox(
                width: double.infinity,
                child: Text(
                  'مين يجلس على الدكة لهذا السؤال؟',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              ...players.map(
                (player) => ActionChip(
                  label: Text(player),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _activateHelper(
                      helper,
                      '$player على الدكة لهذا السؤال',
                      actionDetail: player,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
    _activateHelper(
      helper,
      helper == PartyHelperId.pass
          ? 'السؤال انتقل للفريق الآخر'
          : session.helperDefinition(helper).description,
    );
  }

  void _activateHelper(
    PartyHelperId helper,
    String message, {
    String? actionDetail,
  }) {
    final used = ref
        .read(partyGameControllerProvider.notifier)
        .useHelper(helper, actionDetail: actionDetail);
    if (!used) return;
    ref.read(feedbackServiceProvider).play(FeedbackCue.selection);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

final class _PartyRoundBar extends StatelessWidget {
  const _PartyRoundBar({required this.session});

  final PartyGameSession session;

  @override
  Widget build(BuildContext context) => Container(
    height: 37,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(
      color: AppColors.ink,
      border: Border(bottom: BorderSide(color: AppColors.inkSoft)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PartyTeamDot(color: Color(session.teams[0].colorValue), size: 8),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  session.teams[0].name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.paper3,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _arabicDigits(session.scores[0]),
                style: const TextStyle(
                  color: AppColors.paper0,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                _arabicDigits(session.scores[1]),
                style: const TextStyle(
                  color: AppColors.paper0,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  session.teams[1].name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.paper3,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PartyTeamDot(color: Color(session.teams[1].colorValue), size: 8),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _PortraitQuestionLayout extends StatelessWidget {
  const _PortraitQuestionLayout({
    required this.session,
    required this.category,
    required this.question,
    required this.fixedNow,
    required this.onTimerExpired,
    required this.helperActions,
    required this.onSteal,
    required this.onReveal,
    required this.onReport,
  });
  final PartyGameSession session;
  final PartyCategorySnapshot category;
  final PartyQuestionSnapshot question;
  final DateTime? fixedNow;
  final VoidCallback onTimerExpired, onReveal, onReport;
  final List<Widget> helperActions;
  final VoidCallback? onSteal;

  @override
  Widget build(BuildContext context) {
    final gutter = AhdashV10Metrics.of(context).gutter;
    return Column(
      children: [
        _PartyRoundBar(session: session),
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('party-question-content'),
            padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QuestionMetaStrip(
                  category: category.name,
                  points: question.pointValue,
                  team: session.teams[session.answeringTeamIndex],
                  steal: session.stealActive,
                  startedAt: session.questionTimerStartedAt,
                  total: session.questionTimerDurationSeconds,
                  fixedNow: fixedNow,
                  onExpired: onTimerExpired,
                ),
                const SizedBox(height: 14),
                if (question.format == PartyQuestionFormat.image) ...[
                  SizedBox(
                    height: 190,
                    child: _QuestionMedia(
                      question: question,
                      aspectRatio: 1.8,
                      alignment: Alignment.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _PortraitQuestionCard(
                  question: question.text,
                  accent: Color(category.colorValue),
                ),
                if (session.armedHelper != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    selected: true,
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Text(
                        'المساعد مفعّل • ${session.armedHelper!.label}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (helperActions.isNotEmpty || onSteal != null) ...[
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...helperActions,
                    if (onSteal != null)
                      OutlinedButton.icon(
                        onPressed: onSteal,
                        icon: const Icon(AhdashIcons.pass, size: 18),
                        label: const Text('فرصة خطف'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              PartyPrimaryButton(
                key: const ValueKey('party-reveal-answer'),
                label: 'كشف الإجابة',
                icon: AhdashIcons.visibility,
                feedback: false,
                onPressed: onReveal,
              ),
              TextButton(
                onPressed: onReport,
                child: const Text('بلّغ عن السؤال'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _QuestionMetaStrip extends StatelessWidget {
  const _QuestionMetaStrip({
    required this.category,
    required this.points,
    required this.team,
    required this.steal,
    required this.startedAt,
    required this.total,
    required this.fixedNow,
    required this.onExpired,
  });

  final String category;
  final int points;
  final PartyTeam team;
  final bool steal;
  final DateTime? startedAt;
  final int? total;
  final DateTime? fixedNow;
  final VoidCallback onExpired;

  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 4,
          child: _QuestionMetaCell(label: 'الفئة', value: category),
        ),
        const _QuestionMetaDivider(),
        Expanded(
          flex: 3,
          child: _QuestionMetaCell(
            label: steal ? 'فرصة خطف' : 'يجيب',
            value: team.name,
            accent: Color(team.colorValue),
          ),
        ),
        const _QuestionMetaDivider(),
        SizedBox(
          width: 52,
          child: _QuestionMetaCell(
            label: 'النقاط',
            value: _arabicDigits(points),
            accent: AppColors.primary,
          ),
        ),
        const _QuestionMetaDivider(),
        SizedBox(
          width: 44,
          child: startedAt != null && total != null
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 44,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'الوقت',
                          style: TextStyle(
                            color: AppColors.paper3,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        _QuestionTimer(
                          startedAt: startedAt!,
                          total: total!,
                          fixedNow: fixedNow,
                          onExpired: onExpired,
                          textOnly: true,
                          onDark: true,
                        ),
                      ],
                    ),
                  ),
                )
              : const _QuestionMetaCell(
                  label: 'الوقت',
                  value: '—',
                  accent: AppColors.paper0,
                ),
        ),
      ],
    ),
  );
}

final class _QuestionMetaCell extends StatelessWidget {
  const _QuestionMetaCell({
    required this.label,
    required this.value,
    this.accent = AppColors.paper0,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          color: AppColors.paper3,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

final class _QuestionMetaDivider extends StatelessWidget {
  const _QuestionMetaDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 32,
    margin: const EdgeInsets.symmetric(horizontal: 7),
    color: AppColors.inkSoft,
  );
}

final class _PortraitQuestionCard extends StatelessWidget {
  const _PortraitQuestionCard({required this.question, required this.accent});

  final String question;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 176),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.paper1,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.ink, width: 1.25),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F191714),
          offset: Offset(0, 3),
          blurRadius: 0,
        ),
      ],
    ),
    child: Stack(
      children: [
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          child: Container(height: 5, color: accent),
        ),
        PositionedDirectional(
          end: -14,
          bottom: -24,
          child: Text(
            '11',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: AppColors.ink.withValues(alpha: 0.045),
              fontSize: 112,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Center(
            child: Text(
              question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 26,
                height: 1.42,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

String _arabicDigits(int value) {
  const western = '0123456789';
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  return value.toString().split('').map((digit) {
    final index = western.indexOf(digit);
    return index < 0 ? digit : eastern[index];
  }).join();
}

final class _QuestionTimer extends StatefulWidget {
  const _QuestionTimer({
    required this.startedAt,
    required this.total,
    required this.onExpired,
    this.fixedNow,
    this.textOnly = false,
    this.onDark = false,
  });

  final DateTime startedAt;
  final int total;
  final VoidCallback onExpired;
  final DateTime? fixedNow;
  final bool textOnly;
  final bool onDark;

  @override
  State<_QuestionTimer> createState() => _QuestionTimerState();
}

final class _QuestionTimerState extends State<_QuestionTimer>
    with WidgetsBindingObserver {
  Timer? _timer;
  late int _seconds;
  var _didExpire = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncAndSchedule();
  }

  @override
  void didUpdateWidget(covariant _QuestionTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startedAt != widget.startedAt ||
        oldWidget.total != widget.total) {
      _didExpire = false;
      _syncAndSchedule();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncAndSchedule();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _timer?.cancel();
    }
  }

  void _syncAndSchedule() {
    _timer?.cancel();
    final elapsed = (widget.fixedNow ?? DateTime.now())
        .difference(widget.startedAt)
        .inSeconds;
    _seconds = math.max(0, widget.total - elapsed);
    if (_seconds == 0) {
      _expireOnce();
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final elapsed = (widget.fixedNow ?? DateTime.now())
          .difference(widget.startedAt)
          .inSeconds;
      final next = math.max(0, widget.total - elapsed);
      if (next != _seconds) setState(() => _seconds = next);
      if (next == 0) _expireOnce();
    });
  }

  void _expireOnce() {
    _timer?.cancel();
    if (_didExpire) return;
    _didExpire = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onExpired();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final danger = _seconds <= 5;
    final color = danger
        ? context.ahdashColors.dangerTimer
        : context.ahdashColors.primary;
    if (widget.textOnly) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Semantics(
            label: 'باقي $_seconds ثانية',
            child: Text(
              _arabicDigits(_seconds),
              style: TextStyle(
                color: widget.onDark
                    ? danger
                          ? AppColors.gold
                          : AppColors.paper0
                    : AppColors.inkMuted,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Opacity(opacity: 0, child: Text('$_seconds')),
        ],
      );
    }
    return Semantics(
      label: 'باقي $_seconds ثانية',
      child: SizedBox(
        width: 78,
        child: Row(
          children: [
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                value: widget.total <= 0
                    ? 1
                    : (_seconds / widget.total).clamp(0, 1),
                strokeWidth: 3,
                color: color,
                backgroundColor: context.ahdashColors.surfaceMuted,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$_seconds',
              textDirection: TextDirection.ltr,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

final class PartyQuestionRenderer extends StatelessWidget {
  const PartyQuestionRenderer({required this.question, super.key});

  final PartyQuestionSnapshot question;

  @override
  Widget build(BuildContext context) =>
      PartyQuestionRendererRegistry.render(context, question);
}

typedef PartyQuestionWidgetBuilder =
    Widget Function(BuildContext context, PartyQuestionSnapshot question);

/// The released renderer contract. Admin may catalogue future formats, but the
/// mobile game only advertises formats that have a concrete builder here.
abstract final class PartyQuestionRendererRegistry {
  static final Map<PartyQuestionFormat, PartyQuestionWidgetBuilder> _builders =
      {
        PartyQuestionFormat.openAnswer: _renderText,
        PartyQuestionFormat.multipleChoice: _renderText,
        PartyQuestionFormat.trueFalse: _renderText,
        PartyQuestionFormat.image: _renderImage,
        PartyQuestionFormat.imageCrop: _renderImage,
        PartyQuestionFormat.imageBlur: _renderImage,
        PartyQuestionFormat.audio: _renderPlayableMedia,
        PartyQuestionFormat.video: _renderPlayableMedia,
        PartyQuestionFormat.ordering: _renderOrdering,
        PartyQuestionFormat.progressiveHints: _renderHints,
        PartyQuestionFormat.drawing: _renderActivity,
        PartyQuestionFormat.charades: _renderActivity,
        PartyQuestionFormat.secretIdentity: _renderActivity,
        PartyQuestionFormat.numeric: _renderText,
        PartyQuestionFormat.year: _renderText,
      };

  static Set<PartyQuestionFormat> get supportedFormats =>
      Set.unmodifiable(_builders.keys);

  static Widget render(BuildContext context, PartyQuestionSnapshot question) =>
      _builders[question.format]!(context, question);

  static Widget _renderPlayableMedia(
    BuildContext context,
    PartyQuestionSnapshot question,
  ) {
    final isAudio = question.format == PartyQuestionFormat.audio;
    final source = isAudio ? question.audioUrl : question.videoUrl;
    return _SpecialQuestionFrame(
      icon: isAudio ? AhdashIcons.audio : AhdashIcons.play,
      title: question.text,
      instruction: isAudio
          ? 'استمعوا للمقطع ثم قدّموا إجابة واحدة.'
          : 'شاهدوا اللقطة ثم قدّموا إجابة واحدة.',
      action: FilledButton.icon(
        onPressed: source?.isNotEmpty == true
            ? () async {
                final uri = Uri.tryParse(source!);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            : null,
        icon: Icon(isAudio ? AhdashIcons.audio : AhdashIcons.play),
        label: Text(isAudio ? 'تشغيل الصوت' : 'تشغيل الفيديو'),
      ),
    );
  }

  static Widget _renderOrdering(
    BuildContext context,
    PartyQuestionSnapshot question,
  ) => _SpecialQuestionFrame(
    icon: AhdashIcons.random,
    title: question.text,
    instruction:
        'رتبوا العناصر شفهيًا، والمضيف يتحقق من الترتيب بعد كشف الإجابة.',
    action: Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (var index = 0; index < question.orderingItems.length; index++)
          Chip(
            avatar: CircleAvatar(child: Text('${index + 1}')),
            label: Text(question.orderingItems[index]),
          ),
      ],
    ),
  );

  static Widget _renderHints(
    BuildContext context,
    PartyQuestionSnapshot question,
  ) => _ProgressiveHintsQuestion(question: question);

  static Widget _renderActivity(
    BuildContext context,
    PartyQuestionSnapshot question,
  ) {
    final details = switch (question.format) {
      PartyQuestionFormat.drawing => (
        AhdashIcons.edit,
        'يرسم لاعب واحد الإجابة من دون كتابة حروف أو أرقام.',
      ),
      PartyQuestionFormat.charades => (
        AhdashIcons.group,
        'يمثّل لاعب واحد الإجابة من دون كلام، وفريقه يخمّن.',
      ),
      PartyQuestionFormat.secretIdentity => (
        AhdashIcons.visibility,
        'يرى لاعب واحد الهوية سرًا، ويجيب عن أسئلة فريقه بنعم أو لا.',
      ),
      _ => (AhdashIcons.help, 'اتبعوا تعليمات المضيف.'),
    };
    return _SpecialQuestionFrame(
      icon: details.$1,
      title: question.text,
      instruction: details.$2,
    );
  }

  static Widget _renderImage(
    BuildContext context,
    PartyQuestionSnapshot question,
  ) {
    final metrics = context.v9Metrics;
    final questionText = Text(
      question.text,
      textAlign: TextAlign.center,
      style: AhdashTypography.question.copyWith(
        color: context.ahdashColors.textPrimary,
        fontSize: _questionFontSize(metrics, question.text),
        height: 1.3,
        fontWeight: FontWeight.w900,
      ),
    );
    final media = _QuestionMedia(
      question: question,
      aspectRatio: _imageAspectRatio(question),
      alignment: _imageAlignment(question),
    );
    final prompt = Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(metrics.compact ? 8 : 18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'سؤال مصوّر',
                style: TextStyle(
                  color: context.ahdashColors.textMuted,
                  fontSize: metrics.metadataSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: metrics.compact ? 5 : 10),
              questionText,
              if (!metrics.compact) ...[
                const SizedBox(height: 10),
                Text(
                  'لاحظوا تفاصيل الصورة قبل كشف الإجابة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.ahdashColors.textSecondary,
                    fontSize: metrics.metadataSize,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: metrics.compact ? 2 : 6),
      child: metrics.portrait
          ? Column(
              children: [
                Expanded(flex: 6, child: media),
                const SizedBox(height: 14),
                Expanded(flex: 4, child: prompt),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 11, child: media),
                SizedBox(width: metrics.compact ? 12 : 24),
                Expanded(flex: 9, child: prompt),
              ],
            ),
    );
  }

  static Widget _renderText(
    BuildContext context,
    PartyQuestionSnapshot question,
  ) {
    final metrics = context.v9Metrics;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: metrics.compact
              ? math.max(24, (constraints.maxWidth - 668) / 2)
              : math.max(32, (constraints.maxWidth - 840) / 2),
          vertical: metrics.compact ? 8 : 20,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - (metrics.compact ? 16 : 40),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: metrics.compact ? 668 : 840,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 26,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD3C6B2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      question.text,
                      textAlign: TextAlign.center,
                      style: AhdashTypography.question.copyWith(
                        fontSize: _questionFontSize(metrics, question.text),
                        height: metrics.compact ? 1.32 : 1.38,
                        color: context.ahdashColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (question.format == PartyQuestionFormat.trueFalse ||
                        question.format ==
                            PartyQuestionFormat.multipleChoice) ...[
                      SizedBox(height: metrics.compact ? 16 : 24),
                      LayoutBuilder(
                        builder: (context, optionConstraints) {
                          final width = math.max(
                            180.0,
                            (optionConstraints.maxWidth - 12) / 2,
                          );
                          return Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              for (
                                var index = 0;
                                index < question.options.length;
                                index++
                              )
                                SizedBox(
                                  width: width,
                                  child: _PassiveQuestionOption(
                                    index: index,
                                    label: question.options[index],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static double _questionFontSize(AhdashV9Metrics metrics, String question) {
    if (question.length > 100) return metrics.compact ? 24 : 28;
    if (question.length > 60) return metrics.compact ? 26 : 30;
    return metrics.compact ? 28 : 32;
  }

  static double _imageAspectRatio(PartyQuestionSnapshot question) {
    final configured = question.mechanicConfig['aspect_ratio'];
    if (configured is num && configured > 0) {
      return configured.toDouble().clamp(0.65, 2.4);
    }
    final width = question.mechanicConfig['image_width'];
    final height = question.mechanicConfig['image_height'];
    if (width is num && height is num && width > 0 && height > 0) {
      return (width / height).clamp(0.65, 2.4);
    }
    return 16 / 9;
  }

  static Alignment _imageAlignment(PartyQuestionSnapshot question) {
    final focalX = question.mechanicConfig['focal_x'];
    final focalY = question.mechanicConfig['focal_y'];
    if (focalX is! num || focalY is! num) return Alignment.center;
    return Alignment(
      (focalX.toDouble().clamp(0, 1) * 2) - 1,
      (focalY.toDouble().clamp(0, 1) * 2) - 1,
    );
  }
}

final class _SpecialQuestionFrame extends StatelessWidget {
  const _SpecialQuestionFrame({
    required this.icon,
    required this.title,
    required this.instruction,
    this.action,
  });

  final IconData icon;
  final String title;
  final String instruction;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: context.ahdashColors.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AhdashTypography.question.copyWith(
                color: context.ahdashColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              instruction,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.ahdashColors.textSecondary),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    ),
  );
}

final class _ProgressiveHintsQuestion extends StatefulWidget {
  const _ProgressiveHintsQuestion({required this.question});

  final PartyQuestionSnapshot question;

  @override
  State<_ProgressiveHintsQuestion> createState() =>
      _ProgressiveHintsQuestionState();
}

final class _ProgressiveHintsQuestionState
    extends State<_ProgressiveHintsQuestion> {
  var _visibleHints = 0;

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final currentPoints = math.max(
      0,
      question.pointValue - (_visibleHints * question.pointDecayPerHint),
    );
    return _SpecialQuestionFrame(
      icon: AhdashIcons.help,
      title: question.text,
      instruction: _visibleHints == 0
          ? 'ابدؤوا بدون تلميح، ثم اكشفوا تلميحًا عند الحاجة.'
          : question.hints.take(_visibleHints).join('\n• '),
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'قيمة السؤال الحالية: $currentPoints',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _visibleHints < question.hints.length
                ? () => setState(() => _visibleHints += 1)
                : null,
            icon: const Icon(AhdashIcons.visibility),
            label: Text(
              _visibleHints < question.hints.length
                  ? 'اكشف التلميح ${_visibleHints + 1}'
                  : 'ظهرت كل التلميحات',
            ),
          ),
        ],
      ),
    );
  }
}

final class _PassiveQuestionOption extends StatelessWidget {
  const _PassiveQuestionOption({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.ahdashColors.surface.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(AppRadius.small),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text(
            '${index + 1}'.padLeft(2, '0'),
            textDirection: TextDirection.ltr,
            style: AhdashTypography.metadata.copyWith(
              color: context.ahdashColors.textMuted,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AhdashTypography.label,
            ),
          ),
        ],
      ),
    ),
  );
}

final class _QuestionMedia extends ConsumerStatefulWidget {
  const _QuestionMedia({
    required this.question,
    required this.aspectRatio,
    required this.alignment,
  });

  final PartyQuestionSnapshot question;
  final double aspectRatio;
  final Alignment alignment;

  @override
  ConsumerState<_QuestionMedia> createState() => _QuestionMediaState();
}

final class _QuestionMediaState extends ConsumerState<_QuestionMedia> {
  var _retrySeed = 0;
  var _reportedFailure = false;

  @override
  Widget build(BuildContext context) {
    final source = widget.question.imageUrl;
    if (source == null || source.isEmpty) {
      return const _MediaUnavailable();
    }
    final fit = widget.question.format == PartyQuestionFormat.imageCrop
        ? BoxFit.cover
        : BoxFit.contain;
    return Center(
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppRadius.large + 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.large),
            child: ColoredBox(
              color: context.ahdashColors.surfaceMuted,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final pixelRatio = MediaQuery.devicePixelRatioOf(context);
                  final cacheWidth = (constraints.maxWidth * pixelRatio)
                      .round();
                  final cacheHeight = (constraints.maxHeight * pixelRatio)
                      .round();
                  final image = source.startsWith('assets/')
                      ? Image.asset(
                          source,
                          key: ValueKey('party-media-$_retrySeed'),
                          fit: fit,
                          alignment: widget.alignment,
                          cacheWidth: cacheWidth,
                          cacheHeight: cacheHeight,
                          semanticLabel: 'وسائط السؤال',
                          errorBuilder: (_, error, stackTrace) {
                            _reportFailure(error, stackTrace);
                            return _MediaUnavailable(onRetry: _retry);
                          },
                        )
                      : CachedNetworkImage(
                          key: ValueKey('party-media-$_retrySeed'),
                          imageUrl: source,
                          fit: fit,
                          alignment: widget.alignment,
                          memCacheWidth: cacheWidth,
                          memCacheHeight: cacheHeight,
                          fadeInDuration: const Duration(milliseconds: 180),
                          imageBuilder: (_, provider) => Image(
                            image: provider,
                            fit: fit,
                            alignment: widget.alignment,
                            semanticLabel: 'وسائط السؤال',
                          ),
                          placeholder: (_, _) => const _MediaLoading(),
                          errorWidget: (_, _, _) {
                            _reportFailure(
                              const FormatException(
                                'party_question_media_load_failed',
                              ),
                              StackTrace.current,
                            );
                            return _MediaUnavailable(onRetry: _retry);
                          },
                        );
                  return ClipRect(
                    child:
                        widget.question.format == PartyQuestionFormat.imageBlur
                        ? ImageFiltered(
                            imageFilter: ui.ImageFilter.blur(
                              sigmaX: 13,
                              sigmaY: 13,
                            ),
                            child: image,
                          )
                        : image,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _reportFailure(Object error, StackTrace? stackTrace) {
    if (_reportedFailure) return;
    _reportedFailure = true;
    unawaited(
      ref
          .read(appServicesProvider)
          .crashReporter
          .record(
            const FormatException('party_question_media_load_failed'),
            stackTrace ?? StackTrace.current,
          ),
    );
  }

  Future<void> _retry() async {
    final source = widget.question.imageUrl;
    if (source != null && !source.startsWith('assets/')) {
      await CachedNetworkImage.evictFromCache(source);
    }
    if (!mounted) return;
    setState(() {
      _retrySeed += 1;
      _reportedFailure = false;
    });
  }
}

final class _MediaLoading extends StatelessWidget {
  const _MediaLoading();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'جارٍ تحميل وسائط السؤال',
    child: Center(
      child: SizedBox.square(
        dimension: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: context.ahdashColors.primary,
        ),
      ),
    ),
  );
}

final class _MediaUnavailable extends StatelessWidget {
  const _MediaUnavailable({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'تعذر تحميل وسائط السؤال',
    child: ColoredBox(
      color: const Color(0xFF173F34),
      child: PartyGameplayArtwork(
        scene: PartyGameplayArtworkScene.imageFallback,
        onDark: true,
        accent: AppColors.primary,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  AhdashIcons.image,
                  size: 28,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 4),
                const Text(
                  'تعذر تحميل الصورة',
                  style: TextStyle(
                    color: AppColors.paper0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 2),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onRetry,
                    icon: const Icon(AhdashIcons.refresh, size: 16),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

final class PartyRevealScreen extends ConsumerStatefulWidget {
  const PartyRevealScreen({super.key});

  @override
  ConsumerState<PartyRevealScreen> createState() => _PartyRevealScreenState();
}

final class _PartyRevealScreenState extends ConsumerState<PartyRevealScreen> {
  int? _selectedTeam;
  var _selectedNobody = false;
  var _submitting = false;

  bool get _hasSelection => _selectedTeam != null || _selectedNobody;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(partyGameControllerProvider).session;
    final question = session?.activeQuestion;
    if (session == null || question == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(
            session == null
                ? '/party/categories'
                : PartySetupFlowResolver.routeForSession(session),
          );
        }
      });
      return const SizedBox.shrink();
    }
    if (!session.revealed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/party/question');
      });
      return const SizedBox.shrink();
    }
    final awardableTeams =
        session.armedHelper == PartyHelperId.pass || session.stealActive
        ? <int>[session.answeringTeamIndex]
        : <int>[0, 1];
    final portrait = context.v9Metrics.portrait;
    final compact = context.v9Metrics.compact;
    final answerPanel = PartyEntrance(
      offset: 0.04,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.fromSTEB(
            compact ? 12 : 24,
            4,
            compact ? 12 : 24,
            4,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإجابة الصحيحة • ${question.pointValue} نقطة',
                  style: TextStyle(
                    color: context.ahdashColors.textMuted,
                    fontSize: context.v9Metrics.metadataSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: compact ? 5 : 8),
                Semantics(
                  liveRegion: true,
                  label: 'كُشفت الإجابة الصحيحة: ${question.answer}',
                  child: ExcludeSemantics(
                    child: Text(
                      question.answer,
                      key: const ValueKey('party-revealed-answer'),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: context.ahdashColors.success,
                        fontSize: compact ? 31 : 46,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                if (question.alternativeAnswers.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'نقبل أيضًا: ${question.alternativeAnswers.join('، ')}',
                    style: TextStyle(
                      color: context.ahdashColors.textSecondary,
                      fontSize: context.v9Metrics.metadataSize,
                    ),
                  ),
                ],
                SizedBox(height: compact ? 7 : 12),
                Text(
                  question.text,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!compact && question.explanation?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text(
                    question.explanation!,
                    style: TextStyle(
                      color: context.ahdashColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
                if (session.armedHelper != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${session.armedHelper!.label}${session.helperActionDetail == null ? '' : ' • ${session.helperActionDetail}'}',
                    style: TextStyle(
                      color: context.ahdashColors.gold,
                      fontSize: context.v9Metrics.metadataSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    final scorePanel = Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: compact ? 210 : 360,
        ),
        child: AhdashV9Surface(
          key: const ValueKey('party-score-assignment'),
          tone: AhdashV9SurfaceTone.base,
          padding: EdgeInsets.all(compact ? 10 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'النقطة لمين؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.v9Metrics.sectionSize,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: compact ? 5 : 9),
              for (final index in awardableTeams) ...[
                _AwardChoice(
                  team: session.teams[index],
                  points: question.pointValue,
                  selected: _selectedTeam == index,
                  enabled: !_submitting,
                  onTap: () => setState(() {
                    _selectedTeam = index;
                    _selectedNobody = false;
                  }),
                ),
                const SizedBox(height: 6),
              ],
              _NoScoreChoice(
                selected: _selectedNobody,
                enabled: !_submitting,
                onTap: () => setState(() {
                  _selectedTeam = null;
                  _selectedNobody = true;
                }),
              ),
            ],
          ),
        ),
      ),
    );
    if (portrait) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmExit(context);
        },
        child: BrandScaffold(
          showDevelopmentBadge: false,
          body: PartyV2Canvas(
            child: SafeArea(
              child: _PortraitRevealLayout(
                session: session,
                question: question,
                selectedTeam: _selectedTeam,
                selectedNobody: _selectedNobody,
                submitting: _submitting,
                onTeam: (index) => setState(() {
                  _selectedTeam = index;
                  _selectedNobody = false;
                }),
                onNobody: () => setState(() {
                  _selectedTeam = null;
                  _selectedNobody = true;
                }),
                onSubmit: _submitAward,
              ),
            ),
          ),
        ),
      );
    }
    return _PartyGameScaffold(
      top: Row(
        children: [
          Expanded(
            child: Text(
              'كشف الإجابة الصحيحة',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(width: 8),
          _CompactScorePair(session: session),
        ],
      ),
      bottom: Row(
        children: [
          Expanded(
            child: PartyPrimaryButton(
              key: const ValueKey('party-submit-score'),
              label: _selectedNobody
                  ? 'اعتمد: لا أحد'
                  : _selectedTeam == null
                  ? 'اختر صاحب النقطة'
                  : 'اعتمد النقطة لـ ${session.teams[_selectedTeam!].name}',
              busy: _submitting,
              feedback: false,
              onPressed: !_hasSelection || _submitting ? null : _submitAward,
            ),
          ),
          const SizedBox(width: 10),
          AhdashV9IconButton(
            onPressed: _submitting
                ? null
                : () => _openQuestionReport(context, question.id, session.id),
            icon: AhdashIcons.flag,
            tooltip: 'الإبلاغ عن السؤال',
          ),
        ],
      ),
      child: portrait
          ? Column(
              children: [
                Expanded(flex: 3, child: answerPanel),
                const SizedBox(height: 10),
                Expanded(flex: 2, child: scorePanel),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: answerPanel),
                SizedBox(width: compact ? 10 : 20),
                Expanded(flex: 2, child: scorePanel),
              ],
            ),
    );
  }

  Future<void> _submitAward() async {
    if (_submitting || !_hasSelection) return;
    setState(() => _submitting = true);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final team = _selectedNobody ? null : _selectedTeam;
    final awarded = ref.read(partyGameControllerProvider.notifier).award(team);
    if (!awarded) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر اعتماد النقطة. بقيت الإجابة مكشوفة للمحاولة.'),
        ),
      );
      return;
    }
    await ref
        .read(feedbackServiceProvider)
        .play(team == null ? FeedbackCue.tap : FeedbackCue.correct);
    if (!mounted) return;
    final finished =
        ref.read(partyGameControllerProvider).session?.isComplete ?? false;
    context.go(finished ? '/party/result' : '/party/board');
  }
}

final class _PortraitRevealLayout extends StatelessWidget {
  const _PortraitRevealLayout({
    required this.session,
    required this.question,
    required this.selectedTeam,
    required this.selectedNobody,
    required this.submitting,
    required this.onTeam,
    required this.onNobody,
    required this.onSubmit,
  });
  final PartyGameSession session;
  final PartyQuestionSnapshot question;
  final int? selectedTeam;
  final bool selectedNobody, submitting;
  final ValueChanged<int> onTeam;
  final VoidCallback onNobody, onSubmit;

  @override
  Widget build(BuildContext context) {
    final gutter = AhdashV10Metrics.of(context).gutter;
    final hasSelection = selectedTeam != null || selectedNobody;
    return Column(
      children: [
        _PartyRoundBar(session: session),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3EC),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.ink, width: 1.25),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x21191714),
                        offset: Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E874B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'الجواب الصحيح',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.inkMuted,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        question.answer,
                        key: const ValueKey('party-revealed-answer'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF1E874B),
                          fontSize: 34,
                          height: 1.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (question.explanation != null &&
                          question.explanation!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          question.explanation!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'من يحصل على النقطة؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < session.teams.length; i++) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: _PortraitAwardButton(
                      label: session.teams[i].name,
                      compatibilityLabel:
                          '${session.teams[i].name} (+${question.pointValue})',
                      color: Color(session.teams[i].colorValue),
                      selected: selectedTeam == i,
                      score: session.scores[i],
                      points: question.pointValue,
                      onPressed: submitting ? null : () => onTeam(i),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: _PortraitAwardButton(
                    label: 'لا أحد',
                    color: AppColors.inkMuted,
                    selected: selectedNobody,
                    score: null,
                    points: null,
                    onPressed: submitting ? null : onNobody,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 12),
          child: PartyPrimaryButton(
            key: const ValueKey('party-submit-score'),
            label: !hasSelection
                ? 'اختر من يحصل على النقطة'
                : selectedNobody
                ? 'اعتمد: لا أحد'
                : 'اعتمد النقطة لـ ${session.teams[selectedTeam!].name}',
            busy: submitting,
            feedback: false,
            onPressed: !hasSelection || submitting ? null : onSubmit,
          ),
        ),
      ],
    );
  }
}

final class _PortraitAwardButton extends StatelessWidget {
  const _PortraitAwardButton({
    required this.label,
    this.compatibilityLabel,
    required this.color,
    required this.selected,
    required this.score,
    required this.points,
    required this.onPressed,
  });

  final String label;
  final String? compatibilityLabel;
  final Color color;
  final bool selected;
  final int? score;
  final int? points;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? color.withValues(alpha: 0.13)
            : AppColors.paper0,
        foregroundColor: color,
        side: BorderSide(
          color: selected ? AppColors.ink : AppColors.hairline,
          width: selected ? 1.5 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (points != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? color : AppColors.paper2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${_arabicDigits(points!)}',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              if (score != null) ...[
                const SizedBox(width: 7),
                Text(
                  _arabicDigits(score!),
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          if (compatibilityLabel != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: Text(compatibilityLabel!, maxLines: 1),
              ),
            ),
        ],
      ),
    ),
  );
}

final class _CompactScorePair extends StatelessWidget {
  const _CompactScorePair({required this.session});

  final PartyGameSession session;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${session.teams[0].name} ${session.scores[0]}، ${session.teams[1].name} ${session.scores[1]}',
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PartyTeamDot(color: Color(session.teams[0].colorValue), size: 7),
          const SizedBox(width: 4),
          Text(
            '${session.scores[0]}',
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 12),
          PartyTeamDot(color: Color(session.teams[1].colorValue), size: 7),
          const SizedBox(width: 4),
          Text(
            '${session.scores[1]}',
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ),
  );
}

final class _AwardChoice extends StatelessWidget {
  const _AwardChoice({
    required this.team,
    required this.points,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final PartyTeam team;
  final int points;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    enabled: enabled,
    label: 'احتساب $points نقطة لفريق ${team.name}',
    child: SizedBox(
      height: context.v9Metrics.compact ? 38 : 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? Color(team.colorValue) : null,
          foregroundColor: selected
              ? Colors.white
              : context.ahdashColors.textPrimary,
          side: BorderSide(color: Color(team.colorValue), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: enabled ? onTap : null,
        child: Text(
          '${team.name} (+$points)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  );
}

final class _NoScoreChoice extends StatelessWidget {
  const _NoScoreChoice({
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    enabled: enabled,
    label: 'لا أحد يحصل على النقطة',
    child: SizedBox(
      height: context.v9Metrics.compact ? 38 : 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? context.ahdashColors.surfaceElevated
              : null,
          side: BorderSide(
            color: selected
                ? context.ahdashColors.borderStrong
                : context.ahdashColors.border,
          ),
        ),
        onPressed: enabled ? onTap : null,
        child: const Text('لا أحد'),
      ),
    ),
  );
}

final class PartyResultScreen extends ConsumerStatefulWidget {
  const PartyResultScreen({super.key});

  @override
  ConsumerState<PartyResultScreen> createState() => _PartyResultScreenState();
}

final class _PartyResultScreenState extends ConsumerState<PartyResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(partyGameControllerProvider).session;
      if (session?.isComplete == true &&
          session!.scores[0] != session.scores[1]) {
        ref.read(feedbackServiceProvider).play(FeedbackCue.win);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(partyGameControllerProvider).session;
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/party/categories');
      });
      return const SizedBox.shrink();
    }
    if (!session.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(PartySetupFlowResolver.routeForSession(session));
        }
      });
      return const SizedBox.shrink();
    }
    final tied = session.scores[0] == session.scores[1];
    final canStartTieBreaker =
        tied &&
        session.tieBreakerQuestion != null &&
        !session.tieBreakerStarted;
    final winnerIndex = session.scores[0] > session.scores[1] ? 0 : 1;
    final tournamentMatchId = session.tournamentContext?.matchId;
    late final Widget primaryAction;
    if (tournamentMatchId != null && !tied) {
      primaryAction = PartyPrimaryButton(
        label: 'مراجعة نتيجة البطولة',
        backgroundColor: MediaQuery.sizeOf(context).width < 390
            ? const Color(0xFF1E874B)
            : null,
        foregroundColor: MediaQuery.sizeOf(context).width < 390
            ? Colors.white
            : null,
        onPressed: () async {
          await ref.read(tournamentControllerProvider.notifier).restore();
          if (!context.mounted) return;
          context.go('/tournaments/match/$tournamentMatchId');
        },
      );
    } else if (canStartTieBreaker) {
      primaryAction = PartyPrimaryButton(
        label: 'احسموها بسؤال فاصل',
        backgroundColor: MediaQuery.sizeOf(context).width < 390
            ? const Color(0xFF1E874B)
            : null,
        foregroundColor: MediaQuery.sizeOf(context).width < 390
            ? Colors.white
            : null,
        onPressed: () {
          final started = ref
              .read(partyGameControllerProvider.notifier)
              .startTieBreaker();
          if (started) context.go('/party/question');
        },
      );
    } else {
      primaryAction = PartyPrimaryButton(
        key: const ValueKey('party-play-again'),
        label: 'العب مرة ثانية',
        backgroundColor: MediaQuery.sizeOf(context).width < 390
            ? const Color(0xFF1E874B)
            : null,
        foregroundColor: MediaQuery.sizeOf(context).width < 390
            ? Colors.white
            : null,
        onPressed: () {
          ref.read(partyGameControllerProvider.notifier).beginRematch();
          context.go('/party/categories');
        },
      );
    }
    final newGameButton = TextButton(
      onPressed: () => context.go('/home'),
      child: const Text('تم'),
    );
    if (context.v9Metrics.portrait) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmExit(context);
        },
        child: BrandScaffold(
          showDevelopmentBadge: false,
          body: PartyV2Canvas(
            child: SafeArea(
              child: _PortraitResultLayout(
                session: session,
                winnerIndex: winnerIndex,
                tied: tied,
                primaryAction: primaryAction,
                newGameButton: newGameButton,
              ),
            ),
          ),
        ),
      );
    }
    return _PartyGameScaffold(
      portraitBottomHeight: 94,
      top: Row(
        children: [
          Expanded(
            child: Text(
              'النتيجة النهائية',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(width: 8),
          AhdashV9IconButton(
            icon: AhdashIcons.home,
            tooltip: 'الرئيسية',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      bottom: Column(
        children: [
          Expanded(child: primaryAction),
          SizedBox(height: 34, child: newGameButton),
        ],
      ),
      child: PartyEntrance(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'نهاية اللعبة',
                  style: TextStyle(
                    color: context.ahdashColors.textMuted,
                    fontSize: context.v9Metrics.metadataSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: context.v9Metrics.compact ? 4 : 8),
                if (!tied)
                  AhdashPictogramReveal(
                    duration: PartyV2Motion.intro,
                    child: AhdashPictogramView(
                      pictogram: AhdashPictogram.win,
                      size: context.v9Metrics.compact ? 58 : 82,
                      tone: AhdashPictogramTone.achievement,
                      semanticLabel: 'فوز',
                    ),
                  )
                else
                  AhdashPictogramView(
                    pictogram: AhdashPictogram.draw,
                    size: context.v9Metrics.compact ? 46 : 64,
                    tone: AhdashPictogramTone.achievement,
                    semanticLabel: 'تعادل',
                  ),
                SizedBox(height: context.v9Metrics.compact ? 5 : 10),
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    tied
                        ? canStartTieBreaker
                              ? 'تعادل — سؤال واحد يحسمها'
                              : 'تعادل'
                        : 'الكأس لـ ${session.teams[winnerIndex].name}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: context.v9Metrics.compact ? 28 : 38,
                      height: 1.12,
                    ),
                  ),
                ),
                if (!context.v9Metrics.compact) ...[
                  const SizedBox(height: 5),
                  Text(
                    tied
                        ? 'انتهت الجولة بنتيجة متساوية.'
                        : 'جولة قوية انتهت بفارق ${session.scores[winnerIndex] - session.scores[1 - winnerIndex]} نقطة.',
                    style: TextStyle(color: context.ahdashColors.textSecondary),
                  ),
                ],
                SizedBox(height: context.v9Metrics.compact ? 9 : 16),
                AhdashV9Surface(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.v9Metrics.compact ? 14 : 22,
                    vertical: context.v9Metrics.compact ? 8 : 14,
                  ),
                  child: _ResultScoreline(
                    session: session,
                    winnerIndex: winnerIndex,
                  ),
                ),
                if (!context.v9Metrics.compact) ...[
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: session.scoreEvents.isEmpty
                        ? null
                        : () => _showScoreHistory(session),
                    icon: const Icon(Icons.receipt_long_outlined, size: 17),
                    label: Text(
                      'سجل الاحتساب • ${session.scoreEvents.length} سؤالًا',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showScoreHistory(
    PartyGameSession session,
  ) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.82,
      child: Material(
        color: context.ahdashColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'سجل احتساب النقاط',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: session.scoreEvents.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final event = session.scoreEvents.reversed.elementAt(index);
                    final question = session.questions
                        .where((item) => item.id == event.questionId)
                        .firstOrNull;
                    return ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(event.reason),
                      subtitle: Text(
                        question == null
                            ? 'سؤال فاصل'
                            : '${question.pointValue} نقطة',
                      ),
                      trailing: Text(
                        '${event.teamDeltas[0] >= 0 ? '+' : ''}${event.teamDeltas[0]}  |  ${event.teamDeltas[1] >= 0 ? '+' : ''}${event.teamDeltas[1]}',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final class _PortraitResultLayout extends StatelessWidget {
  const _PortraitResultLayout({
    required this.session,
    required this.winnerIndex,
    required this.tied,
    required this.primaryAction,
    required this.newGameButton,
  });
  final PartyGameSession session;
  final int winnerIndex;
  final bool tied;
  final Widget primaryAction, newGameButton;
  @override
  Widget build(BuildContext context) {
    final gutter = AhdashV10Metrics.of(context).gutter;
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _ResultArtworkHero(
                    accent: tied
                        ? AppColors.gold
                        : Color(session.teams[winnerIndex].colorValue),
                    tied: tied,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tied ? 'منافسة متكافئة' : 'بطل المجلس الحالي',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: tied
                        ? 'تعادل'
                        : 'الكأس لـ ${session.teams[winnerIndex].name}',
                    child: Text(
                      tied
                          ? 'تعادل'
                          : 'الكأس لـ ${session.teams[winnerIndex].name}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        height: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AhdashV10Panel(
                    child: Column(
                      children: [
                        _PortraitResultRow(
                          team: session.teams[winnerIndex],
                          score: session.scores[winnerIndex],
                          winner: !tied,
                        ),
                        const Divider(height: 24),
                        _PortraitResultRow(
                          team: session.teams[1 - winnerIndex],
                          score: session.scores[1 - winnerIndex],
                          winner: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: primaryAction,
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: newGameButton,
          ),
        ],
      ),
    );
  }
}

final class _ResultArtworkHero extends StatelessWidget {
  const _ResultArtworkHero({required this.accent, required this.tied});

  final Color accent;
  final bool tied;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: MediaQuery.sizeOf(context).height < 820 ? 166 : 188,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFF173F34),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.ink, width: 1.25),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        PartyGameplayArtwork(
          scene: PartyGameplayArtworkScene.result,
          accent: accent,
          onDark: true,
        ),
        PositionedDirectional(
          start: 14,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.paper0.withValues(alpha: .3)),
            ),
            child: Text(
              tied ? 'مباراة متكافئة' : 'بطل المجلس',
              style: const TextStyle(
                color: AppColors.paper0,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

final class _PortraitResultRow extends StatelessWidget {
  const _PortraitResultRow({
    required this.team,
    required this.score,
    required this.winner,
  });

  final PartyTeam team;
  final int score;
  final bool winner;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          winner ? '${team.name} (البطل)' : team.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: winner ? AppColors.ink : const Color(0xFF756E63),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${_arabicDigits(score)} نقطة',
            style: TextStyle(
              color: winner ? const Color(0xFF1E874B) : const Color(0xFF756E63),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          Positioned.fill(child: Opacity(opacity: 0, child: Text('$score'))),
        ],
      ),
    ],
  );
}

final class _ResultScoreline extends StatelessWidget {
  const _ResultScoreline({required this.session, required this.winnerIndex});

  final PartyGameSession session;
  final int winnerIndex;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ResultScoreTeam(
          team: session.teams[0],
          score: session.scores[0],
          winner: session.scores[0] != session.scores[1] && winnerIndex == 0,
        ),
      ),
      SizedBox(width: context.v9Metrics.compact ? 8 : 18),
      Text(
        '—',
        style: TextStyle(
          color: context.ahdashColors.textMuted,
          fontSize: context.v9Metrics.compact ? 20 : 26,
        ),
      ),
      SizedBox(width: context.v9Metrics.compact ? 8 : 18),
      Expanded(
        child: _ResultScoreTeam(
          team: session.teams[1],
          score: session.scores[1],
          winner: session.scores[0] != session.scores[1] && winnerIndex == 1,
        ),
      ),
    ],
  );
}

final class _ResultScoreTeam extends StatelessWidget {
  const _ResultScoreTeam({
    required this.team,
    required this.score,
    required this.winner,
  });

  final PartyTeam team;
  final int score;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    final metrics = context.v9Metrics;
    return Semantics(
      label: '${team.name}: $score${winner ? '، الفائز' : ''}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PartyTeamDot(color: Color(team.colorValue), size: 8),
            const SizedBox(height: 3),
            Text(
              team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.ahdashColors.textPrimary,
                fontSize: metrics.compact ? 15 : 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            _AnimatedResultScore(score: score),
          ],
        ),
      ),
    );
  }
}

final class _AnimatedResultScore extends StatelessWidget {
  const _AnimatedResultScore({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<int>(
    tween: IntTween(begin: 0, end: score),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : PartyV2Motion.score,
    builder: (_, value, _) => Text(
      '$value',
      textDirection: TextDirection.ltr,
      style: TextStyle(
        color: context.ahdashColors.textPrimary,
        fontSize: context.v9Metrics.compact ? 28 : 36,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

final class _ScoreRibbon extends StatelessWidget {
  const _ScoreRibbon({required this.session});

  final PartyGameSession session;

  @override
  Widget build(BuildContext context) {
    final portrait =
        MediaQuery.sizeOf(context).height >= MediaQuery.sizeOf(context).width;
    if (portrait) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: const BoxDecoration(
          color: AppColors.ink,
          border: Border(bottom: BorderSide(color: AppColors.inkSoft)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _PortraitTeamScore(
                team: session.teams[0],
                score: session.scores[0],
                active: session.turnTeamIndex == 0,
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 132),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.inkSoft),
              ),
              child: Text(
                'دور ${session.teams[session.turnTeamIndex].name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: _PortraitTeamScore(
                team: session.teams[1],
                score: session.scores[1],
                alignEnd: true,
                active: session.turnTeamIndex == 1,
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: _TeamScore(
            team: session.teams[0],
            score: session.scores[0],
            active: session.turnTeamIndex == 0,
          ),
        ),
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : PartyV2Motion.page,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, -0.2),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            'دور ${session.teams[session.turnTeamIndex].name}',
            key: ValueKey(session.turnTeamIndex),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(session.teams[session.turnTeamIndex].colorValue),
              fontSize: context.v9Metrics.metadataSize,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _TeamScore(
              team: session.teams[1],
              score: session.scores[1],
              active: session.turnTeamIndex == 1,
            ),
          ),
        ),
      ],
    );
  }
}

final class _PortraitTeamScore extends StatelessWidget {
  const _PortraitTeamScore({
    required this.team,
    required this.score,
    this.alignEnd = false,
    this.active = false,
  });

  final PartyTeam team;
  final int score;
  final bool alignEnd;
  final bool active;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: alignEnd
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PartyTeamDot(color: Color(team.colorValue), size: active ? 8 : 6),
            const SizedBox(width: 4),
            Text(
              team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? AppColors.paper0 : AppColors.paper3,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Text(
          '$score',
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: active ? AppColors.primary : AppColors.paper0,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

final class _TeamScore extends StatelessWidget {
  const _TeamScore({
    required this.team,
    required this.score,
    required this.active,
  });

  final PartyTeam team;
  final int score;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final metrics = context.v9Metrics;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: active && !MediaQuery.disableAnimationsOf(context) ? 1.12 : 1,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : PartyV2Motion.page,
          child: PartyTeamDot(
            color: Color(team.colorValue),
            size: active ? 10 : 7,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            team.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(team.colorValue),
              fontSize: metrics.compact ? 15 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 7),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: score),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : PartyV2Motion.score,
          builder: (_, value, _) => Text(
            '$value',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: context.ahdashColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: metrics.compact ? 24 : 30,
            ),
          ),
        ),
      ],
    );
  }
}

final class _CompactHelperAction extends StatelessWidget {
  const _CompactHelperAction({
    required this.definition,
    required this.used,
    required this.active,
    required this.onPressed,
    this.showLabel = false,
  });

  final PartyHelperDefinition definition;
  final bool used;
  final bool active;
  final VoidCallback onPressed;
  final bool showLabel;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: used
        ? '${definition.id.label} — استُخدمت'
        : definition.description,
    child: Semantics(
      button: true,
      enabled: !used,
      selected: active,
      label: definition.id.label,
      child: showLabel
          ? OutlinedButton.icon(
              onPressed: used ? null : onPressed,
              style: OutlinedButton.styleFrom(
                backgroundColor: active ? AppColors.paper2 : null,
              ),
              icon: used
                  ? const Icon(Icons.check_rounded, size: 18)
                  : AhdashPictogramView(
                      pictogram: partyHelperPictogram(
                        definition.id,
                        definition.iconKey,
                      ),
                      size: 18,
                    ),
              label: Text(
                used
                    ? '${definition.id.label} · استُخدمت'
                    : definition.id.label,
              ),
            )
          : IconButton(
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              onPressed: used ? null : onPressed,
              style: IconButton.styleFrom(
                backgroundColor: active ? context.ahdashColors.selected : null,
                foregroundColor: active ? context.ahdashColors.primary : null,
                side: BorderSide(
                  color: active
                      ? context.ahdashColors.primary
                      : context.ahdashColors.border,
                ),
              ),
              icon: used
                  ? const Icon(Icons.check_rounded, size: 18)
                  : AhdashPictogramView(
                      pictogram: partyHelperPictogram(
                        definition.id,
                        definition.iconKey,
                      ),
                      size: 24,
                      tone: active
                          ? AhdashPictogramTone.success
                          : AhdashPictogramTone.standard,
                    ),
            ),
    ),
  );
}

final class _PartyGameScaffold extends StatelessWidget {
  const _PartyGameScaffold({
    required this.top,
    required this.child,
    required this.bottom,
    this.portraitTopHeight,
    this.portraitBottomHeight,
  });

  final Widget top;
  final Widget child;
  final Widget bottom;
  final double? portraitTopHeight;
  final double? portraitBottomHeight;

  @override
  Widget build(BuildContext context) {
    final metrics = context.v9Metrics;
    final v10 = AhdashV10Metrics.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: BrandScaffold(
        body: PartyV2Canvas(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(v10.gutter, 8, v10.gutter, 10),
                  child: Column(
                    children: [
                      SizedBox(
                        height: metrics.portrait
                            ? portraitTopHeight ?? 48
                            : metrics.compact
                            ? 48
                            : 60,
                        child: top,
                      ),
                      SizedBox(height: metrics.compact ? 8 : 16),
                      Expanded(child: child),
                      SizedBox(height: metrics.compact ? 8 : 16),
                      SizedBox(
                        height: metrics.portrait
                            ? portraitBottomHeight ??
                                  metrics.primaryActionHeight
                            : metrics.primaryActionHeight,
                        child: bottom,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _confirmExit(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('تطلعون من الجولة؟'),
      content: const Text(
        'اللعبة محفوظة على هذا الجهاز وتقدرون تكملونها من الرئيسية.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('نكمّل'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            context.go('/home');
          },
          child: const Text('احفظ واخرج'),
        ),
      ],
    ),
  );
}

void _openQuestionReport(
  BuildContext context,
  String questionId,
  String gameId,
) {
  final policy = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(capabilityPolicyProvider);
  if (!policy.allows(AppCapability.reports)) {
    context.push(
      GuestCapabilityPolicy.gateLocation(
        '/party/question',
        capability: AppCapability.reports,
      ),
    );
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.9,
      child: _QuestionReportSheet(questionId: questionId, gameId: gameId),
    ),
  );
}

final class _QuestionReportSheet extends ConsumerStatefulWidget {
  const _QuestionReportSheet({required this.questionId, required this.gameId});

  final String questionId;
  final String gameId;

  @override
  ConsumerState<_QuestionReportSheet> createState() =>
      _QuestionReportSheetState();
}

final class _QuestionReportSheetState
    extends ConsumerState<_QuestionReportSheet> {
  final _details = TextEditingController();
  var _reason = QuestionReportReason.incorrectAnswer;
  var _busy = false;
  var _sent = false;
  var _queued = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PartyV2Canvas(
    motion: false,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: _sent
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: context.ahdashColors.success,
                    size: 48,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'وصلنا بلاغك',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _queued
                        ? 'حُفظ على الجهاز وسيُرسل عند عودة الاتصال.'
                        : 'شكرًا - سيراجعه فريق المحتوى.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'بلّغ عن السؤال',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'اختيار واحد يكفينا لنراجع المحتوى بسرعة.',
                        style: TextStyle(
                          color: context.ahdashColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: ListView(
                          children: QuestionReportReason.values
                              .map(
                                (reason) => ListTile(
                                  selected: reason == _reason,
                                  selectedTileColor: context
                                      .ahdashColors
                                      .primary
                                      .withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  leading: Icon(
                                    reason == _reason
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    color: reason == _reason
                                        ? context.ahdashColors.primary
                                        : context.ahdashColors.textMuted,
                                  ),
                                  title: Text(reason.labelAr),
                                  dense: true,
                                  enabled: !_busy,
                                  onTap: _busy
                                      ? null
                                      : () => setState(() => _reason = reason),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _details,
                          expands: true,
                          minLines: null,
                          maxLines: null,
                          maxLength: 1200,
                          decoration: const InputDecoration(
                            labelText: 'تفصيل مختصر — اختياري',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PartyPrimaryButton(
                        label: 'إرسال البلاغ',
                        icon: Icons.send_rounded,
                        busy: _busy,
                        onPressed: _busy ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    ),
  );

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final status = await ref
          .read(questionReportRepositoryProvider)
          .submit(
            questionId: widget.questionId,
            gameId: widget.gameId,
            reason: _reason,
            comment: _details.text,
          );
      if (!mounted) return;
      if (status == QuestionReportSubmitStatus.authenticationRequired) {
        _message('سجّل دخولك لإرسال البلاغ.');
      } else if (status == QuestionReportSubmitStatus.duplicate) {
        _message('بلاغ مماثل قيد المراجعة بالفعل.');
      } else {
        setState(() {
          _sent = true;
          _queued = status == QuestionReportSubmitStatus.queued;
        });
      }
    } catch (_) {
      _message('تعذر حفظ البلاغ. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
