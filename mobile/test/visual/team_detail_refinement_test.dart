import 'dart:async';

import 'package:ahdash_11/core/config/app_config.dart';
import 'package:ahdash_11/core/services/app_services.dart';
import 'package:ahdash_11/core/settings/app_preferences.dart';
import 'package:ahdash_11/core/theme/app_theme.dart';
import 'package:ahdash_11/features/social/data/social_repository.dart';
import 'package:ahdash_11/features/social/domain/social_entities.dart';
import 'package:ahdash_11/features/social/presentation/social_team_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fake_social_repository.dart';
import '../helpers/phase6_fixture.dart';
import '../helpers/test_app.dart';
import '../helpers/visual_test_variant.dart';

enum _State { owner, member, empty, mvp, loading, error }

void main() {
  setUpAll(() async {
    final fonts = FontLoader('ThmanyahSans');
    for (final weight in ['Regular', 'Medium', 'Bold', 'Black']) {
      fonts.addFont(
        rootBundle.load('assets/fonts/thmanyah/thmanyahsans-$weight.otf'),
      );
    }
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final size in const [Size(390, 844), Size(360, 800)]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      for (final state in _State.values) {
        final variant = VisualTestVariant(size, scale);
        testWidgets('team detail ${state.name} ${variant.label}', (
          tester,
        ) async {
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          addTearDown(() {
            tester.view
              ..resetPhysicalSize()
              ..resetDevicePixelRatio();
          });
          final loading = Completer<SocialTeamDetail>();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                appConfigProvider.overrideWithValue(phase6Config),
                appServicesProvider.overrideWithValue(const AppServices.noop()),
                appPreferencesProvider.overrideWithBuild(
                  (ref, notifier) async =>
                      const AppPreferences(reducedMotion: true),
                ),
                socialRepositoryProvider.overrideWithValue(
                  FakeSocialRepository(),
                ),
                socialTeamDetailProvider.overrideWith((ref, id) {
                  if (state == _State.loading) return loading.future;
                  if (state == _State.error) {
                    return Future.error(
                      StateError('private team backend details'),
                    );
                  }
                  return Future.value(_teamFor(state));
                }),
              ],
              child: testApp(
                MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                    padding: const EdgeInsets.only(top: 47, bottom: 34),
                    viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
                  ),
                  child: const SocialTeamScreen(teamId: 'team-fixture'),
                ),
                theme: AppTheme.light,
              ),
            ),
          );
          if (state == _State.loading) {
            await tester.pump(const Duration(milliseconds: 100));
          } else {
            await tester.pumpAndSettle();
          }
          final dataState = state != _State.loading && state != _State.error;
          expect(
            find.byKey(const ValueKey('team-identity-hero')),
            dataState ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(const ValueKey('team-identity-artwork')),
            dataState ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(const ValueKey('team-weekly-mvp')),
            state == _State.mvp ? findsOneWidget : findsNothing,
          );
          if (state == _State.empty && scale > 1.4) {
            await tester.drag(
              find.byKey(const ValueKey('team-detail-scroll')),
              const Offset(0, -620),
            );
            await tester.pumpAndSettle();
          }
          expect(
            find.byKey(const ValueKey('team-empty-roster')),
            state == _State.empty ? findsOneWidget : findsNothing,
          );
          final images = tester.widgetList<Image>(find.byType(Image)).toList();
          final context = tester.element(find.byType(MaterialApp));
          await tester.runAsync(
            () => Future.wait(
              images.map((image) => precacheImage(image.image, context)),
            ),
          );
          await tester.pump();
          await verifyVisual(
            tester,
            find.byType(MaterialApp),
            'goldens/team_detail_review/${state.name}_${size.width.round()}x${size.height.round()}.png',
            variant,
          );
          expect(find.textContaining('private team backend'), findsNothing);
        });
      }
    }
  }
}

SocialTeamDetail _teamFor(_State state) {
  final isMember = state == _State.member;
  final isEmpty = state == _State.empty;
  final hasMvp = state == _State.mvp;
  return SocialTeamDetail(
    id: 'team-fixture',
    name: 'صقور الجزيرة',
    description: 'مجلس خاص لأعضاء الفريق.',
    primaryColor: '#5F8F0F',
    badgeSeed: '11',
    currentRole: isMember ? 'member' : 'owner',
    currentUserId: isMember ? 'member-1' : 'owner',
    members: isEmpty ? const [] : _members,
    challenges: const [],
    activity: const [],
    weeklyMvp: hasMvp ? _members.first : null,
  );
}

const _members = [
  SocialTeamMember(
    userId: 'owner',
    displayName: 'سلمان الحربي',
    role: 'owner',
    level: 12,
    weeklyPoints: 420,
    rank: 1,
  ),
  SocialTeamMember(
    userId: 'member-1',
    displayName: 'خالد العتيبي',
    role: 'member',
    level: 8,
    weeklyPoints: 280,
    rank: 2,
  ),
  SocialTeamMember(
    userId: 'member-2',
    displayName: 'نواف القحطاني',
    role: 'admin',
    level: 7,
    weeklyPoints: 195,
    rank: 3,
  ),
];
