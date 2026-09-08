import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_services.dart';
import '../../auth/domain/guest_capability_policy.dart';
import '../../auth/presentation/auth_controller.dart';

abstract final class ProblemReportContract {
  static const maxDescriptionLength = 1500;
  static const categories = <String, String>{
    'login': 'تسجيل الدخول',
    'gameplay': 'تجربة اللعب',
    'matchmaking': 'اللعب الجماعي المحلي',
    'room': 'الفرق والبطولات',
    'content': 'المحتوى والأسئلة',
    'image': 'الصور',
    'purchase': 'Premium والمشتريات',
    'notification': 'الإشعارات',
    'performance': 'البطء أو الأداء',
    'other': 'مشكلة أخرى',
  };
  static String? validate(String category, String description) {
    if (!categories.containsKey(category)) return 'اختر نوع المشكلة.';
    if (description.length > maxDescriptionLength) {
      return 'الوصف أطول من الحد المسموح: 1500 حرف.';
    }
    return null; // The existing server contract explicitly permits an empty description.
  }

  static String safeSource(String source) =>
      const {
        '/home',
        '/profile',
        '/settings',
        '/notifications',
        '/football-preferences',
        '/premium',
        '/tournaments',
        '/party/board',
        '/party/question',
        '/party/result',
      }.contains(source)
      ? source
      : '/settings';
}

final class ProblemReportState {
  const ProblemReportState({
    this.category = 'gameplay',
    this.description = '',
    this.busy = false,
    this.sent = false,
    this.uncertain = false,
    this.error,
  });
  final String category, description;
  final bool busy, sent, uncertain;
  final String? error;
}

final problemReportProvider =
    NotifierProvider<ProblemReportController, ProblemReportState>(
      ProblemReportController.new,
    );

class ProblemReportController extends Notifier<ProblemReportState> {
  var _epoch = 0;
  @override
  ProblemReportState build() {
    ref.watch(authControllerProvider);
    _epoch++;
    return const ProblemReportState();
  }

  void update({String? category, String? description}) {
    if (state.busy || state.uncertain || state.sent) return;
    state = ProblemReportState(
      category: category ?? state.category,
      description: description ?? state.description,
    );
  }

  void reset() {
    if (!state.busy) state = const ProblemReportState();
  }

  Future<bool> submit(String source) async {
    if (state.busy || state.sent || state.uncertain) return false;
    final previous = state;
    final validation = ProblemReportContract.validate(
      previous.category,
      previous.description,
    );
    if (validation != null) {
      state = ProblemReportState(
        category: previous.category,
        description: previous.description,
        error: validation,
      );
      return false;
    }
    final account = ref.read(authControllerProvider).asData?.value;
    if (!GuestCapabilityPolicy(account).allows(AppCapability.reports)) {
      state = ProblemReportState(
        category: previous.category,
        description: previous.description,
        error: 'سجّل دخولك لإرسال البلاغ.',
      );
      return false;
    }
    final epoch = _epoch;
    state = ProblemReportState(
      category: previous.category,
      description: previous.description,
      busy: true,
    );
    try {
      final id = await ref
          .read(appServicesProvider)
          .errors
          .submitProblem(
            category: previous.category,
            description: previous.description.trim(),
            screen: ProblemReportContract.safeSource(source),
          );
      if (epoch != _epoch) return false;
      if (id == null || id.isEmpty) {
        state = ProblemReportState(
          category: previous.category,
          description: previous.description,
          error: 'الإبلاغ غير متاح في هذه البيئة. لم يُرسل البلاغ.',
        );
        return false;
      }
      state = const ProblemReportState(sent: true);
      unawaited(
        ref
            .read(appServicesProvider)
            .analytics
            .log('report_submitted')
            .catchError((_) {}),
      );
      return true;
    } on Object catch (error) {
      if (epoch != _epoch) return false;
      // This RPC has no idempotency key. An uncertain timeout cannot be retried automatically.
      final uncertain = error is TimeoutException;
      state = ProblemReportState(
        category: previous.category,
        description: previous.description,
        uncertain: uncertain,
        error: uncertain
            ? 'لم نتأكد من وصول البلاغ. احتفظنا بالنص؛ لا نعيد الإرسال تلقائيًا لتجنب التكرار.'
            : 'تعذر إرسال البلاغ. قد تكون بلغت حد البلاغات؛ حاول لاحقًا.',
      );
      return false;
    }
  }
}
