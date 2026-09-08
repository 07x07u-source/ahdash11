import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/settings/app_preferences.dart';
import '../../../core/theme/ahdash_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/presentation/brand_identity.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/measured_v9.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../../content/domain/app_content.dart';
import '../../content/presentation/app_content_controller.dart';
import '../domain/auth_repository.dart';
import '../domain/guest_capability_policy.dart';
import 'auth_controller.dart';

enum AuthMode { signIn, createAccount }

final class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    this.initialMode = AuthMode.signIn,
    this.returnTo,
    super.key,
  });

  final AuthMode initialMode;
  final String? returnTo;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

final class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  final _portraitScroll = ScrollController(keepScrollOffset: false);
  late AuthMode _mode;
  var _social = <SocialProvider>{};
  var _obscurePassword = true;
  var _initialScrollSettled = false;
  String? _inlineError;

  bool get _createAccount => _mode == AuthMode.createAccount;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _username.dispose();
    _portraitScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        if (mounted) setState(() => _inlineError = _friendlyError(error));
      }
    });
    final auth = ref.watch(authControllerProvider);
    final config = ref.watch(appConfigProvider);
    final content =
        ref.watch(appContentProvider).value ?? AppContentBundle.defaults;
    final preferences = ref.watch(appPreferencesProvider).value;
    final busy = auth is AsyncLoading;
    final nativeMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final showGoogle = config.googleAuthAvailable && nativeMobile;
    final showApple =
        config.appleAuthAvailable &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS;
    final remoteBackground =
        content.imageUrl(AppContentKeys.authLoginBackground) ??
        content.imageUrl(AppContentKeys.brandingLoginArtwork);
    final metrics = context.v9Metrics;
    final reducedMotion =
        MediaQuery.disableAnimationsOf(context) ||
        (preferences?.reducedMotion ?? false);
    final splitCreateAccount =
        metrics.compact && !metrics.portrait && _createAccount;

    return BrandScaffold(
      showDevelopmentBadge: false,
      body: splitCreateAccount
          ? _compactCreateAccountLayout(
              remoteBackground: remoteBackground,
              busy: busy,
              reducedMotion: reducedMotion,
            )
          : _fullBleedLayout(
              remoteBackground: remoteBackground,
              busy: busy,
              showGoogle: showGoogle,
              showApple: showApple,
              compact: metrics.compact,
              portrait: metrics.portrait,
              reducedMotion: reducedMotion,
            ),
    );
  }

  Widget _fullBleedLayout({
    required String? remoteBackground,
    required bool busy,
    required bool showGoogle,
    required bool showApple,
    required bool compact,
    required bool portrait,
    required bool reducedMotion,
  }) {
    if (portrait) {
      return _portraitAuthLayout(
        busy: busy,
        showGoogle: showGoogle,
        showApple: showApple,
        reducedMotion: reducedMotion,
      );
    }
    return ColoredBox(
      color: AppColors.paper1,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 260,
                width: double.infinity,
                child: _LoginBackground(remoteUrl: remoteBackground),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: portrait ? 196 : 0),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.paper1,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: AhdashV10KeyboardScroll(
                  child: _entrance(
                    reducedMotion: reducedMotion,
                    child: _authForm(
                      busy: busy,
                      showGoogle: showGoogle,
                      showApple: showApple,
                      compact: true,
                      compactSplit: false,
                      figmaPortrait: false,
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

  Widget _portraitAuthLayout({
    required bool busy,
    required bool showGoogle,
    required bool showApple,
    required bool reducedMotion,
  }) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (!_initialScrollSettled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _initialScrollSettled = true;
        if (!keyboardOpen && _portraitScroll.hasClients) {
          _portraitScroll.jumpTo(0);
        }
      });
    }
    return ColoredBox(
      color: AppColors.paper0,
      child: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: LayoutBuilder(
            builder: (context, constraints) => KeyedSubtree(
              key: const ValueKey('v10-keyboard-scroll'),
              child: SingleChildScrollView(
                key: ValueKey('auth-scroll-${_mode.name}'),
                controller: _portraitScroll,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  16,
                  keyboardOpen ? 8 : 14,
                  16,
                  keyboardOpen ? 18 : 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        (constraints.maxHeight - (keyboardOpen ? 26 : 34))
                            .clamp(0, double.infinity),
                  ),
                  child: _entrance(
                    reducedMotion: reducedMotion,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AuthPortraitBrand(
                          compact: constraints.maxWidth <= 360,
                        ),
                        SizedBox(height: keyboardOpen ? 10 : 16),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.paper1,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.hairline),
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              constraints.maxWidth <= 360 ? 18 : 22,
                              keyboardOpen ? 16 : 20,
                              constraints.maxWidth <= 360 ? 18 : 22,
                              keyboardOpen ? 16 : 20,
                            ),
                            child: _authForm(
                              busy: busy,
                              showGoogle: showGoogle,
                              showApple: showApple,
                              compact: constraints.maxWidth <= 390,
                              compactSplit: false,
                              figmaPortrait: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactCreateAccountLayout({
    required String? remoteBackground,
    required bool busy,
    required bool reducedMotion,
  }) {
    return ColoredBox(
      color: const Color(0xFF191714),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
            final imageWidth = (constraints.maxWidth * 0.35).clamp(
              220.0,
              295.0,
            );
            return Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        32,
                        14,
                        32,
                        14 + keyboardInset,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              (constraints.maxHeight - 28 - keyboardInset)
                                  .clamp(0, double.infinity),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Theme(
                            data: AppTheme.dark,
                            child: Center(
                              child: _entrance(
                                reducedMotion: reducedMotion,
                                child: _authForm(
                                  busy: busy,
                                  showGoogle: false,
                                  showApple: false,
                                  compact: true,
                                  compactSplit: true,
                                  figmaPortrait: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: imageWidth,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _LoginBackground(remoteUrl: remoteBackground),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00191714), Color(0xE6191714)],
                            ),
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: TextButton.icon(
                              onPressed: busy ? null : _guest,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFFBF7EF),
                              ),
                              icon: const Icon(AhdashIcons.guest, size: 16),
                              label: const Text('الدخول كضيف سريع'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _entrance({required bool reducedMotion, required Widget child}) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_mode),
      duration: reducedMotion ? Duration.zero : AppMotion.reveal,
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      ),
    );
  }

  Widget _authForm({
    required bool busy,
    required bool showGoogle,
    required bool showApple,
    required bool compact,
    required bool compactSplit,
    required bool figmaPortrait,
  }) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final fieldGap = keyboardOpen
        ? 10.0
        : (figmaPortrait ? 14.0 : (compact ? 7.0 : 10.0));
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!figmaPortrait) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _AuthBrand(compact: compact),
            ),
            SizedBox(height: compact ? 5 : 12),
          ],
          Text(
            _createAccount ? 'إنشاء حساب جديد' : 'مستعد تثبت إنك تعرف الكورة؟',
            style: AhdashTypography.headline.copyWith(
              color: AppColors.ink,
              fontSize: figmaPortrait
                  ? (compact ? 22 : 24)
                  : (compact ? 22 : 28),
              height: 1.25,
            ),
          ),
          SizedBox(height: figmaPortrait ? 4 : (compact ? 3 : 5)),
          if (figmaPortrait || !compact || _createAccount)
            Text(
              _createAccount
                  ? 'حساب واحد يحفظ ألعابك وبطولاتك'
                  : figmaPortrait
                  ? 'سجّل دخولك وكمل اللعب'
                  : 'سجل دخولك لتسجيل نتائجك ومنافسة رفاقك.',
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: AhdashTypography.metadata.copyWith(
                color: AppColors.inkSoft,
                fontSize: compact ? 12 : 14,
              ),
            ),
          SizedBox(
            height: keyboardOpen
                ? 10
                : (figmaPortrait ? 17 : (compact ? 10 : 16)),
          ),
          if (showGoogle || showApple) ...[
            _socialActions(
              busy: busy,
              showGoogle: showGoogle,
              showApple: showApple,
              figmaPortrait: figmaPortrait,
            ),
            SizedBox(height: keyboardOpen ? 12 : (figmaPortrait ? 14 : 12)),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'أو',
                    style: TextStyle(color: context.ahdashColors.textMuted),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            SizedBox(height: figmaPortrait ? 10 : 12),
          ],
          if (_createAccount) ...[
            _field(
              controller: _username,
              label: 'اسم اللاعب',
              hintText: 'مثال: محمد السديري',
              icon: AhdashIcons.profile,
              busy: busy,
              compact: compact,
              figmaPortrait: figmaPortrait,
              textInputAction: TextInputAction.next,
              validator: (value) => (value?.trim().length ?? 0) < 3
                  ? 'اكتب اسمًا من 3 أحرف على الأقل'
                  : null,
            ),
            SizedBox(height: fieldGap),
          ],
          _field(
            controller: _email,
            label: 'البريد الإلكتروني',
            hintText: _createAccount ? 'name@domain.com' : null,
            icon: AhdashIcons.email,
            busy: busy,
            compact: compact,
            figmaPortrait: figmaPortrait,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            ltrValue: true,
            autofillHints: const [AutofillHints.email],
            validator: (value) => !(value?.contains('@') ?? false)
                ? 'أدخل بريدًا إلكترونيًا صحيحًا'
                : null,
          ),
          SizedBox(height: fieldGap),
          _field(
            controller: _password,
            label: 'كلمة المرور',
            hintText: _createAccount ? 'لا تقل عن ٨ رموز' : null,
            icon: AhdashIcons.lock,
            busy: busy,
            compact: compact,
            figmaPortrait: figmaPortrait,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            ltrValue: true,
            autofillHints: _createAccount
                ? const [AutofillHints.newPassword]
                : const [AutofillHints.password],
            suffix: IconButton(
              onPressed: busy
                  ? null
                  : () => setState(() => _obscurePassword = !_obscurePassword),
              tooltip: _obscurePassword
                  ? 'إظهار كلمة المرور'
                  : 'إخفاء كلمة المرور',
              icon: Icon(
                _obscurePassword
                    ? AhdashIcons.visibility
                    : AhdashIcons.visibilityOff,
                size: compact ? 17 : 19,
              ),
            ),
            validator: (value) =>
                (value?.length ?? 0) < 8 ? 'استخدم 8 أحرف على الأقل' : null,
            onSubmitted: (_) => busy ? null : _submit(),
          ),
          if (_inlineError != null) ...[
            SizedBox(height: compact ? 5 : 8),
            _AuthError(message: _inlineError!),
          ],
          SizedBox(height: figmaPortrait ? 16 : (compact ? 8 : 12)),
          if (compactSplit)
            Row(
              children: [
                Expanded(child: _primaryAction(busy: busy, compact: true)),
                const SizedBox(width: 12),
                Expanded(child: _modeToggle(busy: busy, compact: true)),
              ],
            )
          else ...[
            _primaryAction(
              busy: busy,
              compact: compact,
              figmaPortrait: figmaPortrait,
            ),
            SizedBox(height: figmaPortrait ? 10 : (compact ? 5 : 8)),
            _modeToggle(busy: busy, compact: compact),
            if (_createAccount && figmaPortrait) ...[
              const SizedBox(height: 2),
              Text(
                'بإنشاء حسابك، أنت توافق على شروط الاستخدام وسياسة الخصوصية.',
                textAlign: TextAlign.center,
                style: AhdashTypography.metadata.copyWith(
                  color: AppColors.muted,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
            if (!_createAccount) ...[
              SizedBox(height: figmaPortrait ? 8 : 4),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'أو',
                      style: TextStyle(color: context.ahdashColors.textMuted),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              SizedBox(height: figmaPortrait ? 8 : 4),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  key: const ValueKey('auth-guest-action'),
                  onPressed: busy ? null : _guest,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.hairline),
                  ),
                  icon: const Icon(AhdashIcons.guest),
                  label: const Text('الدخول كضيف'),
                ),
              ),
              if (figmaPortrait) ...[
                const SizedBox(height: 8),
                const Text(
                  'لعب محلي على هذا الجهاز. الأصدقاء والبطولات وبيانات الحساب تتطلب تسجيل الدخول.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool busy,
    required bool compact,
    required bool figmaPortrait,
    required FormFieldValidator<String> validator,
    String? hintText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    bool ltrValue = false,
    Iterable<String>? autofillHints,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) {
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.small),
      borderSide: const BorderSide(color: AppColors.hairline, width: 1.2),
    );
    final field = TextFormField(
      controller: controller,
      enabled: !busy,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      textDirection: ltrValue ? TextDirection.ltr : TextDirection.rtl,
      textAlign: ltrValue ? TextAlign.left : TextAlign.right,
      autofillHints: autofillHints,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: AhdashTypography.body.copyWith(
        color: AppColors.ink,
        fontSize: compact ? 13 : 14,
      ),
      decoration: InputDecoration(
        hintText: hintText ?? label,
        hintTextDirection: ltrValue ? TextDirection.ltr : TextDirection.rtl,
        hintStyle: AhdashTypography.body.copyWith(
          color: AppColors.inkSoft,
          fontSize: compact ? 12 : 14,
        ),
        prefixIcon: Icon(icon, size: compact ? 16 : 18),
        prefixIconColor: AppColors.ink,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 52,
        ),
        suffixIcon: suffix,
        suffixIconColor: AppColors.ink,
        filled: true,
        fillColor: figmaPortrait ? AppColors.paper1 : const Color(0x26191714),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: compact ? 11 : 13,
        ),
        constraints: figmaPortrait ? const BoxConstraints(minHeight: 52) : null,
        enabledBorder: outline,
        disabledBorder: outline.copyWith(
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: outline.copyWith(
          borderSide: BorderSide(color: context.ahdashColors.primary, width: 2),
        ),
        errorBorder: outline.copyWith(
          borderSide: BorderSide(color: context.ahdashColors.error),
        ),
        focusedErrorBorder: outline.copyWith(
          borderSide: BorderSide(color: context.ahdashColors.error, width: 2),
        ),
        errorStyle: TextStyle(
          color: context.ahdashColors.error,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
    if (!figmaPortrait) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AhdashTypography.metadata.copyWith(
            color: AppColors.inkSoft,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _primaryAction({
    required bool busy,
    required bool compact,
    bool figmaPortrait = false,
  }) {
    return SizedBox(
      height: figmaPortrait ? 52 : (compact ? 44 : 48),
      child: FilledButton(
        key: const ValueKey('auth-primary-action'),
        style: figmaPortrait && _createAccount
            ? FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E874B),
                foregroundColor: Colors.white,
              )
            : null,
        onPressed: busy ? null : _submit,
        child: busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_createAccount ? 'إنشاء حساب' : 'تسجيل الدخول'),
      ),
    );
  }

  Widget _modeToggle({required bool busy, required bool compact}) {
    return TextButton(
      key: const ValueKey('auth-mode-toggle'),
      onPressed: busy ? null : _toggleMode,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        textStyle: AhdashTypography.metadata.copyWith(
          fontSize: compact ? 11 : 13,
          decoration: TextDecoration.underline,
        ),
      ),
      child: Text.rich(
        TextSpan(
          text: _createAccount ? 'عندك حساب؟  ' : 'ما عندك حساب؟  ',
          children: [
            TextSpan(
              text: _createAccount ? 'تسجيل الدخول' : 'إنشاء حساب',
              style: const TextStyle(
                color: Color(0xFF237A45),
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _socialActions({
    required bool busy,
    required bool showGoogle,
    required bool showApple,
    required bool figmaPortrait,
  }) {
    return Column(
      children: [
        if (showGoogle)
          SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton(
              key: const ValueKey('auth-google-action'),
              onPressed: busy
                  ? null
                  : () => _signInSocial(SocialProvider.google),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1F1F1F),
                side: const BorderSide(color: Color(0xFF747775)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: figmaPortrait
                  ? Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: _social.contains(SocialProvider.google)
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('المتابعة باستخدام Google'),
                        ),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: _ProviderMark(google: true),
                        ),
                      ],
                    )
                  : (_social.contains(SocialProvider.google)
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('المتابعة باستخدام Google')),
            ),
          ),
        if (showGoogle && showApple) const SizedBox(height: 10),
        if (showApple)
          SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton(
              key: const ValueKey('auth-apple-action'),
              onPressed: busy
                  ? null
                  : () => _signInSocial(SocialProvider.apple),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.paper0,
              ),
              child: figmaPortrait
                  ? const Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: [
                        Center(child: Text('المتابعة باستخدام Apple')),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _ProviderMark(
                            icon: Icons.apple_rounded,
                            dark: true,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.apple_rounded),
                        SizedBox(width: 8),
                        Text('المتابعة باستخدام Apple'),
                      ],
                    ),
            ),
          ),
      ],
    );
  }

  void _toggleMode() {
    setState(() {
      _mode = _createAccount ? AuthMode.signIn : AuthMode.createAccount;
      _inlineError = null;
      _formKey.currentState?.reset();
    });
    if (_portraitScroll.hasClients) _portraitScroll.jumpTo(0);
  }

  Future<void> _submit() async {
    setState(() => _inlineError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_createAccount) {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(_email.text.trim(), _password.text, _username.text.trim());
    } else {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(_email.text.trim(), _password.text);
    }
    _openHome();
  }

  Future<void> _guest() async {
    setState(() => _inlineError = null);
    await ref.read(authControllerProvider.notifier).continueAsGuest();
    _openHome();
  }

  Future<void> _signInSocial(SocialProvider provider) async {
    if (_social.isNotEmpty) return;
    setState(() {
      _social = {provider};
      _inlineError = null;
    });
    final authenticated = await ref
        .read(authControllerProvider.notifier)
        .signInWithSocial(provider);
    if (!mounted) return;
    setState(() => _social = {});
    if (authenticated) _openHome();
  }

  void _openHome() {
    if (!mounted) return;
    if (ref.read(authControllerProvider) case AsyncData(
      :final value,
    ) when value != null) {
      context.go(
        value.isGuest
            ? '/home'
            : GuestCapabilityPolicy.safeReturnTo(widget.returnTo),
      );
    }
  }

  String _friendlyError(Object error) {
    if (error case SocialSignInException(:final code)) {
      return switch (code) {
        SocialSignInFailureCode.network =>
          'الاتصال ضعيف، جرّب تسجيل الدخول بقوقل مرة ثانية.',
        SocialSignInFailureCode.timeout =>
          'استغرق تسجيل الدخول وقتًا أطول من المتوقع.',
        SocialSignInFailureCode.configuration ||
        SocialSignInFailureCode.missingToken =>
          'إعداد تسجيل الدخول بقوقل يحتاج مراجعة.',
        SocialSignInFailureCode.provider => 'تعذر إكمال تسجيل الدخول بقوقل.',
        _ => 'تعذر تسجيل دخولك بقوقل، جرّب مرة ثانية.',
      };
    }
    return 'تعذر إكمال العملية. راجع البيانات وحاول مرة أخرى.';
  }
}

