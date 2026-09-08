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
        'الأصدقاء',
        'أضف ربعك وتابع طلبات الصداقة من حسابك. بيانات الأصدقاء خاصة بأصحابها.',
        AhdashIcons.group,
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
      AppCapability.ranking => (
        'الترتيب',
        'سجّل دخولك لعرض الترتيب المتاح وبيانات حسابك، عندما تكون متوفرة.',
        AhdashIcons.chart,
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
    return AhdashV10Page(
      title: label,
      subtitle: 'ميزة مرتبطة بحسابك',
      onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GuestIdentityHero(label: label, icon: icon),
          const SizedBox(height: 22),
          const Text(
            'سجّل دخولك\nوكمل التحدّي',
            style: TextStyle(
              fontSize: 29,
              height: 1.18,
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
          const SizedBox(height: 20),
          AhdashV10PrimaryButton(
            key: const ValueKey('gate-sign-in'),
            label: 'تسجيل الدخول',
            onPressed: () =>
                context.push(GuestCapabilityPolicy.authLocation(target)),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            key: const ValueKey('gate-create-account'),
            onPressed: () => context.push(
              GuestCapabilityPolicy.authLocation(target, create: true),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('إنشاء حساب'),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'لعبتك المحلية تبقى على هذا الجهاز. تسجيل الدخول لا يبدأ لعبة جديدة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.inkMuted,
            ),
          ),
          TextButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
            child: const Text('العودة'),
          ),
        ],
      ),
    );
  }
}

final class _GuestIdentityHero extends StatelessWidget {
  const _GuestIdentityHero({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    height: 194,
    decoration: BoxDecoration(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(24),
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const PositionedDirectional(
          top: 10,
          bottom: 10,
          end: 10,
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
          top: 20,
          bottom: 18,
          start: 20,
          end: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AhdashBrandLogo(
                width: 118,
                height: 36,
                onDarkSurface: true,
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
                  fontSize: 21,
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
