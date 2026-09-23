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
        remoteBackground: remoteBackground,
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
    required String? remoteBackground,
    required bool busy,
    required bool showGoogle,
    required bool showApple,
    required bool reducedMotion,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardOpen = mediaQuery.viewInsets.bottom > 0;
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
      color: AppColors.ink,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth <= 360;
            final safeTop = mediaQuery.padding.top;
            final safeBottom = mediaQuery.padding.bottom;
            final sheetTop = keyboardOpen
                ? safeTop + 48
                : compact
                ? 188.0
                : 202.0;
            final topPadding = keyboardOpen ? 16.0 : 21.0;
            final bottomPadding = keyboardOpen
                ? mediaQuery.viewInsets.bottom + 18
                : safeBottom + 18;
            final minimumContentHeight =
                (constraints.maxHeight - sheetTop - topPadding - bottomPadding)
                    .clamp(0.0, double.infinity);
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: sheetTop + 30,
                  child: _AuthHero(
                    remoteUrl: remoteBackground,
                    condensed: keyboardOpen,
                  ),
                ),
                Positioned(
                  top: sheetTop,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.paper0,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x30191714),
                          blurRadius: 24,
                          offset: Offset(0, -6),
                        ),
                      ],
                    ),
                    child: KeyedSubtree(
                      key: const ValueKey('v10-keyboard-scroll'),
                      child: SingleChildScrollView(
                        key: ValueKey('auth-scroll-${_mode.name}'),
                        controller: _portraitScroll,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          compact ? 22 : 26,
                          topPadding,
                          compact ? 22 : 26,
                          bottomPadding,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: minimumContentHeight,
                          ),
                          child: _entrance(
                            reducedMotion: reducedMotion,
                            child: _authForm(
                              busy: busy,
                              showGoogle: showGoogle,
                              showApple: showApple,
                              compact: true,
                              compactSplit: false,
                              figmaPortrait: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
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
        ? 8.0
        : (figmaPortrait ? 9.0 : (compact ? 7.0 : 10.0));
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
            _createAccount ? 'إنشاء حساب جديد' : 'تسجيل دخول',
            style: AhdashTypography.headline.copyWith(
              color: AppColors.ink,
              fontSize: figmaPortrait
                  ? (compact ? 20 : 22)
                  : (compact ? 22 : 28),
              height: 1.2,
            ),
          ),
          SizedBox(height: figmaPortrait ? 3 : (compact ? 3 : 5)),
          if (!_createAccount)
            Text(
              figmaPortrait
                  ? 'سجّل دخولك وكمل اللعب'
                  : 'سجل دخولك لتسجيل نتائجك ومنافسة رفاقك.',
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: AhdashTypography.metadata.copyWith(
                color: AppColors.inkSoft,
                fontSize: compact ? 11 : 14,
              ),
            ),
          SizedBox(
            height: keyboardOpen
                ? 9
                : (figmaPortrait ? 15 : (compact ? 10 : 16)),
          ),
          if (showGoogle || showApple) ...[
            _socialActions(
              busy: busy,
              showGoogle: showGoogle,
              showApple: showApple,
              figmaPortrait: figmaPortrait,
            ),
            SizedBox(height: keyboardOpen ? 9 : (figmaPortrait ? 12 : 12)),
            Row(
              children: [
                const Expanded(
                  child: Divider(color: AppColors.hairline, thickness: 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'أو',
                    style: AhdashTypography.metadata.copyWith(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Expanded(
                  child: Divider(color: AppColors.hairline, thickness: 1),
                ),
              ],
            ),
            SizedBox(height: figmaPortrait ? 9 : 12),
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
              constraints: const BoxConstraints.tightFor(
                width: AhdashSizing.touchTarget,
                height: AhdashSizing.touchTarget,
              ),
              onPressed: busy
                  ? null
                  : () => setState(() => _obscurePassword = !_obscurePassword),
              tooltip: _obscurePassword
                  ? 'إظهار كلمة المرور'
                  : 'إخفاء كلمة المرور',
              icon: Semantics(
                toggled: !_obscurePassword,
                label: _obscurePassword
                    ? 'كلمة المرور مخفية'
                    : 'كلمة المرور ظاهرة',
                child: Icon(
                  _obscurePassword
                      ? AhdashIcons.visibility
                      : AhdashIcons.visibilityOff,
                  size: compact ? 18 : 20,
                ),
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
          SizedBox(height: figmaPortrait ? 12 : (compact ? 8 : 12)),
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
            SizedBox(height: figmaPortrait ? 5 : (compact ? 5 : 8)),
            _modeToggle(busy: busy, compact: compact),
            if (_createAccount && figmaPortrait) ...[
              const SizedBox(height: 1),
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
              SizedBox(height: figmaPortrait ? 1 : 4),
              Center(
                child: TextButton.icon(
                  key: const ValueKey('auth-guest-action'),
                  onPressed: busy ? null : _guest,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.inkMuted,
                    minimumSize: const Size(48, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: AhdashTypography.metadata.copyWith(
                      fontSize: compact ? 11 : 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(AhdashIcons.guest, size: 16),
                  label: const Text('الدخول كضيف'),
                ),
              ),
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
      borderRadius: BorderRadius.circular(figmaPortrait ? 12 : AppRadius.small),
      borderSide: BorderSide(
        color: figmaPortrait ? const Color(0xFFD9CDBB) : AppColors.hairline,
        width: 1,
      ),
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
        prefixIconColor: figmaPortrait ? AppColors.inkMuted : AppColors.ink,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 48,
        ),
        suffixIcon: suffix,
        suffixIconColor: AppColors.ink,
        filled: true,
        fillColor: figmaPortrait
            ? const Color(0xFFFFFCF7)
            : const Color(0x26191714),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: figmaPortrait ? 10 : (compact ? 11 : 13),
        ),
        constraints: figmaPortrait ? const BoxConstraints(minHeight: 48) : null,
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
            color: AppColors.ink,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
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
      height: figmaPortrait ? 50 : (compact ? 44 : 48),
      child: FilledButton(
        key: const ValueKey('auth-primary-action'),
        style: figmaPortrait
            ? FilledButton.styleFrom(
                backgroundColor: context.ahdashColors.primary,
                foregroundColor: AppColors.ink,
                disabledBackgroundColor: context.ahdashColors.primary
                    .withValues(alpha: .45),
                disabledForegroundColor: AppColors.ink.withValues(alpha: .55),
                shape: const StadiumBorder(
                  side: BorderSide(color: AppColors.ink, width: 1.1),
                ),
                textStyle: AhdashTypography.button.copyWith(
                  fontWeight: FontWeight.w900,
                ),
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
        foregroundColor: AppColors.inkMuted,
        minimumSize: const Size(48, 40),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        textStyle: AhdashTypography.metadata.copyWith(
          fontSize: compact ? 11 : 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Text.rich(
        TextSpan(
          text: _createAccount ? 'عندك حساب؟  ' : 'ما عندك حساب؟  ',
          children: [
            TextSpan(
              text: _createAccount ? 'تسجيل الدخول' : 'إنشاء حساب',
              style: const TextStyle(
                color: Color(0xFF2E7D4F),
                fontWeight: FontWeight.w900,
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
    final compactWidth = MediaQuery.sizeOf(context).width <= 360;
    final actionHeight = figmaPortrait ? 48.0 : (compactWidth ? 48.0 : 52.0);
    return Column(
      children: [
        if (showGoogle)
          SizedBox(
            height: actionHeight,
            width: double.infinity,
            child: OutlinedButton(
              key: const ValueKey('auth-google-action'),
              onPressed: busy
                  ? null
                  : () => _signInSocial(SocialProvider.google),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1F1F1F),
                side: const BorderSide(color: AppColors.hairline),
                shape: const StadiumBorder(),
                textStyle: AhdashTypography.button.copyWith(
                  fontSize: compactWidth ? 12 : 13,
                  fontWeight: FontWeight.w800,
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
        if (showGoogle && showApple) SizedBox(height: compactWidth ? 8 : 10),
        if (showApple)
          SizedBox(
            height: actionHeight,
            width: double.infinity,
            child: OutlinedButton(
              key: const ValueKey('auth-apple-action'),
              onPressed: busy
                  ? null
                  : () => _signInSocial(SocialProvider.apple),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.paper0,
                side: const BorderSide(color: AppColors.ink),
                shape: const StadiumBorder(),
                textStyle: AhdashTypography.button.copyWith(
                  fontSize: compactWidth ? 12 : 13,
                  fontWeight: FontWeight.w800,
                ),
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
    FocusManager.instance.primaryFocus?.unfocus();
    final scrollOffset = _portraitScroll.hasClients
        ? _portraitScroll.offset
        : null;
    setState(() {
      _social = {provider};
      _inlineError = null;
    });
    _restorePortraitScroll(scrollOffset);
    final authenticated = await ref
        .read(authControllerProvider.notifier)
        .signInWithSocial(provider);
    if (!mounted) return;
    setState(() => _social = {});
    _restorePortraitScroll(scrollOffset);
    if (authenticated) _openHome();
  }

  void _restorePortraitScroll(double? offset) {
    if (offset == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_portraitScroll.hasClients) return;
      _portraitScroll.jumpTo(
        offset.clamp(0, _portraitScroll.position.maxScrollExtent),
      );
    });
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
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 24,
    child: Center(
      child: google
          ? Image.asset(
              'assets/images/providers/google_g_light.png',
              width: 20,
              height: 20,
              filterQuality: FilterQuality.high,
            )
          : icon != null
          ? Icon(icon, size: 20, color: dark ? AppColors.paper0 : AppColors.ink)
          : const SizedBox.shrink(),
    ),
  );
}

final class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.remoteUrl, required this.condensed});

  final String? remoteUrl;
  final bool condensed;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'هوية أحدعش فوق ملعب كرة قدم مضيء',
    image: true,
    child: ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _LoginBackground(remoteUrl: remoteUrl),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.paper0.withValues(alpha: condensed ? .72 : .48),
                  AppColors.paper0.withValues(alpha: .12),
                  AppColors.palm.withValues(alpha: .10),
                ],
                stops: const [0, .56, 1],
              ),
            ),
          ),
          Align(
            alignment: condensed ? const Alignment(0, .08) : Alignment.center,
            child: SizedBox(
              width: condensed ? 132 : 174,
              height: condensed ? 44 : 58,
              child: Image.asset(
                'assets/branding/logo-wordmark.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: 126,
              height: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0),
                      AppColors.primary.withValues(alpha: .9),
                      AppColors.primary.withValues(alpha: 0),
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

final class _AuthBrand extends StatelessWidget {
  const _AuthBrand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final darkSurface = Theme.of(context).brightness == Brightness.dark;
    return AhdashBrandLogo(
      width: compact ? 112 : 142,
      height: compact ? 38 : 46,
      onDarkSurface: darkSurface,
    );
  }
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
            'assets/images/backgrounds/v10_auth_stadium_light.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0, .12),
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
