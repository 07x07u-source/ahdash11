import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/ahdash_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/brand_identity.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../domain/guest_capability_policy.dart';
import 'capability_provider.dart';

void openCapabilityDestination(
  BuildContext context,
  WidgetRef ref,
  String path,
) {
  final policy = ref.read(capabilityPolicyProvider);
  context.push(
    policy.allowsLocation(path)
        ? path
        : GuestCapabilityPolicy.gateLocation(path),
  );
}

/// A contextual full-page gate: protected screen providers are never mounted.
final class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({
    required this.destination,
    this.requiredCapability,
    super.key,
  });
  final String destination;
  final AppCapability? requiredCapability;

  @override
  Widget build(BuildContext context) {
    final target = GuestCapabilityPolicy.safeReturnTo(destination);
    final capability =
        requiredCapability ?? GuestCapabilityPolicy.capabilityFor(target);
    final (label, description, icon) = switch (capability) {
      AppCapability.friends => (
        'اللاعبون المحظورون',
        'إدارة قائمة الحظر مرتبطة بحسابك وتحافظ على اختيارات الخصوصية الخاصة بك.',
        Icons.block_outlined,
      ),
      AppCapability.teamChallenge => (
        'تحدي فريق',
        'الفرق والدعوات والتحديات مرتبطة بهوية حسابك وصلاحيات الفريق.',
        AhdashIcons.team,
      ),
      AppCapability.tournaments => (
        'البطولات',
        'أنشئ بطولتك وتابع فرقها ونتائجها بحساب يحدد صلاحيات المنظم والمشاركين.',
        AhdashIcons.tournament,
      ),
      AppCapability.savedGames => (
        'ألعاب محفوظة',
        'أرشيف الألعاب يتطلب حسابًا. تقدر تكمل لعبتك المحلية الحالية من الرئيسية على هذا الجهاز.',
        AhdashIcons.undo,
      ),
      AppCapability.premium => (
        'Premium',
        'سجّل دخولك لعرض خطط المتجر أو استعادة مشترياتك للحساب الصحيح. الاشتراك لا يمنح أفضلية في النقاط.',
        AhdashIcons.premium,
      ),
      AppCapability.notifications => (
        'الإشعارات',
        'دعواتك وتنبيهات حسابك تخصك. سجّل دخولك لعرضها.',
        AhdashIcons.notifications,
      ),
      AppCapability.footballPreferences => (
        'تفضيلاتك الكروية',
        'اختياراتك الكروية تُحفظ في ملف حسابك وتظهر وفق إعدادات خصوصيتك.',
        AhdashIcons.football,
      ),
      AppCapability.reports => (
        'الإبلاغ',
        'إرسال البلاغات يحتاج حسابًا. سجّل دخولك ثم ارجع لإكمال البلاغ.',
        AhdashIcons.flag,
      ),
      _ => (
        'حسابك',
        'ملفك وبياناتك الخاصة تحتاج حسابًا. سجّل دخولك للوصول إليها.',
        AhdashIcons.profile,
      ),
    };
    final headline = switch (capability) {
      AppCapability.tournaments => 'سجّل دخولك\nوابدأ بطولتك',
      AppCapability.premium => 'سجّل دخولك\nوافتح مزاياك',
      AppCapability.notifications => 'سجّل دخولك\nوشوف تنبيهاتك',
      _ => 'سجّل دخولك\nوكمل من هنا',
    };
    return AhdashV10Page(
      title: 'حسابك',
      subtitle: 'ميزة مرتبطة بحسابك',
      onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GuestIdentityHero(label: label, icon: icon),
          const SizedBox(height: 14),
          _GuestGateContext(label: label),
          const SizedBox(height: 16),
          Text(
            headline,
            style: TextStyle(
              fontSize: MediaQuery.sizeOf(context).width < 390 ? 27 : 30,
              height: 1.16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 16),
          const _GuestGateBenefits(),
          const SizedBox(height: 18),
          AhdashV10PrimaryButton(
            key: const ValueKey('gate-sign-in'),
            label: 'تسجيل الدخول',
            icon: Icons.arrow_back_rounded,
            onPressed: () =>
                context.push(GuestCapabilityPolicy.authLocation(target)),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            key: const ValueKey('gate-create-account'),
            onPressed: () => context.push(
              GuestCapabilityPolicy.authLocation(target, create: true),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.inkSoft),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('إنشاء حساب'),
          ),
          const SizedBox(height: 12),
          const _GuestLocalNote(),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('العودة للعب'),
          ),
        ],
      ),
    );
  }
}

