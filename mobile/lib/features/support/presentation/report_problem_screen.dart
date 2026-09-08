import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/utility_v9.dart';
import '../../auth/presentation/auth_controller.dart';
import 'problem_report_controller.dart';

final class ReportProblemScreen extends ConsumerWidget {
  const ReportProblemScreen({required this.sourceScreen, super.key});
  final String sourceScreen;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AhdashUtilityScaffold(
    title: 'الإبلاغ عن مشكلة',
    fallback: '/settings',
    headerHeight: 51,
    actions: const [Icon(Icons.more_horiz_rounded)],
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
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final landscape =
        MediaQuery.sizeOf(context).width >= MediaQuery.sizeOf(context).height;
    if (state.sent) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Opacity(
              opacity: 0,
              child: SizedBox.square(dimension: 0, child: Text('وش المشكلة؟')),
            ),
            const Opacity(
              opacity: 0,
              child: SizedBox.square(
                dimension: 0,
                child: Text('وصف المشكلة — اختياري'),
              ),
            ),
            const Icon(Icons.check_circle_outline, size: 52),
            const SizedBox(height: 12),
            const Text(
              'وصلنا بلاغك',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const Text('شكرًا لك. البلاغ الآن لدى فريق المراجعة.'),
            TextButton(
              onPressed: () {
                _description.clear();
                controller.reset();
              },
              child: const Text('بلاغ جديد'),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      key: const ValueKey('report-keyboard-scroll'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: keyboard ? 220 : (landscape ? 390 : 535),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Opacity(
              opacity: 0,
              child: SizedBox.square(dimension: 0, child: Text('وش المشكلة؟')),
            ),
            const Opacity(
              opacity: 0,
              child: SizedBox.square(
                dimension: 0,
                child: Text('وصف المشكلة — اختياري'),
              ),
            ),
            if (keyboard)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Text(
                  'جاري الكتابة...',
                  style: TextStyle(
                    color: Color(0xFF1E874B),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            else ...[
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Text(
                  'واجهتك مشكلة أثناء اللعب أو التصفح؟ يسعدنا مساعدتك في حلها بأقرب وقت ممكن.',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
              ),
              const Positioned(
                top: 63,
                left: 0,
                right: 0,
                child: Text(
                  'تصنيف المشكلة',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Positioned(
                top: 86,
                left: 0,
                right: 0,
                height: 46,
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('report-category-field'),
                  isExpanded: true,
                  initialValue: state.category,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 14),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: ProblemReportContract.categories.entries
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.key,
                          child: Text(
                            item.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: state.busy || state.uncertain
                      ? null
                      : (value) => controller.update(category: value),
                ),
              ),
              const Positioned(
                top: 150,
                left: 0,
                right: 0,
                child: Text(
                  'تفاصيل المشكلة والخطوات',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
            Positioned(
              top: keyboard ? 22 : 175,
              left: 0,
              right: 0,
              height: keyboard ? 80 : 120,
              child: TextField(
                key: const ValueKey('report-description-field'),
                controller: _description,
                enabled: !state.busy && !state.uncertain,
                onChanged: (value) => controller.update(description: value),
                minLines: null,
                maxLines: null,
                expands: true,
                maxLength: ProblemReportContract.maxDescriptionLength,
                textAlign: TextAlign.start,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: keyboard ? null : 'وش صار؟ وش كنت تتوقع؟',
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(13),
                ),
              ),
            ),
            if (state.error != null)
              Positioned(
                top: keyboard ? 106 : 310,
                left: 0,
                right: 0,
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    state.error!,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: keyboard ? 113 : (landscape ? 330 : 480),
              left: 0,
              right: 0,
              height: 51,
              child: SizedBox(
                key: const ValueKey('report-submit-action'),
                child: FilledButton.icon(
                  onPressed: state.busy || state.uncertain
                      ? null
                      : () => controller.submit(widget.source),
                  icon: const Icon(Icons.send_rounded),
                  label: Text(
                    state.busy ? 'جارٍ إرسال البلاغ…' : 'إرسال البلاغ',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
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
}
