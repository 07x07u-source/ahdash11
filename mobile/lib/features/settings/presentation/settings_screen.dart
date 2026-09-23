import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/app_services.dart';
import '../../../core/services/legal_link_service.dart';
import '../../../core/settings/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/utility_v9.dart';
import '../../auth/domain/guest_capability_policy.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/capability_provider.dart';
import '../../premium/presentation/premium_controller.dart';
import 'notification_preferences_controller.dart';

final class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

final class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _busy = <String>{};
  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final user = ref.watch(authControllerProvider).asData?.value;
    final preferences =
        ref.watch(appPreferencesProvider).value ?? const AppPreferences();
    final premium =
        ref.watch(premiumControllerProvider).asData?.value.hasAccess ?? false;
    final hasAccount = user != null && !user.isGuest;
    return AhdashUtilityScaffold(
      title: 'الإعدادات',
      child: ListView(
        key: const ValueKey('settings-scroll'),
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _identityCard(
            username: user?.username ?? 'ضيف',
            hasAccount: hasAccount,
            premium: premium,
            onTap: () => context.push('/profile'),
          ),
          const SizedBox(height: 18),
          _sectionLabel('تجربة اللعب', Icons.tune_rounded),
          const SizedBox(height: 8),
          _devicePreferencesCard(preferences),
          const SizedBox(height: 16),
          _section('حسابك وتفضيلاتك', Icons.person_outline_rounded, [
            _settingsRow(
              icon: Icons.person_outline_rounded,
              label: 'تعديل الملف الشخصي',
              subtitle: hasAccount ? user.username : 'يتطلب حسابًا',
              onTap: () => context.push('/profile'),
            ),
            _settingsRow(
              icon: Icons.sports_soccer_rounded,
              label: 'تفضيلاتي الكروية',
              subtitle: hasAccount ? 'الأندية والبطولات' : 'يتطلب حسابًا',
              onTap: () => context.push('/football-preferences'),
            ),
            _settingsRow(
              icon: Icons.notifications_none_rounded,
              label: 'تفضيلات الإشعارات',
              subtitle: hasAccount
                  ? 'تحكم بالدعوات والتحديثات'
                  : 'يتطلب حسابًا',
              onTap: () => _group('notifications'),
              last: true,
            ),
          ]),
          const SizedBox(height: 14),
          _sectionLabel('Premium', Icons.workspace_premium_outlined),
          const SizedBox(height: 8),
          _premiumRow(active: premium, onTap: () => context.push('/premium')),
          const SizedBox(height: 16),
          _section('الدعم والخصوصية', Icons.shield_outlined, [
            _settingsRow(
              icon: Icons.campaign_outlined,
              label: 'الإبلاغ عن مشكلة',
              subtitle: 'ساعدنا نحسّن تجربتك',
              onTap: () => context.push('/report-problem'),
            ),
            _settingsRow(
              icon: Icons.block_rounded,
              label: 'اللاعبون المحظورون',
              subtitle: hasAccount ? null : 'يتطلب حسابًا',
              onTap: () => context.push('/blocked-players'),
            ),
            _settingsRow(
              icon: Icons.description_outlined,
              label: 'شروط الاستخدام',
              onTap: () => _openLegal(config.termsUrl),
            ),
            _settingsRow(
              icon: Icons.verified_user_outlined,
              label: 'سياسة الخصوصية',
              onTap: () => _openLegal(config.privacyPolicyUrl),
              last: true,
            ),
          ]),
          const SizedBox(height: 14),
          _sectionLabel('الجلسة', Icons.logout_rounded),
          const SizedBox(height: 8),
          SizedBox(
            height: 54,
            child: OutlinedButton(
              key: ValueKey(hasAccount ? 'settings-sign-out' : 'settings-auth'),
              onPressed: hasAccount
                  ? (_busy.contains('signout') ? null : _signOut)
                  : () => context.push('/auth'),
              style: OutlinedButton.styleFrom(
                foregroundColor: hasAccount
                    ? const Color(0xFFC83443)
                    : AppColors.ink,
                backgroundColor: AppColors.paper1,
                side: BorderSide(
                  color: hasAccount
                      ? const Color(0xFFC83443).withValues(alpha: .28)
                      : AppColors.hairline,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hasAccount ? 'تسجيل الخروج' : 'تسجيل الدخول',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_busy.contains('signout'))
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      hasAccount ? Icons.logout_rounded : Icons.login_rounded,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _identityCard({
    required String username,
    required bool hasAccount,
    required bool premium,
    required VoidCallback onTap,
  }) {
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 16;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 5,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: .32),
                ),
              ),
              child: Text(
                hasAccount ? 'مساحتك الشخصية' : 'وضع الضيف',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (premium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Premium',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          username,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.paper0,
            fontSize: 22,
            height: 1.12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
    final artwork = SizedBox(
      width: largeText ? 138 : 122,
      height: largeText ? 106 : 102,
      child: ExcludeSemantics(
        child: Image.asset(
          'assets/visuals/settings_identity_art_v2.png',
          key: const ValueKey('settings-identity-art'),
          fit: BoxFit.contain,
          cacheWidth: 256,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
    return Material(
      key: const ValueKey('settings-identity-card'),
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [Color(0xFF244A39), Color(0xFF172A21), Color(0xFF111713)],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: largeText
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [copy, const SizedBox(height: 8), artwork],
                  )
                : Row(
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: 12),
                      artwork,
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _devicePreferencesCard(AppPreferences preferences) {
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 19;
    final controls = <Widget>[
      _quickPreference(
        keyName: 'sound',
        icon: Icons.volume_up_outlined,
        label: 'الصوت',
        enabled: preferences.soundEffects,
        onTap: () => _setLocalPreference(
          'sound',
          () => ref
              .read(appPreferencesProvider.notifier)
              .setSoundEffects(!preferences.soundEffects),
        ),
      ),
      _quickPreference(
        keyName: 'haptics',
        icon: Icons.vibration_rounded,
        label: 'الاهتزاز',
        enabled: preferences.haptics,
        onTap: () => _setLocalPreference(
          'haptics',
          () => ref
              .read(appPreferencesProvider.notifier)
              .setHaptics(!preferences.haptics),
        ),
      ),
      _quickPreference(
        keyName: 'motion',
        icon: Icons.animation_rounded,
        label: 'حركة أقل',
        enabled: preferences.reducedMotion,
        onTap: () => _setLocalPreference(
          'motion',
          () => ref
              .read(appPreferencesProvider.notifier)
              .setReducedMotion(!preferences.reducedMotion),
        ),
      ),
    ];
    return Material(
      key: const ValueKey('settings-device-preferences'),
      color: AppColors.paper1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'تعديلات سريعة',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _group('local'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'عرض التفاصيل',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            if (largeText)
              Column(
                children: [
                  for (var index = 0; index < controls.length; index++) ...[
                    controls[index],
                    if (index != controls.length - 1) const SizedBox(height: 8),
                  ],
                ],
              )
            else
              Row(
                children: [
                  for (var index = 0; index < controls.length; index++) ...[
                    Expanded(child: controls[index]),
                    if (index != controls.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            const SizedBox(height: 9),
            const Row(
              children: [
                Icon(
                  Icons.cloud_done_outlined,
                  size: 14,
                  color: AppColors.palm,
                ),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'تحفظ هذه الخيارات تلقائيًا على جهازك.',
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickPreference({
    required String keyName,
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final busy = _busy.contains('preference-$keyName');
    return Semantics(
      button: true,
      toggled: enabled,
      label: '$label، ${enabled ? 'مفعّل' : 'متوقف'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('settings-quick-$keyName'),
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 78),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFFE9F5CF) : AppColors.paper0,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: enabled ? AppColors.primary : AppColors.hairline,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: enabled ? AppColors.ink : AppColors.paper2,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: busy
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          icon,
                          size: 17,
                          color: enabled
                              ? AppColors.primary
                              : AppColors.inkMuted,
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        enabled ? 'مفعّل' : 'متوقف',
                        style: TextStyle(
                          color: enabled ? AppColors.palm : AppColors.inkMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _sectionLabel(title, icon),
      const SizedBox(height: 8),
      Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: rows),
      ),
    ],
  );

  Widget _sectionLabel(String title, IconData icon) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 4),
    child: Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 13, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 12,
            height: 1,
            letterSpacing: .2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: AppColors.hairline)),
      ],
    ),
  );

  Widget _settingsRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? subtitle,
    bool last = false,
  }) => Column(
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.paper1,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.inkSoft),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 10,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 17,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
      if (!last)
        const Padding(
          padding: EdgeInsetsDirectional.only(start: 60),
          child: Divider(height: 1),
        ),
    ],
  );

  Widget _premiumRow({
    required bool active,
    required VoidCallback onTap,
  }) => Material(
    key: const ValueKey('settings-premium-row'),
    color: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: active ? AppColors.primary : AppColors.gold),
    ),
    clipBehavior: Clip.antiAlias,
    child: Ink(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF2A241A), Color(0xFF171613)],
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.gold,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: (active ? AppColors.primary : AppColors.gold)
                          .withValues(alpha: .2),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(
                  active
                      ? Icons.verified_rounded
                      : Icons.workspace_premium_rounded,
                  color: AppColors.ink,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active ? 'Premium مفعّل' : 'أحدعش Premium',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      active
                          ? 'اشتراكك نشط — اضغط للإدارة'
                          : 'فئات حصرية وتجربة لعب بلا إعلانات',
                      style: const TextStyle(
                        color: AppColors.paper3,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: .1)),
                ),
                child: Text(
                  active ? 'إدارة' : 'اكتشف',
                  style: TextStyle(
                    color: active ? AppColors.primary : AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _setLocalPreference(
    String key,
    Future<void> Function() action,
  ) async {
    final busyKey = 'preference-$key';
    if (!_busy.add(busyKey)) return;
    setState(() {});
    try {
      await action();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ التفضيل. أعد المحاولة.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(busyKey));
    }
  }

  Future<void> _openLegal(String value) async {
    final service = ref.read(legalLinkServiceProvider);
    if (!service.isAvailable(value)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('الرابط غير مهيأ بعد.')));
      }
      return;
    }
    final result = await service.open(value);
    if (mounted && result.messageAr != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.messageAr!)));
    }
  }

  Future<void> _signOut() async {
    if (!_busy.add('signout')) return;
    setState(() {});
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (mounted) context.go('/auth');
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تسجيل الخروج. حاول مجددًا.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove('signout'));
    }
  }

  Future<void> _group(String group) async {
    final capability = group == 'account'
        ? AppCapability.profile
        : group == 'notifications'
        ? AppCapability.notifications
        : AppCapability.localSettings;
    if (!ref.read(capabilityPolicyProvider).allows(capability)) {
      await context.push<void>(
        GuestCapabilityPolicy.gateLocation(
          group == 'account' ? '/profile' : '/notifications',
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: .88,
        child: _SettingsGroup(group: group),
      ),
    );
  }
}