final class _ProviderMark extends StatelessWidget {
  const _ProviderMark({this.icon, this.dark = false, this.google = false});

  final IconData? icon;
  final bool dark;
  final bool google;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: dark ? AppColors.paper0 : AppColors.paper1,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.hairline),
    ),
    child: google
        ? Image.asset(
            'assets/images/providers/google_g_light.png',
            width: 36,
            height: 36,
            filterQuality: FilterQuality.high,
          )
        : icon != null
        ? Icon(icon, size: 19, color: AppColors.ink)
        : const SizedBox.shrink(),
  );
}

final class _AuthPortraitBrand extends StatelessWidget {
  const _AuthPortraitBrand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    label: 'أحدعش 11، تحديات كرة قدم عربية',
    child: Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.ahdashColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: AhdashBrandLogo.mark(width: 28, height: 28),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أحدعش | 11',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AhdashTypography.sectionTitle.copyWith(
                  color: AppColors.ink,
                  fontSize: compact ? 19 : 21,
                ),
              ),
              Text(
                'معرفة كروية. تحدّي سعودي.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AhdashTypography.metadata.copyWith(
                  color: AppColors.muted,
                  fontSize: compact ? 10 : 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.paper2,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.hairline),
          ),
          child: const Icon(
            AhdashIcons.football,
            size: 20,
            color: AppColors.ink,
          ),
        ),
      ],
    ),
  );
}

