import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/ahdash_pictograms.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/measured_v9.dart';
import '../data/social_repository.dart';

final class SocialJoinTeamScreen extends ConsumerStatefulWidget {
  const SocialJoinTeamScreen({this.initialCode, super.key});

  final String? initialCode;

  @override
  ConsumerState<SocialJoinTeamScreen> createState() =>
      _SocialJoinTeamScreenState();
}

final class _SocialJoinTeamScreenState
    extends ConsumerState<SocialJoinTeamScreen> {
  late final TextEditingController _code;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.initialCode ?? '');
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = context.v9Metrics;
    return BrandScaffold(
      body: AhdashV9Frame(
        child: Column(
          children: [
            AhdashV9TopBar(
              title: 'الانضمام إلى فريق',
              kicker: 'فرقّي',
              leading: AhdashV9IconButton(
                icon: Icons.arrow_forward_rounded,
                tooltip: 'رجوع',
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/teams'),
              ),
            ),
            SizedBox(height: metrics.sectionGap),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            AhdashPictogramView(
                              pictogram: AhdashPictogram.teamsStep,
                              scale: metrics.compact
                                  ? AhdashPictogramScale.compactFeature
                                  : AhdashPictogramScale.sectionIdentity,
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'مكانك مع الفريق',
                                    style: TextStyle(
                                      fontSize: metrics.heroSize,
                                      height: 1.05,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'اطلب الرمز من القائد، أو افتح رابط/QR الدعوة وسيُملأ الرمز تلقائيًا.',
                                    style: TextStyle(
                                      color: context.ahdashColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: metrics.majorGap),
                        TextField(
                          key: const Key('social-team-join-code'),
                          controller: _code,
                          autofocus: widget.initialCode == null,
                          enabled: !_busy,
                          maxLength: 12,
                          textCapitalization: TextCapitalization.characters,
                          textDirection: TextDirection.ltr,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp('[A-Za-z0-9]'),
                            ),
                          ],
                          onSubmitted: (_) => _confirmAndJoin(),
                          decoration: const InputDecoration(
                            labelText: 'رمز الفريق',
                            hintText: 'مثال: 11TEAM24',
                            prefixIcon: Icon(Icons.key_rounded),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            key: const Key('social-team-join-error'),
                            style: TextStyle(
                              color: context.ahdashColors.error,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                        SizedBox(height: metrics.sectionGap),
                        AhdashV9PrimaryAction(
                          label: _busy ? 'جارٍ الانضمام…' : 'مراجعة والانضمام',
                          icon: Icons.login_rounded,
                          minimumWidth: double.infinity,
                          onPressed: _busy ? null : _confirmAndJoin,
                        ),
                        const SizedBox(height: 14),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: context.ahdashColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.ahdashColors.border,
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Icon(Icons.verified_user_outlined),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'رمز الفريق دعوة معتمدة؛ لذلك يكون الانضمام فوريًا. الدعوات المرسلة إلى حسابك تظهر في صفحة فرقّي ويمكن قبولها أو رفضها.',
                                  ),
                                ),
                              ],
                            ),
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
    );
  }

  Future<void> _confirmAndJoin() async {
    final code = _code.text.trim().toUpperCase();
    if (code.length < 4) {
      setState(() => _error = 'أدخل رمز فريق صالحًا.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الانضمام'),
        content: const Text(
          'ستنضم إلى الفريق فورًا لأن الرمز نفسه دعوة خاصة من القائد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('انضمام'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(socialRepositoryProvider).joinTeam(code);
      ref.invalidate(socialHubProvider);
      if (!mounted) return;
      final teamName = '${result['team_name'] ?? 'فريقك'}';
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded),
          title: const Text('تم الانضمام'),
          content: Text('أصبحت عضوًا في $teamName.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('افتح الفريق'),
            ),
          ],
        ),
      );
      if (mounted) context.go('/teams');
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذر الانضمام. تحقق من الرمز أو غادر فريقك الحالي أولًا.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
