import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/components.dart';
import '../../../shared/presentation/v10_portrait.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/social_repository.dart';
import 'social_visuals.dart';

final class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({this.inviteTeamId, super.key});

  final String? inviteTeamId;

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

final class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<Map<String, Object?>>? _searchResults;
  var _searching = false;
  var _searchFailed = false;
  var _searchRevision = 0;
  Timer? _searchDebounce;
  final _busyIds = <String>{};

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _accessibleBuild(context);

  Widget _accessibleBuild(BuildContext context) {
    final online = ref.watch(socialRepositoryProvider).isAvailable;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return AhdashV10Page(
      title: 'الأصدقاء',
      subtitle: widget.inviteTeamId == null
          ? 'كوّن دائرتك وابدأ اللعب مع أشخاص تعرفهم'
          : 'اختر صديقًا لدعوته إلى الفريق',
      onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      actions: [
        IconButton.outlined(
          tooltip: 'الفِرق',
          onPressed: () => context.push('/teams'),
          style: IconButton.styleFrom(
            foregroundColor: AppColors.ink,
            backgroundColor: AppColors.paper1,
            minimumSize: const Size(44, 44),
            side: const BorderSide(color: AppColors.hairline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.groups_3_outlined),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          key: const ValueKey('friends-keyboard-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          // The page Scaffold already reserves the keyboard inset.
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            if (inset == 0) ...[
              SocialHero(
                title: 'مع الربع أحلى',
                subtitle: 'ابحث بالاسم واجمع فريقك.',
                scene: SocialArtworkScene.friends,
                actionLabel: 'أضف لاعبًا',
                onAction: online ? _searchFocus.requestFocus : null,
                compact: true,
                artwork: Transform.scale(
                  scale: 1.3,
                  child: Image.asset(
                    'assets/visuals/friends_social_hero_v2.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Container(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              decoration: BoxDecoration(
                color: AppColors.paper1,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (inset == 0)
                    const Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(4, 1, 4, 9),
                      child: Row(
                        children: [
                          _SearchHeaderIcon(),
                          SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ابحث عن لاعب',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'بالاسم الظاهر أو اسم المستخدم',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.inkMuted,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    key: const ValueKey('friends-search-field'),
                    controller: _searchController,
                    focusNode: _searchFocus,
                    enabled: online,
                    textInputAction: TextInputAction.search,
                    onChanged: _queueSearch,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.paper0,
                      hintText: 'الاسم أو اسم المستخدم',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.person_search_rounded),
                      suffixIconConstraints: const BoxConstraints(minWidth: 48),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              tooltip: 'مسح البحث',
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close_rounded, size: 19),
                            ),
                          IconButton(
                            tooltip: 'بحث',
                            onPressed: online && !_searching ? _search : null,
                            style: IconButton.styleFrom(
                              foregroundColor: AppColors.ink,
                              backgroundColor: AppColors.brandLime,
                              disabledBackgroundColor: AppColors.paper2,
                            ),
                            icon: _searching
                                ? const SizedBox.square(
                                    dimension: 19,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.search_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!online) ...[
              const SizedBox(height: 12),
              const AhdashV10Panel(
                child: Row(
                  children: [
                    Icon(Icons.cloud_off_rounded),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'يلزم اتصال بالخادم. البحث والطلبات لا تُحاكى محليًا.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_searchFailed) ...[
              const SizedBox(height: 12),
              const _SearchMessage(
                icon: Icons.wifi_off_rounded,
                text: 'تعذر البحث الآن. حاول بعد قليل.',
              ),
            ],
            if (_searchResults != null) ...[
              const SizedBox(height: 20),
              _SectionTitle(
                title: 'نتائج البحث',
                count: _searchResults!.length,
                icon: Icons.manage_search_rounded,
                accent: AppColors.palm,
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                child: _searchResults!.isEmpty
                    ? const SocialEmptyState(
                        key: ValueKey('friends-no-results'),
                        title: 'لا يوجد لاعب مطابق.',
                        message: 'راجع كتابة الاسم أو جرّب اسم المستخدم.',
                        scene: SocialArtworkScene.search,
                        artwork: _FriendsDiscoveryArtwork(),
                      )
                    : Column(
                        key: const ValueKey('friends-search-results'),
                        children: _searchResults!
                            .map(_searchResult)
                            .toList(growable: false),
                      ),
              ),
            ],
            const SizedBox(height: 20),
            ref
                .watch(friendsDashboardProvider)
                .when(
                  loading: () => const _FriendsLoadingView(),
                  error: (_, _) => SocialEmptyState(
                    title: 'تعذر تحميل الأصدقاء',
                    message: 'تحقق من الاتصال وحاول مجددًا.',
                    actionLabel: 'إعادة المحاولة',
                    actionIcon: Icons.refresh_rounded,
                    onAction: _reload,
                    scene: SocialArtworkScene.search,
                    artwork: const _FriendsDiscoveryArtwork(),
                  ),
                  data: (data) {
                    final inbox = _rows(data['inbox']);
                    final outbox = _rows(data['outbox']);
                    final friends = _rows(data['friends']);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FriendsOverview(
                          friends: friends.length,
                          inbox: inbox.length,
                          outbox: outbox.length,
                        ),
                        const SizedBox(height: 20),
                        if (inbox.isNotEmpty) ...[
                          _SectionTitle(
                            title: 'بانتظار ردك',
                            count: inbox.length,
                            icon: Icons.mark_email_unread_rounded,
                            accent: AppColors.brandLime,
                            emphasized: true,
                          ),
                          const SizedBox(height: 8),
                          ...inbox.map(_incomingRequest),
                          const SizedBox(height: 20),
                        ],
                        if (outbox.isNotEmpty) ...[
                          _SectionTitle(
                            title: 'طلبات مرسلة',
                            count: outbox.length,
                            icon: Icons.schedule_send_rounded,
                            accent: AppColors.gold,
                          ),
                          const SizedBox(height: 8),
                          ...outbox.map(_outgoingRequest),
                          const SizedBox(height: 20),
                        ],
                        _SectionTitle(
                          title: 'دائرة الأصدقاء',
                          count: friends.length,
                          icon: Icons.groups_rounded,
                          accent: AppColors.palm,
                        ),
                        const SizedBox(height: 8),
                        if (friends.isEmpty)
                          SocialEmptyState(
                            title: 'ربعك ينتظرك',
                            artwork: const _FriendsDiscoveryArtwork(),
                            message: 'ابحث عن لاعب وأرسل أول طلب صداقة.',
                            scene: SocialArtworkScene.friends,
                            actionLabel: 'ابدأ البحث',
                            onAction: online ? _searchFocus.requestFocus : null,
                          )
                        else
                          ...friends.map(_friendCard),
                      ],
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  Widget _searchResult(Map<String, Object?> row) {
    final relationship = '${row['relationship'] ?? 'none'}';
    return _PlayerCard(
      row: row,
      tone: _PlayerCardTone.search,
      trailing: switch (relationship) {
        'friend' => const _RelationshipPill(
          label: 'صديق',
          icon: Icons.check_rounded,
          color: AppColors.palm,
        ),
        'pending_sent' => const _RelationshipPill(
          label: 'بانتظار الرد',
          icon: Icons.schedule_rounded,
          color: AppColors.coffee,
        ),
        'pending_received' => OutlinedButton.icon(
          onPressed: () => _reload(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          icon: const Icon(Icons.inbox_rounded, size: 16),
          label: const Text('راجع الطلب'),
        ),
        _ => FilledButton.icon(
          onPressed: _busyIds.contains('${row['user_id']}')
              ? null
              : () => _sendRequest(row),
          style: FilledButton.styleFrom(
            side: const BorderSide(color: AppColors.ink),
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: const Text('إضافة'),
        ),
      },
    );
  }

  Widget _incomingRequest(Map<String, Object?> row) {
    final id = '${row['request_id']}';
    return _PlayerCard(
      row: row,
      subtitle: row['message'] == null ? null : '${row['message']}',
      tone: _PlayerCardTone.incoming,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'رفض',
            onPressed: _busyIds.contains(id)
                ? null
                : () => _respond(id, accept: false),
            style: IconButton.styleFrom(
              foregroundColor: AhdashColors.light.error,
              backgroundColor: AppColors.danger.withValues(alpha: .08),
              minimumSize: const Size(44, 44),
            ),
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: _busyIds.contains(id)
                ? null
                : () => _respond(id, accept: true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(60, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('قبول'),
          ),
        ],
      ),
    );
  }

  Widget _outgoingRequest(Map<String, Object?> row) {
    final id = '${row['request_id']}';
    return _PlayerCard(
      row: row,
      subtitle: 'بانتظار قبول الطلب',
      tone: _PlayerCardTone.outgoing,
      trailing: TextButton(
        onPressed: _busyIds.contains(id)
            ? null
            : () => _respond(id, accept: false),
        style: TextButton.styleFrom(
          minimumSize: const Size(58, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: const BorderSide(color: AppColors.hairline),
          backgroundColor: AppColors.paper0,
        ),
        child: const Text('إلغاء'),
      ),
    );
  }

  Widget _friendCard(Map<String, Object?> row) {
    final id = '${row['user_id']}';
    return _PlayerCard(
      row: row,
      tone: _PlayerCardTone.friend,
      trailing: PopupMenuButton<String>(
        enabled: !_busyIds.contains(id),
        tooltip: 'خيارات الصديق',
        icon: const Icon(Icons.more_horiz_rounded),
        style: IconButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.paper2,
          minimumSize: const Size(44, 44),
        ),
        onSelected: (action) => _friendAction(action, row),
        itemBuilder: (_) => [
          if (widget.inviteTeamId != null)
            const PopupMenuItem(
              value: 'team_invite',
              child: Text('دعوة للفريق'),
            ),
          const PopupMenuItem(value: 'report', child: Text('إبلاغ')),
          const PopupMenuItem(value: 'remove', child: Text('إزالة الصديق')),
          const PopupMenuItem(value: 'block', child: Text('حظر اللاعب')),
        ],
      ),
    );
  }

  Future<void> _friendAction(String action, Map<String, Object?> row) async {
    final id = '${row['user_id']}';
    switch (action) {
      case 'team_invite':
        final teamId = widget.inviteTeamId;
        if (teamId == null) return;
        await _action(id, () async {
          await ref.read(socialRepositoryProvider).inviteFriend(teamId, id);
          _message('أرسلنا دعوة الفريق بشكل خاص.');
        });
        return;
      case 'report':
        await _reportPlayer(row);
        return;
      case 'block':
        await _blockPlayer(row);
        return;
      case 'remove':
        await _removeFriend(row);
        return;
    }
  }

  Future<void> _reload() async {
    ref.invalidate(friendsDashboardProvider);
    try {
      await ref.read(friendsDashboardProvider.future);
    } catch (_) {
      // The provider renders the retry state; keep refresh callbacks handled.
    }
  }

  Future<void> _search() async {
    _searchDebounce?.cancel();
    final query = _searchController.text.trim();
    if (query.length < 2) {
      _message('اكتب حرفين على الأقل للبحث.');
      return;
    }
    final revision = ++_searchRevision;
    setState(() {
      _searching = true;
      _searchFailed = false;
      _searchResults = null;
    });
    try {
      final data = await ref
          .read(socialRepositoryProvider)
          .searchPlayers(query);
      if (mounted && revision == _searchRevision) {
        setState(() => _searchResults = data);
      }
    } catch (_) {
      if (mounted && revision == _searchRevision) {
        setState(() => _searchFailed = true);
      }
    } finally {
      if (mounted && revision == _searchRevision) {
        setState(() => _searching = false);
      }
    }
  }

  void _queueSearch(String value) {
    _searchDebounce?.cancel();
    ++_searchRevision;
    setState(() {
      _searchResults = null;
      _searchFailed = false;
      _searching = false;
    });
    if (value.trim().length < 2) return;
    _searchDebounce = Timer(const Duration(milliseconds: 420), _search);
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    ++_searchRevision;
    _searchController.clear();
    setState(() {
      _searchResults = null;
      _searchFailed = false;
      _searching = false;
    });
    _searchFocus.requestFocus();
  }

  Future<void> _sendRequest(Map<String, Object?> row) async {
    final id = '${row['user_id']}';
    final actor = await ref.read(authControllerProvider.future);
    if (!mounted) return;
    if (actor?.id == id) {
      _message('لا يمكنك إرسال طلب صداقة إلى حسابك.');
      return;
    }
    await _action(id, () async {
      await ref.read(socialRepositoryProvider).sendFriendRequest(id);
      _message('تم إرسال طلب الصداقة.');
      if (mounted && _searchController.text.trim().length >= 2) {
        await _search();
      }
    });
  }

  Future<void> _respond(String requestId, {required bool accept}) async {
    await _action(requestId, () async {
      await ref
          .read(socialRepositoryProvider)
          .respondFriendRequest(requestId, accept: accept);
      _message(accept ? 'أصبح اللاعب ضمن أصدقائك.' : 'تم تحديث الطلب.');
      await _reload();
    });
  }

  Future<void> _removeFriend(Map<String, Object?> row) async {
    final id = '${row['user_id']}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إزالة الصديق؟'),
        content: Text('سيُزال ${row['display_name']} من قائمتك.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    await _action(id, () async {
      await ref.read(socialRepositoryProvider).removeFriend(id);
      await _reload();
    });
  }

  Future<void> _blockPlayer(Map<String, Object?> row) async {
    final id = '${row['user_id']}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حظر اللاعب؟'),
        content: const Text(
          'لن يظهر في البحث وستُلغى الصداقة والطلبات المشتركة. يمكنك فك الحظر لاحقًا من الخصوصية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.paper0,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حظر'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _action(id, () async {
      await ref.read(socialRepositoryProvider).blockPlayer(id);
      await _reload();
      _message('تم حظر اللاعب.');
    });
  }

  Future<void> _reportPlayer(Map<String, Object?> row) async {
    var reason = 'abuse';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إبلاغ آمن'),
          content: DropdownButtonFormField<String>(
            initialValue: reason,
            decoration: const InputDecoration(labelText: 'السبب'),
            items: const [
              DropdownMenuItem(value: 'abuse', child: Text('إساءة')),
              DropdownMenuItem(value: 'spam', child: Text('إزعاج أو تكرار')),
              DropdownMenuItem(value: 'impersonation', child: Text('انتحال')),
              DropdownMenuItem(value: 'other', child: Text('سبب آخر')),
            ],
            onChanged: (value) =>
                setDialogState(() => reason = value ?? 'abuse'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('تراجع'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true) return;
    final id = '${row['user_id']}';
    await _action(id, () async {
      await ref
          .read(socialRepositoryProvider)
          .reportPlayer(userId: id, reason: reason);
      _message('وصل البلاغ للمراجعة.');
    });
  }

  Future<void> _action(String id, Future<void> Function() action) async {
    setState(() => _busyIds.add(id));
    try {
      await action();
    } catch (_) {
      _message('تعذر إكمال العملية الآمنة.');
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  void _message(String value) {
    if (!mounted) return;
    showAhdashSnackbar(context, value);
  }

  List<Map<String, Object?>> _rows(Object? value) =>
      (value as List? ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map(Map<String, Object?>.from)
          .toList(growable: false);
}

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.count,
    required this.icon,
    required this.accent,
    this.emphasized = false,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color accent;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: emphasized
          ? const EdgeInsetsDirectional.fromSTEB(8, 7, 8, 7)
          : EdgeInsets.zero,
      decoration: emphasized
          ? BoxDecoration(
              color: AppColors.brandLime.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.brandLime.withValues(alpha: .52),
              ),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 16,
              color: emphasized
                  ? AppColors.ink
                  : accent == AppColors.gold
                  ? AppColors.coffee
                  : accent,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 38, minHeight: 28),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: emphasized ? AppColors.ink : AppColors.paper1,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: emphasized ? AppColors.ink : AppColors.hairline,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$count',
              style: TextStyle(
                color: emphasized ? AppColors.brandLime : AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PlayerCardTone { search, incoming, outgoing, friend }

final class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.row,
    required this.trailing,
    required this.tone,
    this.subtitle,
  });

  final Map<String, Object?> row;
  final Widget trailing;
  final String? subtitle;
  final _PlayerCardTone tone;

  @override
  Widget build(BuildContext context) {
    final name = '${row['display_name'] ?? row['username'] ?? 'لاعب 11'}';
    final username = '${row['username'] ?? ''}'.trim();
    final metadata =
        subtitle ?? (username.isEmpty ? null : 'اسم المستخدم · $username');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SocialPlayerRow(
        displayName: name,
        avatarUrl: row['avatar_url'] as String?,
        subtitle: metadata,
        highlighted: tone == _PlayerCardTone.incoming,
        trailing: trailing,
      ),
    );
  }
}

final class _FriendsDiscoveryArtwork extends StatelessWidget {
  const _FriendsDiscoveryArtwork();

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('friends-discovery-artwork'),
    width: 180,
    height: 120,
    child: Image.asset(
      'assets/visuals/friends_discovery_cutout_v1.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    ),
  );
}

final class _SearchHeaderIcon extends StatelessWidget {
  const _SearchHeaderIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(11),
    ),
    child: const Icon(
      Icons.person_add_alt_1_rounded,
      size: 17,
      color: AppColors.brandLime,
    ),
  );
}

final class _FriendsOverview extends StatelessWidget {
  const _FriendsOverview({
    required this.friends,
    required this.inbox,
    required this.outbox,
  });

  final int friends;
  final int inbox;
  final int outbox;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '$friends أصدقاء، $inbox طلبات بانتظار ردك، $outbox طلبات مرسلة',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .1),
            offset: const Offset(0, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _OverviewMetric(
              value: friends,
              label: 'أصدقاء',
              icon: Icons.groups_rounded,
              color: AppColors.brandLime,
            ),
          ),
          const _OverviewDivider(),
          Expanded(
            child: _OverviewMetric(
              value: inbox,
              label: 'بانتظارك',
              icon: Icons.mark_email_unread_rounded,
              color: AppColors.gold,
            ),
          ),
          const _OverviewDivider(),
          Expanded(
            child: _OverviewMetric(
              value: outbox,
              label: 'مرسلة',
              icon: Icons.schedule_send_rounded,
              color: AppColors.teamBlue,
            ),
          ),
        ],
      ),
    ),
  );
}

final class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: AppColors.paper0,
                  fontSize: 16,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.paper3,
                  fontSize: 10,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _OverviewDivider extends StatelessWidget {
  const _OverviewDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 32,
    color: AppColors.paper0.withValues(alpha: .16),
  );
}

final class _FriendsLoadingView extends StatelessWidget {
  const _FriendsLoadingView();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: const SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(
            color: AppColors.brandLime,
            strokeWidth: 2.5,
          ),
        ),
      ),
      const SizedBox(height: 14),
      const _FriendSkeletonRow(),
      const SizedBox(height: 8),
      const _FriendSkeletonRow(),
      const SizedBox(height: 8),
      const _FriendSkeletonRow(),
    ],
  );
}

final class _FriendSkeletonRow extends StatelessWidget {
  const _FriendSkeletonRow();

  @override
  Widget build(BuildContext context) => Container(
    height: 68,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.paper1,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.hairline),
    ),
    child: Row(
      children: [
        const CircleAvatar(radius: 20, backgroundColor: AppColors.paper2),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 118,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 7),
              Container(
                width: 76,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _RelationshipPill extends StatelessWidget {
  const _RelationshipPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 36),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: .38)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

final class _SearchMessage extends StatelessWidget {
  const _SearchMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.paper1,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.hairline),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 9),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
