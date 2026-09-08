import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/app_error_reporter.dart';
import '../../../core/services/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/presentation/ahdash_pictograms.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/game_ui.dart';
import '../../../shared/presentation/measured_v9.dart';
import '../../game/domain/game_mode.dart';

enum _LobbyPath { quickMatch, privateRoom }

final class OnlineLobbyScreen extends ConsumerStatefulWidget {
  const OnlineLobbyScreen({
    this.friendUserId,
    this.initialFormat,
    this.gameType = GameType.classic,
    super.key,
  });

  final String? friendUserId;
  final String? initialFormat;
  final GameType gameType;

  @override
  ConsumerState<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

final class _OnlineLobbyScreenState extends ConsumerState<OnlineLobbyScreen> {
  final _codeController = TextEditingController();
  var _busy = false;
  var _matchmaking = false;
  var _cancelMatchmaking = false;
  String? _status;
  late _LobbyPath _path;

  bool get _roomOnly =>
      widget.initialFormat == '2v2' ||
      widget.initialFormat == 'room' ||
      widget.friendUserId != null;

  @override
  void initState() {
    super.initState();
    _path = _roomOnly ? _LobbyPath.privateRoom : _LobbyPath.quickMatch;
  }

  @override
  void dispose() {
    _cancelMatchmaking = true;
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final metrics = context.v9Metrics;
    return BrandScaffold(
      body: AhdashGameWorld(
        child: AhdashV9Frame(
          child: Column(
            children: [
              AhdashV9TopBar(
                title: _path == _LobbyPath.quickMatch
                    ? 'مواجهة سريعة'
                    : widget.initialFormat == '2v2'
                    ? 'جهّز فريقك'
                    : 'غرفة ربعك',
                kicker: widget.gameType.titleAr,
              ),
              SizedBox(height: metrics.sectionGap),
              Expanded(
                child: !config.hasSupabase
                    ? const AppMessageState(
                        icon: Icons.lock_person_rounded,
                        title: 'يلزم اتصال بالخادم',
                        message:
                            'المطابقة والغرف لا تعملان بوضع وهمي. أضف إعدادات Supabase لتفعيل التحقق والخادم صاحب القرار.',
                      )
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 920),
                          child: Column(
                            children: [
                              if (!_roomOnly) ...[
                                SizedBox(
                                  height: metrics.touchTarget,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _LobbyPathTab(
                                          label: 'مواجهة سريعة',
                                          selected:
                                              _path == _LobbyPath.quickMatch,
                                          onTap: () => setState(
                                            () => _path = _LobbyPath.quickMatch,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _LobbyPathTab(
                                          label: 'غرفة خاصة',
                                          selected:
                                              _path == _LobbyPath.privateRoom,
                                          onTap: () => setState(
                                            () =>
                                                _path = _LobbyPath.privateRoom,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: metrics.sectionGap),
                              ],
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration:
                                      MediaQuery.disableAnimationsOf(context)
                                      ? Duration.zero
                                      : const Duration(milliseconds: 220),
                                  child: _path == _LobbyPath.quickMatch
                                      ? _quickMatchPath(metrics)
                                      : _privateRoomPath(metrics),
                                ),
                              ),
                              if (_status != null) ...[
                                SizedBox(height: metrics.sectionGap),
                                _statusBar(),
                              ],
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickMatchPath(AhdashV9Metrics metrics) {
    final title = Text(
      _matchmaking ? 'نبحث لك عن منافس…' : 'جاهز لمواجهة مباشرة؟',
      textAlign: metrics.portrait ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontSize: metrics.heroSize,
        height: 1.05,
        fontWeight: FontWeight.w900,
      ),
    );
    final description = Text(
      'سنختار لاعبًا قريبًا من تقييمك، والخادم يعتمد الإجابات والنتيجة.',
      textAlign: metrics.portrait ? TextAlign.center : TextAlign.start,
      maxLines: metrics.compact ? 2 : 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: context.ahdashColors.textSecondary,
        fontSize: metrics.bodySize,
        height: 1.4,
      ),
    );
    final action = AhdashV9PrimaryAction(
      label: _matchmaking ? 'إلغاء البحث' : 'ابدأ البحث',
      onPressed: _matchmaking ? _cancelQueue : (_busy ? null : _queueMatch),
    );
    if (metrics.portrait) {
      return Column(
        key: const ValueKey('quick-match'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AhdashPictogramView(
            pictogram: AhdashPictogram.questionStep,
            scale: AhdashPictogramScale.sectionIdentity,
          ),
          const SizedBox(height: 20),
          title,
          const SizedBox(height: 8),
          description,
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: action),
        ],
      );
    }
    return Row(
      key: const ValueKey('quick-match'),
      children: [
        const AhdashPictogramView(
          pictogram: AhdashPictogram.questionStep,
          scale: AhdashPictogramScale.sectionIdentity,
        ),
        SizedBox(width: metrics.compact ? 20 : 36),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 8), description],
          ),
        ),
        SizedBox(width: metrics.compact ? 20 : 44),
        SizedBox(width: metrics.compact ? 220 : 280, child: action),
      ],
    );
  }

  Widget _privateRoomPath(AhdashV9Metrics metrics) => Column(
    key: const ValueKey('private-room'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: Row(
          children: [
            const AhdashPictogramView(
              pictogram: AhdashPictogram.teamsStep,
              scale: AhdashPictogramScale.sectionIdentity,
            ),
            SizedBox(width: metrics.compact ? 20 : 36),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friendUserId != null
                        ? 'غرفة لصديقك'
                        : 'اجمع ربعك في غرفة واحدة',
                    style: TextStyle(
                      fontSize: metrics.heroSize,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.friendUserId != null
                        ? 'أنشئ الغرفة وسيصل الرمز لصديقك.'
                        : 'أنشئ غرفة جديدة أو ادخل بالرمز المكوّن من 6 أرقام.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.ahdashColors.textSecondary,
                      fontSize: metrics.bodySize,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (metrics.portrait)
        SizedBox(
          height: 104,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.initialFormat == '2v2' || _busy
                            ? null
                            : () => _createRoom('friend_1v1'),
                        child: const Text('إنشاء 1 ضد 1'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.initialFormat == '1v1' || _busy
                            ? null
                            : () => _createRoom('team_2v2'),
                        child: const Text('إنشاء 2 ضد 2'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'رمز الغرفة',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 112,
                      child: AhdashV9PrimaryAction(
                        label: 'انضمام',
                        onPressed: _busy ? null : _joinRoom,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      else
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: metrics.secondaryActionHeight,
                child: OutlinedButton(
                  onPressed: widget.initialFormat == '2v2' || _busy
                      ? null
                      : () => _createRoom('friend_1v1'),
                  child: const Text('إنشاء 1 ضد 1'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: metrics.secondaryActionHeight,
                child: OutlinedButton(
                  onPressed: widget.initialFormat == '1v1' || _busy
                      ? null
                      : () => _createRoom('team_2v2'),
                  child: const Text('إنشاء 2 ضد 2'),
                ),
              ),
            ),
            SizedBox(width: metrics.compact ? 12 : 24),
            SizedBox(
              width: metrics.compact ? 220 : 270,
              height: metrics.inputHeight,
              child: TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'رمز الغرفة',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: metrics.compact ? 130 : 160,
              child: AhdashV9PrimaryAction(
                label: 'انضمام',
                onPressed: _busy ? null : _joinRoom,
              ),
            ),
          ],
        ),
    ],
  );

  Widget _statusBar() => GameHud(
    children: [
      if (_busy)
        const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      else
        const Icon(Icons.info_outline_rounded, size: 18),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(_status!, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );

  Future<void> _queueMatch() async {
    setState(() {
      _busy = true;
      _matchmaking = true;
      _cancelMatchmaking = false;
      _status = 'جارٍ البحث عن منافس قريب من تقييمك…';
    });
    try {
      for (var attempt = 0; attempt < 30 && !_cancelMatchmaking; attempt++) {
        final response = await Supabase.instance.client.functions.invoke(
          'queue-matchmaking',
          body: {
            'categoryIds': <String>[],
            'questionCount': 15,
            'initialRange': 100,
            'gameType': widget.gameType.slug,
          },
        );
        final data = response.data;
        if (data case {'status': 'matched', 'match_id': final String matchId}) {
          if (mounted) context.go('/online/match/$matchId');
          return;
        }
        if (mounted) setState(() => _status = _responseMessage(data));
        await Future<void>.delayed(const Duration(seconds: 3));
      }
      if (!_cancelMatchmaking && mounted) {
        setState(
          () => _status = 'لم نجد منافسًا الآن. حاول مرة أخرى بعد قليل.',
        );
      }
    } catch (error, stackTrace) {
      unawaited(
        ref
            .read(appServicesProvider)
            .errors
            .report(
              severity: AppErrorSeverity.warning,
              category: AppErrorCategory.matchmaking,
              feature: 'quick_match_queue',
              error: error,
              stackTrace: stackTrace,
              screen: '/online',
            ),
      );
      if (mounted) {
        setState(
          () => _status = 'تعذر البحث عن منافس. تحقق من الاتصال وحاول مجددًا.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _matchmaking = false;
        });
      }
    }
  }

  Future<void> _createRoom(String mode) async {
    await _invoke('create-room', {
      'mode': mode,
      'categoryIds': const <String>[],
      'questionCount': 15,
      'gameType': widget.gameType.slug,
    });
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _status = 'أدخل رمزًا من 6 أرقام.');
      return;
    }
    await _invoke('join-room', {'code': code});
  }

  Future<void> _cancelQueue() async {
    _cancelMatchmaking = true;
    setState(() => _status = 'جارٍ إلغاء البحث…');
    try {
      await Supabase.instance.client.functions.invoke(
        'queue-matchmaking',
        body: const {'action': 'cancel'},
      );
      if (mounted) setState(() => _status = 'تم إلغاء البحث.');
    } catch (error, stackTrace) {
      unawaited(
        ref
            .read(appServicesProvider)
            .errors
            .report(
              severity: AppErrorSeverity.info,
              category: AppErrorCategory.matchmaking,
              feature: 'quick_match_cancel',
              error: error,
              stackTrace: stackTrace,
              screen: '/online',
            ),
      );
      if (mounted) setState(() => _status = 'توقف البحث على هذا الجهاز.');
    }
  }

  Future<void> _invoke(String functionName, Map<String, Object?> body) async {
    setState(() {
      _busy = true;
      _status = 'جارٍ الاتصال بالخادم…';
    });
    try {
      final response = await Supabase.instance.client.functions.invoke(
        functionName,
        body: body,
      );
      if (!mounted) return;
      if (response.data case {
        'room_id': final String roomId,
        'match_id': final String matchId,
      }) {
        final code = response.data is Map
            ? '${(response.data as Map)['room_code'] ?? _codeController.text.trim()}'
            : '';
        if (functionName == 'create-room' && widget.friendUserId != null) {
          await Supabase.instance.client.rpc<Object?>(
            'invite_friend_to_room',
            params: {
              'p_room_id': roomId,
              'p_friend_user_id': widget.friendUserId,
            },
          );
        }
        if (!mounted) return;
        context.go(
          Uri(
            path: '/room/$roomId',
            queryParameters: {
              'matchId': matchId,
              if (code.isNotEmpty) 'code': code,
            },
          ).toString(),
        );
        return;
      }
      setState(() => _status = _responseMessage(response.data));
    } catch (error, stackTrace) {
      unawaited(
        ref
            .read(appServicesProvider)
            .errors
            .report(
              severity: AppErrorSeverity.warning,
              category: AppErrorCategory.room,
              feature: functionName,
              error: error,
              stackTrace: stackTrace,
              screen: '/online',
            ),
      );
      if (!mounted) return;
      setState(
        () => _status = 'تعذر إكمال الطلب. تحقق من الاتصال وحاول مجددًا.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _responseMessage(Object? data) {
    if (data case {'room_code': final Object? code}) {
      return 'رمز غرفتك: $code';
    }
    if (data case {'status': final Object? status}) {
      if (status == 'queued') {
        final position = data['queue_position'];
        final range = data['current_rating_range'];
        return 'في قائمة الانتظار • الترتيب $position • نطاق التقييم ±$range';
      }
      return 'الحالة: $status';
    }
    return 'تم إرسال الطلب بنجاح.';
  }
}

final class _LobbyPathTab extends StatelessWidget {
  const _LobbyPathTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.ahdashColors;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.selected : colors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? colors.primary : colors.textPrimary,
              fontSize: context.v9Metrics.compact ? 14 : 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