final class _SettingsGroup extends ConsumerStatefulWidget {
  const _SettingsGroup({required this.group});
  final String group;
  @override
  ConsumerState<_SettingsGroup> createState() => _SettingsGroupState();
}

final class _SettingsGroupState extends ConsumerState<_SettingsGroup> {
  bool _busy = false;
  String? _message;
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final preferences =
        ref.watch(appPreferencesProvider).value ?? const AppPreferences();
    final config = ref.watch(appConfigProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.hairline,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                switch (widget.group) {
                  'notifications' => Icons.notifications_none_rounded,
                  'local' => Icons.tune_rounded,
                  'account' => Icons.person_outline_rounded,
                  _ => Icons.support_agent_rounded,
                },
                color: AppColors.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    switch (widget.group) {
                      'account' => 'الحساب وهوية اللاعب',
                      'notifications' => 'تفضيلات الإشعارات',
                      'local' => 'تجربة اللعب',
                      _ => 'المساعدة والخصوصية',
                    },
                    style: const TextStyle(
                      fontSize: 21,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    switch (widget.group) {
                      'notifications' => 'اختر التحديثات التي تهمك.',
                      'local' => 'اضبط الإحساس والصوت على هذا الجهاز.',
                      'account' => 'تحكم في هويتك وبيانات حسابك.',
                      _ => 'كل أدوات المساعدة في مكان واحد.',
                    },
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'إغلاق',
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                minimumSize: const Size.square(44),
                backgroundColor: AppColors.paper1,
                side: const BorderSide(color: AppColors.hairline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (_message != null)
          Semantics(
            liveRegion: true,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F5CF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary),
              ),
              child: Text(
                _message!,
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        if (widget.group == 'local') ...[
          const _SettingsNotice(
            icon: Icons.phone_android_rounded,
            text: 'هذه التفضيلات محلية، ولا تحتاج إلى تسجيل الدخول.',
          ),
          const SizedBox(height: 12),
          _preferenceSwitch(
            icon: Icons.volume_up_outlined,
            title: 'المؤثرات الصوتية',
            subtitle: 'أصوات الإجابة والمؤقت والنتائج',
            value: preferences.soundEffects,
            onChanged: _busy
                ? null
                : (v) => _run(
                    () => ref
                        .read(appPreferencesProvider.notifier)
                        .setSoundEffects(v),
                  ),
          ),
          _preferenceSwitch(
            icon: Icons.vibration_rounded,
            title: 'الاهتزاز',
            subtitle: 'استجابة لمسية للأزرار والأحداث المهمة',
            value: preferences.haptics,
            onChanged: _busy
                ? null
                : (v) => _run(
                    () =>
                        ref.read(appPreferencesProvider.notifier).setHaptics(v),
                  ),
          ),
          _preferenceSwitch(
            icon: Icons.animation_rounded,
            title: 'تقليل الحركة',
            subtitle: 'حركات انتقال أبسط وأكثر هدوءًا',
            value: preferences.reducedMotion,
            onChanged: _busy
                ? null
                : (v) => _run(
                    () => ref
                        .read(appPreferencesProvider.notifier)
                        .setReducedMotion(v),
                  ),
          ),
        ] else if (widget.group == 'account') ...[
          if (user != null && !user.isGuest)
            ListTile(
              title: Text(user.username),
              subtitle: const Text('الحساب الحالي'),
            ),
          const Text('هوية Player 11'),
          for (final variant in Player11Variant.values)
            CheckboxListTile(
              title: Text(variant.labelAr),
              value: variant == preferences.player11Variant,
              onChanged: _busy
                  ? null
                  : (_) => _run(
                      () => ref
                          .read(appPreferencesProvider.notifier)
                          .setPlayer11Variant(variant),
                    ),
            ),
          ListTile(
            title: const Text('ملفي الكروي'),
            onTap: () {
              Navigator.pop(context);
              context.push('/profile');
            },
          ),
          if (GuestCapabilityPolicy(user).hasAccount) ...[
            ListTile(
              title: const Text('تسجيل الخروج'),
              enabled: !_busy,
              onTap: () => _run(() async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.go('/auth');
              }),
            ),
            ListTile(
              title: const Text('حذف الحساب'),
              enabled: !_busy,
              onTap: _delete,
            ),
          ],
        ] else if (widget.group == 'notifications') ...[
          const _SettingsNotice(
            icon: Icons.info_outline_rounded,
            text:
                'التفضيلات تحدد ما نرسله، بينما وصوله يعتمد أيضًا على إذن الجهاز والاتصال.',
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                    final allowed = await ref
                        .read(appServicesProvider)
                        .notifications
                        .requestPermission();
                    if (mounted) {
                      setState(
                        () => _message = allowed
                            ? 'إذن الإشعارات مفعّل.'
                            : 'لم يُمنح إذن الإشعارات.',
                      );
                    }
                  }),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'التحقق من إذن الجهاز',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 14),
          ref
              .watch(notificationPreferencesProvider)
              .when(
                skipLoadingOnRefresh: false,
                skipLoadingOnReload: false,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Column(
                  children: [
                    const Text(
                      'تفضيلات الإشعارات غير متاحة. سجّل دخولك وتحقق من الاتصال.',
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(notificationPreferencesProvider),
                      child: const Text('أعد المحاولة'),
                    ),
                  ],
                ),
                data: (values) => Column(
                  children: [
                    for (final entry in const {
                      'match_invites': 'دعوات المباريات',
                      'challenges': 'تحديات الفريق',
                      'rewards': 'المكافآت',
                      'season_events': 'أحداث الموسم',
                      'announcements': 'الأخبار',
                      'teams': 'الفِرق',
                      'promotions': 'العروض الترويجية',
                    }.entries)
                      _preferenceSwitch(
                        icon: _notificationPreferenceIcon(entry.key),
                        title: entry.value,
                        subtitle: _notificationPreferenceDescription(entry.key),
                        value: values[entry.key] ?? false,
                        onChanged: _busy
                            ? null
                            : (v) => _run(
                                () => ref
                                    .read(
                                      notificationPreferencesProvider.notifier,
                                    )
                                    .setPreference(entry.key, v),
                              ),
                      ),
                  ],
                ),
              ),
        ] else ...[
          ListTile(
            title: const Text('الإبلاغ عن مشكلة'),
            onTap: () {
              Navigator.pop(context);
              context.push('/report-problem');
            },
          ),
          ListTile(
            title: const Text('اللاعبون المحظورون'),
            onTap: () {
              Navigator.pop(context);
              context.push('/blocked-players');
            },
          ),
          _legalTile('سياسة الخصوصية', config.privacyPolicyUrl),
          _legalTile('الشروط والأحكام', config.termsUrl),
        ],
      ],
    );
  }

  Widget _preferenceSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: value ? const Color(0xFFE9F5CF) : AppColors.paper1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: value ? AppColors.primary : AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: value ? AppColors.ink : AppColors.paper0,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value ? AppColors.ink : AppColors.hairline,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: value ? AppColors.primary : AppColors.inkMuted,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 10,
            height: 1.35,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    ),
  );

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } on Object {
      if (mounted) {
        setState(() => _message = 'تعذر إكمال الإجراء. أعد المحاولة.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _legalTile(String title, String value) {
    final service = ref.read(legalLinkServiceProvider);
    final available = service.isAvailable(value);
    return ListTile(
      title: Text(title),
      subtitle: available ? null : const Text('الرابط غير مهيأ بعد.'),
      enabled: available && !_busy,
      onTap: available ? () => _open(value) : null,
    );
  }

  Future<void> _open(String value) => _run(() async {
    final result = await ref.read(legalLinkServiceProvider).open(value);
    if (mounted && result.messageAr != null) {
      setState(() => _message = result.messageAr);
    }
  });
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('حذف الحساب نهائيًا؟'),
        content: const Text(
          'هذا الإجراء يطلب حذف بيانات الحساب ولا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('حذف الحساب'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      await ref.read(authControllerProvider.notifier).deleteAccount();
      if (mounted) context.go('/auth');
    });
  }
}

final class _SettingsNotice extends StatelessWidget {
  const _SettingsNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.paper1,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.hairline),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.palm, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
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

IconData _notificationPreferenceIcon(String key) => switch (key) {
  'match_invites' => Icons.sports_soccer_rounded,
  'challenges' => Icons.bolt_rounded,
  'rewards' => Icons.redeem_rounded,
  'season_events' => Icons.emoji_events_outlined,
  'announcements' => Icons.campaign_outlined,
  'teams' => Icons.groups_outlined,
  _ => Icons.local_offer_outlined,
};

String _notificationPreferenceDescription(String key) => switch (key) {
  'match_invites' => 'دعوات اللعب والمواجهات الجديدة',
  'challenges' => 'تحديثات تحدياتك الجماعية',
  'rewards' => 'المكافآت الجاهزة للاستلام',
  'season_events' => 'بدايات ونهايات أحداث الموسم',
  'announcements' => 'أهم أخبار ومزايا أحدعش',
  'teams' => 'دعوات الفريق وتغييرات الأعضاء',
  _ => 'العروض والفرص المختارة لك',
};
