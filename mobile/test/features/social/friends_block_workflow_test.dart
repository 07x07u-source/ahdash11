import 'dart:async';

import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/auth/presentation/auth_controller.dart';
import 'package:ahdash_11/features/social/data/social_repository.dart';
import 'package:ahdash_11/features/social/presentation/blocked_players_screen.dart';
import 'package:ahdash_11/features/social/presentation/friends_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/fake_social_repository.dart';
import '../../fixtures/v10_feature_fixtures.dart';
import '../../helpers/test_app.dart';

void main() {
  testWidgets('friends empty and dashboard failure are deliberate states', (
    tester,
  ) async {
    await _pump(tester, const FriendsScreen(), FakeSocialRepository());
    expect(find.text('ابحث عن لاعب وأرسل أول طلب صداقة.'), findsOneWidget);

    final failing = FakeSocialRepository()
      ..dashboardError = StateError('private dashboard error');
    await _pump(tester, const FriendsScreen(), failing);
    expect(find.text('تعذر تحميل الأصدقاء'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(find.textContaining('private dashboard'), findsNothing);
  });

  testWidgets('friend search add is single-submit and refreshes safely', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = FakeSocialRepository(
      searchResults: [V10FeatureFixtures.friendSearchResults.first],
    )..sendGate = gate;
    await _pump(tester, const FriendsScreen(), repository);

    await tester.enterText(
      find.byKey(const ValueKey('friends-search-field')),
      'لاعب',
    );
    await tester.tap(find.byTooltip('بحث'));
    await tester.pumpAndSettle();
    final add = find.widgetWithText(FilledButton, 'إضافة');
    expect(add, findsOneWidget);

    await tester.tap(add);
    await tester.pump();
    expect(repository.sends, 1);
    expect(tester.widget<FilledButton>(add).onPressed, isNull);

    gate.complete();
    await tester.pumpAndSettle();
    expect(repository.sends, 1);
    expect(find.text('تم إرسال طلب الصداقة.'), findsOneWidget);
  });

  testWidgets('stale self result is rejected before a protected mutation', (
    tester,
  ) async {
    final repository = FakeSocialRepository(
      searchResults: V10FeatureFixtures.selfSearchResult,
    );
    await _pump(tester, const FriendsScreen(), repository);
    await tester.enterText(
      find.byKey(const ValueKey('friends-search-field')),
      'حساب',
    );
    await tester.tap(find.byTooltip('بحث'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'إضافة'));
    await tester.pump();
    expect(repository.sends, 0);
    expect(find.text('لا يمكنك إرسال طلب صداقة إلى حسابك.'), findsOneWidget);
  });

  testWidgets('pending and existing relationships cannot be added twice', (
    tester,
  ) async {
    final repository = FakeSocialRepository(
      searchResults: V10FeatureFixtures.friendSearchResults.sublist(1),
    );
    await _pump(tester, const FriendsScreen(), repository);
    await tester.enterText(
      find.byKey(const ValueKey('friends-search-field')),
      'طلب',
    );
    await tester.tap(find.byTooltip('بحث'));
    await tester.pumpAndSettle();
    expect(find.text('بانتظار الرد'), findsOneWidget);
    expect(find.text('صديق'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'إضافة'), findsNothing);
  });

  testWidgets('search no-results and failure preserve concise Arabic UX', (
    tester,
  ) async {
    final empty = FakeSocialRepository();
    await _pump(tester, const FriendsScreen(), empty);
    await tester.enterText(
      find.byKey(const ValueKey('friends-search-field')),
      'غائب',
    );
    await tester.tap(find.byTooltip('بحث'));
    await tester.pumpAndSettle();
    expect(find.text('لا يوجد لاعب مطابق.'), findsOneWidget);

    final failing = FakeSocialRepository()
      ..searchError = StateError('raw search response');
    await _pump(tester, const FriendsScreen(), failing);
    await tester.enterText(
      find.byKey(const ValueKey('friends-search-field')),
      'لاعب',
    );
    await tester.tap(find.byTooltip('بحث'));
    await tester.pumpAndSettle();
    expect(find.text('تعذر البحث الآن. حاول بعد قليل.'), findsOneWidget);
    expect(find.textContaining('raw search'), findsNothing);
  });

  testWidgets('friend requests and removal exercise real supported actions', (
    tester,
  ) async {
    final repository = FakeSocialRepository(
      dashboard: V10FeatureFixtures.populatedFriendsDashboard,
    );
    await _pump(tester, const FriendsScreen(), repository);

    await tester.tap(find.widgetWithText(FilledButton, 'قبول'));
    await tester.pumpAndSettle();
    expect(repository.responses, 1);

    await tester.tap(find.widgetWithText(TextButton, 'إلغاء'));
    await tester.pumpAndSettle();
    expect(repository.responses, 2);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('إزالة الصديق'));
    await tester.pumpAndSettle();
    expect(find.text('إزالة الصديق؟'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'إزالة'));
    await tester.pumpAndSettle();
    expect(repository.removals, 1);
  });

  testWidgets('block uses confirmation, refreshes list and hides the user', (
    tester,
  ) async {
    final repository = FakeSocialRepository(
      dashboard: V10FeatureFixtures.populatedFriendsDashboard,
    );
    await _pump(tester, const FriendsScreen(), repository);
    expect(find.text('صديق الاختبار الأول'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('حظر اللاعب'));
    await tester.pumpAndSettle();
    expect(find.text('حظر اللاعب؟'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'حظر'));
    await tester.pumpAndSettle();

    expect(repository.blocks, 1);
    expect(find.text('صديق الاختبار الأول'), findsNothing);
    expect(find.text('تم حظر اللاعب.'), findsOneWidget);
  });

  testWidgets('block failure is localized and never exposes internals', (
    tester,
  ) async {
    final repository = FakeSocialRepository(
      dashboard: V10FeatureFixtures.populatedFriendsDashboard,
    )..blockError = StateError('private database detail');
    await _pump(tester, const FriendsScreen(), repository);
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('حظر اللاعب'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'حظر'));
    await tester.pumpAndSettle();

    expect(find.text('تعذر إكمال العملية الآمنة.'), findsOneWidget);
    expect(find.textContaining('private database'), findsNothing);
  });

  testWidgets('unblock refreshes the populated list to its empty state', (
    tester,
  ) async {
    final repository = FakeSocialRepository(
      blockedPlayers: V10FeatureFixtures.blockedPlayers,
    );
    await _pump(tester, const BlockedPlayersScreen(), repository);
    expect(find.text('حساب محظور للاختبار'), findsOneWidget);
    await tester.tap(find.text('فك الحظر'));
    await tester.pumpAndSettle();
    expect(repository.unblocks, 1);
    expect(find.text('قائمة الحظر فارغة'), findsOneWidget);
  });

  testWidgets('unblock failure preserves the row and shows a safe error', (
    tester,
  ) async {
    final repository = FakeSocialRepository(
      blockedPlayers: V10FeatureFixtures.blockedPlayers,
    )..unblockError = StateError('secret response');
    await _pump(tester, const BlockedPlayersScreen(), repository);
    await tester.tap(find.text('فك الحظر'));
    await tester.pumpAndSettle();
    expect(repository.unblocks, 1);
    expect(find.text('حساب محظور للاختبار'), findsOneWidget);
    expect(find.text('تعذر فك الحظر.'), findsOneWidget);
    expect(find.textContaining('secret response'), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  FakeSocialRepository repository,
) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        socialRepositoryProvider.overrideWithValue(repository),
        authControllerProvider.overrideWithBuild(
          (ref, notifier) async => V10FeatureFixtures.account,
        ),
        appPreferencesProvider.overrideWithBuild(
          (ref, notifier) async => const AppPreferences(reducedMotion: true),
        ),
      ],
      child: testApp(screen, theme: AppTheme.light),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}
