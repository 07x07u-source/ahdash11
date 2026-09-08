import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/presentation/brand_identity.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/components.dart';
import '../../../shared/presentation/game_ui.dart';
import '../../../shared/presentation/landscape_layout.dart';
import '../../premium/presentation/premium_access_provider.dart';
import 'solo_match_controller.dart';

final class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(soloMatchControllerProvider);
    if (result.status != SoloMatchStatus.finished) {
      return BrandScaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/home'),
            child: const Text('العودة للرئيسية'),
          ),
        ),
      );
    }
    final formatter = NumberFormat.decimalPattern('ar');
    final accuracy = (result.accuracy * 100).round();
    final outcome = accuracy >= 80
        ? 'أداء استثنائي'
        : accuracy >= 60
        ? 'جولة قوية'
        : 'واصل التحدي';
    final accent = accuracy >= 80
        ? AppColors.primary
        : accuracy >= 60
        ? AppColors.gold
        : AppColors.muted;
    return BrandScaffold(
      body: SafeArea(
        child: AhdashGameWorld(
          child: Builder(
            builder: (context) {
              final metrics = LandscapeMetrics.of(context);
              return Padding(
                padding: EdgeInsets.all(metrics.gutter),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final outcomeZone = _OutcomeZone(
                      outcome: outcome,
                      accent: accent,
                      accuracy: accuracy,
                    );
                    final scoreZone = _ScoreZone(
                      score: formatter.format(result.playerScore),
                      correct: result.correctAnswers,
                      total: result.questions.length,
                      accent: accent,
                    );
                    final stats = _StatsActions(
                      correct: result.correctAnswers,
                      wrong: result.wrongAnswers,
                      longestStreak: result.longestStreak,
                      personalBest: result.personalBestScore,
                      accuracy: accuracy,
                      averageSeconds:
                          result.averageResponseTime.inMilliseconds / 1000,
                      onReplay: () async {
                        await _showAdIfEligible(ref);
                        await ref
                            .read(soloMatchControllerProvider.notifier)
                            .replay();
                        if (context.mounted) context.go('/solo/match');
                      },
                      onShare: () {
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                'نتيجتي في تحدي أحدعش: ${result.correctAnswers}/${result.questions.length} إجابة صحيحة، $accuracy% دقة، ${result.playerScore} نقطة',
                          ),
                        );
                        showAhdashSnackbar(context, 'تم نسخ النتيجة');
                      },
                      onHome: () async {
                        await _showAdIfEligible(ref);
                        ref.read(soloMatchControllerProvider.notifier).reset();
                        if (context.mounted) context.go('/home');
                      },
                    );
                    return AccessibilityViewport(
                      child: constraints.maxWidth >= 700
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 3, child: outcomeZone),
                                SizedBox(width: metrics.panelGap),
                                Expanded(flex: 4, child: scoreZone),
                                SizedBox(width: metrics.panelGap),
                                Expanded(flex: 4, child: stats),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 3, child: outcomeZone),
                                SizedBox(height: metrics.panelGap),
                                Expanded(flex: 4, child: scoreZone),
                                SizedBox(height: metrics.panelGap),
                                Expanded(flex: 5, child: stats),
                              ],
                            ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showAdIfEligible(WidgetRef ref) async {
    final services = ref.read(appServicesProvider);
    if (!services.ads.enabled) return;
    try {
      if (!(await ref.read(premiumAccessProvider.future)).adsAllowed) {
        return;
      }
      await services.ads.showInterstitialIfDue();
    } catch (_) {
      // Provider outages never block navigation.
    }
  }
}

final class _OutcomeZone extends StatelessWidget {
  const _OutcomeZone({
    required this.outcome,
    required this.accent,
    required this.accuracy,
  });
  final String outcome;
  final Color accent;
  final int accuracy;

  @override
  Widget build(BuildContext context) => GamePanel(
    tone: accuracy >= 60 ? GameSurfaceTone.gold : GameSurfaceTone.raised,
    cut: 20,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AhdashIcon(
          accuracy >= 80 ? AhdashGlyph.premium : AhdashGlyph.classic,
          size: 44,
          color: accent,
          active: true,
        ),
        const SizedBox(height: 8),
        Text(
          outcome,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(color: accent),
        ),
        Text(
          '$accuracy% دقة في تحديك الفردي',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(color: context.ahdashColors.textMuted, fontSize: 11),
        ),
      ],
    ),
  );
}

final class _ScoreZone extends StatelessWidget {
  const _ScoreZone({
    required this.score,
    required this.correct,
    required this.total,
    required this.accent,
  });
  final String score;
  final int correct;
  final int total;
  final Color accent;

  @override
  Widget build(BuildContext context) => GamePanel(
    selected: true,
    cut: 24,
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      children: [
        const CompactSectionTitle(
          eyebrow: 'AHDASH SOLO',
          title: 'حصيلة تحدي أحدعش',
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: _Score(label: 'النقاط', value: score, color: accent),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: const AhdashBrandLogo.mark(height: 32),
            ),
            Expanded(
              child: _Score(
                label: 'الصحيح من $total',
                value: '$correct/$total',
                color: context.ahdashColors.textSecondary,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          'تحدٍ فردي من 11 سؤالًا • بلا خصم وهمي',
          style: TextStyle(color: context.ahdashColors.textMuted, fontSize: 10),
        ),
      ],
    ),
  );
}

final class _Score extends StatelessWidget {
  const _Score({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: TextStyle(color: context.ahdashColors.textMuted)),
      FittedBox(
        child: Text(
          value,
          style: TextStyle(
            color: color,
            fontFamily: 'ThmanyahSans',
            fontSize: 38,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}

final class _StatsActions extends StatelessWidget {
  const _StatsActions({
    required this.correct,
    required this.wrong,
    required this.longestStreak,
    required this.personalBest,
    required this.accuracy,
    required this.averageSeconds,
    required this.onReplay,
    required this.onShare,
    required this.onHome,
  });
  final int correct;
  final int wrong;
  final int longestStreak;
  final int personalBest;
  final int accuracy;
  final double averageSeconds;
  final VoidCallback onReplay;
  final VoidCallback onShare;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => GamePanel(
    cut: 16,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CompactSectionTitle(title: 'إحصائيات الجولة'),
        const SizedBox(height: 8),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'إجابات صحيحة',
                        value: '$correct',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _Metric(
                        label: 'خاطئة / أفضل سلسلة',
                        value: '$wrong / $longestStreak',
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _Metric(label: 'الدقة', value: '$accuracy%'),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _Metric(
                        label: 'متوسط / رقم شخصي',
                        value:
                            '${averageSeconds.toStringAsFixed(1)} ث / $personalBest',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: onReplay,
                child: const Text('إعادة التحدي'),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'مشاركة النتيجة',
              onPressed: onShare,
              icon: const Icon(Icons.share_outlined),
            ),
            IconButton(
              tooltip: 'الرئيسية',
              onPressed: onHome,
              icon: const Icon(Icons.home_outlined),
            ),
          ],
        ),
      ],
    ),
  );
}

final class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.color = AppColors.primary,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.ahdashColors.surfaceMuted,
      border: BorderDirectional(start: BorderSide(color: color, width: 3)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: context.ahdashColors.textMuted,
                fontSize: 10,
              ),
            ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
