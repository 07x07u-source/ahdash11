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
  testWidgets('clearing an in-flight search cannot restore stale results', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = FakeSocialRepository(
      searchResults: V10FeatureFixtures.friendSearchResults,
    )..searchGate = gate;
    await _pump(tester, const FriendsScreen(), repository);
    final field = find.byKey(const ValueKey('friends-search-field'));
    await tester.enterText(field, 'لاعب');
    await tester.tap(find.byTooltip('بحث'));
    await tester.pump();
    expect(tester.widget<TextField>(field).enabled, isTrue);
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
    await tester.tap(find.byTooltip('مسح البحث'));
    await tester.pump();
    gate.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(find.text('نتائج البحث'), findsNothing);
    expect(repository.searches, 1);
  });

  testWidgets('new query wins when an older search completes last', (
    tester,
  ) async {
    final older = Completer<List<Map<String, Object?>>>();
    final newer = Completer<List<Map<String, Object?>>>();
    final repository = FakeSocialRepository()
      ..searchHandler = (query) =>
          query == 'قديم' ? older.future : newer.future;
    await _pump(tester, const FriendsScreen(), repository);
    final field = find.byKey(const ValueKey('friends-search-field'));
    await tester.enterText(field, 'قديم');
    await tester.tap(find.byTooltip('بحث'));
    await tester.pump();
    await tester.enterText(field, 'جديد');
    await tester.pump(const Duration(milliseconds: 420));
    expect(repository.searches, 2);
    newer.complete([
      {
        'user_id': 'new',
        'display_name': 'النتيجة الحالية',
        'relationship': 'friend',
      },
    ]);
    await tester.pumpAndSettle();
    older.complete([
      {
        'user_id': 'old',
        'display_name': 'النتيجة القديمة',
        'relationship': 'friend',
      },
    ]);
    await tester.pumpAndSettle();
    expect(find.text('النتيجة الحالية'), findsOneWidget);
    expect(find.text('النتيجة القديمة'), findsNothing);
  });

  testWidgets('short queries clear results without another server request', (
    tester,
  ) async {
    final repository = FakeSocialRepository(
      searchResults: V10FeatureFixtures.friendSearchResults,
    );
    await _pump(tester, const FriendsScreen(), repository);
    final field = find.byKey(const ValueKey('friends-search-field'));
    await tester.enterText(field, 'لاعب');
    await tester.tap(find.byTooltip('بحث'));
    await tester.pumpAndSettle();
    expect(find.text('نتائج البحث'), findsOneWidget);
    await tester.enterText(field, 'ل');
    await tester.pumpAndSettle();
    expect(find.text('نتائج البحث'), findsNothing);
    expect(repository.searches, 1);
  });

  testWidgets('dashboard retry handles repeated failure then recovers', (
    tester,
  ) async {
    final repository = FakeSocialRepository()
      ..dashboardError = StateError('private error');
    await _pump(tester, const FriendsScreen(), repository);
    final retry = find.widgetWithText(FilledButton, 'إعادة المحاولة');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('تعذر تحميل الأصدقاء'), findsOneWidget);
    repository.dashboardError = null;
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text('تعذر تحميل الأصدقاء'), findsNothing);
    expect(find.text('ربعك ينتظرك'), findsOneWidget);
  });

  testWidgets(
    'friends artwork CTA is accessible and reduced motion is respected',
    (tester) async {
      final repository = FakeSocialRepository();
      await _pump(tester, const FriendsScreen(), repository);
      final add = find.widgetWithText(FilledButton, 'أضف لاعبًا');
      expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
      await tester.tap(add);
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('friends-search-field'));
      expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
      await tester.enterText(field, 'لاعب');
      await tester.tap(find.byTooltip('بحث'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
        Duration.zero,
      );
    },
  );

  testWidgets('friends empty and dashboard failure are deliberate states', (
    tester,
  ) async {
    await _pump(tester, const FriendsScreen(), FakeSocialRepository());
    expect(find.text('ابحث عن لاعب وأرسل أول طلب صداقة.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('friends-discovery-artwork')),
      findsOneWidget,
    );
    expect(find.text('SOCIAL 11'), findsNothing);

    final failing = FakeSocialRepository()
      ..dashboardError = StateError('private dashboard error');
    await _pump(tester, const FriendsScreen(), failing);
    expect(find.text('تعذر تحميل الأصدقاء'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('friends-discovery-artwork')),
      findsOneWidget,
    );
    expect(find.text('SOCIAL 11'), findsNothing);
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
    expect(
      find.byKey(const ValueKey('friends-discovery-artwork')),
      findsNWidgets(2),
    );
    expect(find.text('SOCIAL 11'), findsNothing);

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

    await tester.drag(
      find.byKey(const ValueKey('friends-keyboard-scroll')),
      const Offset(0, -160),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'إلغاء'));
    await tester.pumpAndSettle();
    expect(repository.responses, 2);

    await tester.ensureVisible(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('إزالة الصديق'));
    await tester.pumpAndSettle();
    expect(find.text('إزالة الصديق؟'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'إزالة'));
    await tester.pumpAndSettle();
    expect(repository.removals, 1);
  });

  testWidgets('populated friends remain readable on compact scaled text', (
    tester,
  ) async {
    final repository = FakeSocialRepository(
      dashboard: V10FeatureFixtures.populatedFriendsDashboard,
    );
    await _pump(
      tester,
      const FriendsScreen(),
      repository,
      size: const Size(360, 800),
      textScale: 1.3,
    );

    expect(find.text('بانتظار ردك'), findsOneWidget);
    expect(find.text('وليد الدوسري'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('دائرة الأصدقاء'));
    await tester.pumpAndSettle();
    expect(find.text('سلمان الحربي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('block uses confirmation, refreshes list and hides the user', (
    tester,
  ) async {
    final repository = FakeSocialRepository(
      dashboard: V10FeatureFixtures.populatedFriendsDashboard,
    );
    await _pump(tester, const FriendsScreen(), repository);
    expect(find.text('سلمان الحربي'), findsOneWidget);

    await tester.ensureVisible(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('حظر اللاعب'));
    await tester.pumpAndSettle();
    expect(find.text('حظر اللاعب؟'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'حظر'));
    await tester.pumpAndSettle();

    expect(repository.blocks, 1);
    expect(find.text('سلمان الحربي'), findsNothing);
    expect(find.text('تم حظر اللاعب.'), findsOneWidget);
  });

  testWidgets('block failure is localized and never exposes internals', (
    tester,
  ) async {
    final repository = FakeSocialRepository(
      dashboard: V10FeatureFixtures.populatedFriendsDashboard,
    )..blockError = StateError('private database detail');
    await _pump(tester, const FriendsScreen(), repository);
    await tester.ensureVisible(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
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

  testWidgets('blocked list retry and refresh reload real rows safely', (
    tester,
  ) async {
    final repository = FakeSocialRepository(
      blockedPlayers: V10FeatureFixtures.blockedPlayers,
    )..blockedLoadError = StateError('private blocked list response');
    await _pump(tester, const BlockedPlayersScreen(), repository);
    expect(find.text('تعذر تحميل قائمة الحظر'), findsOneWidget);
    expect(find.textContaining('private blocked'), findsNothing);
    repository.blockedLoadError = null;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(repository.blockedLoads, 2);
    expect(find.text('حساب محظور للاختبار'), findsOneWidget);
    await tester.tap(find.byTooltip('تحديث قائمة الحظر'));
    await tester.pumpAndSettle();
    expect(repository.blockedLoads, 3);
    expect(find.text('حساب محظور للاختبار'), findsOneWidget);
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
  FakeSocialRepository repository, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = size
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
      child: testApp(
        MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: screen,
        ),
        theme: AppTheme.light,
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}
