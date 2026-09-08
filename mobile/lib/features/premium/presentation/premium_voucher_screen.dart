import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/utility_v9.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../data/premium_voucher_repository.dart';
import '../domain/premium_access.dart';
import 'premium_voucher_controller.dart';

final class PremiumVoucherScreen extends ConsumerStatefulWidget {
  const PremiumVoucherScreen({super.key});

  @override
  ConsumerState<PremiumVoucherScreen> createState() =>
      _PremiumVoucherScreenState();
}

final class _PremiumVoucherScreenState
    extends ConsumerState<PremiumVoucherScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(premiumVoucherControllerProvider);
    return AhdashUtilityScaffold(
      title: 'استخدام قسيمة Premium',
      child: PremiumVoucherContentView(
        value: value,
        codeController: _codeController,
        onRedeem: () => ref
            .read(premiumVoucherControllerProvider.notifier)
            .redeem(_codeController.text),
        onDone: () => context.go('/premium'),
      ),
    );
  }
}

final class PremiumVoucherContentView extends StatelessWidget {
  const PremiumVoucherContentView({
    required this.value,
    required this.codeController,
    required this.onRedeem,
    required this.onDone,
    super.key,
  });

  final PremiumVoucherView value;
  final TextEditingController codeController;
  final Future<bool> Function() onRedeem;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    if (value.succeeded) {
      return _VoucherSuccess(value: value, onDone: onDone);
    }
    return ListView(
      key: const ValueKey('premium-voucher-scroll'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        bottom: 20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      children: [
        const _VoucherHero(),
        const SizedBox(height: 18),
        const Text(
          'أدخل رمز القسيمة',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'القسيمة تمنح Premium لفترة محددة ولا تنشئ اشتراكًا متجددًا.',
          style: TextStyle(
            height: 1.55,
            fontSize: 14,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
          decoration: BoxDecoration(
            color: AppColors.paper1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.ink),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsetsDirectional.fromSTEB(5, 0, 5, 8),
                child: Row(
                  children: [
                    Text(
                      'رمز القسيمة',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Spacer(),
                    Text(
                      'VOUCHER / 24',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 8,
                        letterSpacing: .8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: codeController,
                builder: (context, code, _) => TextField(
                  key: const ValueKey('premium-voucher-field'),
                  controller: codeController,
                  enabled: !value.busy,
                  autofocus: false,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  inputFormatters: const [_VoucherCodeFormatter()],
                  onSubmitted: value.busy ? null : (_) => onRedeem(),
                  style: const TextStyle(
                    fontSize: 15,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.paper0,
                    hintText: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.confirmation_number_outlined,
                        size: 18,
                      ),
                    ),
                    suffixIcon: IconButton(
                      tooltip: code.text.isEmpty ? 'لصق الرمز' : 'مسح الرمز',
                      onPressed: value.busy
                          ? null
                          : code.text.isEmpty
                          ? () async {
                              final data = await Clipboard.getData(
                                Clipboard.kTextPlain,
                              );
                              if (data?.text case final text?) {
                                codeController.text =
                                    PremiumVoucherRepository.formatVoucherCode(
                                      text,
                                    );
                              }
                            }
                          : codeController.clear,
                      icon: Icon(
                        code.text.isEmpty
                            ? Icons.content_paste_rounded
                            : Icons.close_rounded,
                        size: 19,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (value.message != null) ...[
          const SizedBox(height: 12),
          _VoucherMessage(value.message!),
        ],
        const SizedBox(height: 18),
        AhdashV10PrimaryButton(
          key: const ValueKey('premium-voucher-submit'),
          label: value.busy ? 'جارٍ التحقق…' : 'تفعيل القسيمة',
          icon: Icons.lock_open_rounded,
          loading: value.busy,
          onPressed: value.busy ? null : () => onRedeem(),
        ),
        const SizedBox(height: 12),
        const Text(
          'يتم التفعيل بعد تأكيد الخادم فقط. لا نعتمد على ساعة الجهاز.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

final class _VoucherHero extends StatelessWidget {
  const _VoucherHero({this.success = false});

  final bool success;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Container(
      height: textScale >= 1.2 ? 280 : 202,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.ink, width: 1.3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PositionedDirectional(
            top: 12,
            bottom: 12,
            end: 10,
            width: 174,
            child: CustomPaint(painter: _VoucherPainter(success: success)),
          ),
          const PositionedDirectional(
            top: 0,
            bottom: 0,
            start: 0,
            width: 5,
            child: ColoredBox(color: AppColors.gold),
          ),
          PositionedDirectional(
            top: 22,
            bottom: 20,
            start: 20,
            end: 158,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AHDASH / PROMO PASS 11',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 8.5,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  success ? 'Premium\nمفتوح' : 'هدية كروية\nبوقت محدد',
                  style: const TextStyle(
                    color: AppColors.paper0,
                    fontSize: 27,
                    height: 1.14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  success ? 'تم تأكيدها من الخادم' : 'غير متجددة تلقائيًا',
                  style: const TextStyle(color: AppColors.paper3, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _VoucherSuccess extends StatelessWidget {
  const _VoucherSuccess({required this.value, required this.onDone});

  final PremiumVoucherView value;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final annual = value.redemption?.type == PremiumVoucherType.annualPromo;
    return Column(
      key: const ValueKey('premium-voucher-success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _VoucherHero(success: true),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.paper1,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.success),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: AppColors.ink),
                ),
                child: const Icon(Icons.check_rounded, size: 28),
              ),
              const SizedBox(height: 12),
              const Text(
                'تم تفعيل Premium',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                annual ? 'قسيمة سنوية غير متجددة.' : 'قسيمة شهرية غير متجددة.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 6),
              Text(
                value.message ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.5),
              ),
            ],
          ),
        ),
        const Spacer(),
        AhdashV10PrimaryButton(
          label: 'متابعة إلى Premium',
          icon: Icons.arrow_back_rounded,
          onPressed: onDone,
        ),
      ],
    );
  }
}

final class _VoucherMessage extends StatelessWidget {
  const _VoucherMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('premium-voucher-message'),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.paper1,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.hairline),
    ),
    child: Text(message, textAlign: TextAlign.center),
  );
}

final class _VoucherCodeFormatter extends TextInputFormatter {
  const _VoucherCodeFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = PremiumVoucherRepository.formatVoucherCode(newValue.text);
    final clipped = formatted.length <= 29
        ? formatted
        : formatted.substring(0, 29);
    return TextEditingValue(
      text: clipped,
      selection: TextSelection.collapsed(offset: clipped.length),
    );
  }
}

final class _VoucherPainter extends CustomPainter {
  const _VoucherPainter({required this.success});

  final bool success;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.paper3.withValues(alpha: .38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final field = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
      const Radius.circular(18),
    );
    canvas.drawRRect(field, line);
    canvas.drawLine(
      Offset(size.width * .5, 3),
      Offset(size.width * .5, size.height - 3),
      line,
    );
    canvas.drawCircle(Offset(size.width * .5, size.height * .5), 24, line);

    final route = Path()
      ..moveTo(size.width * .08, size.height * .78)
      ..quadraticBezierTo(
        size.width * .42,
        size.height * .52,
        size.width * .82,
        size.height * .72,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = success ? AppColors.primary : AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(size.width * .82, size.height * .72),
      4,
      Paint()..color = success ? AppColors.primary : AppColors.gold,
    );

    void ticket(Rect rect, Color color, double angle, String label) {
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(angle);
      final local = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: rect.width,
          height: rect.height,
        ),
        const Radius.circular(12),
      );
      canvas.drawRRect(local, Paint()..color = color);
      canvas.drawRRect(
        local,
        Paint()
          ..color = AppColors.paper0.withValues(alpha: .6)
          ..style = PaintingStyle.stroke,
      );
      canvas.drawLine(
        Offset(-rect.width * .18, -rect.height / 2),
        Offset(-rect.width * .18, rect.height / 2),
        Paint()
          ..color = AppColors.ink.withValues(alpha: .45)
          ..strokeWidth = 1,
      );
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: 'ThmanyahSans',
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(-text.width / 2 + 8, -text.height / 2));
      canvas.restore();
    }

    ticket(
      Rect.fromLTWH(size.width * .18, size.height * .2, 92, 58),
      AppColors.gold,
      -.12,
      '11',
    );
    ticket(
      Rect.fromLTWH(size.width * .32, size.height * .34, 96, 62),
      AppColors.primary,
      .07,
      success ? 'OPEN' : 'PASS',
    );

    final lockCenter = Offset(size.width * .22, size.height * .42);
    final lock = Paint()
      ..color = AppColors.paper0
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCircle(
        center: lockCenter.translate(success ? 7 : 0, -8),
        radius: 10,
      ),
      success ? 2.7 : 3.14,
      success ? 2.8 : 3.14,
      false,
      lock,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: lockCenter.translate(0, 6),
          width: 30,
          height: 25,
        ),
        const Radius.circular(7),
      ),
      lock,
    );
  }

  @override
  bool shouldRepaint(covariant _VoucherPainter oldDelegate) =>
      oldDelegate.success != success;
}
