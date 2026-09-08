import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/presentation/app_states.dart';
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
  Timer? _searchDebounce;
  final _busyIds = <String>{};

  @override
  void initState() {
    super.initState();
  }

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
      title: 'ربعك',
      subtitle: widget.inviteTeamId == null
          ? 'أصدقاء وطلبات حقيقية من الخادم'
          : 'اختر صديقًا لدعوته إلى الفريق',
      onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      actions: [
        IconButton(
          tooltip: 'الفِرق',
          onPressed: () => context.push('/teams'),
          icon: const Icon(Icons.groups_3_outlined),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          key: const ValueKey('friends-keyboard-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(bottom: 16 + inset),
          children: [
            SocialHero(
              title: 'ربعك في أحدعش',
              subtitle: 'ابحث، أرسل طلبًا، واجمع فريقك من العلاقات الحقيقية.',
              scene: SocialArtworkScene.friends,
              actionLabel: 'إضافة صديق',
              onAction: online ? _searchFocus.requestFocus : null,
              compact: true,
            ),
            const SizedBox(height: 14),
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
                  const Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(4, 0, 4, 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ابحث في مجتمع أحدعش',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'PASS / 01',
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
                  TextField(
                    key: const ValueKey('friends-search-field'),
                    controller: _searchController,
                    focusNode: _searchFocus,
                    enabled: online && !_searching,
                    textInputAction: TextInputAction.search,
                    onChanged: _queueSearch,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.paper0,
                      hintText: 'ابحث باسم اللاعب',
                      prefixIcon: const Icon(Icons.person_search_rounded),
                      suffixIconConstraints: const BoxConstraints(minWidth: 48),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              tooltip: 'مسح البحث',
                              onPressed: _searching ? null : _clearSearch,
                              icon: const Icon(Icons.close_rounded, size: 19),
                            ),
                          IconButton(
                            tooltip: 'بحث',
                            onPressed: online && !_searching ? _search : null,
                            icon: _searching
                                ? const SizedBox.square(
                                    dimension: 19,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.arrow_back_rounded),
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
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _searchResults!.isEmpty
                    ? const SocialEmptyState(
                        key: ValueKey('friends-no-results'),
                        title: 'لا يوجد لاعب مطابق.',
                        message: 'راجع كتابة الاسم أو جرّب اسم المستخدم.',
                        scene: SocialArtworkScene.search,
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
                  loading: () => const LoadingSkeleton(lines: 6),
                  error: (_, _) => AppMessageState(
                    title: 'تعذر تحميل الأصدقاء',
                    message: 'تحقق من الاتصال وحاول مجددًا.',
                    actionLabel: 'إعادة المحاولة',
                    onAction: _reload,
                  ),
                  data: (data) {
                    final inbox = _rows(data['inbox']);
                    final outbox = _rows(data['outbox']);
                    final friends = _rows(data['friends']);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (inbox.isNotEmpty) ...[
                          _SectionTitle(
                            title: 'طلبات واردة',
                            count: inbox.length,
                          ),
                          const SizedBox(height: 8),
                          ...inbox.map(_incomingRequest),
                          const SizedBox(height: 20),
                        ],
                        if (outbox.isNotEmpty) ...[
                          _SectionTitle(
                            title: 'طلبات مرسلة',
                            count: outbox.length,
                          ),
                          const SizedBox(height: 8),
                          ...outbox.map(_outgoingRequest),
                          const SizedBox(height: 20),
                        ],
                        _SectionTitle(
                          title: 'قائمة الأصدقاء',
                          count: friends.length,
                        ),
                        const SizedBox(height: 8),
                        if (friends.isEmpty)
                          SocialEmptyState(
                            title: 'ربعك ينتظرك',
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
      trailing: switch (relationship) {
        'friend' => const Chip(label: Text('صديق')),
        'pending_sent' => const Chip(label: Text('بانتظار الرد')),
        'pending_received' => FilledButton.tonal(
          onPressed: () => _reload(),
          child: const Text('راجع الطلب'),
        ),
        _ => FilledButton.icon(
          onPressed: _busyIds.contains('${row['user_id']}')
              ? null
              : () => _sendRequest(row),
          style: FilledButton.styleFrom(
            side: const BorderSide(color: AppColors.ink),
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'رفض',
            onPressed: _busyIds.contains(id)
                ? null
                : () => _respond(id, accept: false),
            icon: const Icon(Icons.close_rounded, color: AppColors.danger),
          ),
          FilledButton(
            onPressed: _busyIds.contains(id)
                ? null
                : () => _respond(id, accept: true),
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
      trailing: TextButton(
        onPressed: _busyIds.contains(id)
            ? null
            : () => _respond(id, accept: false),
        child: const Text('إلغاء'),
      ),
    );
  }

  Widget _friendCard(Map<String, Object?> row) {
    final id = '${row['user_id']}';
    return _PlayerCard(
      row: row,
      subtitle: 'من ربعك في أحدعش',
      trailing: PopupMenuButton<String>(
        enabled: !_busyIds.contains(id),
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
    await ref.read(friendsDashboardProvider.future);
  }

  Future<void> _search() async {
    _searchDebounce?.cancel();
    final query = _searchController.text.trim();
    if (query.length < 2) {
      _message('اكتب حرفين على الأقل للبحث.');
      return;
    }
    setState(() {
      _searching = true;
      _searchFailed = false;
    });
    try {
      final data = await ref
          .read(socialRepositoryProvider)
          .searchPlayers(query);
      if (mounted) {
        setState(() => _searchResults = data);
      }
    } catch (_) {
      if (mounted) setState(() => _searchFailed = true);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _queueSearch(String value) {
    if (mounted) setState(() {});
    _searchDebounce?.cancel();
    if (value.trim().length < 2) return;
    _searchDebounce = Timer(const Duration(milliseconds: 420), _search);
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _searchResults = null;
      _searchFailed = false;
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
      await _search();
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
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 38, minHeight: 28),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.paper1,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.hairline),
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

final class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.row, required this.trailing, this.subtitle});

  final Map<String, Object?> row;
  final Widget trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final name = '${row['display_name'] ?? row['username'] ?? 'لاعب 11'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SocialPlayerRow(
        displayName: name,
        avatarUrl: row['avatar_url'] as String?,
        username: '${row['username'] ?? ''}',
        subtitle: subtitle,
        trailing: trailing,
      ),
    );
  }
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
