import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/utility_v9.dart';
import '../../auth/presentation/auth_controller.dart';
import 'problem_report_controller.dart';

final class ReportProblemScreen extends ConsumerWidget {
  const ReportProblemScreen({required this.sourceScreen, super.key});

  final String sourceScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AhdashUtilityScaffold(
    title: 'بلاغ عن مشكلة',
    fallback: '/settings',
    child: _ReportForm(
      key: ValueKey(ref.watch(authControllerProvider).asData?.value?.id),
      source: sourceScreen,
    ),
  );
}

final class _ReportForm extends ConsumerStatefulWidget {
  const _ReportForm({required this.source, super.key});

  final String source;

  @override
  ConsumerState<_ReportForm> createState() => _ReportFormState();
}

final class _ReportFormState extends ConsumerState<_ReportForm> {
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _description = TextEditingController(
      text: ref.read(problemReportProvider).description,
    );
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(problemReportProvider);
    final controller = ref.read(problemReportProvider.notifier);
    if (state.sent) {
      return _ReportSuccess(
        onNewReport: () {
          _description.clear();
          controller.reset();
        },
        onBack: () =>
            context.canPop() ? context.pop() : context.go('/settings'),
      );
    }

    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final count = state.description.runes.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('report-keyboard-scroll'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              bottom: 12 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!keyboard) ...[
                  const _ReportIntro(),
                  const SizedBox(height: 20),
                ] else ...[
                  const _WritingStatus(),
                  const SizedBox(height: 12),
                ],
                const _FieldHeading(
                  title: 'وش المشكلة؟',
                  helper: 'اختر أقرب تصنيف حتى يصل البلاغ للفريق الصحيح.',
                  step: '01',
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: const ValueKey('report-category-field'),
                  isExpanded: true,
                  initialValue: state.category,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'تصنيف المشكلة',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                      borderSide: const BorderSide(color: AppColors.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                      borderSide: const BorderSide(color: AppColors.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                      borderSide: const BorderSide(
                        color: AppColors.palm,
                        width: 1.5,
                      ),
                    ),
                  ),
                  items: ProblemReportContract.categories.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Row(
                            children: [
                              Icon(
                                _categoryIcon(entry.key),
                                color: AppColors.inkMuted,
                                size: 18,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: state.busy || state.uncertain
                      ? null
                      : (value) => controller.update(category: value),
                ),
                const SizedBox(height: 20),
                const _FieldHeading(
                  title: 'وصف المشكلة — اختياري',
                  helper: 'اكتب ما حدث، والخطوة التي سبقته، وما كنت تتوقعه.',
                  step: '02',
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('report-description-field'),
                  controller: _description,
                  enabled: !state.busy && !state.uncertain,
                  onChanged: (value) => controller.update(description: value),
                  minLines: keyboard ? 3 : 5,
                  maxLines: keyboard ? 5 : 8,
                  maxLength: ProblemReportContract.maxDescriptionLength,
                  textAlign: TextAlign.start,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText:
                        'مثال: بعد انتهاء السؤال ظهرت النتيجة دون احتساب النقاط…',
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.palm,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.tips_and_updates_outlined,
                      size: 15,
                      color: AppColors.palm,
                    ),
                    const SizedBox(width: 5),
                    const Expanded(
                      child: Text(
                        'وصف واضح يسرّع الوصول للحل.',
                        style: TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      '$count/${ProblemReportContract.maxDescriptionLength}',
                      style: TextStyle(
                        color:
                            count > ProblemReportContract.maxDescriptionLength
                            ? AppColors.danger
                            : AppColors.inkMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  _ReportError(
                    message: state.error!,
                    uncertain: state.uncertain,
                    onReset: () {
                      _description.clear();
                      controller.reset();
                    },
                  ),
                ],
                const SizedBox(height: 14),
                const _PrivacyNote(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          key: const ValueKey('report-submit-action'),
          height: 54,
          child: FilledButton.icon(
            onPressed: state.busy || state.uncertain
                ? null
                : () => controller.submit(widget.source),
            icon: state.busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.ink,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 20),
            label: Text(
              state.busy ? 'جارٍ إرسال البلاغ…' : 'إرسال البلاغ',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

final class _ReportIntro extends StatelessWidget {
  const _ReportIntro();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('report-intro'),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [Color(0xFF234A38), Color(0xFF172B22), Color(0xFF111713)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFF315E49)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF142219).withValues(alpha: .16),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نسمعك',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'صف المشكلة وسنتولى الباقي.',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: .72),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 94,
          height: 84,
          child: ExcludeSemantics(
            child: Image.asset(
              'assets/visuals/report_support_art_v2.png',
              key: const ValueKey('report-support-art'),
              fit: BoxFit.contain,
              cacheWidth: 240,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ],
    ),
  );
}

final class _WritingStatus extends StatelessWidget {
  const _WritingStatus();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFE9F5CF),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.primary),
    ),
    child: const Row(
      children: [
        Icon(Icons.edit_rounded, size: 17, color: AppColors.palm),
        SizedBox(width: 7),
        Expanded(
          child: Text(
            'اكتب التفاصيل براحتك — النص محفوظ أثناء هذه الجلسة.',
            style: TextStyle(
              color: AppColors.inkSoft,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

final class _FieldHeading extends StatelessWidget {
  const _FieldHeading({
    required this.title,
    required this.helper,
    required this.step,
  });

  final String title;
  final String helper;
  final String step;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          step,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              helper,
              style: const TextStyle(
                color: AppColors.inkMuted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

final class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('report-trust-note'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.paper1,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.hairline),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, color: AppColors.palm, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'لحمايتك: لا تكتب كلمة المرور أو بيانات الدفع داخل البلاغ.',
            style: TextStyle(
              color: AppColors.inkSoft,
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

final class _ReportError extends StatelessWidget {
  const _ReportError({
    required this.message,
    required this.uncertain,
    required this.onReset,
  });

  final String message;
  final bool uncertain;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.danger.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (uncertain) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: onReset,
                child: const Text('بدء بلاغ جديد'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

final class _ReportSuccess extends StatelessWidget {
  const _ReportSuccess({required this.onNewReport, required this.onBack});

  final VoidCallback onNewReport;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(12, 56, 12, 24),
    child: Column(
      children: [
        SizedBox(
          key: const ValueKey('report-success-artwork'),
          width: 154,
          height: 126,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 118,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.paper1,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.hairline),
                ),
              ),
              Transform.rotate(
                angle: -.07,
                child: Container(
                  width: 82,
                  height: 92,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: .18),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.done_rounded,
                    color: AppColors.primary,
                    size: 42,
                  ),
                ),
              ),
              PositionedDirectional(
                end: 15,
                top: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.paper0, width: 3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'وصلنا بلاغك',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 27,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'شكرًا لمساعدتنا. أُرسل البلاغ بأمان وأصبح الآن لدى فريق المراجعة.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.inkMuted,
            fontSize: 14,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text(
              'العودة إلى الإعدادات',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: onNewReport, child: const Text('بلاغ جديد')),
      ],
    ),
  );
}

IconData _categoryIcon(String category) => switch (category) {
  'login' => Icons.login_rounded,
  'gameplay' => Icons.sports_esports_rounded,
  'matchmaking' => Icons.groups_rounded,
  'room' => Icons.emoji_events_outlined,
  'content' => Icons.quiz_outlined,
  'image' => Icons.image_outlined,
  'purchase' => Icons.workspace_premium_outlined,
  'notification' => Icons.notifications_none_rounded,
  'performance' => Icons.speed_rounded,
  _ => Icons.more_horiz_rounded,
};