final class _GuestGateContext extends StatelessWidget {
  const _GuestGateContext({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(Icons.lock_open_rounded, size: 17),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          'أنت على وشك فتح: $label',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w800,
            color: AppColors.inkSoft,
          ),
        ),
      ),
    ],
  );
}

final class _GuestGateBenefits extends StatelessWidget {
  const _GuestGateBenefits();

  @override
  Widget build(BuildContext context) => AhdashV10Panel(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
    backgroundColor: AppColors.paper1.withValues(alpha: .68),
    child: const Column(
      children: [
        _GuestBenefitRow(
          icon: Icons.person_outline_rounded,
          title: 'حساب واحد',
          detail: 'تصل لميزاتك الخاصة من مكان واحد',
        ),
        Divider(height: 1, color: AppColors.hairline),
        _GuestBenefitRow(
          icon: Icons.undo_rounded,
          title: 'نكمل من حيث توقفت',
          detail: 'نرجعك للوجهة المطلوبة بعد الدخول',
        ),
        Divider(height: 1, color: AppColors.hairline),
        _GuestBenefitRow(
          icon: Icons.sports_soccer_rounded,
          title: 'اللعبة المحلية باقية',
          detail: 'تسجيل الدخول لا يبدأ لعبة جديدة',
        ),
      ],
    ),
  );
}

final class _GuestBenefitRow extends StatelessWidget {
  const _GuestBenefitRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(icon, size: 19, color: AppColors.inkSoft),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_rounded, size: 17, color: AppColors.inkSoft),
      ],
    ),
  );
}

final class _GuestLocalNote extends StatelessWidget {
  const _GuestLocalNote();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.fromSTEB(12, 9, 12, 9),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.primary.withValues(alpha: .46)),
    ),
    child: const Row(
      children: [
        Icon(Icons.offline_bolt_rounded, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'لعبتك المحلية تبقى على هذا الجهاز، وتقدر ترجع لها في أي وقت.',
            style: TextStyle(
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

final class _GuestIdentityHero extends StatelessWidget {
  const _GuestIdentityHero({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('guest-identity-hero'),
    height: 220,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [Color(0xFF24231F), AppColors.ink],
      ),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: AppColors.inkSoft.withValues(alpha: .45)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x28191714),
          blurRadius: 22,
          offset: Offset(0, 9),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const PositionedDirectional(
          top: 10,
          bottom: 10,
          end: 8,
          width: 164,
          child: CustomPaint(painter: _GuestIdentityPainter()),
        ),
        const PositionedDirectional(
          top: 0,
          bottom: 0,
          start: 0,
          width: 5,
          child: ColoredBox(color: AppColors.primary),
        ),
        PositionedDirectional(
          top: 18,
          bottom: 16,
          start: 18,
          end: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AhdashBrandLogo(
                width: 118,
                height: 34,
                onDarkSurface: true,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
                decoration: BoxDecoration(
                  color: AppColors.paper0.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: AppColors.paper0.withValues(alpha: .16),
                  ),
                ),
                child: const Text(
                  'حساب اللاعب / GUEST',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: AppColors.paper3,
                    fontSize: 8,
                    letterSpacing: .4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.paper0,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'IDENTITY REQUIRED / 11',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: AppColors.paper3,
                  fontSize: 8,
                  letterSpacing: .9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _GuestIdentityPainter extends CustomPainter {
  const _GuestIdentityPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.paper3.withValues(alpha: .34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final field = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      const Radius.circular(18),
    );
    canvas.drawRRect(field, line);
    canvas.drawLine(
      Offset(size.width * .5, 2),
      Offset(size.width * .5, size.height - 2),
      line,
    );
    canvas.drawCircle(field.center, 24, line);
    final route = Path()
      ..moveTo(size.width * .08, size.height * .8)
      ..quadraticBezierTo(
        size.width * .42,
        size.height * .5,
        size.width * .76,
        size.height * .7,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7,
    );
    final card = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * .62, size.height * .45),
        width: 60,
        height: 82,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(card, Paint()..color = AppColors.primary);
    final number = TextPainter(
      text: const TextSpan(
        text: '١١',
        style: TextStyle(
          color: AppColors.ink,
          fontFamily: 'ThmanyahSans',
          fontSize: 25,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    number.paint(
      canvas,
      Offset(
        card.center.dx - number.width / 2,
        card.center.dy - number.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
