import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/feedback_service.dart';
import '../../../core/theme/ahdash_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/presentation/ahdash_pictograms.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/components.dart';
import '../../../shared/presentation/connectivity_status_banner.dart';
import '../../../shared/presentation/game_ui.dart';
import '../../../shared/presentation/landscape_layout.dart';
import '../../../shared/presentation/measured_v9.dart';
import '../../../shared/presentation/social_identity.dart';

final class RoomLobbyScreen extends ConsumerStatefulWidget {
  const RoomLobbyScreen({
    required this.roomId,
    required this.matchId,
    this.initialCode,
    this.enableRealtime = true,
    super.key,
  });

  final String roomId;
  final String matchId;
  final String? initialCode;
  final bool enableRealtime;

  @override
  ConsumerState<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

final class _RoomLobbyScreenState extends ConsumerState<RoomLobbyScreen> {
  late final SupabaseClient _client;
  RealtimeChannel? _channel;
  Timer? _copiedTimer;
  List<Map<String, Object?>> _members = const [];
  String? _code;
  String? _hostUserId;
  String _mode = 'friend_1v1';
  String _status = 'open';
  int _maxMembers = 2;
  bool _loading = true;
  bool _loadInFlight = false;
  bool _busy = false;
  bool _copied = false;
  String? _error;

  String? get _currentUserId => _client.auth.currentUser?.id;
  bool get _isHost => _currentUserId == _hostUserId;
  Map<String, Object?>? get _currentMember =>
      _members.cast<Map<String, Object?>?>().firstWhere(
        (member) => member?['user_id'] == _currentUserId,
        orElse: () => null,
      );
  bool get _isReady => _currentMember?['status'] == 'ready';
  bool get _canStart =>
      _isHost &&
      _members.length == _maxMembers &&
      _members.every((member) => member['status'] == 'ready');

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _code = widget.initialCode;
    unawaited(_load());
    if (widget.enableRealtime) _subscribe();
  }

