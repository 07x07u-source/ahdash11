import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/features/categories/presentation/categories_controller.dart';
import 'package:ahdash_11/features/match/presentation/solo_home_screen.dart';
import 'package:ahdash_11/features/tournament/data/tournament_registration_repository.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_controller.dart';
import 'package:ahdash_11/features/tournament/presentation/tournament_dashboard_screen.dart';
import 'package:ahdash_11/shared/domain/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('tournament dashboard exposes create, join and empty states', (
    tester,
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
          appConfigProvider.overrideWithValue(_config),
          tournamentControllerProvider.overrideWith(
            _IdleTournamentController.new,
          ),
          availableTournamentsProvider.overrideWith((ref) async => const []),
          myTournamentEntriesProvider.overrideWith((ref) async => const []),
        ],
        child: testApp(const TournamentDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الكأس يبدأ بقرار'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tournament-dashboard-create')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tournament-dashboard-join')),
      findsOneWidget,
    );
    expect(
      find.text('لا توجد مشاركة بعد. أنشئ بطولة أو انضم برمز.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('solo home keeps the real category source and start action', (
    tester,
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
          appConfigProvider.overrideWithValue(_config),
          categoriesProvider.overrideWithBuild(
            (ref, notifier) async => const [],
          ),
        ],
        child: testApp(const SoloHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('خلّ تركيزك يتكلم'), findsOneWidget);
    expect(find.byKey(const ValueKey('solo-home-start')), findsOneWidget);
    expect(
      find.text('ستظهر الأقسام المنشورة هنا عند جاهزية الكتالوج.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tournament dashboard filters public tournaments by search', (
    tester,
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
          appConfigProvider.overrideWithValue(_config),
          tournamentControllerProvider.overrideWith(
            _IdleTournamentController.new,
          ),
          availableTournamentsProvider.overrideWith(
            (ref) async => [
              AvailableTournament(
                id: 'one',
                name: 'كأس الأصدقاء',
                capacity: 8,
                playersPerTeam: 2,
                inviteCode: 'FRIENDS',
                createdAt: DateTime(2026),
              ),
              AvailableTournament(
                id: 'two',
                name: 'تحدي المعرفة',
                capacity: 4,
                playersPerTeam: 1,
                inviteCode: 'QUIZ',
                createdAt: DateTime(2026),
              ),
            ],
          ),
          myTournamentEntriesProvider.overrideWith((ref) async => const []),
        ],
        child: testApp(const TournamentDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tournament-search')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('tournament-search')),
      'معرفة',
    );
    await tester.pump();
    expect(find.text('تحدي المعرفة'), findsOneWidget);
    expect(find.text('كأس الأصدقاء'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('solo home exposes category search when catalog has content', (
    tester,
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
          appConfigProvider.overrideWithValue(_config),
          categoriesProvider.overrideWithBuild(
            (ref, notifier) async => const [
              QuizCategory(
                id: 'football',
                name: 'كرة القدم',
                description: 'أسئلة الكرة',
                iconName: 'sports_soccer',
                accentColor: Color(0xFFB6FF3B),
              ),
            ],
          ),
        ],
        child: testApp(const SoloHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('solo-category-search')), findsOneWidget);
    expect(find.text('كرة القدم'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('solo-category-search')),
      'غير موجود',
    );
    await tester.pump();
    expect(find.textContaining('لا يوجد قسم مطابق'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _config = AppConfig(
  environment: AppEnvironment.production,
  supabaseUrl: '',
  supabaseKey: '',
  firebaseEnabled: false,
  adMobEnabled: false,
  revenueCatAndroidKey: '',
  revenueCatIosKey: '',
);

final class _IdleTournamentController extends TournamentController {
  @override
  TournamentState build() => const TournamentState(restored: true);

  @override
  Future<void> restore() async {}
}