final class _AuthBrand extends StatelessWidget {
  const _AuthBrand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'أحدعش',
        style: AhdashTypography.sectionTitle.copyWith(
          color: AppColors.ink,
          fontSize: compact ? 19 : 23,
        ),
      ),
      SizedBox(width: compact ? 7 : 10),
      DecoratedBox(
        decoration: BoxDecoration(
          color: context.ahdashColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 6 : 7),
          child: AhdashBrandLogo.mark(
            width: compact ? 20 : 25,
            height: compact ? 20 : 25,
          ),
        ),
      ),
    ],
  );
}

final class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.ahdashColors.error.withValues(alpha: 0.16),
        border: Border.all(
          color: context.ahdashColors.error.withValues(alpha: 0.7),
        ),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            Icon(
              AhdashIcons.error,
              size: 17,
              color: context.ahdashColors.error,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.ahdashColors.error,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _LoginBackground extends StatelessWidget {
  const _LoginBackground({this.remoteUrl});

  final String? remoteUrl;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ratio = MediaQuery.devicePixelRatioOf(context);
          final width = (constraints.maxWidth * ratio).round();
          final height = (constraints.maxHeight * ratio).round();
          final fallback = Image.asset(
            'assets/images/backgrounds/v9_2_auth_stadium.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            cacheWidth: width,
            cacheHeight: height,
          );
          if (remoteUrl == null || remoteUrl!.isEmpty) return fallback;
          return CachedNetworkImage(
            imageUrl: remoteUrl!,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            memCacheWidth: width,
            memCacheHeight: height,
            fadeInDuration: AppMotion.imageFade,
            placeholder: (_, _) => fallback,
            errorWidget: (_, _, _) => fallback,
          );
        },
      ),
    );
  }
}