  void _subscribe() {
    _channel = _client
        .channel('room:${widget.roomId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: widget.roomId,
          ),
          callback: (_) => unawaited(_load(silent: true)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rooms',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.roomId,
          ),
          callback: (_) => unawaited(_load(silent: true)),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    final channel = _channel;
    if (channel != null) unawaited(_client.removeChannel(channel));
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _client
            .from('rooms')
            .select('code, host_user_id, match_id, mode, status, max_members')
            .eq('id', widget.roomId)
            .single(),
        _client
            .from('room_members')
            .select('user_id, team, seat, status, last_seen_at')
            .eq('room_id', widget.roomId)
            .order('team')
            .order('seat'),
      ]).timeout(const Duration(seconds: 12));
      final room = _map(results[0])!;
      final rawMembers = (results[1] as List)
          .map(_map)
          .whereType<Map<String, Object?>>()
          .toList(growable: false);
      final userIds = rawMembers
          .map((member) => member['user_id'])
          .whereType<String>()
          .toList(growable: false);
      final profiles = userIds.isEmpty
          ? const <Map<String, Object?>>[]
          : (await _client
                        .from('profiles')
                        .select(
                          'id, username, display_name, avatar_url, rating',
                        )
                        .inFilter('id', userIds)
                    as List)
                .map(_map)
                .whereType<Map<String, Object?>>()
                .toList(growable: false);
      final profilesById = {
        for (final profile in profiles) profile['id'] as String: profile,
      };
      final members = rawMembers
          .map(
            (member) => {
              ...member,
              ...?profilesById[member['user_id']],
              'user_id': member['user_id'],
            },
          )
          .toList(growable: false);
      if (!mounted) return;
      if (room['status'] == 'started') {
        context.go('/online/match/${room['match_id'] ?? widget.matchId}');
        return;
      }
      setState(() {
        _loading = false;
        _error = null;
        _members = members;
        _code = room['code'] as String? ?? _code;
        _hostUserId = room['host_user_id'] as String?;
        _mode = room['mode'] as String? ?? _mode;
        _status = room['status'] as String? ?? _status;
        _maxMembers = room['max_members'] as int? ?? _maxMembers;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'تعذر مزامنة الغرفة. تحقق من الاتصال وحاول مجددًا.';
        });
      }
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> _toggleReady() async {
    setState(() => _busy = true);
    try {
      await _client.rpc<Object?>(
        'set_room_ready',
        params: {'p_room_id': widget.roomId, 'p_ready': !_isReady},
      );
      await _load(silent: true);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تحديث حالة الاستعداد.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() async {
    if (!_canStart) return;
    setState(() => _busy = true);
    try {
      final data = await _client.rpc<Object?>(
        'start_room_match',
        params: {'p_room_id': widget.roomId},
      );
      final response = _map(data);
      final matchId = response?['match_id'] as String? ?? widget.matchId;
      if (mounted) context.go('/online/match/$matchId');
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'يجب اكتمال المقاعد واستعداد جميع اللاعبين.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static Map<String, Object?>? _map(Object? value) {
    if (value is! Map) return null;
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  @override
  Widget build(BuildContext context) {
    final landscape = LandscapeMetrics.of(context);
    if (context.v9Metrics.portrait || landscape.accessibilityFallback) {
      return _accessibleBuild(context);
    }
    return _gameBuild(context, context.v9Metrics);
  }

  Widget _accessibleBuild(BuildContext context) {
    return BrandScaffold(
      appBar: AppBar(
        title: Text(_mode == 'team_2v2' ? 'غرفة 2 ضد 2' : 'غرفة الأصدقاء'),
        leading: IconButton(
          onPressed: () => context.go('/online'),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const ConnectivityStatusBanner(),
            Expanded(
              child: ResponsiveContent(
                maxWidth: 680,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                children: [
                                  Text(
                                    'رمز الغرفة',
                                    style: TextStyle(
                                      color: context.ahdashColors.textMuted,
                                    ),
                                  ),
                                  SelectableText(
                                    _code ?? '------',
                                    textDirection: TextDirection.ltr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(
                                          letterSpacing: 8,
                                          color: AppColors.primary,
                                        ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _code == null
                                        ? null
                                        : () async {
                                            await Clipboard.setData(
                                              ClipboardData(text: _code!),
                                            );
                                            await ref
                                                .read(feedbackServiceProvider)
                                                .play(FeedbackCue.copy);
                                            if (!mounted) return;
                                            setState(() => _copied = true);
                                            _copiedTimer?.cancel();
                                            _copiedTimer = Timer(
                                              const Duration(
                                                milliseconds: 1400,
                                              ),
                                              () {
                                                if (mounted) {
                                                  setState(
                                                    () => _copied = false,
                                                  );
                                                }
                                              },
                                            );
                                          },
                                    icon: Icon(
                                      _copied
                                          ? Icons.check_circle_rounded
                                          : Icons.copy_rounded,
                                    ),
                                    label: Text(
                                      _copied ? 'تم النسخ' : 'نسخ الرمز',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'اللاعبون ${_members.length} / $_maxMembers',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (_mode == 'team_2v2') ...[
                            _TeamMembers(
                              label: 'الفريق A',
                              team: 'a',
                              members: _members,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _TeamMembers(
                              label: 'الفريق B',
                              team: 'b',
                              members: _members,
                            ),
                          ] else
                            ..._members.map(
                              (member) => _MemberTile(
                                member,
                                key: ValueKey(member['user_id']),
                              ),
                            ),
                          for (
                            var index = _members.length;
                            index < _maxMembers;
                            index++
                          )
                            const Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Icon(Icons.hourglass_empty_rounded),
                                ),
                                title: Text('بانتظار لاعب…'),
                              ),
                            ),
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _error!,
                              style: const TextStyle(color: AppColors.danger),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          OutlinedButton.icon(
                            onPressed: _busy || _status != 'open'
                                ? null
                                : _toggleReady,
                            icon: Icon(
                              _isReady
                                  ? Icons.undo_rounded
                                  : Icons.check_circle_rounded,
                            ),
                            label: Text(
                              _isReady ? 'إلغاء الاستعداد' : 'أنا مستعد',
                            ),
                          ),
                          if (_isHost) ...[
                            const SizedBox(height: AppSpacing.sm),
                            FilledButton.icon(
                              onPressed: _busy || !_canStart ? null : _start,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('ابدأ المباراة'),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          TextButton.icon(
                            onPressed: _busy ? null : () => _load(),
                            icon: const Icon(Icons.sync_rounded),
                            label: const Text('تحديث الحالة'),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameBuild(BuildContext context, AhdashV9Metrics metrics) {
    return BrandScaffold(
      body: AhdashGameWorld(
        child: AhdashV9Frame(
          child: Column(
            children: [
              AhdashV9TopBar(
                title: _mode == 'team_2v2' ? 'غرفة 2 ضد 2' : 'غرفة الأصدقاء',
                kicker: _status == 'open' ? 'بانتظار الجاهزية' : _status,
                leading: AhdashV9IconButton(
                  icon: AhdashIcons.close,
                  tooltip: 'إغلاق الغرفة',
                  onPressed: () => context.go('/online'),
                ),
                actions: [
                  AhdashV9IconButton(
                    icon: AhdashIcons.refresh,
                    tooltip: 'تحديث',
                    onPressed: _busy ? null : () => _load(),
                  ),
                ],
              ),
              const ConnectivityStatusBanner(),
              SizedBox(height: metrics.compact ? 4 : 8),
              Expanded(
                child: _loading
                    ? const Center(child: ElevenLoader(size: 42))
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: metrics.compact ? 280 : 340,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const AhdashPictogramView(
                                  pictogram: AhdashPictogram.teamsStep,
                                  scale: AhdashPictogramScale.sectionIdentity,
                                ),
                                SizedBox(height: metrics.compact ? 4 : 10),
                                Text(
                                  'رمز الغرفة',
                                  style: TextStyle(
                                    color: context.ahdashColors.textMuted,
                                    fontSize: metrics.metadataSize,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SelectableText(
                                  _code ?? '------',
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(
                                    letterSpacing: 8,
                                    color: context.ahdashColors.primary,
                                    fontSize: metrics.scoreSize,
                                    height: 1.15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _code == null
                                      ? null
                                      : _copyRoomCode,
                                  icon: Icon(
                                    _copied
                                        ? Icons.check_circle_rounded
                                        : Icons.copy_rounded,
                                  ),
                                  label: Text(
                                    _copied ? 'تم النسخ' : 'نسخ الرمز',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            margin: EdgeInsets.symmetric(
                              horizontal: metrics.compact ? 18 : 32,
                              vertical: metrics.compact ? 12 : 28,
                            ),
                            color: context.ahdashColors.border,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'اللاعبون',
                                      style: TextStyle(
                                        fontSize: metrics.sectionSize,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_members.length} / $_maxMembers',
                                      textDirection: TextDirection.ltr,
                                      style: TextStyle(
                                        color: context.ahdashColors.primary,
                                        fontSize: metrics.sectionSize,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: metrics.compact ? 6 : 10),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final columns = _maxMembers > 2
                                          ? 2
                                          : _maxMembers < 1
                                          ? 1
                                          : _maxMembers;
                                      final aspectRatio = _maxMembers > 2
                                          ? 3.15
                                          : 2.2;
                                      const spacing = 10.0;
                                      final cardWidth =
                                          (constraints.maxWidth -
                                              spacing * (columns - 1)) /
                                          columns;
                                      final cardHeight =
                                          cardWidth / aspectRatio;
                                      final rows = (_maxMembers / columns)
                                          .ceil();
                                      final contentHeight =
                                          cardHeight * rows +
                                          spacing * (rows - 1);
                                      return Center(
                                        child: SizedBox(
                                          width: double.infinity,
                                          height: contentHeight
                                              .clamp(0.0, constraints.maxHeight)
                                              .toDouble(),
                                          child: GridView.builder(
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            padding: EdgeInsets.zero,
                                            itemCount: _maxMembers,
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: columns,
                                                  crossAxisSpacing: spacing,
                                                  mainAxisSpacing: spacing,
                                                  childAspectRatio: aspectRatio,
                                                ),
                                            itemBuilder: (_, index) =>
                                                index < _members.length
                                                ? GamePanel(
                                                    padding: EdgeInsets.zero,
                                                    selected:
                                                        _members[index]['status'] ==
                                                        'ready',
                                                    tone:
                                                        _members[index]['status'] ==
                                                            'ready'
                                                        ? GameSurfaceTone
                                                              .selected
                                                        : GameSurfaceTone.base,
                                                    child: _MemberTile(
                                                      _members[index],
                                                      key: ValueKey(
                                                        _members[index]['user_id'],
                                                      ),
                                                    ),
                                                  )
                                                : GamePanel(
                                                    tone: GameSurfaceTone.base,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .hourglass_empty_rounded,
                                                          color: context
                                                              .ahdashColors
                                                              .textMuted,
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        const Text(
                                                          'بانتظار لاعب…',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _error!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ],
                                SizedBox(height: metrics.compact ? 6 : 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: metrics.secondaryActionHeight,
                                        child: OutlinedButton(
                                          onPressed: _busy || _status != 'open'
                                              ? null
                                              : _toggleReady,
                                          child: Text(
                                            _isReady
                                                ? 'إلغاء الاستعداد'
                                                : 'أنا مستعد',
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_isHost) ...[
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: AhdashV9PrimaryAction(
                                          label: 'ابدأ المباراة',
                                          onPressed: _busy || !_canStart
                                              ? null
                                              : _start,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
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
  }

  Future<void> _copyRoomCode() async {
    final code = _code;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    await ref.read(feedbackServiceProvider).play(FeedbackCue.copy);
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _copied = false);
    });
  }
}

final class _TeamMembers extends StatelessWidget {
  const _TeamMembers({
    required this.label,
    required this.team,
    required this.members,
  });

  final String label;
  final String team;
  final List<Map<String, Object?>> members;

  @override
  Widget build(BuildContext context) {
    final teamMembers = members.where((member) => member['team'] == team);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: AppSpacing.xs),
            ...teamMembers.map(
              (member) => _MemberTile(member, key: ValueKey(member['user_id'])),
            ),
          ],
        ),
      ),
    );
  }
}

final class _MemberTile extends StatelessWidget {
  const _MemberTile(this.member, {super.key});

  final Map<String, Object?> member;

  @override
  Widget build(BuildContext context) {
    final ready = member['status'] == 'ready';
    return AhdashEntrance(
      order: (member['seat'] as int? ?? 1).clamp(0, 4),
      child: AhdashPlayerCard(
        displayName:
            '${member['display_name'] ?? member['username'] ?? 'لاعب'}',
        avatarUrl: member['avatar_url'] as String?,
        subtitle: 'Rating ${member['rating'] ?? 1000}',
        rank: member['seat'] as int?,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ready ? 'جاهز' : 'غير جاهز',
              style: TextStyle(
                color: ready
                    ? context.ahdashColors.primary
                    : context.ahdashColors.textMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              ready
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: ready
                  ? context.ahdashColors.primary
                  : context.ahdashColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
