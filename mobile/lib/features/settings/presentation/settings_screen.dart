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
import 'settings_visuals.dart';

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
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _identityCard(
            username: user?.username ?? 'ضيف',
            hasAccount: hasAccount,
            premium: premium,
            onTap: () => context.push('/profile'),
          ),
          const SizedBox(height: 18),
          _section('على هذا الجهاز', Icons.tune_rounded, [
            _settingsRow(
              icon: Icons.tune_rounded,
              label: 'الصوت والاهتزاز والحركة',
              subtitle: [
                if (preferences.soundEffects) 'الصوت',
                if (preferences.haptics) 'الاهتزاز',
                if (preferences.reducedMotion) 'حركة أقل',
              ].join(' • '),
              onTap: () => _group('local'),
              last: true,
            ),
          ]),
          const SizedBox(height: 14),
          _section('الحساب', Icons.person_outline_rounded, [
            _settingsRow(
              icon: Icons.person_outline_rounded,
              label: 'تعديل الملف الشخصي',
              subtitle: hasAccount ? user.username : 'يتطلب حسابًا',
              onTap: () => context.push('/profile'),
              last: true,
            ),
          ]),
          const SizedBox(height: 14),
          _section('كرة القدم', Icons.sports_soccer_rounded, [
            _settingsRow(
              icon: Icons.sports_soccer_rounded,
              label: 'تفضيلاتي الكروية',
              subtitle: hasAccount ? 'الأندية والبطولات' : 'يتطلب حسابًا',
              onTap: () => context.push('/football-preferences'),
              last: true,
            ),
          ]),
          const SizedBox(height: 14),
          _section('الإشعارات', Icons.notifications_none_rounded, [
            _settingsRow(
              icon: Icons.notifications_none_rounded,
              label: 'الإشعارات',
              subtitle: hasAccount ? 'تحكم بما يصلك' : 'يتطلب حسابًا',
              onTap: () => _group('notifications'),
              last: true,
            ),
          ]),
          const SizedBox(height: 14),
          _sectionLabel('Premium', Icons.workspace_premium_outlined),
          const SizedBox(height: 8),
          _premiumRow(active: premium, onTap: () => context.push('/premium')),
          const SizedBox(height: 14),
          _section('الدعم', Icons.support_agent_rounded, [
            _settingsRow(
              icon: Icons.flag_outlined,
              label: 'الإبلاغ عن مشكلة',
              onTap: () => context.push('/report-problem'),
              last: true,
            ),
          ]),
          const SizedBox(height: 14),
          _section('الخصوصية والقانوني', Icons.verified_user_outlined, [
            _settingsRow(
              icon: Icons.block_rounded,
              label: 'اللاعبون المحظورون',
              subtitle: hasAccount ? null : 'يتطلب حسابًا',
              onTap: () => context.push('/blocked-players'),
            ),
            _settingsRow(
              icon: Icons.description_outlined,
              label: 'شروط وأحكام الاستخدام',
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
  }) => Material(
    key: const ValueKey('settings-identity-card'),
    color: AppColors.ink,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: MediaQuery.textScalerOf(context).scale(1) >= 1.2 ? 176 : 138,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PositionedDirectional(
              top: 10,
              bottom: 10,
              end: 10,
              width: 142,
              child: ExcludeSemantics(
                child: SettingsIdentityArtwork(premium: premium),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 148, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hasAccount ? 'PLAYER SETTINGS / 11' : 'GUEST MODE / 11',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      letterSpacing: 1.05,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.paper0,
                      fontSize: 23,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    premium
                        ? 'Premium مفعّل'
                        : hasAccount
                        ? 'إدارة ملفك وتفضيلاتك'
                        : 'سجّل الدخول للوصول إلى ميزات الحساب',
                    maxLines: 2,
                    style: const TextStyle(
                      color: AppColors.paper2,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _section(String title, IconData icon, List<Widget> rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _sectionLabel(title, icon),
      const SizedBox(height: 8),
      Material(
        color: AppColors.paper0,
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

  Widget _premiumRow({required bool active, required VoidCallback onTap}) =>
      Material(
        key: const ValueKey('settings-premium-row'),
        color: AppColors.paper0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.gold),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.gold,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    active ? Icons.check_rounded : Icons.lock_open_rounded,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        active ? 'Premium مفعّل' : 'أحدعش Premium',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        active
                            ? 'إدارة حالة اشتراكك'
                            : 'فئات حصرية • لعب بدون إعلانات',
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.paper0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

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
        Row(
          children: [
            Expanded(
              child: Text(
                switch (widget.group) {
                  'account' => 'الحساب وهوية اللاعب',
                  'notifications' => 'الإشعارات',
                  'local' => 'على هذا الجهاز',
                  _ => 'المساعدة والخصوصية',
                },
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              tooltip: 'إغلاق',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        if (_message != null)
          Semantics(liveRegion: true, child: Text(_message!)),
        if (widget.group == 'local') ...[
          const Text('تفضيلات محلية لا تحتاج إلى حساب.'),
          SwitchListTile(
            title: const Text('المؤثرات الصوتية'),
            value: preferences.soundEffects,
            onChanged: _busy
                ? null
                : (v) => _run(
                    () => ref
                        .read(appPreferencesProvider.notifier)
                        .setSoundEffects(v),
                  ),
          ),
          SwitchListTile(
            title: const Text('الاهتزاز'),
            value: preferences.haptics,
            onChanged: _busy
                ? null
                : (v) => _run(
                    () =>
                        ref.read(appPreferencesProvider.notifier).setHaptics(v),
                  ),
          ),
          SwitchListTile(
            title: const Text('تقليل الحركة'),
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
          const Text(
            'التفضيلات لا تضمن وصول الإشعار؛ إذن الجهاز والاتصال مطلوبان.',
          ),
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
            child: const Text('طلب إذن إشعارات الجهاز'),
          ),
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
                      'friend_requests': 'طلبات ربعك',
                      'match_invites': 'دعوات المباريات',
                      'challenges': 'تحديات الفريق',
                      'rewards': 'المكافآت',
                      'season_events': 'أحداث الموسم',
                      'announcements': 'الأخبار',
                      'teams': 'الفِرق',
                      'promotions': 'العروض الترويجية',
                    }.entries)
                      SwitchListTile(
                        title: Text(entry.value),
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
